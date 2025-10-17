import 'package:dishcovery_app/core/models/scan_model.dart';
import 'package:dishcovery_app/core/models/scan_result_entity.dart';
import 'package:dishcovery_app/objectbox.g.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ObjectBoxDatabase {
  late final Store _store;
  late final Box<ScanResultEntity> _scanResultBox;

  ObjectBoxDatabase._create(this._store) {
    _scanResultBox = Box<ScanResultEntity>(_store);
  }

  static Future<ObjectBoxDatabase> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final store = await openStore(
      directory: p.join(docsDir.path, "dishcovery-obx"),
    );
    return ObjectBoxDatabase._create(store);
  }

  Future<int> insertScanResult(ScanResult result) async {
    if (!result.isFood) {
      return -1;
    }
    final entity = ScanResultEntity.fromScanResult(result);
    return _scanResultBox.put(entity);
  }

  Future<List<ScanResult>> getAllHistory() async {
    final query = _scanResultBox
        .query()
        .order(ScanResultEntity_.createdAt, flags: Order.descending)
        .build();
    final entities = query.find();
    query.close();
    return entities.map((e) => e.toScanResult()).toList();
  }

  Future<bool> deleteHistory(int id) async {
    return _scanResultBox.remove(id);
  }

  Future<void> clearAll() async {
    await _scanResultBox.removeAll();
  }

  Future<void> updateScanResult(ScanResult result) async {
    if (result.id != null) {
      final entity = ScanResultEntity.fromScanResult(result);
      _scanResultBox.put(entity);
      return;
    }

    if (result.firestoreId != null) {
      final existing = getScanResultByFirestoreId(result.firestoreId!);
      if (existing != null && existing.id != null) {
        final entity = ScanResultEntity.fromScanResult(
          result.copyWith(id: existing.id),
        );
        _scanResultBox.put(entity);
        return;
      }
    }

    await insertScanResult(result);
  }

  ScanResult? getScanResultByFirestoreId(String firestoreId) {
    final query = _scanResultBox
        .query(ScanResultEntity_.firestoreId.equals(firestoreId))
        .build();
    final entities = query.find();
    query.close();
    if (entities.isEmpty) return null;
    return entities.first.toScanResult();
  }

  ScanResult? getScanResultById(int id) {
    final entity = _scanResultBox.get(id);
    return entity?.toScanResult();
  }

  Future<List<ScanResult>> getFavorites() async {
    final query = _scanResultBox
        .query(ScanResultEntity_.isFavorite.equals(true))
        .order(ScanResultEntity_.createdAt, flags: Order.descending)
        .build();
    final entities = query.find();
    query.close();
    return entities.map((e) => e.toScanResult()).toList();
  }

  Future<List<ScanResult>> getCachedPublicScans() async {
    final query = _scanResultBox
        .query(ScanResultEntity_.isPublic.equals(true))
        .order(ScanResultEntity_.createdAt, flags: Order.descending)
        .build();
    final entities = query.find();
    query.close();
    return entities.map((e) => e.toScanResult()).toList();
  }

  Future<List<ScanResult>> searchByName(String searchTerm) async {
    final query = _scanResultBox
        .query(
          ScanResultEntity_.name.contains(searchTerm, caseSensitive: false),
        )
        .order(ScanResultEntity_.createdAt, flags: Order.descending)
        .build();
    final entities = query.find();
    query.close();
    return entities.map((e) => e.toScanResult()).toList();
  }

  void close() {
    _store.close();
  }
}
