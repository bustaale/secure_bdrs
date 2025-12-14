# Database System Location - Secure BDRS

## 📍 Database System-kaagu waa ku yaal:

### 1. **Cloud Database (Firebase Firestore)** - Database-ka ugu muhiimsan
**Location:** `lib/services/firebase_service.dart`

**Waxa ku jira:**
- Birth Records Collection (`births`)
- Death Records Collection (`deaths`)
- Real-time data synchronization
- Cloud storage

**Firebase Console:**
- Go to: https://console.firebase.google.com/
- Project: "Secure BDRS"
- Firestore Database → Collections:
  - `births/` - Dhammaan birth records
  - `deaths/` - Dhammaan death records
  - `users/` - User accounts
  - `backups/` - Backup files

---

### 2. **Local Database (SharedPreferences)** - Offline Storage
**Location:** `lib/providers/records_provider.dart`

**Waxa ku jira:**
- Local storage for offline access
- Fallback if Firebase is not available
- SharedPreferences keys:
  - `births` - Birth records JSON
  - `deaths` - Death records JSON
  - `current_user` - Current user data
  - `app_language` - Selected language

**Storage Path:**
- Android: `/data/data/com.secure_bdrs/shared_prefs/`
- iOS: `Library/Preferences/`

---

### 3. **User Database**
**Location:** `lib/services/user_service.dart`

**Waxa ku jira:**
- User accounts storage
- Firestore Collection: `users/`
- Local backup in SharedPreferences

**User Data Structure:**
```
users/
  └── {userId}/
      ├── id
      ├── username
      ├── email
      ├── role (Admin/Registrar/Clerk)
      ├── isActive
      ├── createdAt
      └── lastLogin
```

---

### 4. **Backup Database**
**Location:** `lib/services/backup_service.dart`

**Waxa ku jira:**
- Backup storage in Firestore
- Collection: `backups/`
- Local backup files in app documents directory

**Backup Files Location:**
- Android: `/Android/data/com.secure_bdrs/files/Documents/backup_*.json`
- iOS: `Documents/backup_*.json`

---

### 5. **Account Storage (Local)**
**Location:** `lib/services/account_storage.dart`

**Waxa ku jira:**
- Local account credentials
- SharedPreferences key: `stored_accounts`
- Fallback authentication storage

---

### 6. **Cloud Storage (Files & Documents)**
**Location:** `lib/services/cloud_storage_service.dart`

**Waxa ku jira:**
- Firebase Storage for documents/photos
- Path: `users/{userId}/documents/`
- Automatic cloud upload

**Firebase Storage Path:**
- Firebase Console → Storage
- Bucket: `gs://secure-bdrs.appspot.com/`

---

## 📊 Database Structure:

### Firestore Collections:
```
secure-bdrs (Firebase Project)
├── births/              # Birth records
│   └── {birthId}/
│       ├── id
│       ├── childName
│       ├── dateOfBirth
│       ├── fatherName
│       ├── motherName
│       ├── documents
│       └── photos
│
├── deaths/              # Death records
│   └── {deathId}/
│       ├── id
│       ├── name
│       ├── dateOfDeath
│       └── cause
│
├── users/               # User accounts
│   └── {userId}/
│       ├── id
│       ├── username
│       ├── email
│       ├── role
│       └── isActive
│
└── backups/             # Backup files
    └── {backupId}/
        ├── timestamp
        ├── births
        └── deaths
```

### Local Storage (SharedPreferences):
```
SharedPreferences:
├── births              # JSON array of birth records
├── deaths              # JSON array of death records
├── current_user        # Current logged-in user
├── current_user_id     # Current user ID
├── stored_accounts     # Local account credentials
├── app_language        # Selected language (en/sw)
└── biometric_enabled   # Biometric auth status
```

---

## 🔍 Sidee loo helaa Database-ka:

### 1. Firebase Console (Cloud Database):
1. Open: https://console.firebase.google.com/
2. Select project: "Secure BDRS"
3. Go to "Firestore Database"
4. View collections: `births`, `deaths`, `users`, `backups`

### 2. Local Database (Android):
```bash
# Using ADB:
adb shell run-as com.secure_bdrs
cd /data/data/com.secure_bdrs/shared_prefs/
cat *.xml
```

### 3. Code Files:
- **Cloud Database:** `lib/services/firebase_service.dart`
- **Local Storage:** `lib/providers/records_provider.dart`
- **User Database:** `lib/services/user_service.dart`
- **Backup Database:** `lib/services/backup_service.dart`

---

## 🔐 Database Access:

### Firebase Firestore Rules:
**Location:** `firestore.rules` (project root)

**Current Rules:**
- Birth records: Read/Write for authenticated users
- Death records: Read/Write for authenticated users
- Users: Admin access only
- Backups: Admin access only

---

## 📱 Database Sync:

### Automatic Sync:
- **Real-time sync:** `RecordsProvider` uses Firestore streams
- **Local fallback:** If Firebase unavailable, uses SharedPreferences
- **Cloud upload:** Documents/photos auto-upload to Firebase Storage

### Manual Sync:
- Use "Refresh" button in app
- Backup/Restore feature for manual data management

---

## 📁 Database Files Summary:

| Database Type | Location | Purpose |
|--------------|----------|---------|
| **Firebase Firestore** | Cloud (Firebase) | Main cloud database |
| **SharedPreferences** | Local device | Offline storage & fallback |
| **Firebase Storage** | Cloud (Firebase) | Documents & photos |
| **Local Backup Files** | Documents folder | JSON backup files |

---

## 🛠️ Database Services:

All database operations are handled through these services:
1. `FirebaseService` - Cloud database operations
2. `RecordsProvider` - Data management & sync
3. `UserService` - User account management
4. `BackupService` - Backup & restore
5. `CloudStorageService` - File storage
6. `AccountStorage` - Local account storage

---

## ✅ Summary:

**Database System-kaagu waa:**
- **Cloud:** Firebase Firestore (Primary)
- **Local:** SharedPreferences (Fallback)
- **Files:** Firebase Storage (Documents/Photos)

**Main Database Files:**
- `lib/services/firebase_service.dart` - Cloud database
- `lib/providers/records_provider.dart` - Local database
- `lib/services/user_service.dart` - User database

