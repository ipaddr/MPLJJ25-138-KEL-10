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
import 'pages/reward_code_page.dart'; // Ensure correct import

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initializeDateFormatting('id_ID', null);

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

  const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: onDidReceiveLocalNotification,
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

  runApp(const MyApp());
}

// ... (bagian atas kode main.dart tetap sama)

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
              ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
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
              ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return VerificationWarningPage(
            scheduleId: args['scheduleId'] as String,
            doseTime: args['doseTime'] as String,
          );
        },
        '/waiting-verification': (context) => const WaitingVerificationPage(),
        '/verification-success': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return VerificationSuccessPage(
            isSuccess: args?['isSuccess'] as bool? ?? true,
            message:
                args?['message'] as String? ??
                "Akun Anda telah berhasil diverifikasi oleh admin.",
          );
        },
        // PERHATIKAN PERUBAHAN DI BAWAH INI
        '/verif-done': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return VerificationDonePage(
            scheduleId: args?['scheduleId'] as String? ?? '', // Default value jika null
            doseTime: args?['doseTime'] as String? ?? '',     // Default value jika null
          );
        },
        '/take-photo': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return TakePhotoPage(
            scheduleId: args['scheduleId'] as String,
            doseTime: args['doseTime'] as String,
          );
        },
        // --- START ROUTE UPDATE ---
        // Memastikan '/waiting-photo' mengarah ke WaitingResultPage
        '/waiting-photo': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return WaitingResultPage( // Menggunakan WaitingResultPage
            scheduleId: args['scheduleId'] as String,
            doseTime: args['doseTime'] as String,
            imagePath: args['imagePath'] as String,
          );
        },
        // --- END ROUTE UPDATE ---

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
          final args =
              ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return RewardCodePage(rewardKey: args['rewardKey'] as String);
        },
      },
    );
  }
}