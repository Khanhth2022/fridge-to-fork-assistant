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
    _titleController = TextEditingController(text: 'Test Notification');
    _bodyController = TextEditingController(text: 'This is a test notification');
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
      appBar: AppBar(title: const Text('🧪 Notification Test')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input fields
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                hintText: 'Notification title',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Body',
                border: OutlineInputBorder(),
                hintText: 'Notification body',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _payloadController,
              decoration: const InputDecoration(
                labelText: 'Payload / Deep Link',
                border: OutlineInputBorder(),
                hintText: 'e.g., route:pantry?ingredient=milk',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Predefined test cases
            Text(
              'Quick Test Cases',
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
                      '🥫 Pantry Tests',
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
                      child: const Text('Send: Milk Expiring'),
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
                      child: const Text('Send: Cheese Expired'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _sendTestNotification(
                        title: '✅ Kiểm tra HSD hoàn tất',
                        body: 'Tất cả hàng hóa vẫn tốt',
                        payload: DeepLinkHandler.buildPantryPayload(),
                      ),
                      child: const Text('Send: Check Complete'),
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
                      '🛒 Shopping List Tests',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _sendTestNotification(
                        title: '🛒 Danh sách mua sắm',
                        body: 'Bạn có 5 mục trong danh sách',
                        payload:
                            DeepLinkHandler.buildShoppingListPayload(),
                      ),
                      child: const Text('Send: Shopping List'),
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
                      '👨‍🍳 Recipes Tests',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _sendTestNotification(
                        title: '👨‍🍳 Công thức mới: Cơm chiên',
                        body: 'Tìm hiểu công thức cơm chiên ngon',
                        payload:
                            DeepLinkHandler.buildRecipePayload(recipeId: '123'),
                      ),
                      child: const Text('Send: New Recipe'),
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
                      '📅 Meal Planner Tests',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _sendTestNotification(
                        title: 'Nhắc nhở bữa tối',
                        body: 'Hãy lên kế hoạch cho bữa tối',
                        payload:
                            DeepLinkHandler.buildMealPayload(mealId: '456'),
                      ),
                      child: const Text('Send: Meal Reminder'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Custom notification button
            Text(
              'Custom Notification',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _sendCustomNotification,
              icon: const Icon(Icons.send),
              label: const Text('Send Custom Notification'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await NotificationService().cancelAllNotifications();
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('All notifications cancelled')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Cancel All Notifications'),
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
