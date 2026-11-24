import 'package:flutter_test/flutter_test.dart';

import 'package:dapurkita/models/order_model.dart';
import 'package:dapurkita/screens/admin/kelola_pesanan_screen.dart';

OrderModel buatPesanan(String status, String metodeAmbil) {
  return OrderModel(
    id: 1,
    orderCode: 'TEST-1',
    orderStatus: status,
    paymentMethod: 'cash',
    paymentStatus: 'pending',
    totalAmount: 10000,
    createdAt: '2026-11-22 10:00:00',
    recipientName: 'Tes',
    customerName: 'Tes',
    deliveryMethod: metodeAmbil,
    items: const [],
  );
}

void main() {
  test('Pickup yang siap langsung boleh Selesai', () {
    expect(statusBerikutnyaPesanan(buatPesanan('ready', 'pickup')), [
      'completed',
    ]);
  });

  test('Delivery yang siap harus lewat Diantar dulu', () {
    expect(statusBerikutnyaPesanan(buatPesanan('ready', 'delivery')), [
      'on_delivery',
    ]);
  });

  test('Diantar boleh Selesai', () {
    expect(statusBerikutnyaPesanan(buatPesanan('on_delivery', 'delivery')), [
      'completed',
    ]);
  });

  test('Status final tidak punya pilihan lagi', () {
    expect(
      statusBerikutnyaPesanan(buatPesanan('completed', 'pickup')),
      isEmpty,
    );
    expect(
      statusBerikutnyaPesanan(buatPesanan('cancelled', 'pickup')),
      isEmpty,
    );
  });

  test('Alur awal tetap sama', () {
    expect(statusBerikutnyaPesanan(buatPesanan('pending', 'pickup')), [
      'confirmed',
      'cancelled',
    ]);
    expect(statusBerikutnyaPesanan(buatPesanan('confirmed', 'delivery')), [
      'preparing',
      'cancelled',
    ]);
    expect(statusBerikutnyaPesanan(buatPesanan('preparing', 'delivery')), [
      'ready',
    ]);
  });
}
