import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/cart_item.dart';

class DatabaseHelper {
  static const _databaseName = 'cart.db';
  static const _databaseVersion = 1;
  static const table = 'cart_items';

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        productId TEXT PRIMARY KEY,
        name TEXT,
        price REAL,
        image TEXT,
        quantity INTEGER
      )
    ''');
  }

  Future<void> insertCartItem(CartItem item) async {
    final db = await database;
    await db.insert(
      table,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CartItem>> getCartItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(table);
    return List.generate(maps.length, (i) => CartItem.fromMap(maps[i]));
  }

  Future<void> updateCartItem(CartItem item) async {
    final db = await database;
    await db.update(
      table,
      item.toMap(),
      where: 'productId = ?',
      whereArgs: [item.productId],
    );
  }

  Future<void> deleteCartItem(String productId) async {
    final db = await database;
    await db.delete(table, where: 'productId = ?', whereArgs: [productId]);
  }

  Future<void> clearCart() async {
    final db = await database;
    await db.delete(table);
  }
}
