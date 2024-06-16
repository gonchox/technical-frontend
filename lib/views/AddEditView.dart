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
  late TextEditingController dateController;
  late TextEditingController numProductsController;
  late TextEditingController finalPriceController;

  List<OrderProduct> orderProducts = [];
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  Product? selectedProduct;
  int productQuantity = 1;
  List<Product> availableProducts = [];

  @override
  void initState() {
    super.initState();
    orderNumberController = TextEditingController();
    dateController = TextEditingController(text: DateTime.now().toIso8601String());
    numProductsController = TextEditingController(text: '0');
    finalPriceController = TextEditingController(text: '0.0');

    if (widget.orderId != null) {
      fetchOrderDetails(widget.orderId!);
    }
    fetchAvailableProducts();
  }

  @override
  void dispose() {
    orderNumberController.dispose();
    dateController.dispose();
    numProductsController.dispose();
    finalPriceController.dispose();
    super.dispose();
  }

 Future<void> fetchOrderDetails(int orderId) async {
  try {
    final orderResponse = await http.get(Uri.parse('${url()}orders/$orderId'), headers: headers());
    final productsResponse = await http.get(Uri.parse('${url()}orders/$orderId/products'), headers: headers());

    if (orderResponse.statusCode == 200 && productsResponse.statusCode == 200) {
      // Parse order details
      Map<String, dynamic> orderJson = jsonDecode(orderResponse.body);
      Order order = Order.fromJson(orderJson);

      // Parse products associated with the order
      List<dynamic> productsJson = jsonDecode(productsResponse.body);
      List<OrderProduct> fetchedProducts = productsJson.map((json) {
        int productId = json['id'];
        String productName = json['name'];
        double unitPrice = json['unitPrice'];
        int quantity = json['quantity'];

        
        Product product = Product(id: productId, name: productName, unitPrice: unitPrice);
        return OrderProduct(orderId: orderId, product: product, quantity: quantity);
      }).toList();

      setState(() {
        orderNumberController.text = order.orderNumber;
        dateController.text = order.date.toIso8601String();
        numProductsController.text = fetchedProducts.length.toString();
        finalPriceController.text = calculateFinalPrice(fetchedProducts).toStringAsFixed(2);
        orderProducts.clear();
        orderProducts.addAll(fetchedProducts);
      });
    } else {
      print('Failed to load order details or products: ${orderResponse.statusCode}, ${productsResponse.statusCode}');
    }
  } catch (e) {
    print('Error fetching order details or products: $e');
  }
}


double calculateFinalPrice(List<OrderProduct> products) {
  double totalPrice = 0.0;
  for (var product in products) {
    totalPrice += product.product.unitPrice * product.quantity;
  }
  return totalPrice;
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
      finalPrice: double.parse(finalPriceController.text),
      numProducts: int.parse(numProductsController.text),
    );

    final Map<String, dynamic> postData = {
      'orderNumber': order.orderNumber,
      'date': order.date.toIso8601String(),
      'finalPrice': order.finalPrice,
      'numProducts': order.numProducts,
    };

    http.Response response;
    if (widget.orderId == null) {
      // Creating a new order
      response = await http.post(Uri.parse('${url()}orders'), headers: headers(), body: jsonEncode(postData));

      if (response.statusCode == 201 || response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        int newOrderId = jsonResponse['id'];
        await addProductsToOrder(newOrderId);
        Navigator.of(context).pop(true);
      } else {
        print('Failed to save order: ${response.statusCode}');
      }
    } else {
      // Updating an existing order
      response = await http.put(Uri.parse('${url()}orders/${order.id}'), headers: headers(), body: jsonEncode(postData));

      if (response.statusCode == 200) {
        // Update only necessary products
        await updateProductsInOrder(order.id);
        Navigator.of(context).pop(true); 
      } else {
        print('Failed to update order: ${response.statusCode}');
      }
    }
  } catch (e) {
    print('Error saving/updating order: $e');
  }
}

Future<void> updateProductsInOrder(int orderId) async {
  for (var orderProduct in orderProducts) {
    final response = await http.put(
      Uri.parse('${url()}orders/$orderId/products/${orderProduct.product.id}/${orderProduct.quantity}'),
      headers: headers(),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      print('Failed to update product ${orderProduct.product.id} in order: ${response.statusCode}');
    }
  }
}


  Future<void> addProductsToOrder(int orderId) async {
    for (var orderProduct in orderProducts) {
      final response = await http.post(
        Uri.parse('${url()}orders/$orderId/products/${orderProduct.product.id}/${orderProduct.quantity}'),
        headers: headers(),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Failed to add product ${orderProduct.product.id} to order: ${response.statusCode}');
      }
    }
  }

  void addProduct() {
  if (selectedProduct != null && productQuantity > 0) {
    setState(() {
      // Check if the product already exists in orderProducts
      int existingIndex = orderProducts.indexWhere((op) =>
          op.product.id == selectedProduct!.id);

      if (existingIndex != -1) {
        orderProducts[existingIndex].quantity += productQuantity;
      } else {
        orderProducts.add(OrderProduct(orderId: widget.orderId ?? 0, product: selectedProduct!, quantity: productQuantity));
      }

      finalPriceController.text = calculateFinalPrice(orderProducts).toStringAsFixed(2);
      numProductsController.text = calculateTotalQuantity(orderProducts).toString();

      // Clear selection and quantity for next addition
      selectedProduct = null;
      productQuantity = 1;
    });

    addProductsToOrder(widget.orderId ?? 0);
  }
}

int calculateTotalQuantity(List<OrderProduct> products) {
  int totalQuantity = 0;
  for (var product in products) {
    totalQuantity += product.quantity;
  }
  return totalQuantity;
}



  void editProduct(OrderProduct orderProduct) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      int newQuantity = orderProduct.quantity;
      return AlertDialog(
        title: Text('Edit Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Product: ${orderProduct.product.name}'),
            TextFormField(
              initialValue: orderProduct.quantity.toString(),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Quantity'),
              onChanged: (value) {
                newQuantity = int.tryParse(value) ?? orderProduct.quantity;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Save'),
            onPressed: () async {
              setState(() {
                // Calculate difference to update final price and numProducts
                double priceDifference = (newQuantity - orderProduct.quantity) * orderProduct.product.unitPrice;
                int productDifference = newQuantity - orderProduct.quantity;

                finalPriceController.text = (double.parse(finalPriceController.text) + priceDifference).toStringAsFixed(2);
                numProductsController.text = (int.parse(numProductsController.text) + productDifference).toString();

                orderProduct.quantity = newQuantity;
              });

              try {           
                final response = await http.put(
                  Uri.parse('${url()}orders/${widget.orderId}/products/${orderProduct.product.id}/$newQuantity'),
                  headers: headers(),
                );

                if (response.statusCode == 200) {
                  print('Product quantity updated successfully');
                } else {
                  print('Failed to update product quantity: ${response.statusCode}');
                }
              } catch (e) {
                print('Error updating product quantity: $e');
              }

              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}



void removeProduct(OrderProduct orderProduct) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Remove Product'),
        content: Text('Are you sure you want to remove this product from the order?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Remove'),
            onPressed: () {
              removeProductFromOrder(widget.orderId ?? 0, orderProduct);

              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Future<void> removeProductFromOrder(int orderId, OrderProduct orderProduct) async {
  final response = await http.delete(
    Uri.parse('${url()}orders/$orderId/products/${orderProduct.product.id}/${orderProduct.quantity}'),
    headers: headers(),
  );

  if (response.statusCode != 200) {
    print('Failed to remove product ${orderProduct.product.id} from order: ${response.statusCode}');
    return;
  }

  setState(() {
    finalPriceController.text = (double.parse(finalPriceController.text) - orderProduct.product.unitPrice * orderProduct.quantity).toStringAsFixed(2);
    numProductsController.text = (int.parse(numProductsController.text) - orderProduct.quantity).toString();
    orderProducts.remove(orderProduct);
  });
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
              TextFormField(
                controller: dateController,
                decoration: InputDecoration(labelText: 'Date'),
                enabled: false,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: numProductsController,
                decoration: InputDecoration(labelText: '# Products'),
                enabled: false,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: finalPriceController,
                decoration: InputDecoration(labelText: 'Final Price'),
                enabled: false,
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
               DataTable(
  columns: [
    DataColumn(label: Text('ID')),
    DataColumn(label: Text('Name')),
    DataColumn(label: Text('Unit Price')),
    DataColumn(label: Text('Qty')),
    DataColumn(label: Text('Total Price')),
    DataColumn(label: Text('Options')),
  ],
  rows: orderProducts.map((orderProduct) {
    return DataRow(cells: [
      DataCell(Text(orderProduct.product.id.toString())),
      DataCell(Text(orderProduct.product.name)),
      DataCell(Text('\$${orderProduct.product.unitPrice.toStringAsFixed(2)}')),
      DataCell(Text(orderProduct.quantity.toString())),
      DataCell(Text('\$${(orderProduct.product.unitPrice * orderProduct.quantity).toStringAsFixed(2)}')),
      DataCell(
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => editProduct(orderProduct),
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => removeProduct(orderProduct),
            ),
          ],
        ),
      ),
    ]);
  }).toList(),
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

