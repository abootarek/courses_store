# Course Store App

A Flutter application for selling courses online with Firebase backend, featuring role-based access control (Admin/User) and WhatsApp-based purchase flow.

## Features

### Admin
- 📊 Dashboard with statistics (courses, orders, revenue)
- ➕ Add new courses
- ✅ Approve pending orders
- 🗑️ Delete courses

### User
- 🛍️ Browse available courses
- 📱 Purchase via WhatsApp
- 📧 Email/password authentication

## Tech Stack

- **Framework**: Flutter
- **State Management**: Flutter Bloc (Cubit)
- **Dependency Injection**: GetIt
- **Routing**: GoRouter
- **Backend**: Firebase (Authentication + Firestore)
- **Purchase Flow**: WhatsApp integration via URL Launcher

## Architecture

Clean Architecture with:
- `core/`: DI, Routing, Theme, Constants
- `data/`: Models, Repositories
- `features/`: Auth, Admin, User

## Setup Instructions

### Prerequisites
- Flutter SDK
- Firebase account

### Installation

1. **Clone and install dependencies**
   ```bash
   flutter pub get
   ```

2. **Firebase Setup** (REQUIRED)
   
   Follow the detailed instructions in [FIREBASE_SETUP.md](FIREBASE_SETUP.md):
   - Create Firebase project
   - Add `google-services.json` to `android/app/`
   - Enable Authentication (Email/Password)
   - Enable Cloud Firestore
   - Configure security rules
   - Create admin user

3. **Update WhatsApp Number**
   
   Edit `lib/core/constants/app_constants.dart`:
   ```dart
   static const String whatsappNumber = 'YOUR_ADMIN_WHATSAPP_NUMBER';
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Usage

### First Time Setup
1. Register a new user account
2. Go to Firebase Console → Firestore → users collection
3. Change the user's `role` field from `user` to `admin`
4. Login as admin to access dashboard

### Admin Workflow
1. Login with admin credentials
2. Add courses with title, description, price, and image URL
3. View pending orders from users
4. Approve orders to complete purchases

### User Workflow
1. Register/Login
2. Browse available courses
3. Click "Buy Now" to create order and open WhatsApp
4. Wait for admin approval

## Project Structure

```
lib/
├── core/
│   ├── constants/app_constants.dart
│   ├── di/dependency_injection.dart
│   ├── routing/app_router.dart
│   └── theme/app_theme.dart
├── data/
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── course_model.dart
│   │   └── order_model.dart
│   └── repositories/
│       ├── auth_repository.dart
│       ├── course_repository.dart
│       └── order_repository.dart
└── features/
    ├── auth/
    │   └── presentation/
    │       ├── cubit/
    │       └── screens/
    ├── admin/
    │   └── presentation/
    │       ├── cubit/
    │       └── screens/
    └── user/
        └── presentation/
            ├── cubit/
            └── screens/
```

## Important Notes

> ⚠️ **Firebase Configuration Required**: The app will not run without proper Firebase setup. See [FIREBASE_SETUP.md](FIREBASE_SETUP.md).

> 📱 **WhatsApp Integration**: Make sure to update the admin WhatsApp number in the constants file.

> 🔐 **Admin Creation**: Admin users must be created manually in Firestore by changing the role field.

## License

This project is created for educational purposes.
