import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentDataPage extends StatefulWidget {
  const StudentDataPage({Key? key}) : super(key: key);

  @override
  _StudentDataPageState createState() => _StudentDataPageState();
}

class _StudentDataPageState extends State<StudentDataPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final response = await supabase
    .from('siswa')
    .select('''
      siswa_id,
      nisn,
      nama_lengkap,
      jenis_kelamin,
      agama,
      tempat_lahir,
      tanggal_lahir,
      no_hp,
      nik,
      alamat_siswa (
        jalan,
        rt,
        rw,
        dusun:dusun_id (
          nama_dusun,
          desa:desa_id (
            nama_desa,
            kode_pos,
            kecamatan:kecamatan_id (
              nama_kecamatan,
              kabupaten:kabupaten_id (
                nama_kabupaten,
                provinsi:provinsi_id (nama_provinsi)
              )
            )
          )
        )
      ),
      wali (
        nama_ayah,
        nama_ibu,
        nama_wali,
        alamat_wali
      )
    ''');

      // ✅ Ambil langsung datanya
      final data = response as List;

      debugPrint("✅ Data siswa: ${data.length}");
      debugPrint("Isi data: $data");

      setState(() {
        _students = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      debugPrint("❌ Error fetch siswa: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lihat Data Siswa"),
        backgroundColor: const Color(0xFF5AB9A8),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? const Center(child: Text("Belum ada data siswa."))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Daftar Nama Siswa",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            return Card(
                              elevation: 4,
                              color: const Color.fromARGB(255, 147, 200, 234),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                onTap: () => _showDetails(context, student),
                                title: Text(student['nama_lengkap'] ?? "No Name"),
                                subtitle: Text(
                                  "NISN: ${student['nisn'] ?? 'N/A'}",
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  void _showDetails(BuildContext context, Map<String, dynamic> student) {
    final alamat = student['alamat_siswa']?[0];
    final wali = student['wali']?[0];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 220, 220, 220),
          title: const Text('Detail Informasi Siswa'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("NISN: ${student['nisn']}"),
                Text("Nama: ${student['nama_lengkap']}"),
                Text("Jenis Kelamin: ${student['jenis_kelamin']}"),
                Text("Agama: ${student['agama']}"),
                Text("Tempat Lahir: ${student['tempat_lahir']}"),
                Text("Tanggal Lahir: ${student['tanggal_lahir']}"),
                Text("No HP: ${student['no_hp']}"),
                Text("NIK: ${student['nik']}"),
                const SizedBox(height: 10),
                const Text("Alamat:", style: TextStyle(fontWeight: FontWeight.bold)),
                if (alamat != null) ...[
                  Text("Jalan: ${alamat['jalan'] ?? ''}"),
                  Text("RT/RW: ${alamat['rt'] ?? ''}/${alamat['rw'] ?? ''}"),
                  Text("Dusun: ${alamat['dusun']['nama_dusun'] ?? ''}"),
                  Text("Desa: ${alamat['dusun']['desa']['nama_desa'] ?? ''}"),
                  Text("Kecamatan: ${alamat['dusun']['desa']['kecamatan']['nama_kecamatan'] ?? ''}"),
                  Text("Kabupaten: ${alamat['dusun']['desa']['kecamatan']['kabupaten']['nama_kabupaten'] ?? ''}"),
                  Text("Provinsi: ${alamat['dusun']['desa']['kecamatan']['kabupaten']['provinsi']['nama_provinsi'] ?? ''}"),
                  Text("Kode Pos: ${alamat['dusun']['desa']['kode_pos'] ?? ''}"),
                ],
                const SizedBox(height: 10),
                const Text("Orang Tua / Wali:", style: TextStyle(fontWeight: FontWeight.bold)),
                if (wali != null) ...[
                  Text("Ayah: ${wali['nama_ayah'] ?? ''}"),
                  Text("Ibu: ${wali['nama_ibu'] ?? ''}"),
                  Text("Wali: ${wali['nama_wali'] ?? ''}"),
                  Text("Alamat Wali: ${wali['alamat_wali'] ?? ''}"),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Tutup"),
            ),
          ],
        );
      },
    );
  }
}
