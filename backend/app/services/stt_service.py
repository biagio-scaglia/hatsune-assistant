import os
import asyncio
import logging
from typing import Optional
from faster_whisper import WhisperModel
import ctranslate2
from ..core.config import settings

logger = logging.getLogger(__name__)

class STTService:
    """
    Servizio per la trascrizione vocale locale (Speech-to-Text) basato su faster-whisper.
    Carica il modello in modo pigro (lazy loading) e thread-safe al primo utilizzo.
    """
    _instance = None
    _model: Optional[WhisperModel] = None
    _lock = asyncio.Lock()

    def __new__(cls, *args, **kwargs):
        if not cls._instance:
            cls._instance = super(STTService, cls).__new__(cls)
        return cls._instance

    async def load_model(self) -> WhisperModel:
        """
        Carica in memoria il modello Whisper in modo pigro.
        Utilizza un lock asincrono per garantire il caricamento una sola volta.
        """
        if self._model is not None:
            return self._model

        async with self._lock:
            if self._model is not None:
                return self._model

            model_size = settings.STT_MODEL_SIZE
            device = settings.STT_DEVICE
            compute_type = settings.STT_COMPUTE_TYPE

            # Rilevamento automatico della GPU tramite ctranslate2
            if device == "auto":
                try:
                    cuda_count = ctranslate2.get_cuda_device_count()
                    if cuda_count > 0:
                        device = "cuda"
                        # Usa float16 su GPU se non specificato altrimenti
                        if compute_type == "int8":
                            compute_type = "float16"
                    else:
                        device = "cpu"
                except Exception as e:
                    logger.warning(f"[STT] Errore durante il rilevamento dei device CUDA ({e}). Ripiego su CPU.")
                    device = "cpu"

            # Su CPU float16 non è supportato efficientemente da ctranslate2, ripieghiamo su int8
            if device == "cpu" and compute_type == "float16":
                compute_type = "int8"

            logger.info(
                f"[STT] Inizializzazione modello Whisper: size={model_size} | "
                f"device={device} | compute_type={compute_type}"
            )

            def _init_model():
                # Se è definito un percorso locale per il modello, lo usa direttamente
                if settings.STT_MODEL_PATH and os.path.exists(settings.STT_MODEL_PATH):
                    logger.info(f"[STT] Caricamento modello locale da: {settings.STT_MODEL_PATH}")
                    return WhisperModel(settings.STT_MODEL_PATH, device=device, compute_type=compute_type)
                else:
                    logger.info(f"[STT] Download/Caricamento modello '{model_size}' da Hugging Face...")
                    return WhisperModel(model_size, device=device, compute_type=compute_type)

            try:
                # Esegue l'inizializzazione sincrona (I/O & CPU-bound) in un thread pool
                self._model = await asyncio.to_thread(_init_model)
                logger.info("[STT] Modello Whisper caricato con successo ed attivo.")
            except Exception as e:
                logger.error(f"[STT] Errore critico nel caricamento di Whisper: {e}")
                raise RuntimeError(f"Impossibile caricare il modello Whisper: {e}")

            return self._model

    async def transcribe(self, file_path: str, language: Optional[str] = None) -> str:
        """
        Trascrive un file audio sul disco in testo, eseguendo la computazione in un threadpool.
        """
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"File audio da trascrivere non trovato: {file_path}")

        # Assicura il caricamento del modello
        model = await self.load_model()
        beam_size = settings.STT_BEAM_SIZE
        target_lang = language or settings.STT_DEFAULT_LANGUAGE

        if target_lang == "auto":
            target_lang = None  # Rilevamento automatico della lingua da Whisper

        def _execute_transcription():
            logger.info(f"[STT] Avvio trascrizione per il file: {os.path.basename(file_path)}")
            segments, info = model.transcribe(
                file_path,
                beam_size=beam_size,
                language=target_lang
            )
            # Concatena i testi dei vari segmenti
            transcript_text = "".join([segment.text for segment in segments])
            logger.info(
                f"[STT] Trascrizione ultimata. Lingua: {info.language} "
                f"(probabilità={info.language_probability:.2f})"
            )
            return transcript_text.strip()

        try:
            return await asyncio.to_thread(_execute_transcription)
        except Exception as e:
            logger.error(f"[STT] Eccezione riscontrata durante la trascrizione: {e}")
            raise RuntimeError(f"Errore di trascrizione audio locale: {str(e)}")
