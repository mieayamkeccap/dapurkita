import 'package:flutter_test/flutter_test.dart';

import 'package:dapurkita/services/auth_service.dart';

void main() {
  group('pesanEmailTidakValid', () {
    test('email kosong ditolak', () {
      expect(AuthService.pesanEmailTidakValid(''), 'Email wajib diisi');
      expect(AuthService.pesanEmailTidakValid('   '), 'Email wajib diisi');
    });

    test('format email salah ditolak', () {
      expect(AuthService.pesanEmailTidakValid('abc'), isNotNull);
      expect(AuthService.pesanEmailTidakValid('abc@'), isNotNull);
      expect(AuthService.pesanEmailTidakValid('abc@gmail'), isNotNull);
      expect(AuthService.pesanEmailTidakValid('@gmail.com'), isNotNull);
      expect(AuthService.pesanEmailTidakValid('a b@gmail.com'), isNotNull);
    });

    test('email dengan format benar diterima', () {
      expect(AuthService.pesanEmailTidakValid('admin@gmail.com'), isNull);
      expect(AuthService.pesanEmailTidakValid('eros@gmail.com'), isNull);
      expect(AuthService.pesanEmailTidakValid('nama.lengkap@yahoo.co.id'), isNull);
      expect(AuthService.pesanEmailTidakValid('  admin@gmail.com  '), isNull);
    });
  });
}
