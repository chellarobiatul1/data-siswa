import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentDataPage extends StatefulWidget {
  const StudentDataPage({Key? key}) : super(key: key);

  @override
  State<StudentDataPage> createState() => _StudentDataPageState();
}

class _StudentDataPageState extends State<StudentDataPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _students = [];
  bool _loading = true;

  // Controllers untuk edit form
  final namaController = TextEditingController();
  final nisnController = TextEditingController();
  final genderController = TextEditingController();
  final agamaController = TextEditingController();
  final tempatLahirController = TextEditingController();
  final noHpController = TextEditingController();
  final nikController = TextEditingController();
  final jalanController = TextEditingController();
  final rtController = TextEditingController();
  final rwController = TextEditingController();
  final ayahController = TextEditingController();
  final ibuController = TextEditingController();
  final waliController = TextEditingController();
  final alamatWaliController = TextEditingController();
  
  // Controller untuk autocomplete dusun dan auto-fill fields
  final dusunController = TextEditingController();
  final desaController = TextEditingController();
  final kecamatanController = TextEditingController();
  final kabupatenController = TextEditingController();
  final provinsiController = TextEditingController();
  final kodePosController = TextEditingController();

  DateTime? selectedDate;
  List<Map<String, dynamic>> dusunList = [];
  String dusunInput = '';
  Map<String, String> autoRegion = {
    'desa': '',
    'kode_pos': '',
    'kecamatan': '',
    'kabupaten': '',
    'provinsi': ''
  };

  @override
  void initState() {
    super.initState();
    _fetchStudents();
    _fetchDusun();
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
            alamat_siswa!alamat_siswa_siswa_id_fkey (
              alamat_id,
              jalan,
              rt,
              rw,
              dusun:dusun_id (
                dusun_id,
                nama_dusun,
                desa:desa_id (
                  nama_desa,
                  kode_pos,
                  kecamatan:kecamatan_id (
                    nama_kecamatan,
                    kabupaten:kabupaten_id (
                      nama_kabupaten,
                      provinsi:provinsi_id (
                        nama_provinsi
                      )
                    )
                  )
                )
              )
            ),
            wali!wali_siswa_id_fkey (
              wali_id,
              nama_ayah,
              nama_ibu,
              nama_wali,
              alamat_wali
            )
          ''');

      setState(() {
        _students = List<Map<String, dynamic>>.from(response as List);
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ Fetch error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchDusun() async {
    try {
      final res = await supabase.from('dusun').select('''
        dusun_id,
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
      ''');
      setState(() {
        dusunList = List<Map<String, dynamic>>.from(res as List);
      });
    } catch (e) {
      debugPrint('❌ Fetch dusun error: $e');
    }
  }

  // Fungsi untuk mengisi alamat berdasarkan nama dusun
  Future<Map<String, String>?> _getAlamatInfo(String namaDusun) async {
    try {
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

      if (res == null || res['desa'] == null) return null;

      return {
        'nama_desa': res['desa']['nama_desa'] ?? '',
        'kode_pos': res['desa']['kode_pos'] ?? '',
        'nama_kecamatan': res['desa']['kecamatan']?['nama_kecamatan'] ?? '',
        'nama_kabupaten': res['desa']['kecamatan']?['kabupaten']?['nama_kabupaten'] ?? '',
        'nama_provinsi': res['desa']['kecamatan']?['kabupaten']?['provinsi']?['nama_provinsi'] ?? '',
      };
    } catch (e) {
      debugPrint('❌ Get alamat info error: $e');
      return null;
    }
  }

  Future<void> _deleteStudent(String siswaId) async {
    try {
      // Delete related data first (foreign key constraints)
      await supabase.from('alamat_siswa').delete().eq('siswa_id', siswaId);
      await supabase.from('wali').delete().eq('siswa_id', siswaId);
      
      // Then delete the main student record
      await supabase.from('siswa').delete().eq('siswa_id', siswaId);

      if (mounted) {
        _fetchStudents(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data siswa berhasil dihapus')),
        );
      }
    } catch (e) {
      debugPrint('❌ Delete error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error menghapus data: $e')),
        );
      }
    }
  }

  void _confirmDeleteStudent(String siswaId, String namaLengkap) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus data siswa "$namaLengkap"?\n\nTindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close confirmation dialog
              Navigator.pop(context); // Close detail dialog
              _deleteStudent(siswaId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStudent(String siswaId, String? alamatId, String? waliId) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Update siswa data
      await supabase.from('siswa').update({
        'nisn': nisnController.text,
        'nama_lengkap': namaController.text,
        'jenis_kelamin': genderController.text,
        'agama': agamaController.text,
        'tempat_lahir': tempatLahirController.text,
        'tanggal_lahir': selectedDate?.toIso8601String().split('T')[0], // Format as date only
        'no_hp': noHpController.text,
        'nik': nikController.text,
      }).eq('siswa_id', siswaId);

      // Update or insert alamat_siswa
      final dusunId = await _getDusunIdByName(dusunInput);
      if (dusunId != null) {
        if (alamatId != null) {
          // Update existing alamat
          await supabase.from('alamat_siswa').update({
            'jalan': jalanController.text,
            'rt': rtController.text,
            'rw': rwController.text,
            'dusun_id': dusunId,
          }).eq('alamat_id', alamatId);
        } else {
          // Insert new alamat
          await supabase.from('alamat_siswa').insert({
            'siswa_id': siswaId,
            'jalan': jalanController.text,
            'rt': rtController.text,
            'rw': rwController.text,
            'dusun_id': dusunId,
          });
        }
      }

      // Update or insert wali
      if (ayahController.text.isNotEmpty || 
          ibuController.text.isNotEmpty || 
          waliController.text.isNotEmpty || 
          alamatWaliController.text.isNotEmpty) {
        if (waliId != null) {
          // Update existing wali
          await supabase.from('wali').update({
            'nama_ayah': ayahController.text,
            'nama_ibu': ibuController.text,
            'nama_wali': waliController.text,
            'alamat_wali': alamatWaliController.text, 
          }).eq('wali_id', waliId);
        } else {
          // Insert new wali
          await supabase.from('wali').insert({
            'siswa_id': siswaId,
            'nama_ayah': ayahController.text,
            'nama_ibu': ibuController.text,
            'nama_wali': waliController.text,
            'alamat_wali': alamatWaliController.text,
          });
        }
      }

      if (mounted) {
        // Close loading
        Navigator.of(context).pop();
        Navigator.pop(context);
        _fetchStudents();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil diupdate')),
        );
      }
    } catch (e) {
      debugPrint('❌ Update error: $e');
      if (mounted) {
        // Close loading
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<String?> _getDusunIdByName(String namaDusun) async {
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

  void _showDetails(Map<String, dynamic> s) {
    bool editMode = false;

    // Clear previous data
    _clearEditForm();

    // Pre-fill form data
    namaController.text = s['nama_lengkap'] ?? '';
    nisnController.text = s['nisn'] ?? '';
    genderController.text = s['jenis_kelamin'] ?? '';
    agamaController.text = s['agama'] ?? '';
    tempatLahirController.text = s['tempat_lahir'] ?? '';
    noHpController.text = s['no_hp'] ?? '';
    nikController.text = s['nik'] ?? '';

    final alamat = s['alamat_siswa'];
    Map<String, dynamic>? alamatData;
    if (alamat is List && alamat.isNotEmpty) {
      alamatData = alamat[0]; // Take first address
    } else if (alamat is Map<String, dynamic>) {
      alamatData = alamat;
    }

    jalanController.text = alamatData?['jalan'] ?? '';
    rtController.text = alamatData?['rt'] ?? '';
    rwController.text = alamatData?['rw'] ?? '';
    
    if (alamatData?['dusun'] != null) {
      final dusunFromDB = alamatData!['dusun'];
      dusunInput = dusunFromDB['nama_dusun'] ?? '';
      dusunController.text = dusunInput;
      
      // autocomplete alamat
      final desa = dusunFromDB['desa'];
      if (desa != null) {
        final kec = desa['kecamatan'];
        final kab = kec?['kabupaten'];
        final prov = kab?['provinsi'];
        
        final regionData = {
          'desa': desa['nama_desa'] ?? '',
          'kode_pos': desa['kode_pos'] ?? '',
          'kecamatan': kec?['nama_kecamatan'] ?? '',
          'kabupaten': kab?['nama_kabupaten'] ?? '',
          'provinsi': prov?['nama_provinsi'] ?? ''
        };
        
        setState(() {
          autoRegion = regionData.map((key, value) => MapEntry(key, value.toString()));
        });
        
        // isi controller
        desaController.text = regionData['desa']!;
        kodePosController.text = regionData['kode_pos']!;
        kecamatanController.text = regionData['kecamatan']!;
        kabupatenController.text = regionData['kabupaten']!;
        provinsiController.text = regionData['provinsi']!;
      }
    } else {
      dusunInput = '';
      dusunController.clear();
      _clearAutoRegion();
    }

    final wali = s['wali'];
    Map<String, dynamic>? waliData;
    if (wali is List && wali.isNotEmpty) {
      waliData = wali[0]; // Take first wali
    } else if (wali is Map<String, dynamic>) {
      waliData = wali;
    }

    ayahController.text = waliData?['nama_ayah'] ?? '';
    ibuController.text = waliData?['nama_ibu'] ?? '';
    waliController.text = waliData?['nama_wali'] ?? '';
    alamatWaliController.text = waliData?['alamat_wali'] ?? '';

    if (s['tanggal_lahir'] != null) {
      selectedDate = DateTime.tryParse(s['tanggal_lahir']);
    } else {
      selectedDate = null;
    }

    final alamatId = alamatData?['alamat_id'];
    final waliId = waliData?['wali_id'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateSB) {
          return AlertDialog(
            title: Text(editMode ? 'Edit Siswa' : 'Detail Siswa'),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.7,
              child: SingleChildScrollView(
                child: editMode ? _buildEditForm(setStateSB) : _buildDetailView(s),
              ),
            ),
            actions: [
              if (!editMode) ...[
                TextButton(
                  onPressed: () => setStateSB(() => editMode = true),
                  child: const Text('Edit'),
                ),
                TextButton(
                  onPressed: () => _confirmDeleteStudent(s['siswa_id'], s['nama_lengkap'] ?? 'Unknown'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Hapus'),
                ),
              ],
              if (editMode)
                ElevatedButton(
                  onPressed: () =>
                      _updateStudent(s['siswa_id'], alamatId, waliId),
                  child: const Text('Simpan'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _clearEditForm() {
    namaController.clear();
    nisnController.clear();
    genderController.clear();
    agamaController.clear();
    tempatLahirController.clear();
    noHpController.clear();
    nikController.clear();
    jalanController.clear();
    rtController.clear();
    rwController.clear();
    ayahController.clear();
    ibuController.clear();
    waliController.clear();
    alamatWaliController.clear();
    dusunController.clear();
    desaController.clear();
    kecamatanController.clear();
    kabupatenController.clear();
    provinsiController.clear();
    kodePosController.clear();
    dusunInput = '';
    selectedDate = null;
    _clearAutoRegion();
  }

  void _clearAutoRegion() {
    setState(() {
      autoRegion = {
        'desa': '',
        'kode_pos': '',
        'kecamatan': '',
        'kabupaten': '',
        'provinsi': ''
      };
    });
  }

  // Autocomplete Dusun Widget untuk Edit Form
  Widget _buildDusunAutocomplete(void Function(void Function()) setStateSB) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Autocomplete<Map<String, dynamic>>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<Map<String, dynamic>>.empty();
          }
          return dusunList.where(
            (dusun) => dusun['nama_dusun']
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase()),
          );
        },
        displayStringForOption: (Map<String, dynamic> option) =>
            option['nama_dusun'] as String,
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          dusunController.text = controller.text;
          return TextFormField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: "Ketik Dusun",
              hintText: "Mulai mengetik untuk mencari dusun...",
              prefixIcon: const Icon(
                Icons.home_work,
                color: Color.fromARGB(255, 16, 34, 98),
              ),
              filled: true,
              fillColor: const Color.fromARGB(255, 147, 200, 234),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onChanged: (value) {
              // Clear auto-filled fields when user types
              if (value.isNotEmpty) {
                setStateSB(() {
                  dusunInput = value;
                  _clearAutoFillControllers();
                });
              }
            },
          );
        },
        onSelected: (Map<String, dynamic> selection) async {
          // Show loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );

          setStateSB(() {
            dusunInput = selection['nama_dusun'];
            dusunController.text = dusunInput;
          });

          // Get detailed information
          final detail = await _getAlamatInfo(selection['nama_dusun']);
          
          // Close loading
          Navigator.of(context).pop();

          if (detail != null) {
            setStateSB(() {
              // Fill all address fields
              autoRegion = {
                'desa': detail['nama_desa'] ?? '',
                'kode_pos': detail['kode_pos'] ?? '',
                'kecamatan': detail['nama_kecamatan'] ?? '',
                'kabupaten': detail['nama_kabupaten'] ?? '',
                'provinsi': detail['nama_provinsi'] ?? '',
              };
              
              // Update controllers
              desaController.text = autoRegion['desa']!;
              kodePosController.text = autoRegion['kode_pos']!;
              kecamatanController.text = autoRegion['kecamatan']!;
              kabupatenController.text = autoRegion['kabupaten']!;
              provinsiController.text = autoRegion['provinsi']!;
            });
          }
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: options.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return InkWell(
                      onTap: () => onSelected(option),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option['nama_dusun'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (option['desa'] != null)
                              Text(
                                option['desa']['nama_desa'] ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget untuk auto-fill field (read-only)
  Widget _buildAutoFillField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: const Color.fromARGB(255, 16, 34, 98),
          ),
          filled: true,
          fillColor: const Color.fromARGB(255, 147, 200, 234),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 16, 34, 98),
              width: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  // Widget untuk regular text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null 
            ? Icon(icon, color: const Color.fromARGB(255, 16, 34, 98))
            : null,
          filled: true,
          fillColor: const Color.fromARGB(255, 147, 200, 234),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  void _clearAutoFillControllers() {
    desaController.clear();
    kodePosController.clear();
    kecamatanController.clear();
    kabupatenController.clear();
    provinsiController.clear();
    autoRegion = {
      'desa': '',
      'kode_pos': '',
      'kecamatan': '',
      'kabupaten': '',
      'provinsi': ''
    };
  }

  Widget _buildDetailView(Map<String, dynamic> s) {
    // Handle alamat_siswa
    final alamat = s['alamat_siswa'];
    Map<String, dynamic>? alamatData;
    if (alamat is List && alamat.isNotEmpty) {
      alamatData = alamat[0];
    } else if (alamat is Map<String, dynamic>) {
      alamatData = alamat;
    }

    final d = alamatData?['dusun'];
    final desa = d?['desa'];
    final kec = desa?['kecamatan'];
    final kab = kec?['kabupaten'];
    final prov = kab?['provinsi'];

    // Handle wali
    final wali = s['wali'];
    Map<String, dynamic>? waliData;
    if (wali is List && wali.isNotEmpty) {
      waliData = wali[0];
    } else if (wali is Map<String, dynamic>) {
      waliData = wali;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildInfoRow(Icons.person, "Nama", s['nama_lengkap'] ?? '-'),
        _buildInfoRow(Icons.numbers, "NISN", s['nisn'] ?? '-'),
        _buildInfoRow(Icons.wc, "Jenis Kelamin", s['jenis_kelamin'] ?? '-'),
        _buildInfoRow(Icons.mosque, "Agama", s['agama'] ?? '-'),
        _buildInfoRow(Icons.location_city, "Tempat Lahir", s['tempat_lahir'] ?? '-'),
        _buildInfoRow(Icons.calendar_today, "Tanggal Lahir", s['tanggal_lahir'] ?? '-'),
        _buildInfoRow(Icons.phone, "No HP", s['no_hp'] ?? '-'),
        _buildInfoRow(Icons.perm_identity, "NIK", s['nik'] ?? '-'),
        const Divider(),
        const Text("ALAMAT:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        _buildInfoRow(Icons.streetview, "Jalan", alamatData?['jalan'] ?? '-'),
        _buildInfoRow(Icons.home_work, "RT/RW", "${alamatData?['rt'] ?? '-'} / ${alamatData?['rw'] ?? '-'}"),
        _buildInfoRow(Icons.location_on, "Dusun", d?['nama_dusun'] ?? '-'),
        _buildInfoRow(Icons.location_city, "Desa", desa?['nama_desa'] ?? '-'),
        _buildInfoRow(Icons.local_post_office, "Kode Pos", desa?['kode_pos'] ?? '-'),
        _buildInfoRow(Icons.map, "Kecamatan", kec?['nama_kecamatan'] ?? '-'),
        _buildInfoRow(Icons.apartment, "Kabupaten", kab?['nama_kabupaten'] ?? '-'),
        _buildInfoRow(Icons.flag, "Provinsi", prov?['nama_provinsi'] ?? '-'),
        const Divider(),
        const Text("WALI:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        _buildInfoRow(Icons.family_restroom, "Nama Ayah", waliData?['nama_ayah'] ?? '-'),
        _buildInfoRow(Icons.family_restroom, "Nama Ibu", waliData?['nama_ibu'] ?? '-'),
        _buildInfoRow(Icons.person_outline, "Nama Wali", waliData?['nama_wali'] ?? '-'),
        _buildInfoRow(Icons.location_on, "Alamat Wali", waliData?['alamat_wali'] ?? '-'),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF5AB9A8)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87),
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(void Function(void Function()) setStateSB) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Data Pribadi
        _buildTextField(
          controller: namaController,
          label: "Nama Lengkap",
          icon: Icons.person,
        ),
        _buildTextField(
          controller: nisnController,
          label: "NISN",
          icon: Icons.numbers,
          keyboardType: TextInputType.number,
        ),
        _buildTextField(
          controller: genderController,
          label: "Jenis Kelamin",
          icon: Icons.wc,
        ),
        _buildTextField(
          controller: agamaController,
          label: "Agama",
          icon: Icons.mosque,
        ),
        _buildTextField(
          controller: tempatLahirController,
          label: "Tempat Lahir",
          icon: Icons.location_city,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(selectedDate == null
                  ? "Tanggal Lahir: -"
                  : "Tanggal Lahir: ${selectedDate!.toIso8601String().split('T')[0]}"),
            ),
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime(1990),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setStateSB(() => selectedDate = picked);
              },
              child: const Text("Pilih Tanggal"),
            ),
          ],
        ),
        _buildTextField(
          controller: noHpController,
          label: "No HP",
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
        ),
        _buildTextField(
          controller: nikController,
          label: "NIK",
          icon: Icons.perm_identity,
          keyboardType: TextInputType.number,
        ),
        
        const Divider(),
        const Text("ALAMAT:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        _buildTextField(
          controller: jalanController,
          label: "Jalan",
          icon: Icons.streetview,
        ),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: rtController,
                label: "RT",
                icon: Icons.home_work,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField(
                controller: rwController,
                label: "RW",
                icon: Icons.home_work,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        
        // Autocomplete Dusun
        _buildDusunAutocomplete(setStateSB),
        
        // Auto-fill address fields
        _buildAutoFillField(
          controller: desaController,
          label: "Desa",
          icon: Icons.location_city,
        ),
        _buildAutoFillField(
          controller: kodePosController,
          label: "Kode Pos",
          icon: Icons.local_post_office,
        ),
        _buildAutoFillField(
          controller: kecamatanController,
          label: "Kecamatan",
          icon: Icons.map,
        ),
        _buildAutoFillField(
          controller: kabupatenController,
          label: "Kabupaten",
          icon: Icons.apartment,
        ),
        _buildAutoFillField(
          controller: provinsiController,
          label: "Provinsi",
          icon: Icons.flag,
        ),
        
        const Divider(),
        const Text("WALI:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        _buildTextField(
          controller: ayahController,
          label: "Nama Ayah",
          icon: Icons.family_restroom,
        ),
        _buildTextField(
          controller: ibuController,
          label: "Nama Ibu",
          icon: Icons.family_restroom,
        ),
        _buildTextField(
          controller: waliController,
          label: "Nama Wali",
          icon: Icons.person_outline,
        ),
        _buildTextField(
          controller: alamatWaliController,
          label: "Alamat Wali",
          icon: Icons.location_on,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Siswa'), 
        backgroundColor: const Color(0xFF5AB9A8),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada data siswa',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _students.length,
                  itemBuilder: (c, i) {
                    final s = _students[i];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: const Color.fromARGB(255, 147, 200, 234),
                          child: Text(
                            (s['nama_lengkap'] ?? '')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          s['nama_lengkap'] ?? 'No Name',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NISN: ${s['nisn'] ?? '-'}'),
                            Text('Jenis Kelamin: ${s['jenis_kelamin'] ?? '-'}'),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showDetails(s),
                      ),
                    );
                  },
                ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Navigator.pushNamed(context, '/form');
      //   },
      //   backgroundColor: const Color(0xFF5AB9A8),
      //   child: const Icon(Icons.add, color: Colors.white),
      // ),
    );
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    namaController.dispose();
    nisnController.dispose();
    genderController.dispose();
    agamaController.dispose();
    tempatLahirController.dispose();
    noHpController.dispose();
    nikController.dispose();
    jalanController.dispose();
    rtController.dispose();
    rwController.dispose();
    ayahController.dispose();
    ibuController.dispose();
    waliController.dispose();
    alamatWaliController.dispose();
    dusunController.dispose();
    desaController.dispose();
    kecamatanController.dispose();
    kabupatenController.dispose();
    provinsiController.dispose();
    kodePosController.dispose();
    super.dispose();
  }
}