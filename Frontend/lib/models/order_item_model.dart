
import '../utils/format.dart';

class OrderItemModel {
  final int productId;
  final String productName;
  final int quantity;
  final int price;
  final int subtotal;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: int.parse(json['product_id'].toString()),
      productName: json['product_name'] == null
          ? ''
          : json['product_name'].toString(),
      quantity: int.parse(json['quantity'].toString()),
      price: bacaAngkaDesimal(json['price']),
      subtotal: bacaAngkaDesimal(json['subtotal']),
    );
  }
}
