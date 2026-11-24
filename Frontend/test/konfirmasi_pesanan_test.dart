import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dapurkita/models/order_model.dart';
import 'package:dapurkita/screens/admin/kelola_pesanan_screen.dart';
import 'package:dapurkita/screens/main/main_screen.dart';

OrderModel pesananUji(String status, String metodeAmbil) {
  return OrderModel(
    id: 99,
    orderCode: 'TEST-DIALOG',
    orderStatus: status,
    paymentMethod: 'cash',
    paymentStatus: 'pending',
    totalAmount: 27000,
    createdAt: '2026-11-22 10:00:00',
    recipientName: 'Tes',
    customerName: 'Tes',
    deliveryMethod: metodeAmbil,
    items: const [],
  );
}

void main() {
  testWidgets('Dialog selesai muncul dan Batal mengembalikan false', (
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
                  hasil = await konfirmasiPesananSelesai(
                    context,
                    pesananUji('ready', 'pickup'),
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

    expect(find.text('Pesanan Sudah Selesai?'), findsOneWidget);
    expect(find.textContaining('TEST-DIALOG'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(hasil, false);
  });

  testWidgets('Dialog selesai: Ya, Selesaikan mengembalikan true', (
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
                  hasil = await konfirmasiPesananSelesai(
                    context,
                    pesananUji('ready', 'pickup'),
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

    await tester.tap(find.text('Ya, Selesaikan'));
    await tester.pumpAndSettle();

    expect(hasil, true);
  });

  testWidgets('Profil > Pesanan Saya pindah ke tab Pesanan', (tester) async {
    SharedPreferences.setMockInitialValues({
      'name': 'Customer Uji',
      'email': 'customer.uji@test.local',
    });

    await tester.pumpWidget(const MaterialApp(home: MainScreen()));
    await tester.pumpAndSettle();

    // Buka tab Profil dari bottom navigation
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Pesanan Saya'), findsOneWidget);

    // Tekan menu Pesanan Saya
    await tester.tap(find.text('Pesanan Saya'));
    await tester.pumpAndSettle();

    // Bottom navigation harus pindah ke indeks Pesanan (1)
    final navigasi = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(navigasi.currentIndex, 1);

    // Filter khas layar Pesanan harus tampil
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Diproses'), findsOneWidget);
  });
}
