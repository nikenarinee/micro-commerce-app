import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/welcome_page.dart'; // เริ่มต้นที่หน้า Welcome เป็นหน้าแรกสุด

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yqewlavvffogrreyymgo.supabase.co',
    anonKey: 'sb_publishable_gNs_ghACESZiAuJeQfoOzA_wwXgZAFu',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Micro Commerce',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WelcomePage(), // เริ่มต้นที่หน้า Welcome ตาม Flow ที่ถูกต้อง
      debugShowCheckedModeBanner: false,
    );
  }
}