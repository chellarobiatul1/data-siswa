import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_data_page.dart';

class StudentFormPage extends StatefulWidget {
  const StudentFormPage({Key? key}) : super(key: key);

  @override
  State<StudentFormPage> createState() => _StudentFormPageState();
}

class _StudentFormPageState extends State<StudentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _formData = {};
  final TextEditingController _dateController = TextEditingController();

  // Controller untuk field auto
  final TextEditingController _desaController = TextEditingController();
  final TextEditingController _kecamatanController = TextEditingController();
  final TextEditingController _kabupatenController = TextEditingController();
  final TextEditingController _provinsiController = TextEditingController();
  final TextEditingController _kodePosController = TextEditingController();
  final TextEditingController _dusunController = TextEditingController();

  // === PICK DATE ===
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        final formatted = "${picked.day}/${picked.month}/${picked.year}";
        _dateController.text = formatted;
        _formData['tanggal_lahir'] = formatted;
      });
    }
  }

  // === SIMPAN KE SUPABASE ===
  Future<void> _saveFormData() async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase.from('siswa').insert({
        'nisn': _formData['nisn'],
        'nama_lengkap': _formData['nama'],
        'jenis_kelamin': _formData['jenis_kelamin'],
        'agama': _formData['agama'],
        'tempat_lahir': _formData['tempat_lahir'],
        'tanggal_lahir': _formData['tanggal_lahir'],
        'no_hp': _formData['telepon'],
        'nik': _formData['nik'],
      }).select();

      if (response.isNotEmpty) {
        final siswaId = response.first['siswa_id'];

        // Simpan alamat
        await supabase.from('alamat_siswa').insert({
          'siswa_id': siswaId,
          'jalan': _formData['jalan'],
          'rt': _formData['rt'],
          'rw': _formData['rw'],
          'dusun_id': await _getDusunIdByName(_formData['dusun'] ?? ''),
        });

        // Simpan wali
        await supabase.from('wali').insert({
          'siswa_id': siswaId,
          'nama_ayah': _formData['ayah'],
          'nama_ibu': _formData['ibu'],
          'nama_wali': _formData['wali'],
          'alamat_wali': _formData['alamat_wali'],
        });

        debugPrint("✅ Data berhasil disimpan ke Supabase");
      }
    } catch (e) {
      debugPrint("❌ Gagal simpan data: $e");
    }
  }

  Future<String?> _getDusunIdByName(String namaDusun) async {
    final supabase = Supabase.instance.client;
    final res = await supabase
        .from('dusun')
        .select('dusun_id')
        .ilike('nama_dusun', namaDusun)
        .limit(1);
    if (res.isNotEmpty) {
      return res.first['dusun_id'] as String;
    }
    return null;
  }

  // === FETCH DATA DUSUN UNTUK AUTOCOMPLETE ===
  Future<List<Map<String, dynamic>>> _fetchDusunList() async {
    final supabase = Supabase.instance.client;
    return await supabase.from('dusun').select('nama_dusun');
  }

  Future<Map<String, dynamic>?> _getDusunDetail(String namaDusun) async {
    final supabase = Supabase.instance.client;
    final res = await supabase
        .from('dusun')
        .select('''
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
        ''')
        .eq('nama_dusun', namaDusun)
        .maybeSingle();

    if (res == null) return null;

    return {
      'nama_desa': res['desa']['nama_desa'],
      'kode_pos': res['desa']['kode_pos'],
      'nama_kecamatan': res['desa']['kecamatan']['nama_kecamatan'],
      'nama_kabupaten': res['desa']['kecamatan']['kabupaten']['nama_kabupaten'],
      'nama_provinsi':
          res['desa']['kecamatan']['kabupaten']['provinsi']['nama_provinsi'],
    };
  }

  // === SUBMIT FORM ===
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      debugPrint("Data yang disubmit: $_formData");

      await _saveFormData();

      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StudentDataPage()),
      );

      // kalau page StudentDataPage di-pop dengan `true`, refetch data
      if (result == true) {
        setState(() {});
      }
    }
  }

  // === REUSABLE FIELD ===

  // === AUTOCOMPLETE DUSUN ===
  Widget buildDusunAutocomplete() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchDusunList(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final dusunList = snapshot.data!
            .map((d) => d['nama_dusun'] as String)
            .toList();

        return Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return dusunList.where(
              (dusun) => dusun.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              ),
            );
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            _dusunController.text = controller.text;
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: "Dusun",
                prefixIcon: Icon(Icons.home_work, color: Colors.pink.shade200),
                filled: true,
                fillColor: Colors.blue.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Pilih Dusun' : null,
            );
          },
          onSelected: (String selection) async {
            _formData['dusun'] = selection;
            final detail = await _getDusunDetail(selection);
            if (detail != null) {
              setState(() {
                _desaController.text = detail['nama_desa'];
                _kecamatanController.text = detail['nama_kecamatan'];
                _kabupatenController.text = detail['nama_kabupaten'];
                _provinsiController.text = detail['nama_provinsi'];
                _kodePosController.text = detail['kode_pos'];

                _formData['desa'] = detail['nama_desa'];
                _formData['kecamatan'] = detail['nama_kecamatan'];
                _formData['kabupaten'] = detail['nama_kabupaten'];
                _formData['provinsi'] = detail['nama_provinsi'];
                _formData['kode_pos'] = detail['kode_pos'];
              });
            }
          },
        );
      },
    );
  }

  Widget buildTextField({
    required String label,
    required String keyName,
    TextInputType inputType = TextInputType.text,
    required IconData icon,
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: TextFormField(
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.pink.shade200),
          filled: true,
          fillColor: Colors.blue.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
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

  Widget buildDropdown({
    required String label,
    required String keyName,
    required List<String> items,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.pink.shade200),
          filled: true,
          fillColor: Colors.blue.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (value) {
          _formData[keyName] = value ?? '';
        },
        validator: (value) =>
            (value == null || value.isEmpty) ? 'Pilih $label' : null,
      ),
    );
  }

  // === DATE FIELD BIAR SAMA STYLE ===
  Widget buildDateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: TextFormField(
        controller: _dateController,
        readOnly: true,
        onTap: _pickDate,
        decoration: InputDecoration(
          labelText: 'Tanggal Lahir',
          prefixIcon: Icon(Icons.calendar_today, color: Colors.pink.shade200),
          filled: true,
          fillColor: Colors.blue.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
        validator: (value) =>
            (value == null || value.isEmpty) ? 'Field wajib diisi' : null,
      ),
    );
  }

  // === UI ===
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Form Data Siswa"),
        backgroundColor: Colors.pink.shade200,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              buildTextField(
              label: 'NISN',
              keyName: 'nisn',
              icon: Icons.numbers,
              ),
              buildTextField(
              label: 'Nama Lengkap',
              keyName: 'nama',
              icon: Icons.person,
              ),
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
              buildTextField(
              label: 'Tempat Lahir',
              keyName: 'tempat_lahir',
              icon: Icons.location_city,
              ),
              buildDateField(),
              buildTextField(
              label: 'No. Telp./HP',
              keyName: 'telepon',
              inputType: TextInputType.phone,
              icon: Icons.phone,
              ),
              buildTextField(
              label: 'NIK',
              keyName: 'nik',
              icon: Icons.perm_identity,
              ),

              const SizedBox(height: 20),
              const Text(
              "Alamat",
              style: TextStyle(fontWeight: FontWeight.bold),
              ),
              buildTextField(
              label: 'Jalan',
              keyName: 'jalan',
              icon: Icons.streetview,
              ),
              buildTextField(label: 'RT', keyName: 'rt', icon: Icons.home_work),
              buildTextField(label: 'RW', keyName: 'rw', icon: Icons.home_work),
              buildDusunAutocomplete(),
              const SizedBox(height: 12),

              // Desa (auto)
              TextFormField(
              controller: _desaController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Desa',
                prefixIcon: Icon(
                Icons.location_city,
                color: Colors.pink.shade200,
                ),
                filled: true,
                fillColor: Colors.blue.shade50,
                border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                ),
              ),
              ),
              const SizedBox(height: 12),

              // Kecamatan (auto)
              TextFormField(
              controller: _kecamatanController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Kecamatan',
                prefixIcon: Icon(Icons.map, color: Colors.pink.shade200),
                filled: true,
                fillColor: Colors.blue.shade50,
                border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                ),
              ),
              ),
              const SizedBox(height: 12),

              // Kabupaten (auto)
              TextFormField(
              controller: _kabupatenController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Kabupaten',
                prefixIcon: Icon(
                Icons.apartment,
                color: Colors.pink.shade200,
                ),
                filled: true,
                fillColor: Colors.blue.shade50,
                border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                ),
              ),
              ),
              const SizedBox(height: 12),

              // Provinsi (auto)
              TextFormField(
              controller: _provinsiController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Provinsi',
                prefixIcon: Icon(Icons.flag, color: Colors.pink.shade200),
                filled: true,
                fillColor: Colors.blue.shade50,
                border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                ),
              ),
              ),
              const SizedBox(height: 12),

              // Kode Pos (auto)
              TextFormField(
              controller: _kodePosController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Kode Pos',
                prefixIcon: Icon(
                Icons.local_post_office,
                color: Colors.pink.shade200,
                ),
                filled: true,
                fillColor: Colors.blue.shade50,
                border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                ),
              ),
              ),

              const SizedBox(height: 20),
              const Text(
              "Data Orang Tua / Wali",
              style: TextStyle(fontWeight: FontWeight.bold),
              ),
              buildTextField(
              label: 'Nama Ayah',
              keyName: 'ayah',
              icon: Icons.family_restroom,
              isRequired: false,
              ),
              buildTextField(
              label: 'Nama Ibu',
              keyName: 'ibu',
              icon: Icons.family_restroom,
              isRequired: false,
              ),
              buildTextField(
              label: 'Nama Wali (jika ada)',
              keyName: 'wali',
              icon: Icons.person_outline,
              isRequired: false,
              ),
              buildTextField(
              label: 'Alamat Wali',
              keyName: 'alamat_wali',
              icon: Icons.location_on,
              ),

              const SizedBox(height: 20),
              ElevatedButton(
              onPressed: _submitForm,
              child: const Text("Kirim"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
              onPressed: () {
                Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentDataPage()),
                );
              },
              child: const Text("Lihat Data"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
