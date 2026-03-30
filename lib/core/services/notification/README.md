# 🔔 Cảnh báo & Luồng Điều Hướng (Member 4)

Hệ thống quản lý thông báo đẩy và định tuyến thông minh cho ứng dụng Fridge to Fork.

## 📋 Yêu Cầu Chức Năng

- **FR3.1**: Push Notification - Gửi thông báo đến người dùng
- **FR3.2**: Smart Routing - Định tuyến thông minh dựa trên thông báo

## 📁 Cấu Trúc Tệp

```
lib/
├── core/
│   ├── services/notification/
│   │   ├── notification_service.dart      ✅ Service cho notifications
│   │   ├── background_worker.dart         ✅ Background tasks (8h sáng)
│   │   ├── deep_link_handler.dart         ✅ Smart routing
│   │   ├── ANDROID_SETUP.dart             ℹ️  Setup guide Android
│   │   └── iOS_SETUP.dart                 ℹ️  Setup guide iOS
│   ├── theme/
│   │   ├── app_colors.dart                ✅
│   │   ├── app_theme.dart                 ✅
│   │   └── app_typography.dart            ✅
│   └── widgets/
│       └── notification_test_screen.dart  🧪 Test screen
├── routes/
│   ├── app_router.dart                    ✅ GoRouter config
│   └── route_names.dart                   ✅ Route constants
└── main.dart                              ✅ App entry point
```

## 🚀 Cách Sử Dụng

### 1. Gửi Thông Báo Cơ Bản

```dart
import 'package:fridge_to_fork_assistant/core/services/notification/notification_service.dart';

// Gửi thông báo đơn giản
await NotificationService().showNotification(
  id: 1,
  title: 'Tiêu đề',
  body: 'Nội dung thông báo',
  payload: 'route:pantry', // Deep link (tùy chọn)
);
```

### 2. Gửi Thông Báo Với Deep Link

```dart
import 'package:fridge_to_fork_assistant/core/services/notification/deep_link_handler.dart';

// Mở Pantry khi click vào thông báo
await NotificationService().showNotification(
  id: 2,
  title: '⚠️ Sữa sắp hết hạn',
  body: 'Sữa của bạn sẽ hết hạn trong 2 ngày',
  payload: DeepLinkHandler.buildPantryPayload(ingredient: 'sữa'),
);
```

### 3. Định Tuyến Thông Minh (Deep Link Formats)

| Payload | Kết Quả |
|---------|--------|
| `route:pantry` | Mở màn hình Pantry |
| `route:pantry?ingredient=milk` | Mở form thêm sản phẩm (pre-fill milk) |
| `route:shopping-list` | Mở danh sách mua sắm |
| `route:recipes` | Mở danh sách công thức |
| `screen:recipe:123` | Mở chi tiết công thức ID 123 |
| `screen:meal:456` | Mở chi tiết bữa ăn ID 456 |
| `alert:expiring:cheese` | Mở Pantry với alert cheese expiring |
| `alert:expired:butter` | Mở Pantry với alert butter đã hết hạn |

### 4. Các Helper Function

```dart
// Builds
DeepLinkHandler.buildPantryPayload(ingredient: 'sữa');
DeepLinkHandler.buildShoppingListPayload();
DeepLinkHandler.buildRecipePayload(recipeId: '123');
DeepLinkHandler.buildMealPayload(mealId: '456');
DeepLinkHandler.buildExpiringItemPayload(itemName: 'cheese', isExpired: true);

// Parse
final route = DeepLinkHandler.parsePayloadToRoute(payload);
```

## 📅 Background Tasks

### Kiểm Tra HSD (Hạn Sử Dụng) - 8h Sáng Hàng Ngày

```dart
import 'package:fridge_to_fork_assistant/core/services/notification/background_worker.dart';

// Scheduled tự động trong main()
await BackgroundWorker.scheduleCheckExpiredItems();

// Task sẽ:
// 1. Lấy dữ liệu từ Pantry Repository (Member 1)
// 2. Kiểm tra hàng hóa hết hạn trong 3 ngày
// 3. Gửi thông báo nếu có hàng sắp hết hạn
```

### Sync Dữ Liệu Pantry - Mỗi 6h

```dart
// Scheduled tự động
await BackgroundWorker.schedulePantrySyncTask();
```

## 🧪 Testing

### Sử Dụng Notification Test Screen

1. **Chạy ứng dụng**
   ```bash
   flutter run
   ```

2. **Vào "Test Notifications" từ home screen**

3. **Chọn test case hoặc tùy chỉnh**

### Test Payloads

```dart
// Chuẩn trắc test từ code
NotificationService().showTestNotification(
  title: 'Test',
  body: 'This is a test',
  payload: 'route:pantry?ingredient=milk',
);
```

## ⚙️ Cấu Hình Native

### Android

1. Chỉnh sửa: `android/app/src/main/AndroidManifest.xml`
   ```xml
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
   ```

2. Chỉnh sửa: `android/app/build.gradle.kts`
   ```gradle
   android {
       compileSdk = 33
       defaultConfig {
           targetSdk = 33
       }
   }
   ```

3. Chạy:
   ```bash
   flutter clean && flutter pub get
   ```

Xem chi tiết: [ANDROID_SETUP.dart](lib/core/services/notification/ANDROID_SETUP.dart)

### iOS

1. Mở: `ios/Runner.xcworkspace` (NOT `.xcodeproj`)

2. Chỉnh sửa: `ios/Runner/Info.plist`
   ```xml
   <key>UIBackgroundModes</key>
   <array>
       <string>remote-notification</string>
   </array>
   ```

3. Thêm Capabilities:
   - Push Notifications
   - Background Modes (Remote notifications)

4. Chạy:
   ```bash
   cd ios && pod install --repo-update && cd ..
   flutter clean && flutter pub get
   ```

Xem chi tiết: [iOS_SETUP.dart](lib/core/services/notification/iOS_SETUP.dart)

## 🔗 Integration với Other Members

### Member 1 (Pantry Repository)

```dart
// Trong background_worker.dart _handleCheckExpiredItems()
// TODO: Implement integration
final pantryRepo = PantryRepository();
final items = await pantryRepo.getAllItems();
final expiringSoon = items.where((item) => 
  item.expiryDate.difference(DateTime.now()).inDays <= 3
).toList();
```

### Member 2 (Recipes, Shopping List, Meal Planner)

- Các route đã được định nghĩa trong `app_router.dart`
- Deep linking sẽ tự động mở màn hình của các thành viên

### Member 3 (Nếu có)

- Thêm routes vào `route_names.dart` và `app_router.dart`

## 📊 Files Created/Modified

| File | Status | Mô Tả |
|------|--------|-------|
| `pubspec.yaml` | ✏️ Modified | Thêm go_router, flutter_local_notifications, workmanager |
| `lib/main.dart` | ✏️ Modified | Initialize notification & background services |
| `lib/routes/route_names.dart` | ✅ Created | All route constants |
| `lib/routes/app_router.dart` | ✅ Created | GoRouter configuration |
| `lib/core/services/notification/` | ✅ Created | Services & handlers |
| `lib/core/theme/` | ✅ Created | Theme configuration |
| `lib/core/widgets/notification_test_screen.dart` | ✅ Created | Test UI |

## 🐛 Troubleshooting

### Notification không hiển thị

1. ✅ Kiểm tra Android/iOS setup
2. ✅ Kiểm tra permissions
3. ✅ Xem logs: `flutter logs`
4. ✅ Dùng test screen để verify

### Background task không chạy

1. ✅ Check device không ở battery saver mode
2. ✅ App phải được cấp quyền background
3. ✅ Test trong production build (debug có giới hạn)

### Deep link không hoạt động

1. ✅ Kiểm tra payload format
2. ✅ Dùng `DeepLinkHandler.parsePayloadToRoute()` để test
3. ✅ Xem `deep_link_handler.dart` comments

## 📚 Tài Liệu

- [GoRouter](https://pub.dev/packages/go_router)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- [workmanager](https://pub.dev/packages/workmanager)

---

✅ **Status**: Ready for integration with other team members
