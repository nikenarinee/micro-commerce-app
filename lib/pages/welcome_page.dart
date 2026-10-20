import 'package:flutter/material.dart';
import 'auth_page.dart'; // หรือหน้า Login/Home ของคุณ

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // โลโก้หรือรูปภาพประกอบแอป (ใช้วงกลมสีม่วงแทนไอคอนช้อปปิ้งชั่วคราว)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_bag_rounded,
                  size: 60,
                  color: Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(height: 32),
              // ชื่อแอป
              const Text(
                'NK Shop',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(height: 12),
              // สโลแกน
              const Text(
                'ช้อปสินค้าที่ใช่ สั่งซื้อง่าย\nมั่นใจได้จริงทุกคำสั่งซื้อ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              // ปุ่มเริ่มต้นใช้งาน
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // กดแล้วพาไปหน้า AuthPage (หรือหน้า Login)
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthPage()),
                    );
                  },
                  child: const Text(
                    'เริ่มต้นใช้งาน',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}