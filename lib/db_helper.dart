import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  Future<Database> initDb() async {
    String path = join(await getDatabasesPath(), 'photo_app.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE pin(id INTEGER PRIMARY KEY, code TEXT)');

        await db.execute('''
          CREATE TABLE media(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            path TEXT,
            type TEXT,
            addedAt TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE trash(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            path TEXT,
            type TEXT,
            deletedAt TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE media(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              path TEXT,
              type TEXT,
              addedAt TEXT
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE trash(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              path TEXT,
              type TEXT,
              deletedAt TEXT
            )
          ''');
        }
      },
    );
  }

  Future<void> savePin(String pin) async {
    var database = await db;
    await database.insert('pin', {
      'id': 1,
      'code': pin,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getPin() async {
    var database = await db;
    final result = await database.query('pin', where: 'id = ?', whereArgs: [1]);
    if (result.isNotEmpty) {
      return result.first['code'] as String;
    }
    return null;
  }

  Future<bool> isPinSet() async {
    String? pin = await getPin();
    return pin != null;
  }

  Future<int> insertMedia(String path, String type) async {
    var database = await db;
    return await database.insert('media', {
      'path': path,
      'type': type,
      'addedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getAllMedia() async {
    var database = await db;
    return await database.query('media', orderBy: "addedAt DESC");
  }

  Future<int> deleteMedia(int id) async {
    var database = await db;
    return await database.delete('media', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearMedia() async {
    var database = await db;
    await database.delete('media');
  }

  Future<int> moveToTrash(String path, String type) async {
    final database = await db;
    return await database.insert('trash', {
      "path": path,
      "type": type,
      "deletedAt": DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getAllTrash() async {
    final database = await db;
    return await database.query('trash', orderBy: "deletedAt DESC");
  }

  Future<int> deleteFromTrash(int id) async {
    final database = await db;
    return await database.delete('trash', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearTrash() async {
    final database = await db;
    await database.delete('trash');
  }
}
