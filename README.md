# dishcovery-app

# Folder Structure

lib/
├─ main.dart
├─ app.dart # MaterialApp, theme, route init
├─ routes/
│ └─ app_routes.dart # route name & generator/GoRouter
├─ config/
│ ├─ env.dart # baca runtime env (dart-define)
│ └─ theme.dart # light/dark theme
├─ core/
│ ├─ utils/ # helper (debounce, formatter, etc.)
│ ├─ errors/ # AppException, failure mapper
│ └─ widgets/ # reusable UI atoms (EmptyState, Button)
├─ services/
│ ├─ api_client.dart # Dio singleton + interceptors
│ ├─ image_picker_service.dart # kamera/galeri
│ └─ storage_service.dart # local storage wrapper
├─ models/
│ ├─ recognition_result.dart
│ └─ food_item.dart
├─ repositories/
│ ├─ food_repository.dart # API calls: recognize, recommendations
│ └─ history_repository.dart # local CRUD history
├─ controllers/
│ ├─ recognition_controller.dart # state + logic screen/fitur
│ ├─ history_controller.dart
│ └─ settings_controller.dart
└─ views/
├─ capture/
│ ├─ capture_page.dart
│ └─ widgets/...
├─ result/
│ ├─ result_page.dart
│ └─ widgets/...
├─ history/
│ ├─ history_page.dart
│ └─ widgets/...
└─ settings/
└─ settings_page.dart
