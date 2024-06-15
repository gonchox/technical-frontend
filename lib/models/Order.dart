import 'package:technical_flutter/models/Product.dart';

class Order {
  final int id;
  final String orderNumber;
  final DateTime? date;
  final double totalPrice;
  final List<Product> products;

  Order({
    required this.id,
    required this.orderNumber,
    required this.date,
    required this.totalPrice,
    required this.products,
  });

}
