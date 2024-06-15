import 'package:flutter_testt/models/Product.dart';

class Order {
  final int id;
  final String orderNumber;
  final double finalPrice;
  final List<Product> products;
  
  Order({required this.id, required this.orderNumber, required this.finalPrice, required this.products});

  factory Order.fromJson(Map<String, dynamic> json) {
    List<dynamic> productsList = json['products'] ?? [];
    List<Product> parsedProducts = productsList.map((productJson) => Product.fromJson(productJson)).toList();

    return Order(
      id: json['id'],
      orderNumber: json['orderNumber'],
      finalPrice: json['finalPrice'].toDouble(),
      products: parsedProducts,
    );
  }
}