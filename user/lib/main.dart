import 'package:flutter/material.dart';
import 'pages/welcome_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/google_signin_page.dart';
import 'pages/waiting_verification_page.dart';
import 'pages/verification_success_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/verify_code_page.dart';
import 'pages/new_password_page.dart';
import 'pages/password_success_page.dart';
import 'pages/home_page.dart';
import 'pages/verification_warning_page.dart';
import 'pages/take_photo_page.dart';
import 'pages/waiting_photo_page.dart';
import 'pages/result_photo_page.dart';
import 'pages/waiting_result_page.dart';
import 'pages/verification_done_page.dart';
import 'pages/reward_page.dart';
import 'pages/reward_code_page.dart';
import 'pages/reward_claimed_page.dart';

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
        '/waiting-verification': (context) => const WaitingVerificationPage(),
        '/verification-success': (context) => const VerificationSuccessPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/verify-code': (context) => const VerifyCodePage(),
        '/new-password': (context) => const NewPasswordPage(),
        '/password-success': (context) => const PasswordSuccessPage(),
        '/home': (context) => const HomePage(),
        '/verification-warning': (context) => const VerificationWarningPage(),
        '/take-photo': (context) => const TakePhotoPage(),
        '/waiting-photo': (context) => const WaitingPhotoPage(),
        '/result-photo': (context) => const ResultPhotoPage(),
        '/waiting-result': (context) => const WaitingResultPage(),
        '/verif-done': (context) => const VerificationDonePage(),
        '/reward': (context) => const RewardPage(),
        '/reward-code': (context) => const RewardCodePage(),
        '/reward-claimed': (context) => const RewardClaimedPage(),
      },
    );
  }
}
