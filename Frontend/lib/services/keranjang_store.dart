
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

// Penyimpan keranjang sederhana.
// Cukup satu variabel global, bukan state management.
// Setiap layar memanggil setState setelah memakai fungsi di sini.
class KeranjangStore {
  static List<CartItemModel> items = [];

  // Menambah produk. Kalau sudah ada, jumlahnya ditambah.
  static void tambahItem(ProductModel product, int jumlah) {
    for (var item in items) {
      if (item.product.id == product.id) {
        item.quantity = item.quantity + jumlah;
        return;
      }
    }

    items.add(CartItemModel(product: product, quantity: jumlah));
  }

  static void kurangiItem(int productId) {
    for (var i = 0; i < items.length; i++) {
      if (items[i].product.id == productId) {
        items[i].quantity = items[i].quantity - 1;

        if (items[i].quantity <= 0) {
          items.removeAt(i);
        }

        return;
      }
    }
  }

  static void hapusItem(int productId) {
    for (var i = 0; i < items.length; i++) {
      if (items[i].product.id == productId) {
        items.removeAt(i);
        return;
      }
    }
  }

  static void kosongkan() {
    items = [];
  }

  static int totalBelanja() {
    int total = 0;

    for (var item in items) {
      total = total + item.subtotal();
    }

    return total;
  }

  static int jumlahBarang() {
    int jumlah = 0;

    for (var item in items) {
      jumlah = jumlah + item.quantity;
    }

    return jumlah;
  }

  // Data keranjang untuk dikirim ke backend
  static List<Map<String, dynamic>> dataUntukPesanan() {
    List<Map<String, dynamic>> hasil = [];

    for (var item in items) {
      hasil.add({
        'product_id': item.product.id,
        'quantity': item.quantity,
      });
    }

    return hasil;
  }
}
