import 'dart:io'; // Perlu jika Platform.isAndroid digunakan
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- PENTING: TAMBAHKAN IMPORT INI

// Autentikasi dan halaman awal
import 'pages/welcome_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/verify_code_page.dart';
import 'pages/new_password_page.dart';
import 'pages/password_success_page.dart';

// Home & Profile
import 'pages/home_page.dart';
import 'pages/profile_user.dart';

// Verifikasi & Foto Obat
import 'pages/med_info_page.dart';
import 'pages/verification_warning_page.dart';
import 'pages/waiting_verification_page.dart';
import 'pages/verification_success_page.dart';
import 'pages/verification_done_page.dart';
import 'pages/take_photo_page.dart';
import 'pages/waiting_photo_page.dart';
import 'pages/waiting_result_page.dart';
import 'pages/result_photo_page.dart';

// Reward
import 'pages/reward_page.dart';
import 'pages/reward_code_page.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('id_ID', null);
  Intl.defaultLocale = 'id_ID';

  // ✅ Inisialisasi Awesome Notifications
  await AwesomeNotifications().initialize(
    null, // default icon di Android (null atau path ke icon)
    [
      NotificationChannel(
        channelKey: 'reminder_channel',
        channelName: 'Pengingat Obat',
        channelDescription: 'Notifikasi pengingat minum obat harian',
        defaultColor: Colors.blue,
        importance: NotificationImportance.High,
        channelShowBadge: true,
        locked: true, // Notifikasi tidak bisa digeser atau dihapus oleh pengguna
        // playSound: true, // Sound diatur di sini
        // soundSource: 'resource://raw/res_custom_sound', // Untuk custom sound
      )
    ],
    debug: true, // Aktifkan debug log Awesome Notifications
  );

  // ✅ Minta izin notifikasi Android 13+ dan alarm
  if (Platform.isAndroid) {
    // Meminta izin notifikasi umum Awesome Notifications
    final notifPermission = await AwesomeNotifications().isNotificationAllowed();
    if (!notifPermission) {
      print('DEBUG: Meminta izin notifikasi umum Awesome Notifications.');
      await AwesomeNotifications().requestPermissionToSendNotifications();
    } else {
      print('DEBUG: Izin notifikasi umum Awesome Notifications sudah diberikan.');
    }

    // Meminta izin SCHEDULE_EXACT_ALARM menggunakan permission_handler
    final exactAlarm = await Permission.scheduleExactAlarm.status;
    if (!exactAlarm.isGranted) {
      print('DEBUG: Meminta izin SCHEDULE_EXACT_ALARM.');
      await Permission.scheduleExactAlarm.request();
    } else {
      print('DEBUG: Izin SCHEDULE_EXACT_ALARM sudah diberikan.');
    }
  }

  // ✅ Cek status login
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final String? userId = prefs.getString('userId'); // Ambil userId juga

  String initialRoute = '/'; // Default route

  if (isLoggedIn == true && userId != null) {
    // Jika sudah login, cek apakah token Firebase masih valid
    final user = FirebaseAuth.instance.currentUser; // <-- FirebaseAuth sudah diimport
    if (user != null && user.uid == userId) {
      initialRoute = '/home'; // User sudah login dan token valid
      print('DEBUG: Pengguna sudah login, masuk ke Home.');
    } else {
      // Jika token tidak valid (misal, user dihapus dari Firebase), hapus status login
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('userId');
      print('DEBUG: Token Firebase tidak valid, kembali ke Welcome.');
    }
  } else {
    print('DEBUG: Pengguna belum login, masuk ke Welcome.');
  }

  runApp(MyApp(initialRoute: initialRoute)); // Kirim initialRoute ke MyApp
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute}); // Konstruktor sudah benar

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SembuhTBC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Poppins'),
      initialRoute: initialRoute, // Gunakan initialRoute dari SharedPreferences
      routes: {
        '/': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/verify-code': (context) => const VerifyCodePage(),
        '/new-password': (context) => const NewPasswordPage(),
        '/password-success': (context) => const PasswordSuccessPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfileUserPage(),
        '/med-info': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return MedInfoPage(
            scheduleId: args['scheduleId'],
            name: args['name'],
            dose: args['dose'],
            medicineType: args['medicineType'],
            doseTime: args['doseTime'],
          );
        },
        '/verification-warning': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return VerificationWarningPage(
            scheduleId: args['scheduleId'],
            doseTime: args['doseTime'],
          );
        },
        '/waiting-verification': (context) => const WaitingVerificationPage(),
        '/verification-success': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return VerificationSuccessPage(
            isSuccess: args?['isSuccess'] ?? true,
            message: args?['message'] ?? "Akun Anda telah berhasil diverifikasi oleh admin.",
          );
        },
        '/verif-done': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return VerificationDonePage(
            scheduleId: args?['scheduleId'] ?? '',
            doseTime: args?['doseTime'] ?? '',
          );
        },
        '/take-photo': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return TakePhotoPage(
            scheduleId: args['scheduleId'],
            doseTime: args['doseTime'],
          );
        },
        '/waiting-photo': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return WaitingResultPage(
            scheduleId: args['scheduleId'],
            doseTime: args['doseTime'],
            imagePath: args['imagePath'],
          );
        },
        '/result-photo': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ResultPhotoPage(
            scheduleId: args['scheduleId'],
            doseTime: args['doseTime'],
            isPhotoVerified: args['isPhotoVerified'],
            imagePath: args['imagePath'],
          );
        },
        '/reward': (context) => const RewardPage(),
        '/reward-code': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return RewardCodePage(rewardKey: args['rewardKey']);
        },
      },
    );
  }
}