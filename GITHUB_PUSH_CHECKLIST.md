# ✅ Pre-GitHub Push Checklist

Chứng thực rằng bạn đã sẵn sàng push lên GitHub mà không lộ credentials.

## Bảo Mật (CRITICAL)

- [ ] ✅ `.gitignore` đã được update (xem [.gitignore](.gitignore))
- [ ] ❌ **KHÔNG** commit `android/app/google-services.json`
- [ ] ❌ **KHÔNG** commit `lib/firebase_options.dart`
- [ ] ❌ **KHÔNG** commit `android/key.properties`
- [ ] ❌ **KHÔNG** commit bất kỳ file `.jks` hoặc `.keystore`
- [ ] ✅ Kiểm tra trạng thái files: `git status`

### Để kiểm tra có file nhạy cảm chưa:
```bash
git status
# Nếu thấy các file trên, ĐỪNG commit!
# Chạy:
git rm --cached <file-name>
git commit -m "chore: remove sensitive files from tracking"
```

## Tài Liệu

- [ ] ✅ [README.md](README.md) - project overview + setup guide
- [ ] ✅ [SETUP_FIREBASE.md](SETUP_FIREBASE.md) - Firebase configuration guide
- [ ] ❓ [LICENSE](LICENSE) - update license info
- [ ] ❓ [CONTRIBUTING.md](CONTRIBUTING.md) - contribution guidelines (optional)

## Code Quality

- [ ] ✅ `flutter analyze` - không có lỗi
- [ ] ✅ `flutter test` - all tests pass (nếu có)
- [ ] ✅ Format code: `flutter format lib/`
- [ ] ✅ Remove unused imports: chạy `dart fix --apply` (optional)

## Git Configuration

- [ ] ✅ Tạo `.gitattributes` để normalize line endings (optional nhưng tốt)
- [ ] ✅ Cấu hình `.gitignore` chính xác
- [ ] ✅ Không có uncommitted changes (chạy `git status`)

## GitHub Repository

### Trước khi push:
1. Tạo repo trên GitHub (private hoặc public)
2. Copy git URL từ GitHub (HTTPS hoặc SSH)
3. Add remote: `git remote add origin <url>`

### Push lần đầu:
```bash
# Check trạng thái
git status

# Add files (tất cả except .gitignore)
git add .

# Commit
git commit -m "Initial commit: Fridge to Fork Assistant with auth and sync"

# Push
git branch -M main
git push -u origin main
```

### Nếu có branches khác:
```bash
git push -u origin <branch-name>
```

## Documentation Updates (Optional nhưng Recommended)

- [ ] ❓ Add badges (Flutter, Dart version, etc.)
- [ ] ❓ Add screenshots/demo video link
- [ ] ❓ Add troubleshooting section
- [ ] ❓ Add development setup (Android SDK, Flutter version)

## Post-Push Verification

- [ ] ✅ Kiểm tra repo trên GitHub:
  - Không thấy `google-services.json`
  - Không thấy `firebase_options.dart`
  - Không thấy `.jks` files
- [ ] ✅ Clone repo trên máy khác để test setup lần đầu
- [ ] ✅ Follow [SETUP_FIREBASE.md](SETUP_FIREBASE.md) để ensure people can setup

## Useful Commands

```bash
# Xem tất cả files sẽ được commit
git add . && git status

# Xem tất cả files đang tracked
git ls-files

# Xem tất cả files bị ignore
git status --ignored

# Xem history commit
git log --oneline -10

# Undo last commit (nếu nhầm)
git reset --soft HEAD~1
```

## Nếu Nhầm Commit Sensitive Files

```bash
# Cách 1: Xóa từ history (RECOMMENDED)
git rm --cached android/app/google-services.json
git commit -m "chore: remove sensitive Firebase config"
git push

# Cách 2: Amend last commit (nếu chưa push)
git reset HEAD android/app/google-services.json
git commit --amend -m "Initial commit: fixed"
git push -f

# Cách 3: Full history clean (nếu đã public, cần inform team)
git filter-branch --tree-filter 'rm -f android/app/google-services.json' HEAD
git push -f
```

**⚠️ Nếu repo public và đã expose credentials, re-generate tất cả Firebase API keys ASAP!**

---

**Ready to push? ✅ Verify all checkboxes above!**
