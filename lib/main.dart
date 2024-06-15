import 'package:flutter/material.dart';
import 'package:flutter_testt/views/MyOrdersView.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My App',
      home: MyOrdersView(),
      routes: {
        '/my-orders': (context) => MyOrdersView(),
      }
    );
  }
}
