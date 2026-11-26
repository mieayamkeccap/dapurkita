
// Satu alamat pengiriman milik customer, dibaca dari tabel `addresses`.
class AlamatModel {
  final int id;
  final String label;
  final String alamat;
  final bool utama;

  AlamatModel({
    required this.id,
    required this.label,
    required this.alamat,
    required this.utama,
  });

  factory AlamatModel.fromJson(Map<String, dynamic> json) {
    // is_primary dari MySQL bisa berupa 1 atau 0
    bool utama = false;

    if (json['is_primary'] == 1 || json['is_primary'] == true) {
      utama = true;
    }

    return AlamatModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      label: json['label'] == null ? '' : json['label'].toString(),
      alamat: json['address'] == null ? '' : json['address'].toString(),
      utama: utama,
    );
  }
}
