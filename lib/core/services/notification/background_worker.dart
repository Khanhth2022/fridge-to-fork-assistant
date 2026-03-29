import 'package:workmanager/workmanager.dart';
import 'package:flutter/material.dart';
import 'notification_service.dart';

/// Background task definitions
class BackgroundTaskNames {
  /// Daily task to check for expired items at 8 AM
  static const String checkExpiredItems = 'checkExpiredItems';
  
  /// Periodic task to sync pantry data
  static const String syncPantryData = 'syncPantryData';
}

/// Background worker for handling notifications and scheduled tasks
class BackgroundWorker {
  static final BackgroundWorker _instance = BackgroundWorker._internal();

  factory BackgroundWorker() {
    return _instance;
  }

  BackgroundWorker._internal();

  /// Initialize background tasks
  /// 
  /// This should be called in main() before runApp()
  /// Enable debug mode only during development
  static Future<void> initialize({bool debugMode = false}) async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: debugMode,
    );
    debugPrint('BackgroundWorker initialized');
  }

  /// Schedule daily check for expired items at 8 AM
  /// 
  /// This uses a daily periodic task that starts from 8 AM
  static Future<void> scheduleCheckExpiredItems() async {
    await Workmanager().registerPeriodicTask(
      BackgroundTaskNames.checkExpiredItems,
      BackgroundTaskNames.checkExpiredItems,
      frequency: const Duration(days: 1),
      initialDelay: _calculateInitialDelay(),
      constraints: Constraints(
        requiresDeviceIdle: false,
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
      ),
      backoffPolicy: BackoffPolicy.exponential,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
    debugPrint('Scheduled checkExpiredItems task');
  }

  /// Schedule periodic sync of pantry data
  static Future<void> schedulePantrySyncTask() async {
    await Workmanager().registerPeriodicTask(
      BackgroundTaskNames.syncPantryData,
      BackgroundTaskNames.syncPantryData,
      frequency: const Duration(hours: 6),
      constraints: Constraints(
        requiresDeviceIdle: false,
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
      ),
      backoffPolicy: BackoffPolicy.exponential,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
    debugPrint('Scheduled syncPantryData task');
  }

  /// Cancel background tasks
  static Future<void> cancelCheckExpiredItemsTask() async {
    await Workmanager().cancelByTag(BackgroundTaskNames.checkExpiredItems);
    debugPrint('Cancelled checkExpiredItems task');
  }

  static Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
    debugPrint('Cancelled all background tasks');
  }

  /// Calculate initial delay to run task at 8 AM
  static Duration _calculateInitialDelay() {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 8, 0);

    // If 8 AM has already passed today, schedule for tomorrow
    if (now.isAfter(scheduledTime)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final delay = scheduledTime.difference(now);
    debugPrint('Initial delay for 8 AM task: ${delay.inMinutes} minutes');
    
    return delay;
  }

  static BackgroundWorker get instance => _instance;
}

/// Callback dispatcher for background tasks
/// 
/// This must be a top-level function and cannot access instance variables
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    debugPrint('Background task started: $taskName');

    try {
      switch (taskName) {
        case BackgroundTaskNames.checkExpiredItems:
          await _handleCheckExpiredItems();
          break;

        case BackgroundTaskNames.syncPantryData:
          await _handleSyncPantryData();
          break;

        default:
          debugPrint('Unknown task: $taskName');
      }

      debugPrint('Background task completed: $taskName');
      return true;
    } catch (e) {
      debugPrint('Error in background task $taskName: $e');
      return false;
    }
  });
}

/// Handle expired items check
/// 
/// This fetches items from the pantry repository and checks for items
/// that are expiring soon (within 3 days) or already expired
Future<void> _handleCheckExpiredItems() async {
  debugPrint('Checking for expired items...');

  try {
    // TODO: Implement integration with Member 1's Pantry Repository
    // Example pseudocode:
    // final pantryRepo = PantryRepository();
    // final items = await pantryRepo.getAllItems();
    // final expiringSoon = items.where((item) => 
    //   item.expiryDate.difference(DateTime.now()).inDays <= 3
    // ).toList();

    // For now, we'll simulate the check
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call

    // Example: Send notification for simulated expired items
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    // Simulate checking for items expiring tomorrow
    bool hasExpiringItems = now.day % 7 == 0; // Arbitrary condition for demo

    if (hasExpiringItems) {
      await NotificationService().showNotification(
        id: 1001,
        title: '⚠️ Hàng hóa sắp hết hạn',
        body: 'Có ${'1'} sản phẩm sắp hết hạn trong ${tomorrow.day} ngày',
        payload: 'route:pantry',
      );
      debugPrint('Sent expiring items notification');
    }

    // Always send at least a debug notification
    await NotificationService().showNotification(
      id: 1000,
      title: '✓ Kiểm tra HSD hoàn tất',
      body: 'Lần kiểm tra gần nhất: ${now.toString()}',
      payload: 'route:pantry',
    );
  } catch (e) {
    debugPrint('Error checking expired items: $e');
    await NotificationService().showNotification(
      id: 1002,
      title: '❌ Lỗi kiểm tra HSD',
      body: 'Không thể kiểm tra hàng hóa hết hạn',
      payload: 'route:pantry',
    );
  }
}

/// Handle pantry data sync
/// 
/// This synchronizes pantry data from local storage with any remote sources
Future<void> _handleSyncPantryData() async {
  debugPrint('Syncing pantry data...');

  try {
    // TODO: Implement integration with Member 1's Pantry Repository
    // Example pseudocode:
    // final pantryRepo = PantryRepository();
    // await pantryRepo.syncWithRemote();

    await Future.delayed(const Duration(seconds: 3)); // Simulate sync

    debugPrint('Pantry data synced successfully');
  } catch (e) {
    debugPrint('Error syncing pantry data: $e');
  }
}
