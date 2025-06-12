import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

class ProfileAdminPage extends StatefulWidget {
  const ProfileAdminPage({super.key});

  @override
  State<ProfileAdminPage> createState() => _ProfileAdminPageState();
}

class _ProfileAdminPageState extends State<ProfileAdminPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(
    text: "********", // Default text for password field
  );
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isEditMode = false;
  bool _isLoading = true;
  DateTime? _selectedDate;
  File? _profileImage;
  String? _profileImageBase64;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    final user = _authService.getCurrentUser();
    if (user != null) {
      _userId = user.uid;
      _emailController.text = user.email ?? '';

      final profileData = await _authService.getAdminProfile(user.uid);
      if (profileData != null) {
        _nameController.text = profileData['username'] ?? '';
        _genderController.text = profileData['gender'] ?? 'Perempuan';

        if (profileData['birthDate'] != null) {
          _selectedDate = DateTime.parse(profileData['birthDate']);
          _dobController.text =
              "${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}";
        }

        _profileImageBase64 =
            profileData['profilePictureBase64']; // Ambil base64 dari Firestore
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal memilih gambar: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _convertImageToBase64() async {
    if (_profileImage == null)
      return _profileImageBase64; // Jika tidak ada gambar baru, gunakan yang lama

    try {
      List<int> imageBytes = await _profileImage!.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      print('Berhasil mengonversi gambar ke base64.');
      return base64Image;
    } catch (e) {
      print("Error converting image to base64: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal mengonversi gambar: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
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
      // Reset gambar jika batal edit
      if (!_isEditMode) {
        _profileImage = null;
      }
      // Reset password visibility saat mode edit diubah
      _isPasswordVisible = false;
    });
  }

  Future<void> _saveProfile() async {
    if (_userId == null || _selectedDate == null) return;

    FocusScope.of(context).unfocus(); // Tutup keyboard

    setState(() {
      _isLoading = true;
    });

    try {
      String? newImageBase64 = await _convertImageToBase64();
      String finalImageBase64 = newImageBase64 ?? _profileImageBase64 ?? '';

      await _authService.updateAdminProfile(
        uid: _userId!,
        username: _nameController.text,
        gender: _genderController.text,
        birthDate: _selectedDate!,
        profilePictureBase64: finalImageBase64, // Kirim base64 ke AuthService
      );

      setState(() {
        _profileImageBase64 = finalImageBase64;
        _profileImage = null; // Reset image file setelah konversi
        _isEditMode = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Profil berhasil diperbarui"),
        ),
      );
    } catch (e) {
      print("Error saving profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Gagal menyimpan perubahan: ${e.toString()}"),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fungsi untuk menampilkan dialog konfirmasi logout
  Future<void> _showLogoutConfirmation(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
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
                  "Konfirmasi Logout",
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0072CE),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Apakah Anda yakin ingin logout dari akun?",
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 15,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Batal",
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context); // Close dialog first
                        await _logout(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0072CE),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Logout",
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Fungsi untuk melakukan proses logout
  Future<void> _logout(BuildContext context) async {
    final authService = AuthService();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await authService.signOut();
      // Navigasi ke halaman login dan hapus semua rute sebelumnya
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/', // Asumsikan '/' adalah rute login Anda
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Logout gagal: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        title: const Text(
          'Profil Admin',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 24,
            color: Color(0xFF0072CE),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 70,
                          backgroundImage: _getProfileImage(),
                          backgroundColor: Colors.grey[200],
                        ),
                        if (_isEditMode)
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 20,
                                color: Colors.black,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _nameController.text,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "ID: ${_userId?.substring(0, 7).toUpperCase() ?? 'ADM0000'}",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildFormFields(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (_profileImage != null) {
      return FileImage(_profileImage!);
    } else if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
      try {
        List<int> imageBytes = base64Decode(_profileImageBase64!);
        return MemoryImage(Uint8List.fromList(imageBytes));
      } catch (e) {
        print("Error decoding base64 image: $e");
        return const AssetImage("assets/images/avatar.png");
      }
    }
    return const AssetImage("assets/images/avatar.png");
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField("Nama", _nameController, _isEditMode),
        const SizedBox(height: 16),
        _buildTextField("Email", _emailController, false, isEmail: true),
        const SizedBox(height: 16),
        _buildPasswordField(),
        const SizedBox(height: 16),
        _buildGenderField(),
        const SizedBox(height: 16),
        _buildDateField(),
        const SizedBox(height: 24),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool enabled, {
    bool isEmail = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType:
              isEmail ? TextInputType.emailAddress : TextInputType.text,
          style: TextStyle(
            fontSize: 15,
            color: enabled ? Colors.black : Colors.grey,
          ),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 16,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    // Note: It's not possible to retrieve the actual plain text password from Firebase for security reasons.
    // The password field will display "********" by default.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Sandi",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          enabled: false, // Password field should remain disabled
          style: const TextStyle(fontSize: 15, color: Colors.grey),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 16,
            ),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                  // If revealing, temporary clear the controller text to show nothing or allow input if enabled
                  // But since it's disabled, it will just toggle obscurity of "********"
                  if (_isPasswordVisible) {
                    _passwordController.text =
                        ""; // Clear to show empty or allow new input if enabled
                  } else {
                    _passwordController.text = "********"; // Revert to masked
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Jenis Kelamin",
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 6),
        AbsorbPointer(
          absorbing: !_isEditMode,
          child: DropdownButtonFormField<String>(
            value:
                _genderController.text.isNotEmpty
                    ? _genderController.text
                    : 'Perempuan',
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 16,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            items:
                ["Laki-laki", "Perempuan"].map((gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
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
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tanggal Lahir",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 6),
        AbsorbPointer(
          absorbing: !_isEditMode,
          child: TextFormField(
            controller: _dobController,
            style: TextStyle(
              fontSize: 15,
              color: _isEditMode ? Colors.black : Colors.grey,
            ),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.calendar_today),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 16,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            readOnly: true,
            onTap: _isEditMode ? () => _selectDate(context) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_isEditMode) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0072CE),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Simpan Perubahan",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _toggleEditMode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey, // Abu-abu
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Batal Edit",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _toggleEditMode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0072CE), // Biru
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Edit Profil",
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
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            // Memanggil dialog konfirmasi logout
            onPressed: () => _showLogoutConfirmation(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, // Merah
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Logout",
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
    );
  }
}
