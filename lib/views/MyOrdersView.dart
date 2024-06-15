import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_testt/models/Order.dart';
import '../endpoints/serviceApi.dart';
import 'AddEditView.dart';

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
        print('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
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
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('# Products')),
                  DataColumn(label: Text('Final Price')),
                  DataColumn(label: Text('Options')),
                ],
                rows: orders.map((order) {
                  return DataRow(cells: [
                    DataCell(Text(order.id.toString())),
                    DataCell(Text(order.orderNumber)),
                    DataCell(Text(order.date.toString())),
                    DataCell(Text(order.numProducts.toString())), // Display numProducts
                    DataCell(Text('\$${order.finalPrice.toStringAsFixed(2)}')),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddEditView(orderId: order.id),
                              ),
                            ).then((_) {
                              fetchOrders(); // Refresh orders after editing
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
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
                                      deleteOrder(order.id);
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ).then((_) {
                              fetchOrders(); // Refresh orders after deleting
                            });
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditView(),
            ),
          ).then((_) {
            fetchOrders(); // Refresh orders after adding new order
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void deleteOrder(int orderId) async {
    try {
      final response = await http.delete(Uri.parse('${url()}orders/$orderId'), headers: headers());

      if (response.statusCode == 200) {
        setState(() {
          orders.removeWhere((order) => order.id == orderId);
        });
      } else {
        print('Failed to delete order: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting order: $e');
    }
  }
}
