import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/layout.dart';
import 'package:frontend/login_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
//for geolocation
import 'package:frontend/utility/geofencing.dart';
//for firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
//for notification
import 'package:frontend/utility/noti_service.dart';
//provider
import 'package:frontend/providers/teacher_provider.dart';
import 'package:provider/provider.dart';

final kcolorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
NotiService notiService = NotiService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //firebase initialization
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // get all necesaary permissions
  await _requestPermissions();

  //setup geolocation
  final Geofencing geofencing = Geofencing();
  await geofencing.initGeofencing();

  //setup notiservice
  notiService.initNotification();

  // get the current user
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userRole = prefs.getString("user_role");

  Widget screen = const LoginScreen();
  TeacherProvider teacherProvider = TeacherProvider();

  if (userRole == "student") {
    screen = const Layout(currentUser: UserRole.student);
  }

  if (userRole == "teacher") {
    screen = const Layout(currentUser: UserRole.teacher);
    await teacherProvider.loadTeacherFromPrefs();
  }

  _setupFCMListeners();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (context) => teacherProvider)],
      child: MyApp(screen: screen),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.screen});

  final Widget screen;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData().copyWith(
        colorScheme: kcolorScheme,
        textTheme: GoogleFonts.latoTextTheme(),
        appBarTheme: const AppBarTheme().copyWith(
          backgroundColor: kcolorScheme.primary,
          // centerTitle: true,
        ),
      ),
      home: screen,
    );
  }
}

Future<void> _requestPermissions() async {
  await Permission.location.request();
  await Permission.locationAlways.request();
  await Permission.notification.request();

  await _requestNotificationPermissions();
}

Future<void> _requestNotificationPermissions() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else {
    print('User denied permission');
  }
}

void _setupFCMListeners() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Foreground Message: ${message.notification?.title}");
    notiService.showNotification(
      title: "${message.notification?.title}",
      body: "${message.notification?.body}",
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("Notification Clicked: ${message.notification?.title}");
  });
}
