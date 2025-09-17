import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'student_data_page.dart'; // Import halaman Data Siswa

class StudentFormPage extends StatefulWidget {
  const StudentFormPage({Key? key}) : super(key: key);

  @override
  State<StudentFormPage> createState() => _StudentFormPageState();
}

class _StudentFormPageState extends State<StudentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _formData = {}; // Data form disimpan di sini
  final TextEditingController _dateController = TextEditingController();

  // Fungsi untuk memilih tanggal
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
        _formData['tanggal_lahir'] = _dateController.text; // Simpan tanggal lahir
      });
    }
  }

  // Fungsi untuk menyimpan data menggunakan SharedPreferences
  Future<void> _saveFormData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('nisn', _formData['nisn'] ?? '');
    prefs.setString('nama', _formData['nama'] ?? '');
    prefs.setString('jenis_kelamin', _formData['jenis_kelamin'] ?? '');
    prefs.setString('agama', _formData['agama'] ?? '');
    prefs.setString('tempat_lahir', _formData['tempat_lahir'] ?? '');
    prefs.setString('tanggal_lahir', _formData['tanggal_lahir'] ?? '');
    prefs.setString('telepon', _formData['telepon'] ?? '');
    prefs.setString('nik', _formData['nik'] ?? '');
    prefs.setString('alamat', _formData['alamat'] ?? '');
    prefs.setString('jalan', _formData['jalan'] ?? '');
    prefs.setString('rt_rw', _formData['rt_rw'] ?? '');
    prefs.setString('dusun', _formData['dusun'] ?? '');
    prefs.setString('desa', _formData['desa'] ?? '');
    prefs.setString('kecamatan', _formData['kecamatan'] ?? '');
    prefs.setString('kabupaten', _formData['kabupaten'] ?? '');
    prefs.setString('provinsi', _formData['provinsi'] ?? '');
    prefs.setString('kode_pos', _formData['kode_pos'] ?? '');
    prefs.setString('ayah', _formData['ayah'] ?? '');
    prefs.setString('ibu', _formData['ibu'] ?? '');
    prefs.setString('wali', _formData['wali'] ?? '');
    prefs.setString('alamat_wali', _formData['alamat_wali'] ?? '');
  }

  // Fungsi untuk mengirim form dan navigasi ke halaman berikutnya
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      debugPrint("Data yang disubmit: $_formData"); // Debug print

      // Simpan data
      _saveFormData();

      // Kirim data ke halaman berikutnya
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StudentDataPage(data: _formData)),
      );
    }
  }

  // Fungsi untuk membuat widget input text field
  Widget buildTextField({
    required String label,
    required String keyName,
    TextInputType inputType = TextInputType.text,
    required IconData icon, // Menambahkan parameter icon
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: TextFormField(
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.pink.shade200), // Label dengan warna pink soft
          prefixIcon: Icon(icon, color: Colors.pink.shade200), // Warna ikon pink soft
          filled: true, // Membuat latar belakang field lebih terlihat
          fillColor: Colors.blue.shade50, // Latar belakang soft blue pada input field
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.lightBlue.shade100, width: 2), // Biru muda pada border
            borderRadius: BorderRadius.circular(15),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.lightBlue.shade100, width: 2), // Biru muda pada border
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Field $label wajib diisi';
          }
          return null;
        },
        onSaved: (value) {
          if (value != null && value.isNotEmpty) {
            _formData[keyName] = value;
          }
        },
      ),
    );
  }

  // Fungsi untuk membuat widget dropdown
  Widget buildDropdown({
    required String label,
    required String keyName,
    required List<String> items,
    required IconData icon, // Menambahkan parameter icon
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.pink.shade200), // Label dengan warna pink soft
          prefixIcon: Icon(icon, color: Colors.pink.shade200), // Warna ikon pink soft
          filled: true,
          fillColor: Colors.blue.shade50, // Latar belakang soft blue pada dropdown
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: const Color.fromARGB(255, 64, 132, 164), width: 2), // Biru muda pada border
            borderRadius: BorderRadius.circular(15),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.lightBlue.shade100, width: 2), // Biru muda pada border
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        items: items
            .map((e) => DropdownMenuItem<String>( 
                  value: e, 
                  child: Text(e), 
                ))
            .toList(),
        onChanged: (value) {
          _formData[keyName] = value ?? ''; 
        },
        validator: (value) =>
            (value == null || value.isEmpty) ? 'Pilih $label' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Form Data Siswa"),
        backgroundColor: Colors.pink.shade200, // Pink soft untuk background app bar
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Data Siswa",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 175, 95, 122)),
                  ),
                  const SizedBox(height: 16),

                  // Data Siswa
                  buildTextField(label: 'NISN', keyName: 'nisn', icon: Icons.numbers),
                  buildTextField(label: 'Nama Lengkap', keyName: 'nama', icon: Icons.person),
                  buildDropdown(
                    label: 'Jenis Kelamin',
                    keyName: 'jenis_kelamin',
                    items: ['Laki-laki', 'Perempuan'],
                    icon: Icons.account_balance,
                  ),
                  buildDropdown(
                    label: 'Agama',
                    keyName: 'agama',
                    items: ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Budha'],
                    icon: Icons.account_balance,
                  ),
                  buildTextField(label: 'Tempat Lahir', keyName: 'tempat_lahir', icon: Icons.location_city),
                  TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Lahir',
                      prefixIcon: Icon(Icons.calendar_today, color: Color.fromARGB(255, 172, 99, 124)), // Warna ikon pink soft
                    ),
                    onTap: _pickDate,
                  ),
                  buildTextField(
                    label: 'No. Telp./HP',
                    keyName: 'telepon',
                    inputType: TextInputType.phone,
                    icon: Icons.phone,
                  ),
                  buildTextField(label: 'NIK', keyName: 'nik', icon: Icons.perm_identity),
                  buildTextField(label: 'Alamat', keyName: 'alamat', icon: Icons.home),
                  buildTextField(label: 'Jalan', keyName: 'jalan', icon: Icons.streetview),
                  buildTextField(label: 'RT/RW', keyName: 'rt_rw', icon: Icons.home_work),
                  buildTextField(label: 'Dusun', keyName: 'dusun', icon: Icons.location_on),
                  buildTextField(label: 'Desa', keyName: 'desa', icon: Icons.location_city),
                  buildTextField(label: 'Kecamatan', keyName: 'kecamatan', icon: Icons.location_on),
                  buildTextField(label: 'Kabupaten', keyName: 'kabupaten', icon: Icons.location_city),
                  buildTextField(label: 'Provinsi', keyName: 'provinsi', icon: Icons.map),
                  buildTextField(label: 'Kode Pos', keyName: 'kode_pos', icon: Icons.mail),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Heading Data Orang Tua / Wali
                  const Text(
                    "Data Orang Tua / Wali",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 179, 103, 128)),
                  ),
                  buildTextField(label: 'Nama Ayah', keyName: 'ayah', icon: Icons.family_restroom),
                  buildTextField(label: 'Nama Ibu', keyName: 'ibu', icon: Icons.family_restroom),
                  buildTextField(
                      label: 'Nama Wali (jika ada)', 
                       keyName: 'wali',
                       icon: Icons.person_outline,
                       ),
                  buildTextField(label: 'Alamat Wali', keyName: 'alamat_wali', icon: Icons.location_on),

                  const SizedBox(height: 20),

                  // Tombol Kirim dan Lihat Data
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tombol Kirim
                      ElevatedButton(
                        onPressed: _submitForm,
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
                        child: const Text("Kirim"),
                      ),
                      // Tombol Lihat Data
                      ElevatedButton(
                        onPressed: () {
                          // Pindahkan ke halaman StudentDataPage untuk melihat data
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentDataPage(data: _formData),
                            ),
                          );
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
                        child: const Text("Lihat Data"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
