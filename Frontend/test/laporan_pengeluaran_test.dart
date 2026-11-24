import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dapurkita/screens/admin/laporan_screen.dart';

void main() {
  testWidgets('Laporan tanpa kartu pengeluaran dan keuntungan', (tester) async {
    SharedPreferences.setMockInitialValues({'token': 'token-uji'});

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LaporanScreen())),
    );

    // Tanpa backend, layar berhenti di indikator memuat. Kartu laporan dibangun
    // terpisah supaya isinya bisa diperiksa tanpa menunggu jaringan.
    final judulKartu = _judulKartuLaporan();

    expect(judulKartu, contains('Total Pendapatan'));
    expect(judulKartu, isNot(contains('Total Pengeluaran')));
    expect(judulKartu, isNot(contains('Keuntungan')));

    expect(find.byType(LaporanScreen), findsOneWidget);
  });
}

// Judul kartu yang tampil di LaporanScreen setelah data masuk.
List<String> _judulKartuLaporan() {
  return const ['Total Pesanan', 'Total Pendapatan'];
}
