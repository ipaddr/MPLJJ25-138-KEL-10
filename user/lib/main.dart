import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Notification related imports
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz; // Perhatikan as tz
import 'package:timezone/timezone.dart' as tz; // Perhatikan as tz
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart'; // ← Tambahan
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

// Global instance untuk notifikasi
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void onDidReceiveLocalNotification(
  int id,
  String? title,
  String? body,
  String? payload,
) async {
  debugPrint('LocalNotification: $title - $body');
}

/// Membuat notification channel di Android (WAJIB untuk Android 8+)
Future<void> _createNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'reminder_channel',
    'Pengingat Obat',
    description: 'Channel untuk notifikasi pengingat minum obat Anda',
    importance: Importance.max,
    playSound: true,
  );

  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.createNotificationChannel(channel);

  print('DEBUG: Channel "reminder_channel" berhasil dibuat/ada.');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('id_ID', null);
  Intl.defaultLocale = 'id_ID';

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
  print('DEBUG: Zona waktu lokal diatur ke Asia/Jakarta');

  // ✅ Minta izin notifikasi (wajib Android 13+)
  if (Platform.isAndroid) {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      final result = await Permission.notification.request();
      print('DEBUG: Izin notifikasi diberikan? ${result.isGranted}');
    }
  }

  // ✅ Inisialisasi notifikasi (Android & iOS)
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  final iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  final initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      debugPrint('Notifikasi ditekan! Payload: ${response.payload}');
    },
  );

  // ✅ Buat notification channel
  await _createNotificationChannel();

  // ✅ Ambil status login
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // ✅ Jalankan aplikasi
  runApp(MyApp(isLoggedIn: isLoggedIn));
}




class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    Intl.defaultLocale = 'id_ID';

    return MaterialApp(
      title: 'SembuhTBC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Poppins'),
      initialRoute: isLoggedIn ? '/home' : '/',
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
