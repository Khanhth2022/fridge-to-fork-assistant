// ignore_for_file: file_names, dangling_library_doc_comments

/// iOS Notification Configuration Guide
/// 
/// 📋 Bước 1: Update Info.plist
/// File: ios/Runner/Info.plist
/// 
/// Thêm hoặc kiểm tra:
/// ```xml
/// <key>UIBackgroundModes</key>
/// <array>
///     <string>remote-notification</string>
///     <string>fetch</string>
/// </array>
/// ```
/// 
/// 📋 Bước 2: Update Podfile
/// File: ios/Podfile
/// 
/// Đảm bảo platform:
/// ```ruby
/// platform :ios, '12.0'
/// ```
/// 
/// 📋 Bước 3: Update Runner.xcodeproj
/// 1. Mở ios/Runner.xcworkspace (KHÔNG phải .xcodeproj)
/// 2. Chọn Runner project
/// 3. Chọn targets -> Runner
/// 4. Tab "Build Phases" -> "Link Binary With Libraries"
///    Thêm: UserNotifications.framework
/// 5. Tab "Signing & Capabilities"
///    - Chọn "+ Capability"
///    - Thêm: "Push Notifications"
///    - Thêm: "Background Modes"
///    - Checked: "Remote notifications"
/// 
/// 📋 Bước 4: Cấu hình requestPermissions trong AppDelegate
/// File: ios/Runner/GeneratedPluginRegistrant.m
/// 
/// NotificationService sẽ tự động yêu cầu permissions
/// 
/// 📋 Bước 5: Lệnh CLI
/// ```bash
/// cd ios
/// rm -rf Pods
/// rm Podfile.lock
/// pod install --repo-update
/// cd ..
/// flutter clean
/// flutter pub get
/// ```
/// 
///━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 
/// 📝 Checklist:
/// - [ ] Info.plist có remote-notification background mode
/// - [ ] Podfile platform >= 12.0
/// - [ ] Runner.xcworkspace mở (không .xcodeproj)
/// - [ ] UserNotifications.framework linked
/// - [ ] Push Notifications capability added
/// - [ ] Background Modes capability added
/// - [ ] Pod install chạy
/// - [ ] flutter clean && flutter pub get
/// 

class IOSNotificationSetup {
  static const String docString = '''
  ✅ iOS SETUP HOÀN TẬT
  
  Các bước quan trọng:
  1. Info.plist background modes ✓
  2. Push Notifications capability ✓
  3. UserNotifications framework ✓
  4. Pod install ✓
  5. flutter_local_notifications ✓
  ''';
}
