import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyOrdersScreen extends StatefulWidget {

  MyOrdersScreen();

  @override
  _MyOrdersScreenState createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<Order> orders = []; // List to hold fetched orders
  bool isLoading = false; // State variable for loading indicator

  @override
  void initState() {
    super.initState();
    fetchOrders(); // Fetch orders when screen initializes
  }

  Future<void> fetchOrders() async {
    setState(() {
      isLoading = true; // Set loading state to true
    });
    
    try {
      var url = 'http://localhost:8080/api/orders'; // Replace with your API endpoint
      var response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        List<Order> fetchedOrders = [];
        
        for (var item in jsonData) {
          fetchedOrders.add(Order(
            id: item['id'],
            orderNumber: item['orderNumber'],
            date: DateTime.parse(item['date']),
            finalPrice: item['finalPrice'].toDouble(),
          ));
        }
        
        setState(() {
          orders = fetchedOrders; // Update orders list with fetched data
          isLoading = false; // Set loading state to false
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() {
        isLoading = false; // Set loading state to false
      });
      // Handle error as needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? Center(child: Text('No orders found.'))
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    Order order = orders[index];
                    return ListTile(
                      title: Text('Order #${order.orderNumber}'),
                      subtitle: Text('Date: ${order.date.toString()}'),
                      trailing:
                          Text('Total Price: \$${order.finalPrice.toStringAsFixed(2)}'),
                      // Add onTap handler if needed
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Implement action for floating action button (if any)
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class Order {
  final int id;
  final String orderNumber;
  final DateTime date;
  final double finalPrice;

  Order({
    required this.id,
    required this.orderNumber,
    required this.date,
    required this.finalPrice,
  });
}
