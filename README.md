# Share Location App

Aplikasi Flutter untuk berbagi lokasi real-time dengan teman. Aplikasi ini memungkinkan pengguna untuk:

- Login dan registrasi dengan Firebase Authentication
- Melihat lokasi teman secara real-time di Google Maps
- Update dan melihat story/feeds
- Sistem pertemanan dengan konfirmasi
- Tracking lokasi real-time

## Fitur Utama

### Autentikasi
- Registrasi dan login dengan email/password
- Reset password
- Update profil pengguna

### Lokasi Real-time
- Tracking lokasi pengguna secara real-time
- Menampilkan lokasi teman di Google Maps
- Status online/offline teman
- Toggle sharing lokasi

### Sistem Pertemanan
- Cari dan tambah teman
- Konfirmasi permintaan pertemanan
- Daftar teman dengan status online
- Hapus/unfriend teman

### Feed/Story
- Upload foto dengan caption
- Like story
- Timeline feed dari teman-teman
- Real-time updates

### Profil Pengguna
- Edit profil dan foto
- Pengaturan privasi lokasi
- Informasi akun

## Struktur Proyek

```
lib/
├── main.dart                 # Entry point aplikasi
├── firebase_options.dart     # Konfigurasi Firebase
├── models/                   # Data models
│   ├── user_model.dart
│   ├── story_model.dart
│   └── friend_request_model.dart
├── services/                 # Business logic
│   └── auth_service.dart
├── providers/                # State management
│   ├── auth_provider.dart
│   └── location_provider.dart
├── screens/                  # UI Screens
│   ├── auth_wrapper.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── maps_screen.dart
│   ├── feed_screen.dart
│   ├── friends_screen.dart
│   └── profile_screen.dart
├── widgets/                  # Reusable widgets
└── utils/                    # Utility functions
```

## Setup Firebase

1. Buat project baru di [Firebase Console](https://console.firebase.google.com/)

2. Tambahkan aplikasi Android:
   - Download `google-services.json`
   - Letakkan di `android/app/`

3. Tambahkan aplikasi iOS:
   - Download `GoogleService-Info.plist`
   - Letakkan di `ios/Runner/`

4. Enable layanan Firebase:
   - Authentication (Email/Password)
   - Cloud Firestore
   - Firebase Storage

5. Jalankan perintah untuk mengenerate `firebase_options.dart`:
   ```bash
   flutter pub add firebase_core
   flutterfire configure
   ```

6. Update konfigurasi di `firebase_options.dart` dengan data dari project Firebase Anda

## Setup Google Maps

1. Dapatkan API key dari [Google Cloud Console](https://console.cloud.google.com/)

2. Enable APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API

3. Tambahkan API key:
   - Android: `android/app/src/main/AndroidManifest.xml`
   - iOS: `ios/Runner/AppDelegate.swift`

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^3.6.0
  firebase_auth: ^5.2.0
  cloud_firestore: ^5.4.0
  firebase_storage: ^12.2.0
  
  # Google Maps & Location
  google_maps_flutter: ^2.9.0
  location: ^7.0.0
  geolocator: ^13.0.1
  
  # UI & Navigation
  fluttertoast: ^8.2.8
  image_picker: ^1.1.2
  cached_network_image: ^3.4.1
  
  # State Management
  provider: ^6.1.2
  
  # Utilities
  permission_handler: ^11.3.1
  shared_preferences: ^2.3.2
```

## Cara Menjalankan

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Setup Firebase dan Google Maps (lihat instruksi di atas)

3. Jalankan aplikasi:
   ```bash
   flutter run
   ```

## Permissions

### Android

Tambahkan permissions di `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS

Tambahkan permissions di `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to location to share with friends</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs access to location to share with friends</string>
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to upload profile pictures and stories</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to upload images</string>
```

## Database Structure

### Users Collection
```javascript
{
  uid: string,
  email: string,
  name: string,
  photoUrl?: string,
  createdAt: timestamp,
  isOnline: boolean,
  lastSeen: timestamp,
  location?: GeoPoint
}
```

### Friends Collection
```javascript
{
  userId: string,
  friendId: string,
  createdAt: timestamp
}
```

### Friend Requests Collection
```javascript
{
  senderId: string,
  receiverId: string,
  status: string, // pending, accepted, rejected
  createdAt: timestamp
}
```

### Stories Collection
```javascript
{
  userId: string,
  imageUrl: string,
  caption: string,
  createdAt: timestamp,
  likes: array<string>
}
```

## Kontribusi

1. Fork repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## License

MIT License

## Support

Jika ada pertanyaan atau masalah, silakan buat issue di repository.
