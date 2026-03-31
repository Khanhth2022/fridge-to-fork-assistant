# Firebase Setup Guide

Tệp `google-services.json` và `firebaseConfig.dart` đã được loại khỏi repository vì chúng chứa API keys nhạy cảm.

## Để setup Firebase cho dự án này:

### 1. Tạo Firebase Project
1. Vào [Firebase Console](https://console.firebase.google.com/)
2. Tạo project mới hoặc dùng project hiện có
3. Lưu `Project ID`

### 2. Thêm Android App
1. Trong Firebase Console, chọn project
2. Bấm "Add app" → chọn Android
3. Nhập **Package Name**: `com.example.fridge_to_fork_assistant`
4. Thêm **SHA-1 fingerprint** (chạy: `cd android && ./gradlew signingReport`)
5. Download `google-services.json`
6. Copy vào: `android/app/google-services.json`

### 3. Chạy FlutterFire Configure
```bash
dart pub global activate flutterfire_cli

flutterfire configure --project=YOUR_PROJECT_ID
```

Lệnh này sẽ tạo lại `lib/firebase_options.dart` tự động.

### 4. Enable Email/Password Auth
1. Vào Firebase Console → Authentication
2. Bấm "Sign-in method"
3. Enable "Email/Password"
4. Lưu

### 5. Setup Firestore (optional, để backup)
1. Vào Firebase Console → Firestore Database
2. Tạo database mới (mode: Start in test mode để dev)
3. Database location: `asia-southeast1` (nếu ở VN)

### 6. Enable Identity Toolkit API
1. Vào [Google Cloud Console](https://console.cloud.google.com/)
2. Chọn project Firebase của bạn
3. APIs & Services → Search "Identity Toolkit"
4. Bấp "Enable"

### 7. Hợp lệ hóa SHA-1 Fingerprint (Android Sign-in)
```bash
cd android
./gradlew signingReport
```

Copy SHA-1 từ debug keystore, thêm vào Firebase Console → Project Settings → Android app.

## File được ignore (cần cấu hình cá nhân)
- `android/app/google-services.json` - Firebase config
- `lib/firebase_options.dart` - Auto-generated, tạo lại bằng flutterfire
- `android/key.properties` - Signing credentials

## Chạy App
```bash
flutter pub get
flutter run
```

## Lưu ý bảo mật
⚠️ **KHÔNG commit những file này lên GitHub:**
- `google-services.json`
- `firebase_options.dart`
- Bất kỳ file chứa API keys hoặc credentials

Nếu nhầm commit, xóa ngay bằng:
```bash
git rm --cached android/app/google-services.json
git rm --cached lib/firebase_options.dart
git commit -m "chore: remove sensitive Firebase config files"
```

Rồi force push hoặc tạo PR để cẩn thận không lộ credentials.
