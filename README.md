# DISHCOVERY App

Capstone Project BEKUP 2025 — Aplikasi pengenalan kuliner Indonesia berbasis Mobile
---

## 📂 Folder Structure

```text
lib/
├─ main.dart # Entry point aplikasi
├─ app.dart # Root MaterialApp, theme, route init
│
├─ routes/
│ └─ app_routes.dart # Route name & generator/GoRouter
│
├─ config/
│ ├─ env.dart # Runtime env (dart-define)
│ └─ theme.dart # Konfigurasi light/dark theme
│
├─ core/
│ ├─ utils/ # Helper (debounce, formatter, etc.)
│ ├─ errors/ # AppException, failure mapper
│ └─ widgets/ # Reusable UI atoms (EmptyState, Button, dll.)
│
├─ services/
│ ├─ api_client.dart # HTTP client (Dio singleton + interceptors)
│ ├─ image_picker_service.dart # Kamera / galeri handler
│ └─ storage_service.dart # Local storage wrapper (SharedPref/Hive/Isar)
│
├─ models/
│ ├─ recognition_result.dart # Data model hasil pengenalan
│ └─ food_item.dart # Data model item makanan
│
├─ repositories/
│ ├─ food_repository.dart # Akses API: recognize, recommendations
│ └─ history_repository.dart # Akses lokal CRUD history
│
├─ controllers/
│ ├─ recognition_controller.dart # State + logic untuk food recognition
│ ├─ history_controller.dart # State + logic untuk riwayat
│ └─ settings_controller.dart # State + logic untuk pengaturan
│
└─ views/
├─ capture/
│ ├─ capture_page.dart # UI untuk ambil/pilih foto
│ └─ widgets/...
│
├─ result/
│ ├─ result_page.dart # UI untuk hasil pengenalan
│ └─ widgets/...
│
├─ history/
│ ├─ history_page.dart # UI daftar riwayat pencarian
│ └─ widgets/...
│
└─ settings/
└─ settings_page.dart # UI halaman pengaturan



