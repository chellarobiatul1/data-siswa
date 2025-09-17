import 'package:flutter/material.dart';
import '../screens/student_form_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Data Siswa',
      theme: ThemeData(
        primaryColor: const Color(0xFF5AB9A8),  // Warna utama aplikasi
        fontFamily: 'Roboto',                    // Font default aplikasi
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          color: Color(0xFF5AB9A8),             // AppBar yang konsisten
        ),
      ),
      home: const StudentFormPage(),
    );
  }
}
