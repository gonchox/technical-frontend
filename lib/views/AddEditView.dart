import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_testt/models/Order.dart';
import 'package:flutter_testt/models/Product.dart';
import 'package:flutter_testt/models/OrderProduct.dart';
import '../endpoints/serviceApi.dart';

class AddEditView extends StatefulWidget {
  final int? orderId;

  AddEditView({Key? key, this.orderId}) : super(key: key);

  @override
  _AddEditViewState createState() => _AddEditViewState();
}

class _AddEditViewState extends State<AddEditView> {
  late TextEditingController orderNumberController;
  List<OrderProduct> orderProducts = [];
  double finalPrice = 0.0;
  int numProducts = 0; // Added numProducts
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  Product? selectedProduct;
  int productQuantity = 1;
  List<Product> availableProducts = [];

  @override
  void initState() {
    super.initState();
    orderNumberController = TextEditingController();

    if (widget.orderId != null) {
      fetchOrderDetails(widget.orderId!);
    }
    fetchAvailableProducts();
  }

  @override
  void dispose() {
    orderNumberController.dispose();
    super.dispose();
  }

  Future<void> fetchOrderDetails(int orderId) async {
    try {
      final response = await http.get(Uri.parse('${url()}orders/$orderId'), headers: headers());

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonData = jsonDecode(response.body);
        Order order = Order.fromJson(jsonData);

        setState(() {
          orderNumberController.text = order.orderNumber;
          orderProducts = order.products
              .map((product) => OrderProduct(orderId: order.id, product: product, quantity: 1))
              .toList();
          finalPrice = order.finalPrice;
          numProducts = order.numProducts; // Update numProducts
        });
      } else {
        print('Failed to load order details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching order details: $e');
    }
  }

  Future<void> fetchAvailableProducts() async {
    try {
      final response = await http.get(Uri.parse('${url()}products'), headers: headers());

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          availableProducts = data.map((json) => Product.fromJson(json)).toList();
        });
      } else {
        print('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  Future<void> saveOrder() async {
    try {
      if (!formKey.currentState!.validate()) {
        return;
      }

      Order order = Order(
        id: widget.orderId ?? 0,
        orderNumber: orderNumberController.text,
        date: DateTime.now(),
        products: orderProducts.map((op) => op.product).toList(),
        finalPrice: finalPrice,
        numProducts: numProducts, // Include numProducts
      );

      final Map<String, dynamic> postData = {
        'orderNumber': order.orderNumber,
        'date': order.date.toIso8601String(),
        'products': order.products.map((product) => product.toJson()).toList(),
        'finalPrice': order.finalPrice,
        'numProducts': order.numProducts, // Pass numProducts in JSON
      };

      http.Response response;
      if (widget.orderId == null) {
        response = await http.post(Uri.parse('${url()}orders'),
            headers: headers(), body: jsonEncode(postData));

        if (response.statusCode == 201 || response.statusCode == 200) {
          Map<String, dynamic> jsonResponse = jsonDecode(response.body);
          int newOrderId = jsonResponse['id'];
          await addProductsToOrder(newOrderId);
          Navigator.of(context).pop();
        } else {
          print('Failed to save order: ${response.statusCode}');
        }
      } else {
        response = await http.put(Uri.parse('${url()}orders/${order.id}'),
            headers: headers(), body: jsonEncode(postData));

        if (response.statusCode == 200) {
          await addProductsToOrder(order.id);
          Navigator.of(context).pop();
        } else {
          print('Failed to save order: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error saving order: $e');
    }
  }

  Future<void> addProductsToOrder(int orderId) async {
    for (var orderProduct in orderProducts) {
      final response = await http.post(
        Uri.parse('${url()}orders/$orderId/products/${orderProduct.product.id}/${orderProduct.quantity}'),
        headers: headers(),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print(
            'Failed to add product ${orderProduct.product.id} to order: ${response.statusCode}');
      }
    }
  }

  void addProduct() {
    if (selectedProduct != null && productQuantity > 0) {
      setState(() {
        orderProducts.add(OrderProduct(orderId: widget.orderId ?? 0, product: selectedProduct!, quantity: productQuantity));
        finalPrice += selectedProduct!.unitPrice * productQuantity;
        numProducts++; // Increment numProducts
        selectedProduct = null;
        productQuantity = 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product successfully added!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.orderId == null ? 'Add Order' : 'Edit Order'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: orderNumberController,
                decoration: InputDecoration(labelText: 'Order Number'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Order number is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              Text('Add Product:'),
              DropdownButton<Product>(
                hint: Text('Select Product'),
                value: selectedProduct,
                onChanged: (Product? newValue) {
                  setState(() {
                    selectedProduct = newValue;
                  });
                },
                items: availableProducts.map((Product product) {
                  return DropdownMenuItem<Product>(
                    value: product,
                    child: Text(product.name),
                  );
                }).toList(),
              ),
              TextFormField(
                initialValue: productQuantity.toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Quantity'),
                onChanged: (value) {
                  setState(() {
                    productQuantity = int.tryParse(value) ?? 1;
                  });
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: addProduct,
                child: Text('Add Product'),
              ),
              SizedBox(height: 16.0),
              Text('Selected Products:'),
              ListView.builder(
                shrinkWrap: true,
                itemCount: orderProducts.length,
                itemBuilder: (context, index) {
                  OrderProduct orderProduct = orderProducts[index];
                  return ListTile(
                    title: Text(orderProduct.product.name),
                    subtitle: Text('\$${orderProduct.product.unitPrice.toStringAsFixed(2)} x ${orderProduct.quantity}'),
                  );
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: saveOrder,
                child: Text(widget.orderId == null ? 'Create Order' : 'Update Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
