import 'package:flutter/material.dart';
import '../../../features/pantry/pantry_repository.dart';
import '../../../features/pantry/models/pantry_item_model.dart';
import 'notification_service.dart';

class ExpiryNotificationService {
  static const int defaultThresholdDays = 2;

  static Future<int> checkAndNotifyExpiringItems({
    int thresholdDays = defaultThresholdDays,
  }) async {
    final repository = PantryRepository();
    final items = await repository.getAllItems();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final expiringSoon = items.where((item) {
      final daysLeft = _daysUntil(item, today);
      return daysLeft >= 0 && daysLeft <= thresholdDays;
    }).toList();

    if (expiringSoon.isEmpty) {
      return 0;
    }

    final names = expiringSoon.map((e) => e.name).take(3).join(', ');
    final remainCount = expiringSoon.length - 3;
    final summary = remainCount > 0 ? '$names và $remainCount sản phẩm khác' : names;

    await NotificationService().showNotification(
      id: _buildNotificationId(today),
      title: 'Canh bao han su dung',
      body: '$summary sap het han trong $thresholdDays ngay toi.',
      payload: 'route:pantry',
    );

    debugPrint('Expiring items notification sent: ${expiringSoon.length} items');
    return expiringSoon.length;
  }

  static int _daysUntil(PantryItemModel item, DateTime today) {
    return item.expiryDate.difference(today).inDays;
  }

  static int _buildNotificationId(DateTime today) {
    return int.parse('${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}');
  }
}
