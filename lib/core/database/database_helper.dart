import 'package:dishcovery_app/core/models/scan_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _databaseName = 'dishcovery.db';
  static const _databaseVersion = 1;
  static const table = 'history';

  static const columnId = 'id';
  static const columnIsFood = 'isFood';
  static const columnImagePath = 'imagePath';
  static const columnName = 'name';
  static const columnOrigin = 'origin';
  static const columnDescription = 'description';
  static const columnHistory = 'history';
  static const columnRecipe = 'recipe';
  static const columnTags = 'tags';
  static const columnShared = 'shared';
  static const columnSharedAt = 'sharedAt';
  static const columnCreatedAt = 'createdAt';

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
        $columnIsFood INTEGER NOT NULL,
        $columnImagePath TEXT NOT NULL,
        $columnName TEXT NOT NULL,
        $columnOrigin TEXT,
        $columnDescription TEXT,
        $columnHistory TEXT,
        $columnRecipe TEXT,
        $columnTags TEXT,
        $columnShared INTEGER NOT NULL,
        $columnSharedAt TEXT,
        $columnCreatedAt TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertScanResult(ScanResult result) async {
    if (!result.isFood) {
      return -1;
    }
    final db = await database;
    return await db.insert(table, result.toDbMap());
  }

  Future<List<ScanResult>> getAllHistory() async {
    final db = await instance.database;
    final result = await db.query(table, orderBy: '$columnCreatedAt DESC');
    return result.map((dbMap) => ScanResult.fromDbMap(dbMap)).toList();
  }

  Future<int> deleteHistory(int id) async {
    final db = await database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete(table);
  }
}
