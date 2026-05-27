import os
import sys
import asyncio
import wave
import struct
import math

# Aggiunge il path della radice del backend per consentire gli import
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from app.services.stt_service import STTService
from app.core.config import settings

def generate_test_wav(filepath: str, duration: float = 1.5):
    """
    Genera un file WAV sinusoidale di test (tono acustico) per validare Whisper.
    """
    sample_rate = 16000
    num_samples = int(duration * sample_rate)
    frequency = 440.0 # Nota LA standard

    print(f"Generazione file WAV di test in: {filepath}...")
    with wave.open(filepath, 'wb') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            t = float(i) / sample_rate
            value = int(16000.0 * math.sin(2.0 * math.pi * frequency * t))
            data = struct.pack('<h', value)
            wav_file.writeframesraw(data)
    print("File WAV generato.")

async def main():
    print("=== TEST PIPELINE VOCALE (STT locale) ===")
    
    # Forza l'uso del modello 'tiny' per eseguire il test in fretta e con poca memoria
    settings.STT_MODEL_SIZE = "tiny"
    settings.STT_DEVICE = "cpu"
    settings.STT_COMPUTE_TYPE = "int8"
    
    print(f"Configurazione temporanea di test: model_size={settings.STT_MODEL_SIZE} | device={settings.STT_DEVICE}")

    stt_service = STTService()
    
    # Percorso del file WAV di test
    test_filepath = os.path.join(os.path.dirname(os.path.abspath(__file__)), "test_input.wav")
    
    # Genera l'audio
    generate_test_wav(test_filepath)
    
    try:
        print("Avvio caricamento modello STT ed esecuzione trascrizione...")
        # Eseguiamo la trascrizione (dovrebbe produrre una stringa vuota o rumore di fondo, l'importante è che la pipeline non crashi)
        transcript = await stt_service.transcribe(test_filepath, language="it")
        print("\n--- RISULTATO DI TEST STT ---")
        print(f"Testo trascritto: \"{transcript}\"")
        print("-----------------------------\n")
        print("[OK] Test della pipeline completato con successo. Whisper è pronto.")
    except Exception as e:
        print(f"\n[ERRORE] Test fallito: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        # Pulisci il file WAV di test
        if os.path.exists(test_filepath):
            try:
                os.remove(test_filepath)
                print("File WAV di test rimosso.")
            except Exception as e:
                print(f"Errore rimozione file di test: {e}")

if __name__ == "__main__":
    asyncio.run(main())
