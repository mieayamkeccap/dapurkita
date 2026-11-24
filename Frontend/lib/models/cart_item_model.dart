
import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;

  CartItemModel({
    required this.product,
    required this.quantity,
  });

  // Harga satu produk dikali jumlah
  int subtotal() {
    return product.price * quantity;
  }
}
