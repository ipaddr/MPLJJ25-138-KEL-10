import 'package:flutter/material.dart';
import 'package:admin_sembuhtbc/homepage.dart';
import 'package:admin_sembuhtbc/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscureText = true;
  bool _isLoading = false;
  bool _isCheckingAuth = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    _authSubscription = _authService.userStream.listen(
      (user) {
        if (user != null && mounted) {
          _navigateToHome();
        } else if (mounted) {
          setState(() => _isCheckingAuth = false);
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isCheckingAuth = false);
          _showErrorSnackBar('Gagal memeriksa status autentikasi');
        }
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  void _showSnackBar({
    required String message,
    required Color backgroundColor,
    int durationSeconds = 3,
  }) {
    if (!mounted) return;

    // Clear any existing snackbars first
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: durationSeconds),
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

  void _showErrorSnackBar(String message) {
    _showSnackBar(message: message, backgroundColor: Colors.red);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _login() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Harap perbaiki input yang salah');
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Clear any existing errors
      ScaffoldMessenger.of(context).clearSnackBars();

      await _authService.signInWithEmailAndPassword(email, password);
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase errors
      final message = _handleFirebaseError(e);
      _showErrorSnackBar(message);
    } catch (e) {
      // Handle generic errors
      _showErrorSnackBar('Terjadi kesalahan: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        return 'Terjadi kesalahan: ${e.message ?? 'Silakan coba lagi'}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
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
                _buildWelcomeText(),
                const SizedBox(height: 30),
                _buildEmailField(),
                const SizedBox(height: 20),
                _buildPasswordField(),
                const SizedBox(height: 40),
                _buildLoginButton(),
              ],
            ),
          ),
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
              side: BorderSide(
                color: Colors.grey[300] ?? Colors.grey,
                width: 1,
              ),
            ),
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          child: const Icon(Icons.arrow_back, size: 24, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildEmailField() {
    return SizedBox(
      width: 327,
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(fontFamily: 'Urbanist', fontSize: 15),
        decoration: InputDecoration(
          labelText: 'Masukkan email Anda',
          labelStyle: const TextStyle(
            fontFamily: 'Urbanist',
            color: Color.fromARGB(255, 128, 128, 128),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Email harus diisi';
          }
          if (!_isValidEmail(value)) {
            return 'Masukkan email yang valid';
          }
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
        obscureText: _obscureText,
        style: const TextStyle(fontFamily: 'Urbanist', fontSize: 15),
        decoration: InputDecoration(
          labelText: 'Masukkan sandi Anda',
          labelStyle: const TextStyle(
            fontFamily: 'Urbanist',
            color: Color.fromARGB(255, 128, 128, 128),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: () {
              if (mounted) {
                setState(() => _obscureText = !_obscureText);
              }
            },
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Password harus diisi';
          }
          if (value.length < 6) {
            return 'Password minimal 6 karakter';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: 327,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0072CE),
          padding: const EdgeInsets.symmetric(horizontal: 105.5, vertical: 19),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child:
            _isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Text(
                  'Login',
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
      ),
    );
  }
}
