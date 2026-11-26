
class ApiConfig {
  // Alamat backend
  static const String baseUrl = 'http://localhost:8000/api';

  // Endpoint autentikasi
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';

  // Endpoint lainnya
  static const String products = '$baseUrl/products';
  static const String categories = '$baseUrl/categories';
  static const String orders = '$baseUrl/orders';
  static const String payments = '$baseUrl/payments';

  // Endpoint pesanan milik customer
  static const String myOrders = '$baseUrl/orders/my-orders';

  // Endpoint dashboard admin
  static const String dashboardSummary = '$baseUrl/dashboard/summary';
  static const String dashboardTopProducts = '$baseUrl/dashboard/top-products';
  static const String dashboardDailyOrders = '$baseUrl/dashboard/daily-orders';
  static const String dashboardProductSales =
      '$baseUrl/dashboard/product-sales';
}
