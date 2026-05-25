# 🌟 Hatsune Assistant 🌟

> Un assistente alla programmazione interattivo sviluppato in Flutter, con Hatsune Miku come presenza 3D animata collegata a modelli LLM Ollama locali e in Cloud.
> Realizzato con 🩵 da **biagigio**.

---

## 📸 Panoramica del Progetto

Hatsune Assistant unisce l'estetica cyberpunk di Hatsune Miku con una UI scura, moderna ed estremamente responsive progettata per sviluppatori. L'applicazione è realmente connessa a un'istanza locale di Ollama ed è in grado di inviare prompt ed elencare i modelli installati sul tuo PC, integrando al contempo un modello 3D interattivo che reagisce in tempo reale.

### 🩵 Stati e Pose della Miku 3D
L'avatar 3D cambia posa a seconda dello stato di elaborazione dell'assistente:
- **Idle** (`idle.glb`): Stato di riposo/attesa predefinito (con auto-rotazione attiva).
- **Thinking** (`thinking.glb`): Miku si concentra mentre Ollama elabora la risposta.
- **Talking** (`talking.glb`): Miku parla ed espone l'output testuale generato.
- **Victory** (`victory.glb`): Miku festeggia quando riceve complimenti o riscontri positivi (es. scrivendo *"grazie"*, *"bella risposta"*, *"ottimo"*, *"brava"*, *"perfetto"* nella chat), per poi tornare automaticamente in stato Idle dopo 5 secondi.

---

## 🚀 Funzionalità Principali

- **Connessione Ollama Locale & Cloud**:
  - Rilevamento automatico dello stato del server Ollama (online/offline) tramite API.
  - Caricamento dinamico dei modelli installati in locale (`GET /api/tags`).
  - Supporto per modelli in Cloud preconfigurati: `kimi-k2.6:cloud`, `glm-5.1:cloud`, `qwen3.5:cloud`, `nemotron-3-super:cloud`, `gemma4:31b-cloud`.
  - Configurazione dinamica dell'indirizzo host Ollama dalla schermata impostazioni.
- **Chat Reale**: Invia i messaggi all'API di chat di Ollama e mostra le risposte a schermo in tempo reale.
- **Layout Responsive Premium**:
  - **Desktop/Tablet**: Split-screen con barra di navigazione laterale (`NavigationRail`) e visualizzatore Miku 3D persistente sulla destra.
  - **Mobile**: Navigazione inferiore (`NavigationBar`) e visualizzatore Miku 3D posizionato in alto, che si adatta intelligentemente per prevenire overflow quando compare la tastiera.
- **Design System Cyberpunk**: Colori antracite, cyan Miku `#39C5BB` e rosa neon `#FF6B9D`, arricchiti da pannelli con effetto Glassmorphism.

---

## 📦 Modelli 3D (glTF/GLB)

I file 3D dell'assistente sono inclusi localmente nel progetto. Puoi visualizzarli ed orbitarli in 3D nativo direttamente su GitHub ai seguenti link:

* 🩵 [Visualizza Modello 3D - Idle (idle.glb)](assets/models/idle.glb)
* 🩵 [Visualizza Modello 3D - Thinking (thinking.glb)](assets/models/thinking.glb)
* 🩵 [Visualizza Modello 3D - Talking (talking.glb)](assets/models/talking.glb)
* 🩵 [Visualizza Modello 3D - Victory (victory.glb)](assets/models/victory.glb)

---

## 🛠️ Stack Tecnologico & Dipendenze

- **Linguaggio**: Dart
- **Framework**: Flutter (Material 3)
- **Dipendenze Chiave**:
  - `model_viewer_plus`: rendering 3D interattivo dei file GLB.
  - `http`: per le chiamate API REST verso il server Ollama.
  - `google_fonts`: per i font *Rajdhani* (titoli futuristici) e *Inter* (corpo del testo).

---

## 🚀 Installazione ed Esecuzione

### 1. Avvia Ollama in locale
Assicurati che Ollama sia in esecuzione sulla porta standard `11434` e che sia presente almeno un modello (es. `llama3`):
```bash
ollama run llama3
```

### 2. Clona ed esegui l'app Flutter
```bash
# Clona il repository
git clone https://github.com/biagio-scaglia/hatsune-assistant.git
cd hatsune-assistant

# Scarica le dipendenze
flutter pub get

# Avvia l'analisi statica (0 errori garantiti)
flutter analyze

# Avvia i test unitari e di widget
flutter test

# Avvia l'applicazione
flutter run
```

---

## 📁 Struttura delle Cartelle

```text
lib/
├── core/
│   ├── design_system/
│   │   ├── app_colors.dart         # Colori cyberpunk e sfumature neon
│   │   ├── app_spacing.dart        # Margini, padding e raggi dei bordi costanti
│   │   └── app_theme.dart          # Tema scuro globale configurato
│   ├── responsive/
│   │   └── breakpoints.dart        # Rilevamento delle dimensioni dello schermo
│   └── services/
│       └── ollama_service.dart     # Chiamate API tags e chat per Ollama
│   └── state/
│       └── assistant_state.dart    # Gestore dello stato reattivo e pose 3D
├── features/
│   ├── home/                       # Dashboard iniziale e statistiche connessione
│   ├── chat/                       # UI chat reale e gestione input/tastiera
│   ├── models/                     # Picker modelli Ollama locali e cloud
│   └── settings/                   # Impostazione dell'URL host Ollama
├── shared/
│   └── widgets/
│       ├── app_shell.dart          # Navigazione responsive (Rail vs BottomNav)
│       ├── app_top_bar.dart        # Barra superiore con stato del server
│       ├── glass_card.dart         # Card semitrasparenti con bordi neon
│       └── miku_3d_viewer.dart     # Caricamento dinamico dei modelli GLB
└── main.dart                       # Entry point ed iniezione dello stato
```

---

*Hatsune Miku è un marchio registrato di Crypton Future Media, INC. Questo progetto è sviluppato ad uso dimostrativo da biagigio.*
