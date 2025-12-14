# Firebase Setup Guide

## Email Configuration
Admin Email: **moh4383531@gmail.com**

## Setup Steps

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Enter project name: "Secure BDRS"
4. Follow the setup wizard

### 2. Add Firebase to Android App
1. In Firebase Console, click "Add App" → Android
2. Register your app:
   - Package name: `com.secure_bdrs` (check your `android/app/build.gradle`)
   - App nickname: Secure BDRS Android
   - Download `google-services.json`
3. Place `google-services.json` in `android/app/` directory

### 3. Add Firebase to iOS App (if needed)
1. In Firebase Console, click "Add App" → iOS
2. Register your app:
   - Bundle ID: Check `ios/Runner.xcodeproj`
   - Download `GoogleService-Info.plist`
3. Place `GoogleService-Info.plist` in `ios/Runner/` directory

### 4. Configure Android Build Files

#### android/build.gradle (Project level)
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

#### android/app/build.gradle (App level)
Add at the bottom:
```gradle
apply plugin: 'com.google.gms.google-services'
```

### 5. Configure Firestore Database
1. In Firebase Console, go to "Firestore Database"
2. Click "Create Database"
3. Start in **test mode** (for development)
4. Choose a location (closest to your users)

### 6. Set Firestore Rules
Go to Firestore Database → Rules tab:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Birth records
    match /births/{birthId} {
      allow read, write: if request.auth != null;
    }
    
    // Death records
    match /deaths/{deathId} {
      allow read, write: if request.auth != null;
    }
    
    // For development (remove in production)
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

### 7. Install Dependencies
Run in terminal:
```bash
flutter pub get
```

### 8. Create Firebase Options File (Optional)
For automatic configuration, you can use:
```bash
flutterfire configure
```

This will create `lib/firebase_options.dart` automatically.

### 9. Update main.dart
The Firebase initialization is already added in `main.dart`. If you create `firebase_options.dart`, update:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

## Collections Structure

### Births Collection
```
births/
  └── {birthId}/
      ├── id
      ├── childName
      ├── dateOfBirth
      ├── placeOfBirth
      ├── gender
      ├── fatherName
      ├── motherName
      └── ... (all birth record fields)
```

### Deaths Collection
```
deaths/
  └── {deathId}/
      ├── id
      ├── name
      ├── dateOfDeath
      ├── placeOfDeath
      ├── cause
      └── ... (all death record fields)
```

## Features
- ✅ Real-time data synchronization
- ✅ Automatic data sync across devices
- ✅ Offline support (with local caching)
- ✅ Secure data storage in cloud
- ✅ Admin email: moh4383531@gmail.com

## Testing
1. Run `flutter run`
2. Add a birth or death record
3. Check Firebase Console to see the data saved
4. Open app on another device to see real-time sync

## Troubleshooting
- If Firebase initialization fails, check `google-services.json` is in correct location
- Make sure Firestore is enabled in Firebase Console
- Check internet connection
- Verify package names match in Firebase Console and build.gradle

