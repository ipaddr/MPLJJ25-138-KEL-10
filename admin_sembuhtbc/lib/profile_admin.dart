import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'auth_service.dart';
import 'dart:io';

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
    text: "********",
  );
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isEditMode = false;
  bool _isLoading = true;
  bool _isUploading = false;
  DateTime? _selectedDate;
  File? _profileImage;
  String? _profileImageUrl;
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

        _profileImageUrl = profileData['profilePictureUrl'];
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

  Future<String?> _uploadImage() async {
    if (_profileImage == null) return _profileImageUrl;
    if (_userId == null) return null;

    try {
      setState(() {
        _isUploading = true;
      });

      // Validasi file gambar
      if (!await _profileImage!.exists()) {
        throw Exception("File gambar tidak ditemukan");
      }

      // Buat reference ke Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$_userId.jpg');

      // Upload file dengan metadata
      await storageRef.putFile(
        _profileImage!,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Dapatkan download URL
      String downloadUrl = await storageRef.getDownloadURL();
      print('Berhasil upload gambar. URL: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal mengupload gambar: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    } finally {
      setState(() {
        _isUploading = false;
      });
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
    });
  }

  Future<void> _saveProfile() async {
    if (_userId == null || _selectedDate == null) return;

    FocusScope.of(context).unfocus(); // Tutup keyboard

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload gambar jika ada perubahan
      String? newImageUrl = await _uploadImage();
      String finalImageUrl = newImageUrl ?? _profileImageUrl ?? '';

      // Simpan ke Firestore
      await _authService.updateAdminProfile(
        uid: _userId!,
        username: _nameController.text,
        gender: _genderController.text,
        birthDate: _selectedDate!,
        profilePictureUrl: finalImageUrl,
      );

      // Update state
      setState(() {
        _profileImageUrl = finalImageUrl;
        _profileImage = null; // Reset image file setelah upload
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

                // Avatar & Nama
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

                // Form fields
                _buildFormFields(),

                const SizedBox(height: 20),
              ],
            ),
          ),

          if (_isUploading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (_profileImage != null) {
      return FileImage(_profileImage!);
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return NetworkImage(_profileImageUrl!);
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

        // Tombol Aksi
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Sandi",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                enabled: false,
                style: const TextStyle(fontSize: 15, color: Colors.grey),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 16,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ],
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
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        TextButton(
          onPressed: _toggleEditMode,
          child: Text(
            _isEditMode ? "Batal Edit" : "Edit Profil",
            style: TextStyle(
              color: _isEditMode ? Colors.grey : const Color(0xFF0072CE),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 12),

        TextButton(
          onPressed: () {
            _authService.signOut();
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: const Text(
            "Keluar",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
