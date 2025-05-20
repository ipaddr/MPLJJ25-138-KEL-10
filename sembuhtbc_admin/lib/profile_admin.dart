import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileAdminPage extends StatefulWidget {
  const ProfileAdminPage({super.key});

  @override
  State<ProfileAdminPage> createState() => _ProfileAdminPageState();
}

class _ProfileAdminPageState extends State<ProfileAdminPage> {
  final TextEditingController _nameController = TextEditingController(
    text: "Sisil Hasibuan, S.Kep",
  );
  final TextEditingController _emailController = TextEditingController(
    text: "admin.sisilhsb@sembuhtbc.id",
  );
  final TextEditingController _passwordController = TextEditingController(
    text: "12345678",
  );
  final TextEditingController _genderController = TextEditingController(
    text: "Perempuan",
  );
  final TextEditingController _dobController = TextEditingController(
    text: "09/01/2000",
  );

  bool _isPasswordVisible = false;
  bool _isEditMode = false;
  DateTime? _selectedDate;
  File? _profileImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000, 1, 9),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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

            // Avatar & Nama
            Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundImage:
                          _profileImage != null
                              ? FileImage(_profileImage!)
                              : const AssetImage("assets/images/avatar.png")
                                  as ImageProvider,
                      backgroundColor: Colors.grey,
                    ),
                    if (_isEditMode)
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.edit,
                            color: Colors.black,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  "Sisil Hasibuan, S.Kep",
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "ID: ADM1234",
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Nama
            buildLabel("Nama"),
            TextFormField(
              controller: _nameController,
              enabled: _isEditMode,
              style: TextStyle(
                fontFamily: 'Urbanist',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _isEditMode ? Colors.black : Colors.black,
              ),
              decoration: InputDecoration(
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 16,
                ),
              ),
            ),

            // Email
            buildLabel("Email"),
            TextFormField(
              controller: _emailController,
              enabled: _isEditMode,
              style: TextStyle(
                fontFamily: 'Urbanist',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _isEditMode ? Colors.black : Colors.black,
              ),
              decoration: InputDecoration(
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 16,
                ),
              ),
            ),

            // Sandi
            buildLabel("Sandi"),
            _isEditMode
                ? TextFormField(
                  controller: _passwordController,
                  obscureText: false, // Always show password in edit mode
                  style: const TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                )
                : Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        enabled: false,
                        style: const TextStyle(
                          fontFamily: 'Urbanist',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ],
                ),

            // Jenis Kelamin
            buildLabel("Jenis Kelamin"),
            AbsorbPointer(
              absorbing:
                  !_isEditMode, // Blocks all interactions when not in edit mode
              child: DropdownButtonFormField<String>(
                value: _genderController.text,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _isEditMode ? Colors.black : Colors.grey,
                      width: 1.0,
                    ),
                  ),

                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 16,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: _isEditMode ? Colors.white : Colors.white,
                ),
                dropdownColor: Colors.white,
                style: TextStyle(
                  fontFamily: 'Urbanist',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color:
                      _isEditMode
                          ? Colors.black
                          : Colors
                              .grey[600], // Darker grey for better readability
                ),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: _isEditMode ? Colors.grey : Colors.grey[400],
                ),
                iconSize: 24,
                items:
                    ["Laki-laki", "Perempuan"]
                        .map(
                          (gender) => DropdownMenuItem<String>(
                            value: gender,
                            child: Text(
                              gender,
                              style: const TextStyle(
                                fontFamily: 'Urbanist',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                onChanged:
                    _isEditMode
                        ? (value) {
                          setState(() {
                            _genderController.text = value!;
                          });
                        }
                        : null,
              ),
            ),

            // Tanggal Lahir
            buildLabel("Tanggal Lahir"),
            AbsorbPointer(
              absorbing:
                  !_isEditMode, // Will block all interactions when not in edit mode
              child: TextFormField(
                controller: _dobController,
                style: const TextStyle(
                  fontFamily: 'Urbanist',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  suffixIcon: Icon(
                    Icons.calendar_today,
                    color: _isEditMode ? Colors.grey : Colors.grey,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                readOnly: true,
                enableInteractiveSelection:
                    _isEditMode, // Disable text selection when not in edit mode
                onTap: _isEditMode ? () => _selectDate(context) : null,
              ),
            ),

            if (_isEditMode) ...[
              const SizedBox(height: 24),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _toggleEditMode();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Perubahan disimpan")),
                    );
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
                    "Simpan",
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

            const SizedBox(height: 16),

            // Edit Profile Button
            TextButton(
              onPressed: _toggleEditMode,
              child: Text(
                _isEditMode ? "Batal Edit" : "Edit Profile",
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  color: _isEditMode ? Colors.grey : const Color(0xFF0072CE),
                ),
              ),
            ),

            // Logout
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text(
                "Logout",
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Urbanist',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget buildTextField(
    TextEditingController controller, {
    bool isEditable = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: isEditable,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      ),
    );
  }
}
