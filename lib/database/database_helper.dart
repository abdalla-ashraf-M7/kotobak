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
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add coverImagePath column to books table
      await db.execute('ALTER TABLE books ADD COLUMN coverImagePath TEXT;');
    }
    if (oldVersion < 3) {
      // Add cache-related columns
      await db.execute('ALTER TABLE books ADD COLUMN cachedPath TEXT;');
      await db.execute('ALTER TABLE books ADD COLUMN lastCached INTEGER;');

      // Create annotations table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS annotations(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          bookId TEXT NOT NULL,
          page INTEGER NOT NULL,
          type TEXT NOT NULL,
          color INTEGER NOT NULL,
          opacity REAL NOT NULL,
          points TEXT NOT NULL,
          strokeWidth REAL NOT NULL,
          createdAt INTEGER NOT NULL,
          FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
        )
      ''');

      // Create drawing layers table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS drawing_layers(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          bookId TEXT NOT NULL,
          page INTEGER NOT NULL,
          layerName TEXT NOT NULL,
          isVisible BOOLEAN NOT NULL DEFAULT 1,
          strokeColor INTEGER NOT NULL,
          strokeWidth REAL NOT NULL,
          opacity REAL NOT NULL,
          points TEXT NOT NULL,
          createdAt INTEGER NOT NULL,
          FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
        )
      ''');
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
        createdAt INTEGER,
        cachedPath TEXT,
        lastCached INTEGER
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

    // Annotations table
    await db.execute('''
      CREATE TABLE annotations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookId TEXT NOT NULL,
        page INTEGER NOT NULL,
        type TEXT NOT NULL,
        color INTEGER NOT NULL,
        opacity REAL NOT NULL,
        points TEXT NOT NULL,
        strokeWidth REAL NOT NULL,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');

    /* // Drawing layers table
    await db.execute('''
      CREATE TABLE drawing_layers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookId TEXT NOT NULL,
        page INTEGER NOT NULL,
        layerName TEXT NOT NULL,
        isVisible BOOLEAN NOT NULL DEFAULT 1,
        strokeColor INTEGER NOT NULL,
        strokeWidth REAL NOT NULL,
        opacity REAL NOT NULL,
        points TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
      )
    '''); */
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

  Future<void> deleteBook(String bookId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Delete book
      await txn.delete(
        'books',
        where: 'id = ?',
        whereArgs: [bookId],
      );
      // Delete related bookmarks
      await txn.delete(
        'bookmarks',
        where: 'bookId = ?',
        whereArgs: [bookId],
      );
      // Delete related reading history
      await txn.delete(
        'reading_history',
        where: 'bookId = ?',
        whereArgs: [bookId],
      );
    });
  }

  Future<void> updateBook(String bookId, Map<String, dynamic> book) async {
    final db = await database;
    await db.update(
      'books',
      {
        'title': book['title'],
        'author': book['author'],
        'coverImagePath': book['coverImagePath'],
      },
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  // Annotation operations
  Future<int> insertAnnotation(Map<String, dynamic> annotation) async {
    final db = await database;
    return await db.insert('annotations', annotation);
  }

  Future<List<Map<String, dynamic>>> getAnnotations(String bookId, int page) async {
    final db = await database;
    return await db.query(
      'annotations',
      where: 'bookId = ? AND page = ?',
      whereArgs: [bookId, page],
      orderBy: 'createdAt ASC',
    );
  }

  Future<void> updateAnnotation(int id, Map<String, dynamic> annotation) async {
    final db = await database;
    await db.update(
      'annotations',
      annotation,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAnnotation(int id) async {
    final db = await database;
    await db.delete(
      'annotations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Drawing layer operations
  Future<int> insertDrawingLayer(Map<String, dynamic> layer) async {
    final db = await database;
    return await db.insert('drawing_layers', layer);
  }

  Future<List<Map<String, dynamic>>> getDrawingLayers(String bookId, int page) async {
    final db = await database;
    print('Fetching drawings for book: $bookId, page: $page');
    final results = await db.query(
      'drawing_layers',
      where: 'bookId = ? AND page = ?',
      whereArgs: [bookId, page],
      orderBy: 'createdAt ASC',
    );
    print('Found ${results.length} drawings');
    return results;
  }

  Future<void> deleteDrawingLayers(String bookId, int page) async {
    final db = await database;
    await db.delete(
      'drawing_layers',
      where: 'bookId = ? AND page = ?',
      whereArgs: [bookId, page],
    );
  }

  Future<void> updateDrawingLayer(int id, Map<String, dynamic> layer) async {
    final db = await database;
    await db.update(
      'drawing_layers',
      layer,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Cache operations
  Future<void> updateBookCache(String bookId, String cachedPath) async {
    final db = await database;
    await db.update(
      'books',
      {
        'cachedPath': cachedPath,
        'lastCached': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  Future<Map<String, dynamic>?> getBookCache(String bookId) async {
    final db = await database;
    final results = await db.query(
      'books',
      columns: ['cachedPath', 'lastCached'],
      where: 'id = ?',
      whereArgs: [bookId],
    );
    return results.isNotEmpty ? results.first : null;
  }
}
