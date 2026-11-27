
class ApiConfig {
  // Alamat backend.
  //
  // Nilai bawaan tetap localhost supaya `flutter run` di komputer sendiri tidak
  // berubah. Saat build untuk deploy, alamat server diberikan lewat:
  //   flutter build web --dart-define=API_BASE_URL=https://nama.onrender.com/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api',
  );

  // Endpoint autentikasi
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String profile = '$baseUrl/auth/profile';

  // Endpoint lainnya
  static const String products = '$baseUrl/products';
  static const String categories = '$baseUrl/categories';
  static const String orders = '$baseUrl/orders';
  static const String payments = '$baseUrl/payments';

  // Alamat dan favorit milik customer (tersimpan di database)
  static const String addresses = '$baseUrl/addresses';
  static const String favorites = '$baseUrl/favorites';
  static const String favoriteIds = '$baseUrl/favorites/ids';

  // Endpoint pesanan milik customer
  static const String myOrders = '$baseUrl/orders/my-orders';

  // Endpoint dashboard admin
  static const String dashboardSummary = '$baseUrl/dashboard/summary';
  static const String dashboardTopProducts = '$baseUrl/dashboard/top-products';
  static const String dashboardDailyOrders = '$baseUrl/dashboard/daily-orders';
  static const String dashboardProductSales =
      '$baseUrl/dashboard/product-sales';
}
