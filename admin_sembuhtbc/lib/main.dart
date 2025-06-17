import 'package:flutter/material.dart';
import 'package:admin_sembuhtbc/manage_med.dart';
import 'package:admin_sembuhtbc/welcome_admin_screen.dart';
import 'package:admin_sembuhtbc/login_screen.dart';
import 'package:admin_sembuhtbc/homepage.dart';
import 'package:admin_sembuhtbc/profile_admin.dart';
import 'package:admin_sembuhtbc/looking_user.dart';
import 'firebase_options.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:admin_sembuhtbc/verif_acc.dart';
import 'package:admin_sembuhtbc/auth_service.dart';

// Import wajib untuk inisialisasi lokalisasi
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  // Urutan ini sudah benar dan harus seperti ini
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Baris kunci untuk memperbaiki error
  await initializeDateFormatting('id_ID', null);

  // Tambahkan print untuk verifikasi di konsol debug
  print("--- INISIALISASI LOKALISASI 'id_ID' SELESAI. APLIKASI SIAP. ---");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SembuhTBC Admin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 255, 255, 255),
        ),
        useMaterial3: true,
        fontFamily: 'Urbanist',
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomePage(),
        '/manage': (context) => const ManageMedPage(),
        '/profile': (context) => const ProfileAdminPage(),
        '/verify': (context) => const VerifikasiPasienScreen(),
        '/looking-user': (context) => const LookingUserPage(),
      },
    );
  }
}

// Class AuthWrapper tidak perlu diubah, biarkan seperti adanya
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _authSubscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authSubscription = _authService.userStream.listen((user) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<User?>(
      stream: _authService.userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomePage();
        }

        return const WelcomeAdminScreen();
      },
    );
  }
}
