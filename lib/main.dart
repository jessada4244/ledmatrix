import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home.dart';
import 'crud_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // เริ่มต้น Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LED Matrix Manager',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      initialRoute: '/', // หน้าเริ่มต้น
      routes: {
        '/': (context) => HomeScreen(),
        '/crud': (context) => CrudScreen(),
      },
    );
  }
}
