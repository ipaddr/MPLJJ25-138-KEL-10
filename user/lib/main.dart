import 'package:flutter/material.dart';

// Autentikasi dan halaman awal
import 'pages/welcome_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/google_signin_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/verify_code_page.dart';
import 'pages/new_password_page.dart';
import 'pages/password_success_page.dart';

// Home & Profile
import 'pages/home_page.dart';
import 'pages/profile_user.dart';

// Verifikasi & Foto
import 'pages/verification_warning_page.dart';
import 'pages/waiting_verification_page.dart';
import 'pages/verification_success_page.dart';
import 'pages/verification_done_page.dart';
import 'pages/take_photo_page.dart';
import 'pages/waiting_photo_page.dart';
import 'pages/result_photo_page.dart';
import 'pages/waiting_result_page.dart';

// Reward (mengikuti nama file yg kamu pakai: kapital di tengah)
import 'pages/Reward_Page.dart';
import 'pages/Reward_Code_Page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SembuhTBC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/signin-google': (context) => const GoogleSignInPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/verify-code': (context) => const VerifyCodePage(),
        '/new-password': (context) => const NewPasswordPage(),
        '/password-success': (context) => const PasswordSuccessPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfileUserPage(),
        '/verification-warning': (context) => const VerificationWarningPage(),
        '/waiting-verification': (context) => const WaitingVerificationPage(),
        '/verification-success': (context) => const VerificationSuccessPage(),
        '/verif-done': (context) => const VerificationDonePage(),
        '/take-photo': (context) => const TakePhotoPage(),
        '/waiting-photo': (context) => const WaitingPhotoPage(),
        '/result-photo': (context) => const ResultPhotoPage(),
        '/waiting-result': (context) => const WaitingResultPage(),
        '/reward': (context) => const RewardPage(),
        '/reward-code': (context) => const RewardCodePage(),
      },
    );
  }
}
