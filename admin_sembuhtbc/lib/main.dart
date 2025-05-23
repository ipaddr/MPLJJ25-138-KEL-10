import 'package:flutter/material.dart';
import 'package:admin_sembuhtbc/manage_med.dart';
import 'package:admin_sembuhtbc/welcome_admin_screen.dart';
import 'package:admin_sembuhtbc/login_screen.dart';
import 'package:admin_sembuhtbc/homepage.dart';
import 'package:admin_sembuhtbc/profile_admin.dart';
import 'firebase_options.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:admin_sembuhtbc/verif_acc.dart';
import 'package:admin_sembuhtbc/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      ),
      home: const AuthWrapper(), // Gunakan AuthWrapper sebagai home
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomePage(),
        '/manage': (context) => const ManageMedPage(),
        '/profile': (context) => const ProfileAdminPage(),
        '/verify': (context) => const VerifikasiPasienScreen(),
      },
    );
  }
}

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
    // Listen to authentication state changes
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<User?>(
      stream: _authService.userStream,
      builder: (context, snapshot) {
        // Jika sedang loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Jika sudah memiliki data
        if (snapshot.hasData) {
          final user = snapshot.data;
          if (user != null) {
            // User sudah login, arahkan ke HomePage
            return const HomePage();
          }
        }

        // User belum login, arahkan ke WelcomeAdminScreen
        return const WelcomeAdminScreen();
      },
    );
  }
}
