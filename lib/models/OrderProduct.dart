import 'package:flutter_testt/models/Product.dart';

class OrderProduct {
  final int orderId;
  final Product product;
  int quantity;

  OrderProduct({
    required this.orderId,
    required this.product,
    required this.quantity,
  });

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    return OrderProduct(
      orderId: json['order_id'],
      product: Product.fromJson(json['product']),
      quantity: json['quantity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'product_id': product.id,
      'quantity': quantity,
    };
  }

  void setQuantity(int newQuantity) {
    quantity = newQuantity;
  }
}
