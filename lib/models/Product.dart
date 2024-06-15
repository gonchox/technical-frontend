class Product {
  final int id;
  final String name;
  final double unitPrice;
 
  
  Product({required this.id, required this.name, required this.unitPrice});
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      unitPrice: json['unitPrice'].toDouble(),
    );
  }
}
