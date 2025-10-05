import 'package:dishcovery_app/core/models/scan_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = 'dishcovery.db';
  static const _databaseVersion = 1;
  static const table = 'history';

  static const columnId = 'id';
  static const columnName = 'name';
  static const columnOrigin = 'origin';
  static const columnDescription = 'description';
  static const columnHistory = 'history';
  static const columnTags = 'tags';
  static const columnImagePath = 'imagePath';
  static const columnDate = 'date';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnName TEXT,
        $columnOrigin TEXT,
        $columnDescription TEXT,
        $columnHistory TEXT,
        $columnTags TEXT,
        $columnImagePath TEXT,
        $columnDate TEXT
      )
    ''');
  }

  Future<bool> isDuplicate(String imagePath) async {
    final db = await database;
    final result = await db.query(
      table,
      where: '$columnImagePath = ?',
      whereArgs: [imagePath],
    );
    return result.isNotEmpty;
  }

  Future<int> insertScanResult(ScanResult result) async {
    final db = await database;

    if (result.name.toLowerCase() == 'bukan makanan') {
      return -1;
    }

    return await db.insert(table, {
      columnName: result.name,
      columnOrigin: result.origin,
      columnDescription: result.description,
      columnHistory: result.history,
      columnTags: result.tags.join(', '),
      columnImagePath: result.imagePath,
      columnDate: DateTime.now().toIso8601String(),
    });
  }

  Future<int> insertHistory(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, {
      columnName: data[columnName],
      columnOrigin: data[columnOrigin] ?? '',
      columnDescription: data[columnDescription] ?? '',
      columnHistory: data[columnHistory] ?? '',
      columnTags: data[columnTags] ?? '',
      columnImagePath: data[columnImagePath] ?? '',
      columnDate: data[columnDate] ?? DateTime.now().toIso8601String(),
    });
  }

  Future<List<ScanResult>> getAllHistory() async {
    final db = await instance.database;
    final result = await db.query('history');
    return result.map((json) => ScanResult.fromJson(json)).toList();
  }

  Future<int> deleteHistory(int id) async {
    final db = await database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete(table);
  }

  Future<void> clearAllHistory() async {
    final db = await database;
    await db.delete(table);
  }
}
