import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/database_helper.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _cartItems = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<CartItem> get cartItems => _cartItems;

  double get totalPrice =>
      _cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));

  CartProvider() {
    _loadCart();
  }

  Future<void> _loadCart() async {
    _cartItems = await _dbHelper.getCartItems();
    notifyListeners();
  }

  // Check if a product is in the cart
  bool isInCart(Product product) {
    return _cartItems.any((item) => item.productId == product.id);
  }

  Future<void> addToCart(Product product) async {
    final existingItemIndex = _cartItems.indexWhere(
      (item) => item.productId == product.id,
    );
    if (existingItemIndex >= 0) {
      _cartItems[existingItemIndex].quantity++;
      await _dbHelper.updateCartItem(_cartItems[existingItemIndex]);
    } else {
      final newItem = CartItem.fromProduct(product);
      _cartItems.add(newItem);
      await _dbHelper.insertCartItem(newItem);
    }
    notifyListeners();
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(productId);
      return;
    }
    final itemIndex = _cartItems.indexWhere(
      (item) => item.productId == productId,
    );
    if (itemIndex >= 0) {
      _cartItems[itemIndex].quantity = quantity;
      await _dbHelper.updateCartItem(_cartItems[itemIndex]);
      notifyListeners();
    }
  }

  Future<void> removeFromCart(String productId) async {
    _cartItems.removeWhere((item) => item.productId == productId);
    await _dbHelper.deleteCartItem(productId);
    notifyListeners();
  }

  Future<void> clearCart() async {
    _cartItems.clear();
    await _dbHelper.clearCart();
    notifyListeners();
  }
}