import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Notification related imports
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

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
}

// --- PERUBAHAN UTAMA DI SINI ---
// Fungsi untuk membuat notifikasi channel DENGAN SUARA KUSTOM
Future<void> _createNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'reminder_channel', // id: HARUS sama dengan id channel di AndroidNotificationDetails
    'Pengingat Obat', // name: Nama yang terlihat oleh pengguna di pengaturan notifikasi
    description:
        'Channel untuk notifikasi pengingat minum obat dengan suara alarm.', // deskripsi
    importance: Importance.max, // Pentingnya notifikasi (seperti Urgent)
    playSound: true,
    // Atur suara kustom di sini. Nama file tanpa ekstensi.
    // Pastikan Anda punya file 'alarm.mp3' (atau format lain) di android/app/src/main/res/raw
    sound: RawResourceAndroidNotificationSound('alarm'),
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
  print(
    'DEBUG: Channel notifikasi "reminder_channel" dengan suara kustom telah dibuat.',
  );
}
// --- AKHIR PERUBAHAN ---

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initializeDateFormatting('id_ID', null);

  // --- Inisialisasi Timezone ---
  tz.initializeTimeZones();
  try {
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    print('DEBUG: Zona waktu lokal diatur secara manual ke: Asia/Jakarta');
  } catch (e) {
    print(
      'ERROR: Gagal mengatur zona waktu lokal. Menggunakan default. Error: $e',
    );
  }
  // --- Akhir Inisialisasi Timezone ---

  // --- Inisialisasi FlutterLocalNotificationsPlugin ---
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
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
    },
  );
  // --- Akhir Inisialisasi FlutterLocalNotificationsPlugin ---

  // Panggil fungsi untuk membuat/memverifikasi channel notifikasi
  await _createNotificationChannel();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Intl.defaultLocale = 'id_ID';

    return MaterialApp(
      title: 'SembuhTBC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Poppins'),
      initialRoute: '/',
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
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return MedInfoPage(
            scheduleId: args['scheduleId'] as String,
            name: args['name'] as String,
            dose: args['dose'] as String,
            medicineType: args['medicineType'] as String,
            doseTime: args['doseTime'] as String,
          );
        },
        '/verification-warning': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return VerificationWarningPage(
            scheduleId: args['scheduleId'] as String,
            doseTime: args['doseTime'] as String,
          );
        },
        '/waiting-verification': (context) => const WaitingVerificationPage(),
        '/verification-success': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>?;
          return VerificationSuccessPage(
            isSuccess: args?['isSuccess'] as bool? ?? true,
            message:
                args?['message'] as String? ??
                "Akun Anda telah berhasil diverifikasi oleh admin.",
          );
        },
        '/verif-done': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>?;
          return VerificationDonePage(
            scheduleId: args?['scheduleId'] as String? ?? '',
            doseTime: args?['doseTime'] as String? ?? '',
          );
        },
        '/take-photo': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return TakePhotoPage(
            scheduleId: args['scheduleId'] as String,
            doseTime: args['doseTime'] as String,
          );
        },
        '/waiting-photo': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return WaitingResultPage(
            scheduleId: args['scheduleId'] as String,
            doseTime: args['doseTime'] as String,
            imagePath: args['imagePath'] as String,
          );
        },
        '/result-photo': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return ResultPhotoPage(
            scheduleId: args['scheduleId'],
            doseTime: args['doseTime'],
            isPhotoVerified: args['isPhotoVerified'],
            imagePath: args['imagePath'],
          );
        },
        '/reward': (context) => const RewardPage(),
        '/reward-code': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return RewardCodePage(rewardKey: args['rewardKey'] as String);
        },
      },
    );
  }
}
