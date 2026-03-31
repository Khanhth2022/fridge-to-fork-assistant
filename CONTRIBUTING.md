# Contributing to Fridge to Fork Assistant

Cảm ơn bạn đã quan tâm đóng góp vào project! 🙌

## Code of Conduct

Chúng tôi cam kết duy trì một cộng đồng lành mạnh. Vui lòng:
- Tôn trọng mọi người độc lập với nền tảng, giới tính, bản sắc
- Không spam, không quấy rối, không tấn công
- Giải quyết bất đồng bằng đối thoại xây dựng

## Cách Đóng Góp

### 1. Report Bugs
- Kiểm tra [Issues](https://github.com/yourusername/fridge_to_fork_assistant/issues) trước (có thể đã tồn tại)
- Cung cấp chi tiết:
  - Version Flutter/Dart
  - OS (Android, iOS, Windows)
  - Bước để reproduce
  - Expected vs actual behavior
  - Screenshots/logs

### 2. Đề Xuất Features
- Open issue với tag `enhancement`
- Describe use case + expected behavior
- Nếu có ý định implement, comment vào issue trước

### 3. Cải Thiện Documentation
- Sửa typo / thêm ví dụ / làm rõ
- Tạo PR trực tiếp (không cần issue trước)

### 4. Code Contribution

#### Setup Development Environment
```bash
# Clone + setup
git clone https://github.com/yourusername/fridge_to_fork_assistant.git
cd fridge_to_fork_assistant
flutter pub get

# Setup Firebase (xem SETUP_FIREBASE.md)
flutterfire configure --project=fridge-to-fork-assistant

# Run tests
flutter test
```

#### Code Style
```bash
# Format code
flutter format lib/ android/ test/

# Analyze code
flutter analyze

# Fix issues automatically (optional)
dart fix --apply
```

#### Conventions
- **Branch naming**: `feature/short-description` hoặc `fix/issue-name`
- **Commit messages**: "Add feature X" hoặc "Fix bug in Y"
- **PR title**: Descriptive, tương tự commit message

#### Before submitting PR
- [ ] Code formatted (`flutter format`)
- [ ] No analyze warnings (`flutter analyze`)
- [ ] Tests pass (`flutter test`)
- [ ] Updated README if needed
- [ ] No debug prints/logs
- [ ] Proper error handling
- [ ] Checked for TODOs/FIXMEs

### 5. Create a Pull Request

1. Fork repository
2. Create feature branch
3. Make changes
4. Commit with clear messages
5. Push to your fork
6. Open PR từ your fork → main repo

**PR Template:**
```markdown
## Description
Ngắn gọn mô tả thay đổi

## Related Issue
Closes #123 (nếu fix issue)

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation
- [ ] Refactor
- [ ] Performance

## How Has This Been Tested?
Mô tả test cases

## Screenshots (if UI change)
Attach screenshots/video

## Checklist
- [ ] Code formatted
- [ ] No new warnings
- [ ] Tests pass
- [ ] Documentation updated
```

## Project Structure

```
lib/features/
├── pantry/          # Main feature
├── auth/           # Authentication  
├── recipes/        # Recipe database
├── shopping_list/  # Shopping list
└── meal_planner/   # Meal planning

lib/core/
├── services/       # Business logic
└── widgets/        # Shared widgets
```

## Development Guidelines

### Naming Conventions
- **Classes**: `PascalCase` (e.g., `PantryItemModel`)
- **Variables**: `camelCase` (e.g., `itemId`, `expiryDate`)
- **Constants**: `camelCase` (e.g., `defaultTimeout`)
- **Files**: `snake_case` (e.g., `pantry_item_model.dart`)

### Comments
```dart
// ❌ Avoid
int x = 5; // Set x to 5

// ✅ Good
// Timeout for Firebase requests in milliseconds
int requestTimeout = 5000;

/// This is a widget that displays pantry items
/// 
/// It uses [PantryViewModel] to manage state
class PantryScreen extends StatelessWidget {
  // ...
}
```

### Error Handling
```dart
// ❌ Don't swallow exceptions
try {
  await someAsyncOperation();
} catch (e) {
  // Silent fail - BAD!
}

// ✅ Do handle properly
try {
  await someAsyncOperation();
} catch (e) {
  debugPrint('Error: $e');
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Failed: $e')),
  );
}
```

## Questions?

- 💬 Discussion: GitHub Discussions
- 📧 Email: your-email@example.com
- 🐦 Twitter: @yourusername

---

**Thank you for contributing! ❤️**
