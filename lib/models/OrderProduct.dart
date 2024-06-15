import 'package:flutter_testt/models/Product.dart'; // Import your Product model

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
      product: Product.fromJson(json['product']), // Assuming product JSON structure matches Product model
      quantity: json['quantity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'product_id': product.id, // Assuming Product model has an 'id' field
      'quantity': quantity,
    };
  }

  void setQuantity(int newQuantity) {
    quantity = newQuantity;
  }
}
