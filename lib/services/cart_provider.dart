import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abayka/product.dart';

class CartItem {
  final Product product;
  final String? color;
  final String? size;
  final int quantity;

  CartItem({
    required this.product,
    this.color,
    this.size,
    required this.quantity,
  });

  double get totalPrice => product.price * (1 - product.discount / 100) * quantity;
}

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    return [];
  }

  void addToCart(Product product, {String? color, String? size, int quantity = 1}) {
    // Check if item already exists
    final existingIndex = state.indexWhere((item) =>
        item.product.id == product.id &&
        item.color == color &&
        item.size == size);

    if (existingIndex >= 0) {
      final existingItem = state[existingIndex];
      final updatedItem = CartItem(
        product: existingItem.product,
        color: existingItem.color,
        size: existingItem.size,
        quantity: existingItem.quantity + quantity,
      );
      state = [
        ...state.sublist(0, existingIndex),
        updatedItem,
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      state = [
        ...state,
        CartItem(product: product, color: color, size: size, quantity: quantity),
      ];
    }
  }

  void removeFromCart(CartItem item) {
    state = state.where((i) => i != item).toList();
  }

  void clearCart() {
    state = [];
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);
