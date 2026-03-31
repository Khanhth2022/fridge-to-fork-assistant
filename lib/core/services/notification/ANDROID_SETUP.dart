// ignore_for_file: file_names, dangling_library_doc_comments

/// Android Notification Configuration Guide
///
/// 📋 Bước 1: Update AndroidManifest.xml
/// File: android/app/src/main/AndroidManifest.xml
///
/// Thêm permissions sau:
/// ```xml
/// <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
/// ```
///
/// 📋 Bước 2: Update MainActivity.kt
/// File: android/app/src/main/kotlin/com/.../MainActivity.kt
///
/// Đảm bảo class kế thừa FlutterActivity:
/// ```kotlin
/// import io.flutter.embedding.android.FlutterActivity
///
/// class MainActivity: FlutterActivity() {
/// }
/// ```
///
/// 📋 Bước 3: Sửa build.gradle
/// File: android/app/build.gradle.kts
///
/// Thêm:
/// ```gradle
/// android {
///     compileSdk = 33
///     ...
///     defaultConfig {
///         applicationId = "com.khanh.fridge_to_fork"
///         minSdk = 21
///         targetSdk = 33
///     }
/// }
/// ```
///
/// 📋 Bước 4 (Tùy chọn): Tạo notification channel
/// File: android/app/src/main/kotlin/com/.../NotificationChannelConfig.kt
///
/// Code:
/// ```kotlin
/// import android.app.NotificationChannel
/// import android.app.NotificationManager
/// import android.content.Context
/// import android.os.Build
///
/// object NotificationChannelConfig {
///     fun createNotificationChannels(context: Context) {
///         if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
///             val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
///
///             val defaultChannel = NotificationChannel(
///                 "default_channel",
///                 "Default Channel",
///                 NotificationManager.IMPORTANCE_MAX
///             ).apply {
///                 description = "Default notification channel"
///                 enableVibration(true)
///                 enableLights(true)
///             }
///             manager.createNotificationChannel(defaultChannel)
///
///             val notificationChannel = NotificationChannel(
///                 "notification_channel",
///                 "Notification Channel",
///                 NotificationManager.IMPORTANCE_MAX
///             ).apply {
///                 description = "Custom notification channel"
///                 enableVibration(true)
///                 enableLights(true)
///             }
///             manager.createNotificationChannel(notificationChannel)
///         }
///     }
/// }
/// ```
///
/// Sau đó gọi trong MainActivity.onCreate():
/// ```kotlin
/// override fun onCreate(savedInstanceState: Bundle?) {
///     super.onCreate(savedInstanceState)
///     NotificationChannelConfig.createNotificationChannels(this)
/// }
/// ```
///
///━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
///
/// 📝 Checklist:
/// - [ ] AndroidManifest.xml có POST_NOTIFICATIONS permission
/// - [ ] build.gradle.kts có targetSdk >= 33
/// - [ ] MainActivity extends FlutterActivity
/// - [ ] Channels được tạo (nếu muốn custom)
/// - [ ] pubspec.yaml có flutter_local_notifications
/// - [ ] Chạy `flutter pub get`
///

class AndroidNotificationSetup {
  static const String docString = '''
  ✅ ANDROID SETUP HOÀN TẤT
  
  Các bước quan trọng:
  1. POST_NOTIFICATIONS permission ✓
  2. targetSdk >= 33 ✓
  3. Notification channels ✓
  4. flutter_local_notifications ✓
  ''';
}
