import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../screens/student_form_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 🔹 cek koneksi internet
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      throw Exception('No Internet Connection');
    }

    // 🔹 init Supabase
    await Supabase.initialize(
      url: 'https://jtlvuancowmeeyojuzjy.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp0bHZ1YW5jb3dtZWV5b2p1emp5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgxODQwOTYsImV4cCI6MjA3Mzc2MDA5Nn0.m0tuLmf8OMHwKwE5pf9-CIS4pANA_S-PU3Ekx9VsGYM',
    );

    runApp(const MyApp());

  } on PostgrestException catch (e) {
    runApp(ErrorApp(message: 'Supabase error: ${e.message}'));
  } catch (e) {
    // error umum (termasuk koneksi internet)
    runApp(ErrorApp(message: 'Terjadi kesalahan: $e'));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Data Siswa',
      theme: ThemeData(
        primaryColor: const Color(0xFF5AB9A8),
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          color: Color(0xFF5AB9A8),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const StudentFormPage(),
    );
  }
}

/// Widget untuk menampilkan pesan error
class ErrorApp extends StatelessWidget {
  final String message;
  const ErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      ),
    );
  }
}
