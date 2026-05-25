# 🌟 Hatsune Assistant 🌟

> A premium responsive Flutter mockup interface of a coding assistant featuring Hatsune Miku as an interactive 3D avatar.
> Made with 🩵 by **biagigio**.

---

## 📸 Overview & Features

Hatsune Assistant combines the charm of Hatsune Miku with a sleek, futuristic developer-centric UI. The layout is fully responsive, adjusting seamlessly between Desktop/Tablet and Mobile viewport orientations.

- **Responsive Design System**: 
  - **Desktop/Tablet**: Split-pane layout with the mock chat panel on the left and the 3D model viewer on the right.
  - **Mobile**: Top-to-bottom layout prioritizing the 3D model on top, and chat workflow below.
- **Dynamic 3D Models**: Integrated using `model_viewer_plus`, rendering Hatsune Miku in real-time GLB format.
- **Interactive States**: Instantly toggle Miku between two functional poses:
  - 💬 **Talking**: Active when responding or explaining.
  - 🧠 **Thinking**: Triggered when processing code or working on solutions.
- **Modern UI styling**: Uses custom glassmorphism, glowing accents, cyan & dark-mode elements matching Hatsune Miku's signature palette (#39C5BB).

---

## 📦 3D Models (glTF/GLB)

You can explore the high-fidelity 3D models directly on GitHub:

* 🩵 [Visualizza Modello 3D - Talking (talking.glb)](assets/models/talking.glb)
* 🩵 [Visualizza Modello 3D - Thinking (thinking.glb)](assets/models/thinking.glb)

*GitHub natively supports rendering 3D files inside its web interface. Click the links above to rotate and preview Miku!*

---

## 🛠️ Tech Stack & Dependencies

- **Language**: Dart
- **Framework**: Flutter
- **3D Render Engine**: `model_viewer_plus` (supports interactive touch controls, auto-rotation, and animation control)

---

## 🚀 Setup & Execution

1. **Clone the repository**:
   ```bash
   git clone https://github.com/biagio-scaglia/hatsune-assistant.git
   cd hatsune-assistant
   ```

2. **Fetch dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify structure and analyze code**:
   ```bash
   flutter analyze
   ```

4. **Run the App**:
   - For **Android / iOS**: Ensure a device or emulator is running, then run:
     ```bash
     flutter run
     ```
   - For **Web** (make sure you have the Flutter web SDK configured):
     ```bash
     flutter run -d chrome
     ```

---

## 📁 File Structure

```text
lib/
├── main.dart                 # Application entrypoint
├── theme/
│   └── app_theme.dart        # Cyberpunk & Dark/Cyan custom theme
└── widgets/
    ├── app_header.dart       # Responsive App Bar with branding
    ├── miku_viewer_panel.dart# Handles 3D rendering and state switching
    ├── mock_chat_panel.dart  # Interactive chat flow mockup
    ├── responsive_shell.dart # Responsive layout builder (Desktop vs Mobile)
    └── state_switcher.dart   # Floating state controls
```

---

*Hatsune Miku is a trademark of Crypton Future Media, INC. This project is a UI mockup made for display purposes by biagigio.*
