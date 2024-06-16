class Product {
  final int id;
  final String name;
  final double unitPrice;

  Product({
    required this.id,
    required this.name,
    required this.unitPrice,
  });

  // Factory method to create a Product object from JSON data
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      unitPrice: json['unitPrice'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'unitPrice': unitPrice,
    };
  }
}
