import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'home_page.dart';

class ProfileUserPage extends StatefulWidget {
  const ProfileUserPage({super.key});

  @override
  State<ProfileUserPage> createState() => _ProfileUserPageState();
}

class _ProfileUserPageState extends State<ProfileUserPage> {
  final TextEditingController _nameController =
      TextEditingController(text: "Erna Suriana");
  final TextEditingController _emailController =
      TextEditingController(text: "ErnaSuriana@sembuhtbc.id");
  final TextEditingController _passwordController =
      TextEditingController(text: "12345678");
  final TextEditingController _genderController =
      TextEditingController(text: "Perempuan");
  final TextEditingController _dobController =
      TextEditingController(text: "09/01/2000");

  bool _isPasswordVisible = false;
  bool _isEditMode = false;
  DateTime? _selectedDate;
  File? _profileImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000, 1, 9),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  void _toggleEditMode() {
    setState(() => _isEditMode = !_isEditMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: const Icon(Icons.arrow_back, color: Colors.black),
          ),
        ),
        elevation: 0,
        title: const Text(
          'Profil Admin',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0072CE),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 70,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : const AssetImage("assets/images/avatar.png")
                          as ImageProvider,
                ),
                if (_isEditMode)
                  GestureDetector(
                    onTap: _pickImage,
                    child: const CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.edit, color: Colors.black, size: 16),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text("Sisil Hasibuan, S.Kep",
                style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const Text("ID: ADM1234",
                style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            const SizedBox(height: 8),

            // Nama
            buildLabel("Nama"),
            buildTextField(_nameController),

            // Email
            buildLabel("Email"),
            buildTextField(_emailController),

            // Sandi
            buildLabel("Sandi"),
            _isEditMode
                ? buildTextField(_passwordController)
                : Row(
                    children: [
                      Expanded(
                          child: TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        enabled: false,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      )),
                      IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                      )
                    ],
                  ),

            // Jenis Kelamin
            buildLabel("Jenis Kelamin"),
            DropdownButtonFormField<String>(
              value: _genderController.text,
              items: ["Laki-laki", "Perempuan"]
                  .map((gender) => DropdownMenuItem(
                        value: gender,
                        child: Text(gender),
                      ))
                  .toList(),
              onChanged: _isEditMode
                  ? (value) {
                      if (value != null) {
                        setState(() => _genderController.text = value);
                      }
                    }
                  : null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            // Tanggal Lahir
            buildLabel("Tanggal Lahir"),
            TextFormField(
              controller: _dobController,
              readOnly: true,
              onTap: _isEditMode ? () => _selectDate(context) : null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            if (_isEditMode)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _toggleEditMode();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Perubahan disimpan")));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0072CE),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    "Simpan",
                    style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            TextButton(
              onPressed: _toggleEditMode,
              child: Text(
                _isEditMode ? "Batal Edit" : "Edit Profile",
                style: TextStyle(
                    fontSize: 16,
                    color: _isEditMode ? Colors.grey : Color(0xFF0072CE)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text(
                "Logout",
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Urbanist',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

  Widget buildTextField(TextEditingController controller) => TextFormField(
        controller: controller,
        enabled: _isEditMode,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      );
}
