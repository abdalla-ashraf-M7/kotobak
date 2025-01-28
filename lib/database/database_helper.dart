import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'library.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add coverImagePath column to books table
      await db.execute('ALTER TABLE books ADD COLUMN coverImagePath TEXT;');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Books table
    await db.execute('''
      CREATE TABLE books(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        filePath TEXT NOT NULL,
        coverImagePath TEXT,
        progress REAL DEFAULT 0.0,
        lastRead INTEGER,
        createdAt INTEGER
      )
    ''');

    // Bookmarks table
    await db.execute('''
      CREATE TABLE bookmarks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookId TEXT NOT NULL,
        page INTEGER NOT NULL,
        note TEXT,
        createdAt INTEGER,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');

    // Reading history table
    await db.execute('''
      CREATE TABLE reading_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookId TEXT NOT NULL,
        page INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');
  }

  // Debug method to check table schema
  Future<void> checkTableSchema() async {
    final db = await database;
    var tableInfo = await db.rawQuery("PRAGMA table_info('books')");
    print('Books table schema:');
    for (var column in tableInfo) {
      print('Column: ${column['name']}, Type: ${column['type']}');
    }
  }

  // Book operations
  Future<String> insertBook(Map<String, dynamic> book) async {
    final db = await database;
    book['createdAt'] = DateTime.now().millisecondsSinceEpoch;
    await db.insert('books', book);
    return book['id'];
  }

  Future<List<Map<String, dynamic>>> getBooks() async {
    final db = await database;
    return await db.query('books', orderBy: 'createdAt DESC');
  }

  Future<void> updateBookProgress(String bookId, double progress) async {
    final db = await database;
    await db.update(
      'books',
      {
        'progress': progress,
        'lastRead': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  // Bookmark operations
  Future<int> insertBookmark(String bookId, int page, {String? note}) async {
    final db = await database;
    return await db.insert('bookmarks', {
      'bookId': bookId,
      'page': page,
      'note': note,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getBookmarks(String bookId) async {
    final db = await database;
    return await db.query(
      'bookmarks',
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'page ASC',
    );
  }

  // Reading history operations
  Future<void> addReadingHistory(String bookId, int page) async {
    final db = await database;
    await db.insert('reading_history', {
      'bookId': bookId,
      'page': page,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getReadingHistory(String bookId) async {
    final db = await database;
    return await db.query(
      'reading_history',
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'timestamp DESC',
    );
  }
}
