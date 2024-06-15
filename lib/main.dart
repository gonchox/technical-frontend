import 'package:flutter/material.dart';
import 'package:technical_flutter/AddEditOrderScreen.dart';
import 'package:technical_flutter/MyOrdersScreen.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Orders App',
      initialRoute: '/my-orders',
      routes: {
        '/my-orders': (context) => MyOrdersScreen(),
        '/add-order': (context) => AddEditOrderScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/add-order') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => AddEditOrderScreen(orderId: args['id']),
          );
        }
        return null;
      },
    );
  }
}
