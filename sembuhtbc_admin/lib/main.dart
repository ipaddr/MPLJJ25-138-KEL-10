import 'package:flutter/material.dart';
import 'package:sembuhtbc_admin/manage_med.dart';
import 'package:sembuhtbc_admin/welcome_admin_screen.dart';
import 'package:sembuhtbc_admin/login_screen.dart';
import 'package:sembuhtbc_admin/homepage.dart';
import 'package:sembuhtbc_admin/profile_admin.dart';
//import 'firebase_options.dart';
//import 'package:firebase_core/firebase_core.dart';
//import 'package:firebase_auth/firebase_auth.dart';
//import 'dart:developer' as devtools show log;
import 'package:sembuhtbc_admin/verif_acc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //  try {
  //    await Firebase.initializeApp(
  //      options: DefaultFirebaseOptions.currentPlatform,
  //    );
  //    devtools.log('Firebase initialized successfully');
  //  } catch (e) {
  //    devtools.log('Error initializing Firebase: $e');
  //  }

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
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeAdminScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomePage(),
        '/manage': (context) => const ManageMedPage(),
        '/profile': (context) => const ProfileAdminPage(),
        '/verify': (context) => const VerifikasiPasienScreen(),
      },
    );
  }
}
