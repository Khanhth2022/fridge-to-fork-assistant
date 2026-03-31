import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../../features/pantry/models/pantry_item_model.dart';
import '../auth/auth_service.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService authService;
  static const String _pantryBoxName = 'pantry_items';

  SyncService({required this.authService});

  // Get reference to user's pantry items collection
  CollectionReference<Map<String, dynamic>> _getUserPantryRef() {
    final userId = authService.currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('pantry_items');
  }

  // Backup local pantry to Firestore (Local-first: local wins on conflict)
  Future<void> backupNow() async {
    if (!authService.isLoggedIn) {
      throw 'Vui lòng đăng nhập để sao lưu dữ liệu';
    }

    try {
      final box = await Hive.openBox<PantryItemModel>(_pantryBoxName);
      final localItems = box.values.toList();

      for (var item in localItems) {
        // Skip deleted items (soft delete) for now
        if (item.deletedAtUtcMs != null) continue;

        await _uploadOrUpdateItem(item);
      }

      // Mark all items as synced
      for (int i = 0; i < localItems.length; i++) {
        if (localItems[i].deletedAtUtcMs == null) {
          final updated = localItems[i].copyWith(isDirty: false);
          await box.putAt(i, updated);
        }
      }
    } catch (e) {
      throw 'Lỗi khi sao lưu: $e';
    }
  }

  // Upload or update single item
  Future<void> _uploadOrUpdateItem(PantryItemModel item) async {
    final ref = _getUserPantryRef();

    // Check if cloud has this item
    final cloudDoc = await ref.doc(item.itemId).get();

    if (!cloudDoc.exists) {
      // Cloud doesn't have it, upload
      await ref.doc(item.itemId).set(item.toFirestore());
    } else {
      // Cloud has it, compare timestamps
      final cloudData = cloudDoc.data();
      final cloudUpdatedAtMs = cloudData?['updatedAtUtcMs'] ?? 0;

      if (item.updatedAtUtcMs >= cloudUpdatedAtMs) {
        // Local is newer or same, overwrite cloud
        await ref.doc(item.itemId).update(item.toFirestore());
      }
      // If cloud is newer and local not dirty, pull will happen on restore
    }
  }

  // Restore from Firestore (pull newer items from cloud)
  Future<void> restoreFromCloud() async {
    if (!authService.isLoggedIn) {
      throw 'Vui lòng đăng nhập để khôi phục dữ liệu';
    }

    try {
      final box = await Hive.openBox<PantryItemModel>(_pantryBoxName);
      final ref = _getUserPantryRef();

      // Get all items from cloud
      final snapshot = await ref.get();

      for (var doc in snapshot.docs) {
        final cloudData = doc.data();
        final cloudItem = _fromFirestore(cloudData);

        // Find local item with same ID
        final localItemIndex = box.values.toList().indexWhere(
          (item) => item.itemId == cloudItem.itemId,
        );

        if (localItemIndex == -1) {
          // Local doesn't have it, add from cloud
          await box.add(cloudItem.copyWith(isDirty: false));
        } else {
          // Local has it, check timestamps
          final localItem = box.getAt(localItemIndex)!;

          if (cloudItem.updatedAtUtcMs > localItem.updatedAtUtcMs &&
              !localItem.isDirty) {
            // Cloud is newer and local is not dirty, update local
            await box.putAt(localItemIndex, cloudItem.copyWith(isDirty: false));
          }
          // If local is dirty, keep local (local-first principle)
        }
      }
    } catch (e) {
      throw 'Lỗi khi khôi phục: $e';
    }
  }

  // Sync all items bidirectionally (backup và restore)
  Future<void> syncAll() async {
    await backupNow();
    await restoreFromCloud();
  }

  // Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final box = await Hive.openBox<PantryItemModel>(_pantryBoxName);
      final items = box.values.toList();

      final dirtyCount = items.where((item) => item.isDirty).length;
      final totalCount = items.length;
      final lastSyncTime = box.get('lastSyncTime', defaultValue: null);

      return {
        'isSynced': dirtyCount == 0,
        'dirtyItemCount': dirtyCount,
        'totalItemCount': totalCount,
        'lastSyncTime': lastSyncTime,
      };
    } catch (e) {
      return {'isSynced': false, 'error': e.toString()};
    }
  }

  // Clear all local data (use with caution)
  Future<void> clearAllLocalData() async {
    final box = await Hive.openBox<PantryItemModel>(_pantryBoxName);
    await box.clear();
  }
}

// Extension methods for PantryItemModel
extension PantryItemModelFirestore on PantryItemModel {
  Map<String, dynamic> toFirestore() {
    return {
      'itemId': itemId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'purchaseDate': purchaseDate.millisecondsSinceEpoch,
      'expiryDate': expiryDate.millisecondsSinceEpoch,
      'updatedAtUtcMs': updatedAtUtcMs,
      'deletedAtUtcMs': deletedAtUtcMs,
      'deviceId': deviceId,
    };
  }
}

PantryItemModel _fromFirestore(Map<String, dynamic> data) {
  return PantryItemModel(
    itemId: (data['itemId'] as String?) ?? '',
    name: (data['name'] as String?) ?? '',
    quantity: ((data['quantity'] ?? 0) as num).toDouble(),
    unit: (data['unit'] as String?) ?? '',
    purchaseDate: DateTime.fromMillisecondsSinceEpoch(
      (data['purchaseDate'] ?? 0) as int,
    ),
    expiryDate: DateTime.fromMillisecondsSinceEpoch(
      (data['expiryDate'] ?? 0) as int,
    ),
    updatedAtUtcMs: (data['updatedAtUtcMs'] ?? 0) as int,
    deletedAtUtcMs: data['deletedAtUtcMs'] as int?,
    deviceId: data['deviceId'] as String?,
    isDirty: false,
  );
}
