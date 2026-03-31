import 'package:flutter/material.dart';
import '../services/notification/notification_service.dart';
import '../services/notification/deep_link_handler.dart';

/// Test screen for notifications
/// Use this to test various notification scenarios during development
class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late TextEditingController _payloadController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: 'Kiểm thử thông báo');
    _bodyController = TextEditingController(
      text: 'Đây là một thông báo kiểm thử',
    );
    _payloadController = TextEditingController(text: 'route:pantry');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _payloadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🧪 Kiểm thử thông báo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input fields
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề',
                border: OutlineInputBorder(),
                hintText: 'Tiêu đề thông báo',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Nội dung',
                border: OutlineInputBorder(),
                hintText: 'Nội dung thông báo',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _payloadController,
              decoration: const InputDecoration(
                labelText: 'Tải trọng / Liên kết sâu',
                border: OutlineInputBorder(),
                hintText: 'Ví dụ: route:pantry?ingredient=milk',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Predefined test cases
            Text(
              'Trường hợp Kiểm thử Nhanh',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),

            // Pantry-related notifications
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🥫 Kiểm thử Tủ bếp',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _sendTestNotification(
                        title: '⚠️ Sữa sắp hết hạn',
                        body: 'Sữa của bạn sẽ hết hạn trong 2 ngày',
                        payload: DeepLinkHandler.buildPantryPayload(
                          ingredient: 'sữa',
                        ),
                      ),
                      child: const Text('Gửi: Sữa sắp hết hạn'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _sendTestNotification(
                        title: '❌ Mặt nạ hết hạn',
                        body: 'Mặt nạ của bạn đã hết hạn',
                        payload: DeepLinkHandler.buildExpiringItemPayload(
                          itemName: 'mặt nạ',
                          isExpired: true,
                        ),
                      ),
                      child: const Text('Gửi: Mặt nạ đã hết hạn'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _sendTestNotification(
                        title: '✅ Kiểm tra HSD hoàn tất',
                        body: 'Tất cả hàng hóa vẫn tốt',
                        payload: DeepLinkHandler.buildPantryPayload(),
                      ),
                      child: const Text('Gửi: Kiểm tra Hoàn tất'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Shopping list notifications
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🛒 Kiểm thử Danh sách mua',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _sendTestNotification(
                        title: '🛒 Danh sách mua sắm',
                        body: 'Bạn có 5 mục trong danh sách',
                        payload: DeepLinkHandler.buildShoppingListPayload(),
                      ),
                      child: const Text('Gửi: Danh sách mua'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Recipe notifications
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '👨‍🍳 Kiểm thử Công thức',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _sendTestNotification(
                        title: '👨‍🍳 Công thức mới: Cơm chiên',
                        body: 'Tìm hiểu công thức cơm chiên ngon',
                        payload: DeepLinkHandler.buildRecipePayload(
                          recipeId: '123',
                        ),
                      ),
                      child: const Text('Gửi: Công thức mới'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Meal planner notifications
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📅 Kiểm thử Lên menu',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _sendTestNotification(
                        title: 'Nhắc nhở bữa tối',
                        body: 'Hãy lên kế hoạch cho bữa tối',
                        payload: DeepLinkHandler.buildMealPayload(
                          mealId: '456',
                        ),
                      ),
                      child: const Text('Gửi: Nhắc nhở bữa ăn'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Custom notification button
            Text(
              'Thông báo tùy chỉnh',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _sendCustomNotification,
              icon: const Icon(Icons.send),
              label: const Text('Gửi thông báo tùy chỉnh'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await NotificationService().cancelAllNotifications();
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Tất cả thông báo đã bị hủy')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hủy tất cả thông báo'),
            ),
          ],
        ),
      ),
    );
  }

  void _sendTestNotification({
    required String title,
    required String body,
    required String payload,
  }) {
    NotificationService().showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: payload,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sent: $title'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _sendCustomNotification() {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill title and body')),
      );
      return;
    }

    NotificationService().showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: _titleController.text,
      body: _bodyController.text,
      payload: _payloadController.text.isEmpty ? null : _payloadController.text,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sent: ${_titleController.text}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
