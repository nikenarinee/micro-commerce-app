import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/welcome_page.dart';
import 'pages/reset_password_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yqewlavvffogrreyymgo.supabase.co',
    anonKey: 'sb_publishable_gNs_ghACESZiAuJeQfoOzA_wwXgZAFu',
  );

  // เช็กตั้งแต่ตอนเปิดแอปเลยว่ามี code รีเซ็ตรหัสผ่านติดมาใน URL หรือไม่
  final uri = Uri.base;
  String? code = uri.queryParameters['code'];
  if (code == null && uri.hasFragment) {
    final fragmentUri = Uri.parse(uri.fragment);
    code = fragmentUri.queryParameters['code'];
  }

  // ถ้ามี code ให้ทำการแลก Session รอไว้เลย
  bool hasRecoveryCode = false;
  if (code != null) {
    try {
      await Supabase.instance.client.auth.exchangeCodeForSession(code);
      hasRecoveryCode = true;
    } catch (e) {
      debugPrint('Error exchanging code: $e');
    }
  }

  runApp(MyApp(isPasswordRecovery: hasRecoveryCode));
}

class MyApp extends StatelessWidget {
  final bool isPasswordRecovery;
  const MyApp({super.key, required this.isPasswordRecovery});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Micro Commerce',
      // ถ้ามีโค้ดรีเซ็ต ให้เปิดหน้า ResetPasswordPage ทันทีตั้งแต่หน้าแรก (ตัดปัญหาจอขาว)
      home: isPasswordRecovery ? const ResetPasswordPage() : const WelcomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}