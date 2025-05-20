import 'package:flutter/material.dart';

class ManageMedPage extends StatefulWidget {
  const ManageMedPage({super.key});

  @override
  State<ManageMedPage> createState() => _ManageMedPageState();
}

class _ManageMedPageState extends State<ManageMedPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _doseController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _timesPerDayController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();

  String? _selectedType;
  String? _selectedInterval;
  String? _customInterval;
  bool _alarmEnabled = false;

  final List<String> _typeOptions = ['Tablet', 'Kapsul', 'Sirup', 'Injeksi'];

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _doseController.dispose();
    _amountController.dispose();
    _timeController.dispose();
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
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              TextButton(
                onPressed: () {
                  if (intervalController.text.isNotEmpty) {
                    setState(() {
                      _customInterval = intervalController.text;
                      _selectedInterval = "custom";
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text("Simpan"),
              ),
            ],
          ),
    );
  }

  Future<void> _showConfirmationDialog(BuildContext context) async {
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
                    "Konfirmasi Verifikasi",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0072CE),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Apakah Anda yakin ingin menyimpan jadwal obat untuk pasien dengan ID: ${_idController.text}?",
                    style: const TextStyle(fontSize: 16),
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

  void _saveMedication() {
    final timesPerDay = int.tryParse(_timesPerDayController.text) ?? 0;
    final days = int.tryParse(_daysController.text) ?? 0;
    final totalAmount = timesPerDay * days;

    String medicineUnit = '';
    switch (_selectedType) {
      case 'Tablet':
        medicineUnit = '$totalAmount x minum pil';
        break;
      case 'Kapsul':
        medicineUnit = '$totalAmount x minum kapsul';
        break;
      case 'Sirup':
        medicineUnit = '$totalAmount x sendok sirup';
        break;
      case 'Injeksi':
        medicineUnit = '$totalAmount x suntikan';
        break;
      default:
        medicineUnit = '$totalAmount x minum';
    }

    final interval =
        _selectedInterval == "custom"
            ? int.tryParse(_customInterval ?? "0") ?? 0
            : int.tryParse(_selectedInterval ?? "0") ?? 0;

    final doseTimes = _calculateDoseTimes(
      _timeController.text,
      timesPerDay,
      interval,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Jadwal obat berhasil disimpan",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("Total obat: $medicineUnit"),
            if (doseTimes.isNotEmpty)
              Text("Jadwal minum: ${doseTimes.join(', ')}"),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  List<String> _calculateDoseTimes(
    String firstDose,
    int timesPerDay,
    int intervalHours,
  ) {
    List<String> doseTimes = [];
    if (firstDose.isEmpty) return doseTimes;

    try {
      // Parse the time string correctly
      final timeParts = firstDose.split(RegExp(r'[: ]'));
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      final period = timeParts[2].toLowerCase();

      // Convert 12-hour format to 24-hour format
      if (period == 'pm' && hour != 12) {
        hour += 12;
      } else if (period == 'am' && hour == 12) {
        hour = 0;
      }

      for (int i = 0; i < timesPerDay; i++) {
        doseTimes.add(
          "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}",
        );
        hour += intervalHours;
        if (hour >= 24) {
          hour -= 24;
        }
      }
    } catch (e) {
      debugPrint("Error calculating dose times: $e");
    }

    return doseTimes;
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
              // ID Pasien
              const Text(
                "ID Pasien*",
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _idController,
                decoration: InputDecoration(
                  hintText: "ID (contoh: KJQ12A9)",
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
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
                  focusedBorder: OutlineInputBorder(
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
                  focusedBorder: OutlineInputBorder(
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
                  focusedBorder: OutlineInputBorder(
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
                "Jumlah*",
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
                  hintText: "Jumlah obat (contoh: 30 tablet)",
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
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

              // Pengingat - Waktu Minum Obat
              const Text(
                "Waktu Minum Obat*",
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _timeController,
                decoration: InputDecoration(
                  hintText: "Pilih waktu (contoh: 08:00)",
                  prefixIcon: const Icon(Icons.access_time),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
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
                  );

                  if (pickedTime != null) {
                    setState(() {
                      _timeController.text = pickedTime.format(context);
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
                "Berapa Kali Sehari*",
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
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF0072CE)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Wajib diisi'
                                  : null,
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
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF0072CE)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      hint: const Text("Interval Waktu"),
                      items: const [
                        DropdownMenuItem(
                          value: "4",
                          child: Text("Setiap 4 jam"),
                        ),
                        DropdownMenuItem(
                          value: "6",
                          child: Text("Setiap 6 jam"),
                        ),
                        DropdownMenuItem(
                          value: "8",
                          child: Text("Setiap 8 jam"),
                        ),
                        DropdownMenuItem(
                          value: "12",
                          child: Text("Setiap 12 jam"),
                        ),
                        DropdownMenuItem(
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
                      validator:
                          (value) => value == null ? 'Wajib dipilih' : null,
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
                  focusedBorder: OutlineInputBorder(
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
