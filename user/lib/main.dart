import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:user/pages/welcome_page.dart';
import 'package:user/pages/login_page.dart';
import 'package:user/pages/register_page.dart';
import 'firebase_options.dart'; // Jangan lupa generate dengan `flutterfire configure`

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SembuhTBCApp());
}

class SembuhTBCApp extends StatelessWidget {
  const SembuhTBCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SembuhTBC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
      },
    );
  }
}
