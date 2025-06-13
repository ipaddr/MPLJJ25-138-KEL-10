import 'package:flutter/material.dart';
import 'package:admin_sembuhtbc/auth_service.dart'; // Import AuthService Admin
import 'package:cloud_firestore/cloud_firestore.dart'; // Untuk FieldValue.serverTimestamp() jika diperlukan secara langsung

class ManageMedPage extends StatefulWidget {
  const ManageMedPage({super.key});

  @override
  State<ManageMedPage> createState() => _ManageMedPageState();
}

class _ManageMedPageState extends State<ManageMedPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _doseController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _firstTimeController =
      TextEditingController(); // Mengganti _timeController
  final TextEditingController _timesPerDayController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();

  String? _selectedType;
  String? _selectedInterval;
  String? _customInterval;
  bool _alarmEnabled = false;

  // Variabel untuk memilih pasien
  String? _selectedPasienUid;
  List<Map<String, dynamic>> _verifiedPasienList = [];
  bool _isLoadingPasien = true;

  final AuthService _authService =
      AuthService(); // Inisialisasi AuthService Admin

  final List<String> _typeOptions = ['Tablet', 'Kapsul', 'Sirup', 'Injeksi'];

  @override
  void initState() {
    super.initState();
    _loadVerifiedPasien();
  }

  Future<void> _loadVerifiedPasien() async {
    setState(() {
      _isLoadingPasien = true;
    });
    try {
      _authService.getVerifiedUsers().listen(
        (pasienList) {
          setState(() {
            _verifiedPasienList = pasienList;
            _isLoadingPasien = false;
          });
        },
        onError: (error) {
          print("Error loading verified patients: $error");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal memuat daftar pasien: $error")),
          );
          setState(() {
            _isLoadingPasien = false;
          });
        },
      );
    } catch (e) {
      print("Error subscribing to verified patients: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
      setState(() {
        _isLoadingPasien = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _amountController.dispose();
    _firstTimeController.dispose();
    _timesPerDayController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  Future<void> _showCustomIntervalDialog(BuildContext context) async {
    final intervalController = TextEditingController();
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Interval Custom"),
            content: TextFormField(
              controller: intervalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Interval (jam)",
                hintText: "Misal: 5 untuk 5 jam",
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Wajib diisi';
                if (int.tryParse(value) == null) return 'Harap masukkan angka';
                return null;
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (intervalController.text.isNotEmpty &&
                      int.tryParse(intervalController.text) != null) {
                    setState(() {
                      _customInterval = intervalController.text;
                      _selectedInterval = "custom";
                    });
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Interval tidak valid.")),
                    );
                  }
                },
                child: const Text("Simpan"),
              ),
            ],
          ),
    );
    intervalController.dispose();
  }

  Future<void> _showConfirmationDialog(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final selectedPasienName =
          _verifiedPasienList.firstWhere(
            (pasien) => pasien['uid'] == _selectedPasienUid,
            orElse: () => {'username': 'N/A'},
          )['username'];

      return showDialog(
        context: context,
        builder:
            (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Konfirmasi Jadwal Obat", // Judul dialog diubah
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0072CE),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Apakah Anda yakin ingin menyimpan jadwal obat ini untuk pasien: $selectedPasienName?",
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Batal",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _saveMedication();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0072CE),
                          ),
                          child: const Text(
                            "Simpan",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      );
    }
  }

  Future<void> _saveMedication() async {
    if (_selectedPasienUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Harap pilih pasien terlebih dahulu.",
            style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final timesPerDay = int.tryParse(_timesPerDayController.text) ?? 0;
    final daysDuration = int.tryParse(_daysController.text) ?? 0;
    final interval =
        _selectedInterval == "custom"
            ? int.tryParse(_customInterval ?? "0") ?? 0
            : int.tryParse(_selectedInterval ?? "0") ?? 0;

    if (timesPerDay <= 0 ||
        daysDuration <= 0 ||
        (interval <= 0 && timesPerDay > 1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Data frekuensi atau durasi tidak valid.",
            style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final adminUser = _authService.getCurrentUser();
      if (adminUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Admin tidak login. Tidak bisa menyimpan jadwal.",
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await _authService.addMedicationSchedule(
        pasienUid: _selectedPasienUid!,
        medicineName: _nameController.text.trim(),
        medicineType: _selectedType!,
        dose: _doseController.text.trim(),
        amount: int.parse(_amountController.text),
        firstDoseTime: _firstTimeController.text.trim(),
        timesPerDay: timesPerDay,
        intervalHours: interval,
        daysDuration: daysDuration,
        alarmEnabled: _alarmEnabled,
        assignedByAdminId: adminUser.uid,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Jadwal obat berhasil disimpan!",
            style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold),
          ),
          duration: Duration(seconds: 3),
        ),
      );

      _formKey.currentState?.reset();
      _nameController.clear();
      _doseController.clear();
      _amountController.clear();
      _firstTimeController.clear();
      _timesPerDayController.clear();
      _daysController.clear();
      setState(() {
        _selectedType = null;
        _selectedInterval = null;
        _customInterval = null;
        _alarmEnabled = false;
        _selectedPasienUid = null; // Reset pasien yang dipilih
      });
    } catch (e) {
      print("Error saving medication: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Gagal menyimpan jadwal obat: ${e.toString()}",
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.bold,
            ),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tambah Jadwal Obat',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0072CE),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 48,
              height: 48,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
                child: const Icon(
                  Icons.arrow_back,
                  size: 24,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pilih Pasien
              const Text(
                "Pilih Pasien*",
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              _isLoadingPasien
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      hintText: "Pilih Pasien (ID & Nama)",
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF0072CE)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    value: _selectedPasienUid,
                    items:
                        _verifiedPasienList.map<DropdownMenuItem<String>>((
                          pasien,
                        ) {
                          return DropdownMenuItem<String>(
                            value: pasien['uid'] as String,
                            child: Text(
                              "${pasien['username']} (${(pasien['uid'] as String).substring(0, 7).toUpperCase()})",
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPasienUid = value;
                      });
                    },
                    validator:
                        (value) => value == null ? 'Wajib dipilih' : null,
                  ),
              const SizedBox(height: 16),

              // Nama Obat
              const Text(
                "Nama Obat*",
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: "Nama (contoh: Rifampicin)",
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF0072CE)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Tipe Obat
              const Text(
                "Tipe*",
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF0072CE)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                value: _selectedType,
                hint: const Text("Pilih Opsi"),
                items:
                    _typeOptions.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
                validator: (value) => value == null ? 'Wajib dipilih' : null,
              ),
              const SizedBox(height: 16),

              // Dosis
              const Text(
                "Dosis*",
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _doseController,
                decoration: InputDecoration(
                  hintText: "Dosis (contoh: 100mg)",
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF0072CE)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Jumlah
              const Text(
                "Jumlah (total untuk durasi pengobatan)*", // Label yang lebih jelas
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Jumlah obat (contoh: 30 untuk 30 pil/kapsul)",
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF0072CE)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Wajib diisi';
                  if (int.tryParse(value) == null)
                    return 'Harap masukkan angka';
                  if (int.parse(value) <= 0) return 'Jumlah harus lebih dari 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Pengingat - Waktu Minum Obat
              const Text(
                "Waktu Dosis Pertama*", // Label lebih spesifik
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller:
                    _firstTimeController, // Ganti ke _firstTimeController
                decoration: InputDecoration(
                  hintText: "Pilih waktu (contoh: 08:00 AM)",
                  prefixIcon: const Icon(Icons.access_time),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF0072CE)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                readOnly: true,
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                    builder: (BuildContext context, Widget? child) {
                      return MediaQuery(
                        data: MediaQuery.of(
                          context,
                        ).copyWith(alwaysUse24HourFormat: false),
                        child: child!,
                      );
                    },
                  );

                  if (pickedTime != null) {
                    setState(() {
                      _firstTimeController.text = pickedTime.format(context);
                    });
                  }
                },
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Frekuensi Minum per Hari
              const Text(
                "Jumlah Dosis per Hari*", // Label lebih jelas
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _timesPerDayController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Jumlah (contoh: 3)",
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF0072CE)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Wajib diisi';
                        if (int.tryParse(value) == null)
                          return 'Harap masukkan angka';
                        if (int.parse(value) <= 0)
                          return 'Jumlah harus lebih dari 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: _selectedInterval,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF0072CE)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      hint: const Text("Interval Waktu"),
                      items: [
                        const DropdownMenuItem(
                          value: "24", // Setiap 24 jam untuk 1x sehari
                          child: Text("Setiap 24 jam (1x sehari)"),
                        ),
                        const DropdownMenuItem(
                          value: "12",
                          child: Text("Setiap 12 jam (2x sehari)"),
                        ),
                        const DropdownMenuItem(
                          value: "8",
                          child: Text("Setiap 8 jam (3x sehari)"),
                        ),
                        const DropdownMenuItem(
                          value: "6",
                          child: Text("Setiap 6 jam (4x sehari)"),
                        ),
                        const DropdownMenuItem(
                          value: "custom",
                          child: Text("Custom"),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedInterval = value;
                          if (value == "custom") {
                            _showCustomIntervalDialog(context);
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null) return 'Wajib dipilih';
                        if (value == "custom" &&
                            (_customInterval == null ||
                                int.tryParse(_customInterval!) == 0)) {
                          return 'Harap masukkan interval custom';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Lama Pengobatan (hari)
              const Text(
                "Lama Pengobatan (hari)*",
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _daysController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Durasi (contoh: 30 hari)",
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF0072CE)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Wajib diisi';
                  if (int.tryParse(value) == null)
                    return 'Harap masukkan angka';
                  if (int.parse(value) <= 0) return 'Durasi harus lebih dari 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Switch Alarm
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Hidupkan Alarm",
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Switch(
                    value: _alarmEnabled,
                    onChanged: (val) {
                      setState(() {
                        _alarmEnabled = val;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _showConfirmationDialog(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Harap lengkapi semua field yang wajib diisi.",
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0072CE),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 105.5,
                      vertical: 19,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Simpan',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
