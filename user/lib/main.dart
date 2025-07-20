import 'dart:io'; // Perlu jika Platform.isAndroid digunakan
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Notification related imports
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz; // Perhatikan as tz
import 'package:timezone/timezone.dart' as tz; // Perhatikan as tz
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
// import 'package:flutter_native_timezone/flutter_native_timezone.dart'; // <-- Baris ini Dihapus/Dikomentari

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

// Global instance for notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void onDidReceiveLocalNotification(
  int id,
  String? title,
  String? body,
  String? payload,
) async {
  debugPrint(
    'onDidReceiveLocalNotification: id=$id, title=$title, body=$body, payload=$payload',
  );
  // Di sini Anda bisa menampilkan dialog atau menavigasi jika aplikasi di latar depan (iOS < 10)
}

// Fungsi untuk membuat notifikasi channel (PENTING untuk Android 8.0+)
Future<void> _createNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'reminder_channel', // id: HARUS sama dengan id channel di AndroidNotificationDetails
    'Pengingat Obat', // name: Nama yang terlihat oleh pengguna di pengaturan notifikasi
    description:
        'Channel untuk notifikasi pengingat minum obat Anda', // deskripsi
    importance: Importance.max, // Pentingnya notifikasi (seperti Urgent)
    playSound: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
  print('DEBUG: Notifikasi channel "reminder_channel" dibuat/diverifikasi.');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inisialisasi data simbol lokal untuk intl (penting untuk format tanggal/waktu di berbagai bahasa)
  await initializeDateFormatting('id_ID', null);

  // --- Inisialisasi Timezone ---
  tz.initializeTimeZones(); // Menginisialisasi database zona waktu
  // Karena flutter_native_timezone dihapus, kita set zona waktu secara manual.
  // Ini mengasumsikan semua pengguna berada di zona waktu yang sama (mis. Jakarta).
  tz.setLocalLocation(
    tz.getLocation('Asia/Jakarta'),
  ); // <-- ATUR SECARA MANUAL ZONA WAKTU DEFAULT
  print('DEBUG: Zona waktu lokal diatur secara manual ke: Asia/Jakarta');
  // --- Akhir Inisialisasi Timezone ---

  // --- Inisialisasi FlutterLocalNotificationsPlugin ---
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      ); // Pastikan ini ikon yang benar

  final DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        // onDidReceiveLocalNotification sudah dihapus di versi 16+
        // onDidReceiveLocalNotification: onDidReceiveLocalNotification,
      );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      debugPrint(
        'onDidReceiveNotificationResponse: payload: ${response.payload}',
      );
      // Di sini Anda bisa menambahkan logika untuk menavigasi ke halaman tertentu
      // berdasarkan `response.payload` jika notifikasi di-tap.
    },
    // Jika Anda ingin menangani tap notifikasi saat aplikasi terminated/background,
    // Anda perlu `onDidReceiveBackgroundNotificationResponse` dan fungsi top-level lainnya.
    // @pragma('vm:entry-point')
    // static void notificationTapBackground(NotificationResponse notificationResponse) { ... }
    //onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );
  // --- Akhir Inisialisasi FlutterLocalNotificationsPlugin ---

  // PENTING: Panggil fungsi untuk membuat/memverifikasi channel notifikasi
  await _createNotificationChannel(); // <-- PANGGILAN INI DITAMBAHKAN

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute}); // Konstruktor sudah benar

  @override
  Widget build(BuildContext context) {
    // Setting defaultLocale di sini juga tidak masalah, tapi pastikan juga
    // initializeDateFormatting('id_ID', null); sudah dipanggil sebelum runApp.
    Intl.defaultLocale = 'id_ID';

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