
class CategoryModel {
  final int id;
  final String name;
  final String description;

  CategoryModel({
    required this.id,
    required this.name,
    required this.description,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: int.parse(json['id'].toString()),
      name: json['name'] == null ? '' : json['name'].toString(),
      description: json['description'] == null
          ? ''
          : json['description'].toString(),
    );
  }
}
