import 'package:flutter/material.dart';
import 'package:thuc_tap/screens/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ứng dụng ghi chú',
      home: LoginPage(),
      theme: ThemeData(primarySwatch: Colors.teal),
    );
  }
}
