import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dapurkita/models/order_model.dart';
import 'package:dapurkita/screens/customer/pesanan_screen.dart';

OrderModel pesananUji(String status) {
  return OrderModel(
    id: 77,
    orderCode: 'TEST-DITERIMA',
    orderStatus: status,
    paymentMethod: 'transfer',
    paymentStatus: 'paid',
    totalAmount: 29000,
    createdAt: '2026-11-23 10:00:00',
    recipientName: 'Tes',
    customerName: 'Tes',
    deliveryMethod: 'delivery',
    items: const [],
  );
}

void main() {
  test('Customer boleh selesai sejak pesanan dikonfirmasi', () {
    expect(bolehCustomerSelesaikan('confirmed'), true);
    expect(bolehCustomerSelesaikan('preparing'), true);
    expect(bolehCustomerSelesaikan('ready'), true);
    expect(bolehCustomerSelesaikan('on_delivery'), true);
  });

  test('Pesanan yang belum dikonfirmasi atau sudah final tidak bisa', () {
    expect(bolehCustomerSelesaikan('pending'), false);
    expect(bolehCustomerSelesaikan('completed'), false);
    expect(bolehCustomerSelesaikan('cancelled'), false);
    expect(bolehCustomerSelesaikan(''), false);
  });

  test('Label pembayaran transfer dan statusnya', () {
    expect(teksMetodeBayar('transfer'), 'Transfer Bank');
    expect(teksStatusBayar('paid'), 'Lunas');
    expect(teksStatusBayar('pending'), 'Belum lunas');
  });

  testWidgets('Dialog diterima: Batal mengembalikan false', (tester) async {
    bool? hasil;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  hasil = await konfirmasiPesananDiterima(
                    context,
                    pesananUji('confirmed'),
                  );
                },
                child: const Text('Buka'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();

    expect(find.text('Pesanan Sudah Diterima?'), findsOneWidget);
    expect(find.textContaining('TEST-DITERIMA'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(hasil, false);
  });

  testWidgets('Dialog diterima: Ya, Sudah Diterima mengembalikan true', (
    tester,
  ) async {
    bool? hasil;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  hasil = await konfirmasiPesananDiterima(
                    context,
                    pesananUji('on_delivery'),
                  );
                },
                child: const Text('Buka'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ya, Sudah Diterima'));
    await tester.pumpAndSettle();

    expect(hasil, true);
  });
}
