# Architecture & Tech Decisions

Document các lựa chọn kiến trúc và công nghệ + lý do.

## State Management: Provider

**Decision**: Sử dụng **Provider** thay vì GetX, Bloc, Riverpod

**Pros**:
- ✅ Minimal boilerplate
- ✅ Easy to learn & maintain
- ✅ Native Flutter team recommendation
- ✅ Powerful với ProxyProvider + ChangeNotifierProxyProvider

**Cons**:
- ❌ Less powerful than Bloc
- ❌ Manual state refresh trong một số trường hợp

**Alternatives Considered**:
- GetX: Quá heavy cho project nhỏ, coupling cao
- Bloc: Quá verbose, overkill cho app này
- Riverpod: Quá mới, ecosystem chưa ổn định

---

## Local Storage: Hive

**Decision**: **Hive** instead của shared_preferences, sqflite, isar

**Pros**:
- ✅ Lightweight, type-safe
- ✅ Fast NoSQL database
- ✅ Built-in Dart type adapters
- ✅ không cần SQL syntax phức tạp

**Cons**:
- ❌ không có query language mạnh
- ❌ Cần rebuild adapter khi model change

**Use Case**:
- Lưu danh sách pantry items (dữ liệu semi-structured)
- Lưu user info locally (auth state)
- Không cần complex queries

**Alternatives**:
- shared_preferences: Chỉ cho key-value đơn
- sqflite: Overkill, cần SQL
- isar: Tốt nhưng mới hơn, ecosystem chưa lớn

---

## Cloud Sync: Firebase + Local-First

**Decision**: **Local-first** architecture, Firebase chỉ backup

**Architecture**:
```
Local (Hive) <- PRIMARY SOURCE OF TRUTH
    ↓
Cloud (Firestore) <- BACKUP + SYNC
```

**Pros**:
- ✅ App hoạt động offline hoàn toàn
- ✅ User không bị ép đăng nhập
- ✅ Dữ liệu không bao giờ bị mất nếu sync fail
- ✅ Dữ liệu local luôn thắng khi xung đột

**Cons**:
- ❌ Phức tạp hơn sync 2 chiều
- ❌ Cần xử lý edge cases (stale data, etc.)

**Sync Logic**:
1. **Backup**: Local → Cloud (batch, user-triggered)
2. **Restore**: Cloud → Local (pull newer items nếu local không dirty)
3. **Conflict**: Local timestamp >= Cloud timestamp → Local wins

**Metadata Fields** (cho sync):
```dart
itemId: String         // Unique ID, dùng để identify item across devices
updatedAtUtcMs: int    // Last update timestamp
deletedAtUtcMs: int?   // Soft delete flag
isDirty: bool          // Not yet synced to cloud
```

**Alternatives**:
- Firestore Real-time Sync: Quá heavy, tốn battery
- CloudKit (iOS): Platform-specific
- Custom backend: Complexity + cost

---

## Authentication: Firebase Auth

**Decision**: **Firebase Authentication** for Email/Password login

**Pros**:
- ✅ Zero backend setup
- ✅ Free tier generous (50k users/month)
- ✅ Built-in security, rate limiting
- ✅ Token management automatic
- ✅ Easy social login in future

**Cons**:
- ❌ Vendor lock-in
- ❌ Depends on internet (auth only, app works offline)

**Features**:
- Email/Password sign up + login
- Session persistence (token stored securely)
- Password reset email
- Error handling with Firebase codes

**Alternatives**:
- Custom backend: Complexity
- Auth0: Overkill cho hobby project
- Supabase: Tốt nhưng chưa production-ready khi project start

---

## OCR/Barcode: Google ML Kit

**Decision**: **ML Kit** for receipt scanning

**Pros**:
- ✅ Free, on-device (no API calls)
- ✅ Fast, good accuracy
- ✅ Text Recognition + Barcode scanning

**Cons**:
- ❌ không cải thiện theo time (offline model)
- ❌ Complex setup

**Use Case**:
- Khách hàng chụp ảnh hoá đơn
- ML Kit extract nguyên liệu + giá
- User review + confirm trước thêm

**Alternatives**:
- Google Cloud Vision: Phải gọi API, tính phí
- Tesseract: Offline nhưng chậm hơn
- Proprietary receipt parser (AWS, Microsoft): Expensive

---

## Notifications: flutter_local_notifications

**Decision**: **Local notifications** (phía client)

**Usage**:
- Cảnh báo hạn sử dụng (scheduled)
- Background check (Workmanager trigger)
- User action notifications

**Architecture**:
```
Workmanager (background job) → Check expired items
    ↓
NotificationService → Show local notification
```

**Alternatives**:
- Firebase Cloud Messaging: Cần backend
- OneSignal: Overkill

---

## Background Tasks: Workmanager

**Decision**: **Workmanager** for periodic background jobs

**Pros**:
- ✅ Works on Android + iOS
- ✅ Scheduled tasks (daily, hourly)
- ✅ Works offline

**Cons**:
- ❌ không guarantee execution
- ❌ Limited time window (~15 mins on iOS when in background)

**Use Case**:
```dart
// 1. Daily check for expiring items
await BackgroundWorker.scheduleCheckExpiredItems();

// 2. Periodic sync data (optional)
await BackgroundWorker.schedulePantrySyncTask();
```

**Alternatives**:
- Firebase Cloud Functions: Backend required
- Native Android WorkManager: Platform-specific

---

## Testing Strategy

**Current Status**: Minimal tests
**Goal**: Add unit + widget tests gradually

```dart
// Test examples to add
test('PantryItemModel copyWith works correctly', () {
  // ...
});

testWidgets('PantryScreen displays items', (WidgetTester tester) async {
  // ...
});
```

---

## Security Decisions

### 1. API Keys
- ❌ **NOT** in source code
- ✅ Firebase console management
- ✅ google-services.json (ignored)
- ✅ firebase_options.dart (auto-generated, ignored)

### 2. User Data
- ✅ Encrypted at rest (Firebase default)
- ✅ Token stored in FlutterSecureStorage
- ✅ No sensitive data in SharedPreferences

### 3. Firebase Security Rules (Firestore)
```javascript
// Template (implement after first deploy)
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

---

## Future Considerations

1. **Offline-first sync improvements**:
   - CRDTs (Conflict-free Replicated Data Types)
   - Sync with multiple device support

2. **AI Features**:
   - Recipe suggestion based on pantry
   - Meal planning with budget constraints
   - Nutritional analysis

3. **Social Features**:
   - Recipe sharing
   - Pantry comparison with friends
   - Recipe ratings

4. **Performance**:
   - Image caching for recipes
   - Pagination for large pantry lists
   - Analytics (optional, user opt-in)

---

## References

- [Flutter Architecture - Provider](https://flutter.dev/docs/development/data-and-backend/state-mgmt/intro)
- [Hive Documentation](https://docs.hivedb.dev/)
- [Firebase for Flutter](https://firebase.flutter.dev/)
- [ML Kit for Flutter](https://pub.dev/packages/google_mlkit_text_recognition)
