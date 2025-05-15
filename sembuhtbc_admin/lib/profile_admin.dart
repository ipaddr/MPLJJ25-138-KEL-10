import 'package:flutter/material.dart';

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
    text: "9 Januari 2000",
  );

  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
        elevation: 0,
        title: const Text(
          'Profil Admin',
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
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
                    const CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage(
                        "assets/images/avatar.png",
                      ), // Ganti sesuai gambar kamu
                      backgroundColor: Colors.grey,
                    ),
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.edit, color: Colors.black, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  "Sisil Hasibuan, S.Kep",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text("ID: ADM1234", style: TextStyle(color: Colors.grey)),
              ],
            ),

            const SizedBox(height: 24),

            // Nama
            buildLabel("Nama"),
            buildTextField(_nameController),

            // Email
            buildLabel("Email"),
            buildTextField(_emailController),

            // Sandi
            buildLabel("Sandi"),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Jenis Kelamin
            buildLabel("Jenis Kelamin"),
            buildTextField(_genderController),

            // Tanggal Lahir
            buildLabel("Tanggal Lahir"),
            buildTextField(_dobController),

            const SizedBox(height: 24),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Perubahan disimpan")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Simpan",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Logout
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text("Logout", style: TextStyle(color: Colors.red)),
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
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(border: OutlineInputBorder()),
    );
  }
}
