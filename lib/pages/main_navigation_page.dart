import 'package:flutter/material.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'customer_orders_page.dart'; // หรือหน้าคำสั่งซื้อของลูกค้า
// import หน้าอื่นๆ เพิ่มเติมตามต้องการ

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  // รายการหน้าที่จะสลับตามแท็บด้านล่าง
  final List<Widget> _pages = [
    const HomePage(),           // แท็บ 0: หน้าหลัก
    const CustomerOrdersPage(), // แท็บ 1: คำสั่งซื้อ
    const ProfilePage(),        // แท็บ 2: โปรไฟล์ (ย้ายมาไว้ล่างสุด)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF7C3AED), // สีม่วงหลักของแอป
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'หน้าแรก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'คำสั่งซื้อ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'ฉัน',
          ),
        ],
      ),
    );
  }
}