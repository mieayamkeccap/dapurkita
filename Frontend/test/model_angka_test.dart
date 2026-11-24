import 'package:dapurkita/models/order_item_model.dart';
import 'package:dapurkita/models/order_model.dart';
import 'package:flutter_test/flutter_test.dart';

// MySQL DECIMAL dikirim ke Flutter sebagai teks desimal ("29000.00").
// Test ini memastikan angka uang terbaca benar, bukan jatuh ke 0.
void main() {
  test('total pesanan desimal dibaca sebagai rupiah penuh', () {
    final pesanan = OrderModel.fromJson({
      'id': 1,
      'order_code': 'DK-1',
      'total_amount': '29000.00',
    });

    expect(pesanan.totalAmount, 29000);
  });

  test('total pesanan angka biasa tetap terbaca', () {
    final pesanan = OrderModel.fromJson({
      'id': 2,
      'order_code': 'DK-2',
      'total_amount': 24000,
    });

    expect(pesanan.totalAmount, 24000);
  });

  test('total pesanan kosong atau rusak menjadi 0', () {
    final kosong = OrderModel.fromJson({'id': 3, 'order_code': 'DK-3'});
    final rusak = OrderModel.fromJson({
      'id': 4,
      'order_code': 'DK-4',
      'total_amount': 'abc',
    });

    expect(kosong.totalAmount, 0);
    expect(rusak.totalAmount, 0);
  });

  test('harga dan subtotal item desimal terbaca', () {
    final item = OrderItemModel.fromJson({
      'product_id': 13,
      'product_name': 'ayam balado',
      'quantity': 2,
      'price': '24000.00',
      'subtotal': '48000.00',
    });

    expect(item.price, 24000);
    expect(item.subtotal, 48000);
    expect(item.quantity, 2);
  });
}
