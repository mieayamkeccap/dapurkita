
class ProductModel {
  final int id;
  final int categoryId;
  final String categoryName;
  final String name;
  final String description;
  final int price;
  final String imageUrl;
  final bool isAvailable;

  ProductModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.isAvailable,
  });

  // Mengubah data dari server (JSON) menjadi ProductModel
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    int harga = 0;

    try {
      // Harga dari MySQL DECIMAL datang sebagai "25000.00", jadi dibaca
      // sebagai double dulu sebelum dijadikan int.
      harga = double.parse(json['price'].toString()).toInt();
    } catch (error) {
      harga = 0;
    }

    int kategori = 0;

    try {
      kategori = int.parse(json['category_id'].toString());
    } catch (error) {
      kategori = 0;
    }

    // is_available dari database MySQL bisa berupa 1 atau 0
    bool tersedia = false;

    if (json['is_available'] == 1 || json['is_available'] == true) {
      tersedia = true;
    }

    return ProductModel(
      id: int.parse(json['id'].toString()),
      categoryId: kategori,
      categoryName: json['category_name'] == null
          ? ''
          : json['category_name'].toString(),
      name: json['name'] == null ? '' : json['name'].toString(),
      description: json['description'] == null
          ? ''
          : json['description'].toString(),
      price: harga,
      imageUrl: json['image_url'] == null ? '' : json['image_url'].toString(),
      isAvailable: tersedia,
    );
  }
}
