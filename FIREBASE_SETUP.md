# Firebase Setup Instructions

## Important: Firebase Configuration Required

This app requires Firebase to function. Follow these steps to set up Firebase:

### 1. Create a Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use an existing one
3. Enable **Authentication** (Email/Password provider)
4. Enable **Cloud Firestore**

### 2. Add Firebase to Your Android App

1. In Firebase Console, click "Add app" and select Android
2. Register your app with package name: `com.coursestore.course_store`
3. Download the `google-services.json` file
4. Place it in: `android/app/google-services.json`

### 3. Add Firebase to Your iOS App (Optional)

1. In Firebase Console, click "Add app" and select iOS
2. Register your app with bundle ID: `com.coursestore.courseStore`
3. Download the `GoogleService-Info.plist` file
4. Place it in: `ios/Runner/GoogleService-Info.plist`

### 4. Configure Firestore Security Rules

In Firebase Console, go to Firestore Database > Rules and set:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Courses collection
    match /courses/{courseId} {
      allow read: if true;
      allow write: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Orders collection
    match /orders/{orderId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

### 5. Create an Admin User

Since user registration creates 'user' role by default, you need to manually create an admin:

1. Register a new account through the app
2. Go to Firebase Console > Authentication
3. Copy the user's UID
4. Go to Firestore Database > users collection
5. Find the document with that UID
6. Change the `role` field from `user` to `admin`

### 6. Update WhatsApp Number

In `lib/core/constants/app_constants.dart`, update the WhatsApp number:
```dart
static const String whatsappNumber = '201234567890'; // Replace with actual admin number
```

Also update in `lib/features/user/presentation/screens/course_details_screen.dart` line 41.

### 7. Run the App

```bash
flutter pub get
flutter run
```

## Features

- **Admin**: Login, add courses, view statistics, approve orders
- **User**: Register, browse courses, purchase via WhatsApp
- **Architecture**: Clean Architecture with Cubit, GetIt, GoRouter
