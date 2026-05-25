# 🌟 Hatsune Assistant 🌟

> Un'interfaccia mockup premium e responsive sviluppata in Flutter per un assistente alla programmazione avanzato, con Hatsune Miku come presenza 3D.
> Realizzato con 🩵 da **biagigio**.

---

## 📸 Panoramica del Progetto

Hatsune Assistant unisce l'estetica cibernetica di Hatsune Miku con una UI scura, moderna ed estremamente curata per sviluppatori. Questo aggiornamento introduce un'architettura modulare, un design system coerente e un layout completamente responsive pronto per ospitare modelli di intelligenza artificiale reali (locali come Ollama o cloud).

- **Design System Cyberpunk**: Palette scura antracite (`#080B11`), accenti cyan Miku (`#39C5BB`) e sfumature rosa neon (`#FF6B9D`).
- **Layout Altamente Responsive**:
  - **Mobile**: Navigazione inferiore fluida (`NavigationBar`) e visualizzazione a colonna singola che si adatta all'apertura della tastiera.
  - **Tablet & Desktop**: Navigazione laterale (`NavigationRail`) con ripartizione ottimale dello spazio di lavoro.
- **Predisposizione Modelli (Ollama/Cloud)**: Schermata avanzata di selezione dei modelli (ispirata a Chatbox) con filtri dinamici, indicatori di download locale, stato di attività e provider.
- **Struttura Modulare e Scalabile**: Organizzazione del codice suddivisa per feature (`home`, `chat`, `models`, `settings`) in modo da favorire la manutenibilità e le future integrazioni.

---

## 📦 Modelli 3D (glTF/GLB)

L'applicazione è configurata per ospitare l'avatar 3D di Hatsune Miku. Puoi esplorare e orbitare i file 3D nativi direttamente nell'interfaccia di GitHub:

* 🩵 [Visualizza Modello 3D - Talking (talking.glb)](assets/models/talking.glb)
* 🩵 [Visualizza Modello 3D - Thinking (thinking.glb)](assets/models/thinking.glb)

---

## 🛠️ Stack Tecnologico & Dipendenze

- **Linguaggio**: Dart
- **Framework**: Flutter (Material 3)
- **Motore 3D (Predisposto)**: `model_viewer_plus`
- **Font del Brand**: Google Fonts (*Rajdhani* per i titoli, *Inter* per i contenuti)

---

## 🚀 Installazione ed Esecuzione

1. **Clona il repository**:
   ```bash
   git clone https://github.com/biagio-scaglia/hatsune-assistant.git
   cd hatsune-assistant
   ```

2. **Scarica le dipendenze**:
   ```bash
   flutter pub get
   ```

3. **Verifica l'integrità del codice**:
   ```bash
   flutter analyze
   ```

4. **Avvia i Test**:
   ```bash
   flutter test
   ```

5. **Esegui l'Applicazione**:
   - Per dispositivi mobile (Android/iOS) o simulatori:
     ```bash
     flutter run
     ```
   - Per il browser (Chrome/Edge):
     ```bash
     flutter run -d chrome
     ```

---

## 📁 Struttura delle Cartelle

```text
lib/
├── core/
│   ├── design_system/
│   │   ├── app_colors.dart         # Palette e gradienti cyberpunk
│   │   ├── app_spacing.dart        # Margini, padding e raggi dei bordi
│   │   └── app_theme.dart          # Tema globale scuro Material 3
│   └── responsive/
│       └── breakpoints.dart        # Rilevamento delle dimensioni schermo
├── features/
│   ├── home/                       # Dashboard iniziale e metriche di stato
│   ├── chat/                       # UI chat a bolle con gestione tastiera
│   ├── models/                     # Picker e gestione Ollama/Cloud
│   └── settings/                   # Impostazioni di configurazione ed host
├── shared/
│   └── widgets/
│       ├── app_shell.dart          # Shell responsive con barra di navigazione
│       ├── app_top_bar.dart        # Header premium con stato di connessione
│       └── glass_card.dart         # Card semitrasparenti con bordi definiti
└── main.dart                       # Punto di ingresso dell'app
```

---

*Hatsune Miku è un marchio registrato di Crypton Future Media, INC. Questo progetto è una UI mockup ad uso dimostrativo sviluppata da biagigio.*
