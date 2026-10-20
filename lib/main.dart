import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/welcome_page.dart'; // นำเข้าหน้า Welcome ที่เพิ่งสร้าง

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
      home: const WelcomePage(), // ตั้งให้เปิดมาเจอหน้า Welcome เป็นอันแรก
      debugShowCheckedModeBanner: false,
    );
  }
}