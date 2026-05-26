import os
import uuid
import math
import struct
import wave
import logging
import urllib.request
import zipfile
import shutil
import subprocess
import threading
from typing import Optional, Tuple, Dict
from starlette.concurrency import run_in_threadpool
from ..core.config import settings
from .base_tts import BaseTTSService

logger = logging.getLogger(__name__)

# Definizione dei percorsi fondamentali del backend
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
APP_DIR = os.path.dirname(CURRENT_DIR)
BACKEND_DIR = os.path.dirname(APP_DIR)

# Risoluzione della directory audio
if settings.AUDIO_OUTPUT_DIR:
    if not os.path.isabs(settings.AUDIO_OUTPUT_DIR):
        AUDIO_DIR = os.path.abspath(os.path.join(BACKEND_DIR, settings.AUDIO_OUTPUT_DIR))
    else:
        AUDIO_DIR = settings.AUDIO_OUTPUT_DIR
else:
    AUDIO_DIR = os.path.join(APP_DIR, "static", "generated_audio")

# Risoluzione della directory binari e modelli per Piper
BIN_DIR = os.path.abspath(os.path.join(BACKEND_DIR, "bin", "piper"))
VOICES_DIR = os.path.join(BIN_DIR, "voices")

# Assicura la presenza delle directory richieste
os.makedirs(AUDIO_DIR, exist_ok=True)
os.makedirs(BIN_DIR, exist_ok=True)
os.makedirs(VOICES_DIR, exist_ok=True)

# URL statiche e mappature per il download dei modelli di default
VOICE_URLS: Dict[str, Dict[str, str]] = {
    "it_IT-riccardo-x_low": {
        "onnx": "https://huggingface.co/rhasspy/piper-voices/resolve/main/it/it_IT/riccardo/x_low/it_IT-riccardo-x_low.onnx",
        "json": "https://huggingface.co/rhasspy/piper-voices/resolve/main/it/it_IT/riccardo/x_low/it_IT-riccardo-x_low.onnx.json"
    },
    "en_US-lessac-medium": {
        "onnx": "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx",
        "json": "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json"
    }
}


class TTSService(BaseTTSService):
    """
    Servizio per la sintesi vocale locale (TTS) basato su Piper.
    Scarica automaticamente l'eseguibile di Piper e i modelli ONNX in background
    al primo avvio e gestisce la sintesi vocale tramite esecuzione CLI non bloccante.
    """

    def __init__(self):
        self.download_in_progress = False
        self.download_error: Optional[str] = None
        self.piper_ready = False
        
        # Avvia l'inizializzazione in background per non bloccare lo startup del server
        threading.Thread(target=self._initialize_assets_sync, daemon=True).start()

    def _resolve_piper_exe(self) -> Optional[str]:
        """
        Trova il percorso locale dell'eseguibile piper.exe
        """
        path_extracted = os.path.join(BIN_DIR, "piper", "piper.exe")
        path_flat = os.path.join(BIN_DIR, "piper.exe")
        
        if os.path.exists(path_extracted):
            return path_extracted
        if os.path.exists(path_flat):
            return path_flat
        return None

    def _get_model_urls(self, voice_name: str) -> Tuple[str, str]:
        """
        Trova l'URL di download (.onnx e .json) per una data voce,
        costruendo dinamicamente l'URL di Hugging Face se non mappata.
        """
        if voice_name in VOICE_URLS:
            return VOICE_URLS[voice_name]["onnx"], VOICE_URLS[voice_name]["json"]
            
        # Costruzione dinamica dell'URL secondo la convenzione Piper su Hugging Face
        # Formato atteso: locale-voce-qualita (es: it_IT-riccardo-x_low)
        parts = voice_name.split("-")
        if len(parts) == 3:
            locale, name, quality = parts
            lang = locale.split("_")[0]
            onnx_url = f"https://huggingface.co/rhasspy/piper-voices/resolve/main/{lang}/{locale}/{name}/{quality}/{voice_name}.onnx"
            json_url = f"https://huggingface.co/rhasspy/piper-voices/resolve/main/{lang}/{locale}/{name}/{quality}/{voice_name}.onnx.json"
            return onnx_url, json_url
            
        # Fallback di default su Riccardo in italiano
        logger.warning(f"[TTS] Nome voce '{voice_name}' non standard. Utilizzo fallback su 'it_IT-riccardo-x_low'.")
        return VOICE_URLS["it_IT-riccardo-x_low"]["onnx"], VOICE_URLS["it_IT-riccardo-x_low"]["json"]

    def _download_file(self, url: str, dest_path: str):
        """
        Scarica un file da un URL salvandolo temporaneamente e rinominandolo a completamento.
        """
        logger.info(f"[TTS] Download: {url} -> {dest_path}")
        os.makedirs(os.path.dirname(dest_path), exist_ok=True)
        
        temp_path = dest_path + ".tmp"
        try:
            req = urllib.request.Request(
                url, 
                headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
            )
            with urllib.request.urlopen(req) as response, open(temp_path, "wb") as out_file:
                shutil.copyfileobj(response, out_file)
            
            if os.path.exists(dest_path):
                os.remove(dest_path)
            os.rename(temp_path, dest_path)
            logger.info(f"[TTS] Download completato: {dest_path}")
        except Exception as e:
            if os.path.exists(temp_path):
                try:
                    os.remove(temp_path)
                except OSError:
                    pass
            logger.error(f"[TTS] Errore di download per {url}: {e}")
            raise e

    def _extract_zip(self, zip_path: str, extract_to: str):
        """
        Estrae un file zip in una cartella locale.
        """
        logger.info(f"[TTS] Estrazione: {zip_path} -> {extract_to}")
        try:
            with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                zip_ref.extractall(extract_to)
            logger.info("[TTS] Estrazione completata con successo.")
        except Exception as e:
            logger.error(f"[TTS] Estrazione fallita: {e}")
            raise e

    def _initialize_assets_sync(self):
        """
        Procedura sincrona di inizializzazione degli asset di Piper eseguita all'avvio.
        """
        self.download_in_progress = True
        try:
            # 1. Verifica ed eventuale download di piper.exe standalone
            piper_exe = self._resolve_piper_exe()
            if not piper_exe:
                logger.info("[TTS] Eseguibile piper.exe non trovato. Avvio download di Piper standalone per Windows...")
                zip_url = "https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper_windows_amd64.zip"
                zip_path = os.path.join(BIN_DIR, "piper_windows_amd64.zip")
                
                self._download_file(zip_url, zip_path)
                self._extract_zip(zip_path, BIN_DIR)
                
                try:
                    os.remove(zip_path)
                except OSError:
                    pass
                
                piper_exe = self._resolve_piper_exe()
                if not piper_exe:
                    raise FileNotFoundError("piper.exe non e' presente dopo l'estrazione dello zip.")
            
            # 2. Verifica ed eventuale download del modello vocale di default
            default_voice = settings.TTS_DEFAULT_VOICE
            self._ensure_voice_model_sync(default_voice)
            
            self.piper_ready = True
            logger.info(f"[TTS] Piper TTS pronto per la sintesi. Eseguibile: {piper_exe}")
        except Exception as e:
            self.download_error = str(e)
            logger.error(f"[TTS] Inizializzazione Piper TTS fallita ({e}). Verra' utilizzata la modalita' Fallback (beep).")
        finally:
            self.download_in_progress = False

    def _ensure_voice_model_sync(self, voice_name: str) -> Tuple[str, str]:
        """
        Assicura la presenza locale del file .onnx e .json del modello vocale specificato.
        Ritorna la tupla (percorso_model_onnx, percorso_config_json).
        """
        # Se sono configurati dei path espliciti statici nel .env, li usiamo direttamente
        if settings.PIPER_MODEL_PATH and settings.PIPER_CONFIG_PATH:
            if os.path.exists(settings.PIPER_MODEL_PATH) and os.path.exists(settings.PIPER_CONFIG_PATH):
                return settings.PIPER_MODEL_PATH, settings.PIPER_CONFIG_PATH
            else:
                logger.warning(
                    "[TTS] PIPER_MODEL_PATH o PIPER_CONFIG_PATH non validi. Uso cartella interna."
                )

        model_path = os.path.join(VOICES_DIR, f"{voice_name}.onnx")
        config_path = os.path.join(VOICES_DIR, f"{voice_name}.onnx.json")
        
        if os.path.exists(model_path) and os.path.exists(config_path):
            return model_path, config_path
            
        logger.info(f"[TTS] Modello '{voice_name}' non trovato. Avvio download automatico...")
        onnx_url, json_url = self._get_model_urls(voice_name)
        
        self._download_file(onnx_url, model_path)
        self._download_file(json_url, config_path)
        
        return model_path, config_path

    async def synthesize(
        self,
        text: str,
        voice: Optional[str] = None,
        speed: Optional[float] = None
    ) -> str:
        """
        Sintetizza il testo in formato WAV in modo asincrono delegandolo a un thread pool.
        """
        if not text.strip():
            raise ValueError("Il testo per la sintesi vocale non puo' essere vuoto.")

        active_voice = voice or settings.TTS_DEFAULT_VOICE
        active_speed = speed or settings.TTS_DEFAULT_SPEED
        
        filename = f"audio_{uuid.uuid4().hex}.wav"
        filepath = os.path.join(AUDIO_DIR, filename)

        await run_in_threadpool(
            self._synthesize_sync,
            text=text,
            filepath=filepath,
            voice=active_voice,
            speed=active_speed
        )

        return filename

    def _synthesize_sync(
        self,
        text: str,
        filepath: str,
        voice: str,
        speed: float
    ) -> None:
        """
        Esegue la chiamata sincrona all'eseguibile di Piper tramite subprocess.
        In caso di errori, ripiega sulla generazione di un tono sinusoidale di fallback.
        """
        piper_exe = self._resolve_piper_exe()
        
        if not piper_exe:
            logger.warning("[TTS] Eseguibile piper.exe non disponibile. Uso il fallback a beep.")
            self._generate_fallback_wav(filepath, text)
            self._cleanup_old_files()
            return
            
        try:
            # 1. Assicura che la voce richiesta sia scaricata localmente
            model_path, config_path = self._ensure_voice_model_sync(voice)
            
            # 2. Calcola la velocita' come inverse length scale (1.0 / speed)
            length_scale = 1.0 / speed
            
            # 3. Individua ed assegna la cartella espeak-ng-data per la fonemizzazione
            piper_dir = os.path.dirname(piper_exe)
            espeak_data = os.path.join(piper_dir, "espeak-ng-data")
            
            cmd = [
                piper_exe,
                "--model", model_path,
                "--output_file", filepath,
                "--length-scale", f"{length_scale:.2f}"
            ]
            
            if os.path.exists(espeak_data):
                cmd.extend(["--espeak-data", espeak_data])
                
            logger.info(f"[TTS] Esecuzione subprocess Piper per voce '{voice}'...")
            
            env = os.environ.copy()
            if os.path.exists(espeak_data):
                env["ESPEAK_DATA_PATH"] = espeak_data
                
            # Esegue piper scrivendo il testo in input tramite stdin
            process = subprocess.Popen(
                cmd,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                encoding="utf-8",
                cwd=piper_dir,
                creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
            )
            
            stdout, stderr = process.communicate(input=text)
            
            if process.returncode != 0:
                logger.error(f"[TTS] Piper terminato con codice d'errore {process.returncode}. Stderr: {stderr}")
                raise RuntimeError(f"Piper fallito con errore: {stderr}")
                
            # Verifica la corretta generazione del file audio WAV
            if os.path.exists(filepath) and os.path.getsize(filepath) > 0:
                logger.info(f"[TTS] Sintesi completata con successo: {os.path.basename(filepath)}")
            else:
                raise FileNotFoundError("Il file audio non e' stato creato o risulta vuoto.")
                
        except Exception as e:
            logger.error(f"[TTS] Errore durante la sintesi vocale Piper ({e}). Uso fallback sinusoidale.")
            self._generate_fallback_wav(filepath, text)
            
        self._cleanup_old_files()

    def _generate_fallback_wav(self, filepath: str, text: str):
        """
        Genera un bip sinusoidale cyber come fallback in caso di fallimento o assenza degli asset.
        """
        sample_rate = 24000
        duration_sec = min(max(len(text) * 0.05, 1.0), 4.0)
        num_samples = int(duration_sec * sample_rate)
        frequency = 350.0 + (len(text) % 5) * 50.0

        with wave.open(filepath, 'wb') as wav_file:
            wav_file.setnchannels(1)
            wav_file.setsampwidth(2)
            wav_file.setframerate(sample_rate)
            
            for i in range(num_samples):
                t = float(i) / sample_rate
                mod_freq = frequency + 20.0 * math.sin(2.0 * math.pi * 6.0 * t)
                value = int(16000.0 * math.sin(2.0 * math.pi * mod_freq * t))
                
                # Dissolvenze in ingresso ed uscita per evitare disturbi acustici
                if i < 2400:
                    value = int(value * (i / 2400.0))
                elif i > num_samples - 2400:
                    value = int(value * ((num_samples - i) / 2400.0))
                    
                data = struct.pack('<h', value)
                wav_file.writeframesraw(data)

    def _cleanup_old_files(self):
        """
        Mantiene pulita la cartella dei file statici rimuovendo i file WAV piu' vecchi di 10 minuti.
        """
        try:
            import time
            now = time.time()
            if not os.path.exists(AUDIO_DIR):
                return

            files = [
                os.path.join(AUDIO_DIR, f) 
                for f in os.listdir(AUDIO_DIR) 
                if f.startswith("audio_") and f.endswith(".wav")
            ]

            # 1. Rimuove file piu' vecchi di 10 minuti
            for f in files:
                try:
                    if now - os.path.getmtime(f) > 600:
                        os.remove(f)
                        logger.info(f"[TTS] Eliminato file audio scaduto: {os.path.basename(f)}")
                except OSError:
                    continue

            # 2. Se rimangono piu' di 50 file, ordina e cancella i piu' datati
            files = [
                os.path.join(AUDIO_DIR, f) 
                for f in os.listdir(AUDIO_DIR) 
                if f.startswith("audio_") and f.endswith(".wav")
            ]
            if len(files) > 50:
                files.sort(key=os.path.getmtime)
                for f in files[:-50]:
                    try:
                        os.remove(f)
                        logger.info(f"[TTS] Eliminato file audio eccedente: {os.path.basename(f)}")
                    except OSError:
                        continue
        except Exception as e:
            logger.error(f"[TTS] Errore durante la pulizia dei file statici: {e}")
