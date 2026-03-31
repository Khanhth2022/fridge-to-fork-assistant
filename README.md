# 🍳 Fridge to Fork Assistant

Ứng dụng quản lý tủ bếp thông minh cho những người yêu thích nấu ăn. Theo dõi nguyên liệu, hạn sử dụng, và nhận gợi ý nấu ăn.

## ✨ Tính Năng

- **📦 Quản lý tủ bếp local**: Lưu trữ tất cả nguyên liệu trên máy cục bộ
- **🔍 OCR + Barcode**: Quét hóa đơn/receipt để tự động nhập nguyên liệu
- **⏰ Cảnh báo hạn sử dụng**: Thông báo khi nguyên liệu sắp hết hạn
- **🔐 Đăng nhập & Sao lưu**: Backup dữ liệu lên Firebase (local-first strategy)
- **☁️ Cloud Sync**: Đồng bộ dữ liệu giữa nhiều thiết bị
- **🌍 Local-first**: Dữ liệu luôn hoạt động offline, sync khi có mạng

## 🚀 Quick Start

### Yêu cầu
- Flutter SDK >= 3.10.7
- Android SDK >= API 31
- npm (để cài Firebase CLI)

### Cài đặt

1. **Clone repository**
```bash
git clone https://github.com/yourusername/fridge_to_fork_assistant.git
cd fridge_to_fork_assistant
```

2. **Cài dependencies**
```bash
flutter pub get
```

3. **Setup Firebase** 
   - Xem chi tiết tại [SETUP_FIREBASE.md](SETUP_FIREBASE.md)
   - Tóm tắt: chạy `flutterfire configure --project=fridge-to-fork-assistant`

4. **Chạy app**
```bash
flutter run
```

## 📁 Cấu Trúc Project

```
lib/
├── main.dart                 # Entry point + Firebase init
├── firebase_options.dart     # Auto-generated Firebase config (IGNORED)
├── features/
│   ├── pantry/              # Quản lý tủ bếp
│   │   ├── models/          # PantryItemModel + Hive type
│   │   ├── views/           # UI screens
│   │   ├── view_models/     # Provider ViewModels
│   │   └── pantry_repository.dart
│   ├── auth/                # Đăng nhập / Auth
│   │   ├── views/           # Login screen
│   │   └── view_models/     # AuthViewModel
│   ├── meal_planner/        # Gợi ý meal plans
│   ├── recipes/             # Database công thức
│   └── shopping_list/       # Danh sách mua sắm
├── core/
│   ├── services/
│   │   ├── auth/            # Firebase Auth service
│   │   ├── sync/            # Cloud sync service
│   │   ├── notification/    # Local notifications
│   │   └── scanner/         # OCR + Barcode scanning
│   └── widgets/
android/
├── app/
│   ├── google-services.json  # Firebase config (IGNORED)
│   └── build.gradle.kts
├── build.gradle.kts
└── gradle.properties
```

## 🔌 Tech Stack

- **Framework**: Flutter + Dart
- **State Management**: Provider
- **Local Storage**: Hive (nosql for local items)
- **Cloud Sync**: Firebase Auth + Firestore
- **OCR/Barcode**: Google ML Kit
- **API Keys**: Secure Storage + FlutterSecureStorage

## 🔒 Bảo Mật & Privacy

- ✅ **Local-first**: Dữ liệu lưu local, sync cloud optional
- ✅ **Ignore sensitive files**: `google-services.json`, `firebase_options.dart`
- ✅ **Secure token storage**: Tokens lưu trong FlutterSecureStorage
- ✅ **No analytics** (mặc định): Chỉ khi user bật explicit

### Để push lên GitHub safely:
1. ✅ `.gitignore` đã được cập nhật
2. ✅ `google-services.json` + `firebase_options.dart` bị ignore
3. 🛠️ Nếu nhầm commit sensitive files, chạy:
```bash
git rm --cached android/app/google-services.json
git rm --cached lib/firebase_options.dart
git commit -m "chore: remove sensitive credentials"
git push
```

## 📝 Development

### Chạy tests
```bash
flutter test
```

### Build release APK
```bash
flutter build apk --release
```

### Build release AAB (Google Play)
```bash
flutter build appbundle --release
```

## 🤝 Contributing

1. Fork repository
2. Tạo feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Mở Pull Request

## 📄 License

MIT License - xem [LICENSE](LICENSE) để chi tiết

## 👨‍💻 Author

Dell @fridge-to-fork-assistant

## 📞 Support

Gặp issue? Vui lòng:
1. Kiểm tra [SETUP_FIREBASE.md](SETUP_FIREBASE.md) nếu gặp lỗi Firebase
2. Open issue trên GitHub
3. Discord: [link tới server]

---

**Hạnh phúc nấu ăn! 🍲**
