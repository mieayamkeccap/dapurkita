
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../main.dart';
import '../screens/auth/login_screen.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/order_model.dart';
import '../models/alamat_model.dart';

class ApiService {
  // ---------------------------------------------------------
  // FUNGSI BANTU KECIL
  // ---------------------------------------------------------

  // Mengambil token yang disimpan saat login
  static Future<String> ambilToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString('token') ?? '';
  }

  // Header biasa untuk permintaan yang tidak perlu login
  static Map<String, String> headerBiasa() {
    return {
      'Content-Type': 'application/json',
    };
  }

  // Header untuk permintaan yang harus login (admin / customer)
  static Future<Map<String, String>> headerLogin() async {
    String token = await ambilToken();

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Mengubah teks jawaban server menjadi Map
  static Map<String, dynamic> bacaJson(http.Response response) {
    Map<String, dynamic> body = {};

    try {
      body = jsonDecode(response.body);
    } catch (error) {
      throw Exception('Jawaban server tidak bisa dibaca');
    }

    return body;
  }

  // Dipakai supaya sesi berakhir hanya diproses sekali walau beberapa
  // permintaan 401 datang bersamaan.
  static bool _sedangKeluar = false;

  // Token ditolak server: hapus data login, kembali ke halaman login,
  // lalu beri tahu pengguna.
  static Future<void> tanganiSesiBerakhir() async {
    if (_sedangKeluar) return;

    _sedangKeluar = true;

    final preferences = await SharedPreferences.getInstance();

    await preferences.remove('token');
    await preferences.remove('role');
    await preferences.remove('name');
    await preferences.remove('email');
    await preferences.remove('phone');

    const pesan = 'Sesi login sudah berakhir. Silakan masuk lagi.';

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) {
          return const LoginScreen();
        },
      ),
      (route) => false,
    );

    // SnackBar dipasang setelah layar login tampil, kalau tidak
    // ScaffoldMessenger-nya ikut terbuang bersama halaman lama.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(pesan)),
        );
      }

      _sedangKeluar = false;
    });
  }

  // Cek apakah permintaan berhasil. Kalau gagal, lempar pesan dari server.
  static void cekBerhasil(
    http.Response response,
    Map<String, dynamic> body,
    String pesanCadangan,
  ) {
    // 401 dari endpoint privat = token hilang/kedaluwarsa, bukan sekadar
    // data salah. Langsung akhiri sesi supaya pengguna tidak tertahan
    // di layar dengan data kosong.
    if (response.statusCode == 401) {
      tanganiSesiBerakhir();

      throw SesiBerakhirException(
        'Sesi login sudah berakhir. Silakan masuk lagi.',
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (body['success'] != true) {
        String pesan = pesanCadangan;

        if (body['message'] != null) {
          pesan = body['message'].toString();
        }

        throw Exception(pesan);
      }

      return;
    }

    String pesan = pesanCadangan;

    if (body['message'] != null) {
      pesan = body['message'].toString();
    }

    throw Exception(pesan);
  }

  // ---------------------------------------------------------
  // LOGIN DAN DAFTAR
  // ---------------------------------------------------------

  static Future<Map<String, dynamic>> loginUser(
    String email,
    String password,
  ) async {
    http.Response response;

    try {
      response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: headerBiasa(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    // Kalau login gagal, jangan lempar error.
    // Biarkan layar login yang menampilkan pesannya.
    if (response.statusCode != 200) {
      body['success'] = false;

      if (body['message'] == null) {
        body['message'] = 'Login gagal';
      }
    }

    return body;
  }

  static Future<Map<String, dynamic>> registerUser(
    String name,
    String email,
    String password,
    String phone,
  ) async {
    http.Response response;

    try {
      response = await http.post(
        Uri.parse(ApiConfig.register),
        headers: headerBiasa(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        }),
      );
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    if (response.statusCode != 201) {
      body['success'] = false;

      if (body['message'] == null) {
        body['message'] = 'Pendaftaran gagal';
      }
    }

    return body;
  }

  // ---------------------------------------------------------
  // PRODUK DAN KATEGORI (boleh dilihat tanpa login)
  // ---------------------------------------------------------

  static Future<List<ProductModel>> getProducts() async {
    http.Response response;

    try {
      response = await http.get(Uri.parse(ApiConfig.products));
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal mengambil data produk');

    if (body['data'] is! List) {
      throw Exception('Data produk tidak valid');
    }

    List<ProductModel> daftarProduk = [];

    for (var item in body['data']) {
      daftarProduk.add(ProductModel.fromJson(item));
    }

    return daftarProduk;
  }

  static Future<List<CategoryModel>> getCategories() async {
    http.Response response;

    try {
      response = await http.get(Uri.parse(ApiConfig.categories));
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal mengambil data kategori');

    if (body['data'] is! List) {
      throw Exception('Data kategori tidak valid');
    }

    List<CategoryModel> daftarKategori = [];

    for (var item in body['data']) {
      daftarKategori.add(CategoryModel.fromJson(item));
    }

    return daftarKategori;
  }

  // ---------------------------------------------------------
  // PESANAN CUSTOMER
  // ---------------------------------------------------------

  // Menyimpan pesanan baru. items berisi daftar item keranjang.
  // Pembayaran selalu transfer dan backend langsung mencatatnya lunas.
  static Future<Map<String, dynamic>> saveOrder(
    List<dynamic> items,
    String deliveryMethod,
    String recipientName,
    String recipientPhone,
    String deliveryAddress,
    String notes,
  ) async {
    http.Response response;

    try {
      response = await http.post(
        Uri.parse(ApiConfig.orders),
        headers: await headerLogin(),
        body: jsonEncode({
          'items': items,
          'delivery_method': deliveryMethod,
          'order_type': 'asap',
          'recipient_name': recipientName,
          'recipient_phone': recipientPhone,
          'delivery_address': deliveryAddress,
          'notes': notes,
          'payment_method': 'transfer',
        }),
      );
    } catch (error) {
      // Kalau errornya berasal dari cekBerhasil, teruskan pesannya
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal membuat pesanan');

    return body;
  }

  // Pesanan milik customer yang sedang login
  static Future<List<OrderModel>> getMyOrders() async {
    http.Response response;

    try {
      response = await http.get(
        Uri.parse(ApiConfig.myOrders),
        headers: await headerLogin(),
      );
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal mengambil riwayat pesanan');

    if (body['data'] is! List) {
      throw Exception('Data pesanan tidak valid');
    }

    List<OrderModel> daftarPesanan = [];

    for (var item in body['data']) {
      daftarPesanan.add(OrderModel.fromJson(item));
    }

    return daftarPesanan;
  }

  // Detail satu pesanan (berisi daftar item)
  static Future<OrderModel> getOrderDetail(int orderId) async {
    http.Response response;

    try {
      response = await http.get(
        Uri.parse('${ApiConfig.orders}/$orderId'),
        headers: await headerLogin(),
      );
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal mengambil detail pesanan');

    if (body['data'] == null) {
      throw Exception('Data pesanan tidak valid');
    }

    return OrderModel.fromJson(body['data']);
  }

  // ---------------------------------------------------------
  // ADMIN: DASHBOARD DAN LAPORAN
  // ---------------------------------------------------------

  static Future<Map<String, dynamic>> getDashboardSummary() async {
    http.Response response;

    try {
      response = await http.get(
        Uri.parse(ApiConfig.dashboardSummary),
        headers: await headerLogin(),
      );
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal mengambil ringkasan dashboard');

    if (body['data'] == null) {
      return {};
    }

    return body['data'];
  }

  static Future<List<Map<String, dynamic>>> getTopProducts() async {
    http.Response response;

    try {
      response = await http.get(
        Uri.parse(ApiConfig.dashboardTopProducts),
        headers: await headerLogin(),
      );
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal mengambil produk terlaris');

    List<Map<String, dynamic>> hasil = [];

    if (body['data'] is List) {
      for (var item in body['data']) {
        hasil.add(item);
      }
    }

    return hasil;
  }

  // Jumlah pesanan per hari untuk 7 hari terakhir (grafik dashboard)
  static Future<List<Map<String, dynamic>>> getDailyOrders() async {
    http.Response response;

    try {
      response = await http.get(
        Uri.parse(ApiConfig.dashboardDailyOrders),
        headers: await headerLogin(),
      );
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal mengambil data grafik penjualan');

    List<Map<String, dynamic>> hasil = [];

    if (body['data'] is List) {
      for (var item in body['data']) {
        hasil.add(item);
      }
    }

    return hasil;
  }

  // Penjualan per produk per hari untuk 7 hari terakhir, dikelompokkan
  // per kategori. Produk yang belum pernah terjual tetap ikut dengan
  // angka nol, supaya menu baru langsung punya grafik sendiri.
  static Future<List<Map<String, dynamic>>> getProductSales() async {
    http.Response response;

    try {
      response = await http.get(
        Uri.parse(ApiConfig.dashboardProductSales),
        headers: await headerLogin(),
      );
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal mengambil penjualan per produk');

    List<Map<String, dynamic>> hasil = [];

    if (body['data'] is List) {
      for (var item in body['data']) {
        hasil.add(item);
      }
    }

    return hasil;
  }

  // Menentukan Content-Type gambar dari ekstensi nama file.
  // Dipakai karena MultipartFile.fromBytes tidak menebak dari nama file.
  static MediaType tipeGambar(String? nama) {
    final namaKecil = (nama ?? '').toLowerCase();

    if (namaKecil.endsWith('.png')) return MediaType('image', 'png');
    if (namaKecil.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
  }

  // ---------------------------------------------------------
  // ADMIN: PRODUK
  // ---------------------------------------------------------

  // Simpan produk baru (dengan gambar). Kalau productId 0 = tambah, selain itu = edit.
  static Future<Map<String, dynamic>> simpanProduk({
    required int productId,
    required int categoryId,
    required String name,
    required String description,
    required String price,
    required bool isAvailable,
    Uint8List? gambarBytes,
    String? gambarNama,
  }) async {
    http.Response response;

    try {
      String alamat = ApiConfig.products;

      if (productId != 0) {
        alamat = '${ApiConfig.products}/$productId';
      }

      String token = await ambilToken();

      var permintaan = http.MultipartRequest(
        productId == 0 ? 'POST' : 'PUT',
        Uri.parse(alamat),
      );

      permintaan.headers['Authorization'] = 'Bearer $token';
      permintaan.fields['category_id'] = categoryId.toString();
      permintaan.fields['name'] = name;
      permintaan.fields['description'] = description;
      permintaan.fields['price'] = price;
      permintaan.fields['is_available'] = isAvailable ? '1' : '0';

      if (gambarBytes != null && gambarBytes.isNotEmpty) {
        // fromBytes, bukan fromPath: di Flutter Web tidak ada file di disk.
        // Content-Type wajib diisi sesuai jenis gambar, karena default
        // fromBytes adalah application/octet-stream dan backend menolaknya.
        permintaan.files.add(
          http.MultipartFile.fromBytes(
            'image',
            gambarBytes,
            filename: gambarNama ?? 'produk.jpg',
            contentType: tipeGambar(gambarNama),
          ),
        );
      }

      // Timeout supaya upload yang menggantung tidak diam tanpa pesan.
      var hasilKirim = await permintaan.send().timeout(
        const Duration(seconds: 30),
      );
      response = await http.Response.fromStream(hasilKirim);
    } on TimeoutException {
      throw Exception('Server terlalu lama merespons. Coba lagi.');
    } catch (error) {
      // ClientException = gagal menghubungi server. Error lain diteruskan
      // apa adanya supaya tidak tertutup pesan "tidak terhubung".
      if (error is http.ClientException) {
        throw Exception('Tidak bisa terhubung ke server');
      }

      rethrow;
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal menyimpan produk');

    return body;
  }

  static Future<void> deleteProduct(int productId) async {
    http.Response response;

    try {
      response = await http.delete(
        Uri.parse('${ApiConfig.products}/$productId'),
        headers: await headerLogin(),
      );
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal menghapus produk');
  }

  // ---------------------------------------------------------
  // ADMIN: KATEGORI
  // ---------------------------------------------------------

  static Future<void> simpanKategori({
    required int categoryId,
    required String name,
    required String description,
  }) async {
    http.Response response;

    try {
      if (categoryId == 0) {
        response = await http.post(
          Uri.parse(ApiConfig.categories),
          headers: await headerLogin(),
          body: jsonEncode({
            'name': name,
            'description': description,
          }),
        );
      } else {
        response = await http.put(
          Uri.parse('${ApiConfig.categories}/$categoryId'),
          headers: await headerLogin(),
          body: jsonEncode({
            'name': name,
            'description': description,
          }),
        );
      }
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal menyimpan kategori');
  }

  static Future<void> deleteCategory(int categoryId) async {
    http.Response response;

    try {
      response = await http.delete(
        Uri.parse('${ApiConfig.categories}/$categoryId'),
        headers: await headerLogin(),
      );
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal menghapus kategori');
  }

  // ---------------------------------------------------------
  // ADMIN: PESANAN
  // ---------------------------------------------------------

  static Future<List<OrderModel>> getAllOrders() async {
    http.Response response;

    try {
      response = await http.get(
        Uri.parse(ApiConfig.orders),
        headers: await headerLogin(),
      );
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal mengambil semua pesanan');

    if (body['data'] is! List) {
      throw Exception('Data pesanan tidak valid');
    }

    List<OrderModel> daftarPesanan = [];

    for (var item in body['data']) {
      daftarPesanan.add(OrderModel.fromJson(item));
    }

    return daftarPesanan;
  }

  static Future<void> updateOrderStatus(int orderId, String orderStatus) async {
    http.Response response;

    try {
      response = await http.put(
        Uri.parse('${ApiConfig.orders}/$orderId/status'),
        headers: await headerLogin(),
        body: jsonEncode({
          'order_status': orderStatus,
        }),
      );
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal mengubah status pesanan');
  }

  // Customer menandai pesanannya sudah diterima / selesai.
  // Backend hanya mengizinkan untuk pesanan miliknya sendiri yang sudah
  // dikonfirmasi admin.
  static Future<void> selesaikanPesanan(int orderId) async {
    http.Response response;

    try {
      response = await http.put(
        Uri.parse('${ApiConfig.orders}/$orderId/selesai'),
        headers: await headerLogin(),
      );
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal menandai pesanan selesai');
  }

  static Future<void> verifyPayment(int orderId, String paymentStatus) async {
    http.Response response;

    try {
      response = await http.put(
        Uri.parse('${ApiConfig.payments}/$orderId/verify'),
        headers: await headerLogin(),
        body: jsonEncode({
          'payment_status': paymentStatus,
        }),
      );
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal memproses pembayaran');
  }

  // ---------------------------------------------------------
  // CUSTOMER: PROFIL, ALAMAT, DAN FAVORIT
  // Ketiganya tersimpan di database, bukan di perangkat, supaya
  // datanya tetap ada walaupun pengguna berganti browser.
  // ---------------------------------------------------------

  // Profil milik user yang sedang login
  static Future<Map<String, dynamic>> getProfil() async {
    http.Response response;

    try {
      response = await http.get(
        Uri.parse(ApiConfig.profile),
        headers: await headerLogin(),
      );
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal mengambil data profil');

    if (body['data'] == null) {
      throw Exception('Data profil tidak valid');
    }

    return body['data'];
  }

  // Mengubah nama dan telepon. Email tidak diubah karena dipakai untuk login.
  static Future<Map<String, dynamic>> updateProfil(
    String name,
    String phone,
  ) async {
    http.Response response;

    try {
      response = await http.put(
        Uri.parse(ApiConfig.profile),
        headers: await headerLogin(),
        body: jsonEncode({
          'name': name,
          'phone': phone,
        }),
      );
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal menyimpan profil');

    if (body['data'] == null) {
      return {};
    }

    return body['data'];
  }

  // Alamat milik customer, alamat utama selalu di urutan pertama
  static Future<List<AlamatModel>> getAddresses() async {
    http.Response response;

    try {
      response = await http.get(
        Uri.parse(ApiConfig.addresses),
        headers: await headerLogin(),
      );
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal mengambil data alamat');

    if (body['data'] is! List) {
      throw Exception('Data alamat tidak valid');
    }

    List<AlamatModel> daftar = [];

    for (var item in body['data']) {
      daftar.add(AlamatModel.fromJson(item));
    }

    return daftar;
  }

  // addressId 0 = tambah alamat baru, selain itu = ubah alamat lama
  static Future<void> simpanAlamat({
    required int addressId,
    required String label,
    required String address,
  }) async {
    http.Response response;

    try {
      if (addressId == 0) {
        response = await http.post(
          Uri.parse(ApiConfig.addresses),
          headers: await headerLogin(),
          body: jsonEncode({
            'label': label,
            'address': address,
          }),
        );
      } else {
        response = await http.put(
          Uri.parse('${ApiConfig.addresses}/$addressId'),
          headers: await headerLogin(),
          body: jsonEncode({
            'label': label,
            'address': address,
          }),
        );
      }
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal menyimpan alamat');
  }

  static Future<void> hapusAlamat(int addressId) async {
    http.Response response;

    try {
      response = await http.delete(
        Uri.parse('${ApiConfig.addresses}/$addressId'),
        headers: await headerLogin(),
      );
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal menghapus alamat');
  }

  static Future<void> setAlamatUtama(int addressId) async {
    http.Response response;

    try {
      response = await http.put(
        Uri.parse('${ApiConfig.addresses}/$addressId/utama'),
        headers: await headerLogin(),
      );
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal mengatur alamat utama');
  }

  // Produk favorit lengkap dengan nama kategorinya
  static Future<List<ProductModel>> getFavorites() async {
    http.Response response;

    try {
      response = await http.get(
        Uri.parse(ApiConfig.favorites),
        headers: await headerLogin(),
      );
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal mengambil data favorit');

    if (body['data'] is! List) {
      throw Exception('Data favorit tidak valid');
    }

    List<ProductModel> daftar = [];

    for (var item in body['data']) {
      daftar.add(ProductModel.fromJson(item));
    }

    return daftar;
  }

  // Hanya id produk favorit, dipakai ikon hati di detail produk
  static Future<List<int>> getFavoriteIds() async {
    http.Response response;

    try {
      response = await http.get(
        Uri.parse(ApiConfig.favoriteIds),
        headers: await headerLogin(),
      );
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal mengambil id favorit');

    List<int> hasil = [];

    if (body['data'] is List) {
      for (var item in body['data']) {
        int id = int.tryParse(item.toString()) ?? 0;

        if (id != 0) hasil.add(id);
      }
    }

    return hasil;
  }

  static Future<void> tambahFavorit(int productId) async {
    http.Response response;

    try {
      response = await http.post(
        Uri.parse('${ApiConfig.favorites}/$productId'),
        headers: await headerLogin(),
      );
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal menambahkan favorit');
  }

  static Future<void> hapusFavorit(int productId) async {
    http.Response response;

    try {
      response = await http.delete(
        Uri.parse('${ApiConfig.favorites}/$productId'),
        headers: await headerLogin(),
      );
    } catch (error) {
      throw Exception('Tidak bisa terhubung ke server');
    }

    Map<String, dynamic> body = bacaJson(response);

    cekBerhasil(response, body, 'Gagal menghapus favorit');
  }
}

// Dilempar saat server menolak token (401). Navigasi ke halaman login
// sudah dilakukan ApiService.tanganiSesiBerakhir(); layar cukup
// menampilkan pesannya seperti error biasa.
class SesiBerakhirException implements Exception {
  final String pesan;

  const SesiBerakhirException(this.pesan);

  @override
  String toString() => pesan;
}
