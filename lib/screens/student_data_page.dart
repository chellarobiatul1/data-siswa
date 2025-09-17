import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentDataPage extends StatefulWidget {
  final Map<String, String> data;

  const StudentDataPage({Key? key, required this.data}) : super(key: key);

  static List<Map<String, String>> savedData = [];

  @override
  _StudentDataPageState createState() => _StudentDataPageState();
}

class _StudentDataPageState extends State<StudentDataPage> {
  @override
  void initState() {
    super.initState();

    // Pastikan kita memeriksa apakah data sudah ada di dalam savedData sebelum menambahkannya
    if (widget.data.isNotEmpty &&
        widget.data['nama'] != null &&
        widget.data['nisn'] != null) {
      // Cek apakah data sudah ada di savedData
      bool dataAlreadyExists = StudentDataPage.savedData.any(
        (item) => item['nisn'] == widget.data['nisn'],
      ); // Misalnya kita cek berdasarkan NISN yang unik

      if (!dataAlreadyExists) {
        // Menambah data hanya jika data belum ada
        setState(() {
          StudentDataPage.savedData.add(widget.data);
        });
      } else {
        print("Data dengan NISN ${widget.data['nisn']} sudah ada.");
      }
    } else {
      print("Data kosong atau tidak valid!");
    }
    // _loadSavedData();
  }

  // Fungsi untuk memuat data yang sudah disimpan
  Future<void> _loadSavedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedNISNList = prefs.getStringList('savedNISNList') ?? [];

    // Memuat data dari SharedPreferences
    List<Map<String, String>> loadedData = [];
    for (String nisn in savedNISNList) {
      String? savedDataString = prefs.getString(nisn);
      if (savedDataString != null && savedDataString.isNotEmpty) {
        loadedData.add(
          Map<String, String>.from(savedDataString as Map),
        ); // Menambahkan data
      }
    }
    setState(() {
      StudentDataPage.savedData =
          loadedData; // Menyimpan data yang dimuat ke dalam savedData
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lihat Data Siswa"),
        backgroundColor: const Color(0xFF5AB9A8),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Daftar Nama Siswa",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5AB9A8),
              ),
            ),
            const SizedBox(height: 20),

            // Menampilkan daftar siswa
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: List.generate(StudentDataPage.savedData.length, (
                    index,
                  ) {
                    return ListTile(
                      onTap: () => _showDetails(
                        context,
                        StudentDataPage.savedData[index],
                      ),
                      title: Text(
                        StudentDataPage.savedData[index]['nama'] ?? "No Name",
                      ),
                      subtitle: Text(
                        "NISN: ${StudentDataPage.savedData[index]['nisn'] ?? "N/A"}",
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text("Kembali ke Form"),
            ),
          ],
        ),
      ),
    );
  }

  // Menampilkan detail informasi siswa
  void _showDetails(BuildContext context, Map<String, String> studentData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Detail Informasi Siswa'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: studentData.entries.map((entry) {
                return Text('${entry.key}: ${entry.value}');
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Tutup"),
            ),
          ],
        );
      },
    );
  }
}
