import 'package:flutter/material.dart';
import 'package:thuc_tap/screens/login_page.dart';
import 'package:thuc_tap/services/notification_service.dart';
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
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
      theme: ThemeData(primarySwatch: Colors.teal,fontFamily: 'Roboto Serif'),
    );
  }
}
