
import 'order_item_model.dart';

class OrderModel {
  final int id;
  final String orderCode;
  final String orderStatus;
  final String paymentMethod;
  final String paymentStatus;
  final int totalAmount;
  final String createdAt;
  final String recipientName;
  final String customerName;
  final String deliveryMethod;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.orderCode,
    required this.orderStatus,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.totalAmount,
    required this.createdAt,
    required this.recipientName,
    required this.customerName,
    required this.deliveryMethod,
    required this.items,
  });

  // Data pesanan dari server menjadi OrderModel
  // (items hanya ada kalau server mengirimkannya)
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    int total = 0;

    try {
      // Total dari MySQL DECIMAL datang sebagai "29000.00", jadi dibaca
      // sebagai double dulu sebelum dijadikan int. int.parse akan gagal
      // dan total jadi 0 kalau langsung dibaca.
      total = double.parse(json['total_amount'].toString()).toInt();
    } catch (error) {
      total = 0;
    }

    List<OrderItemModel> daftarItem = [];

    if (json['items'] is List) {
      for (var item in json['items']) {
        daftarItem.add(OrderItemModel.fromJson(item));
      }
    }

    return OrderModel(
      id: int.parse(json['id'].toString()),
      orderCode: json['order_code'] == null
          ? ''
          : json['order_code'].toString(),
      orderStatus: json['order_status'] == null
          ? ''
          : json['order_status'].toString(),
      paymentMethod: json['payment_method'] == null
          ? ''
          : json['payment_method'].toString(),
      paymentStatus: json['payment_status'] == null
          ? ''
          : json['payment_status'].toString(),
      totalAmount: total,
      createdAt: json['created_at'] == null
          ? ''
          : json['created_at'].toString(),
      recipientName: json['recipient_name'] == null
          ? ''
          : json['recipient_name'].toString(),
      customerName: json['customer_name'] == null
          ? ''
          : json['customer_name'].toString(),
      deliveryMethod: json['delivery_method'] == null
          ? ''
          : json['delivery_method'].toString(),
      items: daftarItem,
    );
  }
}
