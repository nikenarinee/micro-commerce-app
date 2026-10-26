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

  // 🔍 ตรวจสอบ token หรือ code จาก URL ทั้งแบบ Query Parameters และ Hash Fragment (#)
  final uri = Uri.base;
  bool hasRecoveryToken = false;

  // 1. เช็กแบบ query parameters ทั่วไป (?code=...)
  String? code = uri.queryParameters['code'];

  // 2. ถ้าไม่เจอใน query ให้ลองเช็กใน hash fragment (#...) ที่ Supabase มักจะส่งมา
  if (code == null && uri.hasFragment) {
    final fragment = uri.fragment;
    final Map<String, String> fragmentParams = Uri.splitQueryString(fragment);
    
    code = fragmentParams['code'];

    // เผื่อกรณีส่งมาเป็น access_token หรือ type=recovery ตรงๆ
    if (code == null && (fragment.contains('type=recovery') || fragment.contains('access_token'))) {
      hasRecoveryToken = true;
      try {
        final accessToken = fragmentParams['access_token'];
        final refreshToken = fragmentParams['refresh_token'];
        if (accessToken != null) {
          await Supabase.instance.client.auth.setSession(accessToken);
        }
      } catch (e) {
        debugPrint('Error setting session from fragment: $e');
      }
    }
  }

  // ถ้ามี code ให้นำไปแลก Session (Exchange Code for Session)
  if (code != null) {
    try {
      await Supabase.instance.client.auth.exchangeCodeForSession(code);
      hasRecoveryToken = true;
    } catch (e) {
      debugPrint('Error exchanging code: $e');
    }
  }

  runApp(MyApp(isPasswordRecovery: hasRecoveryToken));
}

class MyApp extends StatelessWidget {
  final bool isPasswordRecovery;
  const MyApp({super.key, required this.isPasswordRecovery});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Micro Commerce',
      // ถ้าตรวจพบสถานะรีเซ็ตรหัสผ่าน ให้เปิดหน้า ResetPasswordPage ทันที (ป้องกันหน้าจอว่างเปล่า)
      home: isPasswordRecovery ? const ResetPasswordPage() : const WelcomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}