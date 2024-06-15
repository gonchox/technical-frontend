import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_testt/models/Order.dart'; // Import your Order model


import '../endpoints/serviceApi.dart'; // Import your service functions

class MyOrdersView extends StatefulWidget {
  @override
  _MyOrdersViewState createState() => _MyOrdersViewState();
}

class _MyOrdersViewState extends State<MyOrdersView> {
  List<Order> orders = [];

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      final response = await http.get(Uri.parse('${url()}orders'), headers: headers());

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<Order> fetchedOrders = data.map((json) => Order.fromJson(json)).toList();

        setState(() {
          orders = fetchedOrders;
        });
      } else {
        // Handle error cases
        print('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network errors or other exceptions
      print('Error fetching orders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders'),
      ),
      body: orders.isEmpty
          ? Center(child: Text('No orders found.'))
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Order #')),
                  DataColumn(label: Text('Date')), // Replace with actual date field from Order model
                  DataColumn(label: Text('# Products')), // You need to calculate this based on products list in Order model
                  DataColumn(label: Text('Final Price')),
                  DataColumn(label: Text('Options')),
                ],
                rows: orders.map((order) {
                  return DataRow(cells: [
                    DataCell(Text(order.id.toString())),
                    DataCell(Text(order.orderNumber)),
                    DataCell(Text('')), // Replace with date field
                    DataCell(Text(order.products.length.toString())),
                    DataCell(Text('\$${order.finalPrice.toStringAsFixed(2)}')),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            // Navigate to Edit Order view
                            Navigator.pushNamed(context, '/add_edit', arguments: order.id);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            // Show confirmation dialog
                            showDialog(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                title: Text('Confirm Delete'),
                                content: Text('Are you sure you want to delete this order?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Call function to delete order
                                      deleteOrder(order.id);
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Add/Edit Order view
          Navigator.pushNamed(context, '/add_edit');
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void deleteOrder(int orderId) async {
    try {
      final response = await http.delete(Uri.parse('${url()}orders/$orderId'), headers: headers());

      if (response.statusCode == 204) {
        // Order successfully deleted
        setState(() {
          orders.removeWhere((order) => order.id == orderId);
        });
      } else {
        // Handle error cases
        print('Failed to delete order: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network errors or other exceptions
      print('Error deleting order: $e');
    }
  }
}
