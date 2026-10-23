import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/welcome_page.dart'; // เริ่มต้นที่หน้า Welcome เป็นหน้าแรกสุด
import 'reset_password_page.dart'; // นำเข้าหน้า Reset Password ที่เพิ่งสร้าง

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yqewlavvffogrreyymgo.supabase.co',
    anonKey: 'sb_publishable_gNs_ghACESZiAuJeQfoOzA_wwXgZAFu',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    // ดักฟังสถานะ Auth จาก Supabase
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      
      // ถ้ากดลิงก์รีเซ็ตรหัสผ่านมาจากอีเมล
      if (event == AuthChangeEvent.passwordRecovery) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => const ResetPasswordPage(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Micro Commerce',
      navigatorKey: _navigatorKey, // ใช้ NavigatorKey เพื่อให้สั่งเปลี่ยนหน้าจากข้างนอกได้
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WelcomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}