# 🍽️ DISHCOVERY App

[![Codemagic build status](https://api.codemagic.io/apps/YOUR_APP_ID/YOUR_WORKFLOW_ID/status_badge.svg)](https://codemagic.io/apps/YOUR_APP_ID/YOUR_WORKFLOW_ID/latest_build)

A Flutter application for discovering and exploring Indonesian culinary treasures using AI-powered recognition.

-----

## � About The App

Dishcovery is a mobile application that helps users discover and learn about Indonesian cuisine through advanced AI image recognition. Built for the BEKUP 2025 Capstone Project, this app makes exploring Indonesian culinary delights easier and more engaging.

-----

## ✨ Key Features

  - 📸 AI-powered food recognition
  - 🍳 Detailed food information and recipes
  - 📍 Location-based food recommendations
  - 📱 Offline-first architecture with ObjectBox
  - 🌙 Dark/Light theme support
  - 🌐 Multi-language support (ID/EN)
  - 📚 Search history management
  - 🎯 Personalized food preferences

-----

## 🏗️ Architecture

This project uses **Clean Architecture** with **Feature-First** organization for better scalability and maintainability:

```

-----

## 🛠️ Tech Stack

  - **Framework**: Flutter
  - **Language**: Dart
  - **State Management**: Provider
  - **Local Database**: ObjectBox
  - **Authentication**: Firebase Auth
  - **AI Services**: Custom AI API
  - **Analytics**: Firebase Analytics
  - **Image Processing**: Camera API
  - **Localization**: Easy Localization
  - **Navigation**: GoRouter

-----

## 🚀 Installation & Setup

### Prerequisites

  - [Flutter SDK](https://flutter.dev/docs/get-started/install)
  - [Firebase CLI](https://firebase.google.com/docs/cli)
  - [Git](https://git-scm.com/)

### Installation Steps

1.  **Clone the repository**

    ```bash
    git clone https://github.com/Dishcovery-Dev/dishcovery-app.git
    cd dishcovery-app
    ```

2.  **Install dependencies**

    ```bash
    flutter pub get
    ```

3.  **Firebase Setup**
    - Create a Firebase project
    - Add Android & iOS apps in Firebase Console
    - Download and place configuration files:
      - `google-services.json` in `android/app/`
      - `GoogleService-Info.plist` in `ios/Runner/`
    - Initialize Firebase:
      ```bash
      firebase login
      flutterfire configure
      ```

4.  **Generate ObjectBox Code**

    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

5.  **Run the app**

    ```bash
    flutter run
    ```

-----

## 📱 Development

### Code Generation

```bash
# One-time generation
flutter pub run build_runner build

# Watch mode
flutter pub run build_runner watch

# Force generation
flutter pub run build_runner build --delete-conflicting-outputs
```

### Building for Release

#### Android

```bash
flutter build apk --release
# or
flutter build appbundle --release
```

#### iOS

```bash
flutter build ios --release
```

-----

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

-----

## 📁 Project Structure

For detailed project structure and organization, see the folder structure above in the Architecture section.

-----

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting pull requests.

-----

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

-----

## 👥 Team

BEKUP 2025 Capstone Project Team:
- [Team Member 1](https://github.com/username)
- [Team Member 2](https://github.com/username)
- [Team Member 3](https://github.com/username)

-----

## 📞 Support

If you encounter any issues or have questions:

1. Check existing [Issues](https://github.com/Dishcovery-Dev/dishcovery-app/issues)
2. Create a new issue
3. Contact the development team

-----

## 🙏 Acknowledgments

- [BEKUP 2025](https://bekup.com) for the opportunity
- The Flutter Community
- Our mentors and advisors

-----

**Happy Cooking! 🍳**
lib/
├── core/              # Core functionality
│   ├── config/        # App configuration
│   ├── controllers/   # Shared controllers
│   ├── database/     # Local database (ObjectBox)
│   ├── extensions/   # Extension methods
│   ├── models/       # Core data models
│   ├── navigation/   # Navigation services
│   ├── services/     # Core services
│   ├── theme/        # Theme configuration
│   └── widgets/      # Reusable widgets
│
├── features/          # Feature modules
│   ├── auth/         # Authentication
│   ├── capture/      # Image capture
│   ├── history/      # Search history
│   ├── home/         # Home screen
│   ├── onboarding/   # User onboarding
│   ├── result/       # Recognition results
│   └── settings/     # App settings
│
├── providers/         # State management
├── res/              # Resources
└── utils/            # Utilities



