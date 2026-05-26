import os
import uuid
import math
import struct
import wave
import logging
from typing import Optional
from ..core.config import settings
from .base_tts import BaseTTSService

logger = logging.getLogger(__name__)

# Definizione dei percorsi per il salvataggio dei file statici audio
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
APP_DIR = os.path.dirname(CURRENT_DIR)
AUDIO_DIR = os.path.join(APP_DIR, "static", "generated_audio")

# Assicura che la directory per i file audio statici esista
os.makedirs(AUDIO_DIR, exist_ok=True)

# Tentativo di caricamento di Kokoro e dipendenze
has_kokoro = False
pipeline = None
np = None
sf = None

try:
    from kokoro import KPipeline
    import soundfile as sf
    import numpy as np
    
    # Inizializziamo la pipeline con la lingua di default
    pipeline = KPipeline(lang_code=settings.TTS_DEFAULT_LANG)
    has_kokoro = True
    logger.info(f"[TTS] Kokoro TTS caricato con successo con lingua: {settings.TTS_DEFAULT_LANG}")
except Exception as e:
    np = None
    sf = None
    logger.warning(
        f"[TTS] Kokoro TTS o soundfile non caricati ({e}). "
        "Verra' utilizzata la modalita' Fallback (sintesi sinusoidale)."
    )


class TTSService(BaseTTSService):
    """
    Servizio concreto per la sintesi vocale locale (TTS).
    Integra Kokoro TTS e si adatta a un generatore sinusoidale in caso di dipendenze mancanti.
    """

    async def synthesize(
        self,
        text: str,
        voice: Optional[str] = None,
        speed: Optional[float] = None
    ) -> str:
        """
        Sintetizza il testo e salva il file audio in formato WAV.
        Restituisce solo il nome del file generato.
        """
        if not text.strip():
            raise ValueError("Il testo per la sintesi vocale non puo' essere vuoto.")

        # Risoluzione parametri di default
        active_voice = voice or settings.TTS_DEFAULT_VOICE
        active_speed = speed or settings.TTS_DEFAULT_SPEED
        
        filename = f"audio_{uuid.uuid4().hex}.wav"
        filepath = os.path.join(AUDIO_DIR, filename)

        if has_kokoro and pipeline is not None and np is not None and sf is not None:
            try:
                # Esegue la sintesi vocale con Kokoro
                # split_pattern serve a gestire frasi lunghe andando a capo
                generator = pipeline(
                    text,
                    voice=active_voice,
                    speed=active_speed,
                    split_pattern=r'\n+'
                )

                audio_chunks = []
                for _, _, audio in generator:
                    audio_chunks.append(audio)

                if audio_chunks:
                    # Concatena i blocchi audio generati da Kokoro e scrive il file WAV
                    concatenated_audio = np.concatenate(audio_chunks)
                    sf.write(filepath, concatenated_audio, 24000)
                    logger.info(f"[TTS] Audio generato tramite Kokoro TTS: {filename} (voce: {active_voice}, speed: {active_speed})")
                    self._cleanup_old_files()
                    return filename
                else:
                    logger.warning("[TTS] Il generatore Kokoro ha restituito chunk vuoti. Eseguo fallback.")
            except Exception as e:
                logger.error(f"[TTS] Errore sintesi Kokoro ({e}). Eseguo fallback.")

        # Se Kokoro non è installato o fallisce, utilizziamo il fallback a onda sinusoidale (beep)
        self._generate_fallback_wav(filepath, text)
        logger.info(f"[TTS] Audio generato in modalita' Fallback (beep sinusoidale): {filename}")
        self._cleanup_old_files()
        return filename

    def _generate_fallback_wav(self, filepath: str, text: str):
        """
        Genera un file audio di fallback valido senza dipendenze esterne.
        Genera un tono ad altezza variabile in base alla lunghezza del testo.
        """
        sample_rate = 24000
        # Durata proporzionale alla lunghezza del testo (minimo 1s, massimo 4s)
        duration_sec = min(max(len(text) * 0.05, 1.0), 4.0)
        num_samples = int(duration_sec * sample_rate)
        
        # Frequenza base varia a seconda del testo per dare un minimo di variabilita'
        frequency = 350.0 + (len(text) % 5) * 50.0

        with wave.open(filepath, 'wb') as wav_file:
            # 1 canale (mono), 16-bit (2 byte/campione), 24kHz
            wav_file.setnchannels(1)
            wav_file.setsampwidth(2)
            wav_file.setframerate(sample_rate)
            
            for i in range(num_samples):
                # Genera una sinusoide semplice
                t = float(i) / sample_rate
                # Modulazione a frequenza di vibrato leggero per renderlo piu' "cyber"
                mod_freq = frequency + 20.0 * math.sin(2.0 * math.pi * 6.0 * t)
                value = int(16000.0 * math.sin(2.0 * math.pi * mod_freq * t))
                
                # Applica fade-in e fade-out (inviluppo semplice) per evitare click acustici
                if i < 2400: # primi 0.1 secondi (fade-in)
                    value = int(value * (i / 2400.0))
                elif i > num_samples - 2400: # ultimi 0.1 secondi (fade-out)
                    value = int(value * ((num_samples - i) / 2400.0))
                    
                data = struct.pack('<h', value)
                wav_file.writeframesraw(data)

    def _cleanup_old_files(self):
        """
        Strategia di pulizia dei file audio statici generati.
        Cancella i file piu' vecchi di 10 minuti o se superano i 50 file totali.
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
                # Lascia gli ultimi 50 file e cancella i rimanenti
                for f in files[:-50]:
                    try:
                        os.remove(f)
                        logger.info(f"[TTS] Eliminato file audio eccedente: {os.path.basename(f)}")
                    except OSError:
                        continue
        except Exception as e:
            logger.error(f"[TTS] Errore durante la pulizia dei file statici: {e}")
