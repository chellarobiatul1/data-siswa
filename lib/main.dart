import 'package:flutter/material.dart';
import '../screens/student_form_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://jtlvuancowmeeyojuzjy.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp0bHZ1YW5jb3dtZWV5b2p1emp5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgxODQwOTYsImV4cCI6MjA3Mzc2MDA5Nn0.m0tuLmf8OMHwKwE5pf9-CIS4pANA_S-PU3Ekx9VsGYM',                     
  );
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
      debugShowCheckedModeBanner: false,
      home: const StudentFormPage(),
    );
  }
}
