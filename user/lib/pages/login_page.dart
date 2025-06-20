import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _saveLoginStatus(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userId', uid);
    debugPrint('DEBUG: Login berhasil, UID disimpan: $uid');
  }

  Future<void> _clearLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userId');
    debugPrint('DEBUG: Status login dibersihkan dari SharedPreferences');
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Harap perbaiki input yang salah', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final credential = await AuthService.signInWithEmail(email, password);
      final user = credential?.user;

      if (user == null) throw Exception('Gagal mendapatkan user.');

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        throw Exception('User tidak ditemukan di Firestore.');
      }

      final isVerified = userDoc.data()?['isVerified'] == true;

      if (!isVerified) {
        _showSnackBar('Akun Anda belum diverifikasi oleh admin', Colors.orange);
        await _clearLoginStatus();
      } else {
        await _saveLoginStatus(user.uid);
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar('Login gagal: ${_handleFirebaseError(e)}', Colors.red);
      await _clearLoginStatus();
    } catch (e) {
      _showSnackBar('Login error: $e', Colors.red);
      await _clearLoginStatus();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _handleFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'user-disabled':
        return 'Akun ini dinonaktifkan';
      case 'user-not-found':
        return 'Email tidak terdaftar';
      case 'wrong-password':
        return 'Password salah';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan gagal. Coba lagi nanti';
      case 'network-request-failed':
        return 'Gagal terhubung ke jaringan';
      case 'invalid-credential':
        return 'Email atau password salah';
      default:
        return e.message ?? 'Terjadi kesalahan. Silakan coba lagi';
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Urbanist',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Tutup',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Align(
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
              side: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          child: const Icon(Icons.arrow_back, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return SizedBox(
      width: 327,
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: 'Masukkan email Anda',
          labelStyle: const TextStyle(fontFamily: 'Urbanist'),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Email harus diisi';
          if (!_isValidEmail(value)) return 'Masukkan email yang valid';
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField() {
    return SizedBox(
      width: 327,
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          labelText: 'Masukkan sandi Anda',
          labelStyle: const TextStyle(fontFamily: 'Urbanist'),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Password harus diisi';
          if (value.length < 6) return 'Password minimal 6 karakter';
          return null;
        },
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: 327,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0072CE),
          padding: const EdgeInsets.symmetric(vertical: 19),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'Login',
                style: TextStyle(fontFamily: 'Urbanist', fontSize: 16, color: Colors.white),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 20),
                _buildBackButton(),
                const SizedBox(height: 20),
                const Text(
                  'Selamat datang kembali!',
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0072CE),
                  ),
                ),
                const Text(
                  'Senang melihat Anda lagi!',
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0072CE),
                  ),
                ),
                const SizedBox(height: 30),
                _buildEmailField(),
                const SizedBox(height: 20),
                _buildPasswordField(),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                    child: const Text(
                      'Lupa Sandi?',
                      style: TextStyle(
                        fontFamily: 'Urbanist',
                        color: Color(0xFF0072CE),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildLoginButton(),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Belum memiliki akun?", style: TextStyle(fontFamily: 'Urbanist')),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/register'),
                      child: const Text(
                        "Daftar",
                        style: TextStyle(
                          fontFamily: 'Urbanist',
                          color: Color(0xFF0072CE),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
