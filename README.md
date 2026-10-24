# 🛡️ SmokeGuard

<p align="center">
  <img src="https://img.shields.io/badge/Live%20Demo-GitHub%20Pages-success?style=for-the-badge&logo=githubpages&logoColor=white" alt="Live Demo" />
  <a href="https://anupam477.github.io/Smoke-Guard/"><img src="https://img.shields.io/badge/🚀%20Open-Live%20Web%20App-blue?style=for-the-badge" alt="Open App" /></a>
  <a href="https://github.com/Anupam477/Smoke-Guard/releases"><img src="https://img.shields.io/badge/📱%20Download-Android%20APK-green?style=for-the-badge&logo=android&logoColor=white" alt="Download APK" /></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.29.0-02569B?style=flat-square&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-3.7.0-0175C2?style=flat-square&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20Web%20%7C%20iOS-brightgreen?style=flat-square" />
  <img src="https://img.shields.io/badge/Database-Supabase%20%2B%20Drift-3ECF8E?style=flat-square&logo=supabase&logoColor=white" />
  <img src="https://img.shields.io/badge/License-MIT-orange?style=flat-square" />
</p>

---

## 📖 Overview

**SmokeGuard** is a smart IoT and environmental health monitoring mobile & web application. It connects directly with wearable smoke and air-quality sensors over **Bluetooth Low Energy (BLE)** to provide real-time hazard alerts, exposure analytics, sensor calibration, and comprehensive health tracking.

> 🌐 **Live Web Application:** [https://anupam477.github.io/Smoke-Guard/](https://anupam477.github.io/Smoke-Guard/)  
> 📦 **Android APK Releases:** [Download Latest APK](https://github.com/Anupam477/Smoke-Guard/releases)

---

## ✨ Key Features

- **📡 Real-Time BLE Sensor Pairing:** Seamless discovery, pairing, and live telemetry streaming from wearable environmental smoke sensors using `flutter_blue_plus`.
- **🚨 Intelligent Hazard Alarm System:** Multi-tier alarm levels (Safe, Moderate, Warning, Hazardous) with audio-visual warnings and emergency mute controls.
- **📊 Real-Time Telemetry & Gauges:** Smooth animated radial gauges and live hazard banners displaying PM2.5, smoke ppm, and ambient temperature/humidity.
- **📈 Exposure Analytics & Trends:** Interactive historical charts powered by `fl_chart`, tracking daily, weekly, and cumulative smoke exposure.
- **📑 Printable & Shareable Health Reports:** Automated health report generator with PDF export and system sharing (`pdf`, `printing`, `share_plus`).
- **🎯 Sensor Calibration Hub:** Zero-point and span calibration controls to ensure high precision data reading.
- **🌐 Offline-First Architecture:** Local storage with `drift` (SQLite) and secure token storage with cloud synchronization via `Supabase`.
- **🗣️ Multilingual Support:** Native bilingual localization in English & Hindi (हिंदी).

---

## 🛠️ Technology Stack

| Layer | Technologies |
|---|---|
| **Framework** | [Flutter](https://flutter.dev) (v3.29.0) & [Dart](https://dart.dev) (v3.7.0) |
| **State Management** | [Riverpod](https://riverpod.dev) (`flutter_riverpod`) |
| **Navigation** | [GoRouter](https://pub.dev/packages/go_router) |
| **Hardware & IoT** | Bluetooth Low Energy (`flutter_blue_plus`), Foreground Service (`flutter_foreground_task`) |
| **Backend & Cloud** | [Supabase](https://supabase.com) (`supabase_flutter`) |
| **Local Persistence** | [Drift](https://drift.simonbinder.eu/) (SQLite), `flutter_secure_storage`, `shared_preferences` |
| **Data Visualization** | [FL Chart](https://pub.dev/packages/fl_chart) |
| **CI / CD Deployment** | GitHub Actions (`deploy.yml`) to GitHub Pages |

---

## 📂 Project Architecture

```
SmokeGuard/
├── .github/
│   └── workflows/
│       └── deploy.yml          # Automated Flutter Web CI/CD to GitHub Pages
├── android/                    # Android native configuration & manifests
├── ios/                        # iOS native configuration
├── web/                        # Web assembly & PWA assets
├── lib/
│   ├── app.dart                # MaterialApp setup, themes & router config
│   ├── main.dart               # App entrypoint & initializations
│   ├── core/
│   │   ├── config/             # Environment configs & Supabase credentials
│   │   ├── constants/          # App constants, thresholds & styles
│   │   ├── errors/             # Failure models & exception handlers
│   │   ├── router/             # GoRouter navigation route graph
│   │   └── theme/              # Light & dark theme palettes
│   ├── data/
│   │   ├── models/             # User, Device, Exposure & Settings models
│   │   └── repositories/       # Auth, Profile, and Settings data repositories
│   ├── features/
│   │   ├── analytics/          # Trend analysis & exposure charts
│   │   ├── auth/               # Login, Signup, OTP & Password Reset
│   │   ├── awareness/          # Smoke health tips & awareness guide
│   │   ├── dashboard/          # Home screen, live gauges & hazard banners
│   │   ├── device/             # BLE Device scan & Sensor calibration
│   │   ├── exposure/           # Detailed exposure monitoring
│   │   ├── onboarding/         # Splash & introductory walkthrough
│   │   ├── profile/            # User profile setup & medical history
│   │   ├── reports/            # PDF generation & sharing
│   │   └── settings/           # App preferences, language & Demo mode
│   ├── services/
│   │   ├── alerts/             # Local notifications & emergency alarm service
│   │   ├── ble/                # BLE packet parser, mock & real BLE services
│   │   └── supabase/           # Cloud database & authentication client
│   └── l10n/                   # Multi-language translation files (en, hi)
└── test/                       # Unit & widget test suites
```

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed on your machine:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.19.0`)
- [Dart SDK](https://dart.dev/get-dart) (`>= 3.3.0`)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) with Flutter extension
- An Android device or emulator with Bluetooth support

### Installation & Run

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Anupam477/Smoke-Guard.git
   cd Smoke-Guard
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run on connected device or emulator:**
   ```bash
   flutter run
   ```

4. **Build Release APK:**
   ```bash
   flutter build apk --release
   ```

5. **Build & Test Web:**
   ```bash
   flutter build web --release
   ```

---

## 📱 Live Demo & Deployment

- **Web Demo:** Visit [SmokeGuard Web App](https://anupam477.github.io/Smoke-Guard/)
- **GitHub Pages:** Automatically built and deployed on every push to `main` via `.github/workflows/deploy.yml`.

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!  
Feel free to check the [issues page](https://github.com/Anupam477/Smoke-Guard/issues).

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 👨‍💻 Author

**Anupam Kumar**  
- GitHub: [@Anupam477](https://github.com/Anupam477)
- Project Repository: [Smoke-Guard](https://github.com/Anupam477/Smoke-Guard)

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
