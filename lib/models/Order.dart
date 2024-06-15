import 'package:flutter_testt/models/Product.dart';

class Order {
  final int id;
  final String orderNumber;
  final DateTime date;
  final double finalPrice;
  final int numProducts; // Add this field
  List<Product> products;

  Order({
    required this.id,
    required this.orderNumber,
    required this.date,
    required this.finalPrice,
    required this.numProducts,
    required this.products,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<dynamic> productsList = json['products'] ?? [];
    List<Product> parsedProducts = productsList.map((productJson) => Product.fromJson(productJson)).toList();

    DateTime dateTime = DateTime.parse(json['date']);

    return Order(
      id: json['id'],
      orderNumber: json['orderNumber'],
      date: dateTime,
      products: parsedProducts,
      finalPrice: json['finalPrice'].toDouble(),
      numProducts: json['numProducts'],
    );
  }
}
