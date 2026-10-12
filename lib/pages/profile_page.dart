import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String _email = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      _email = user.email ?? '';

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        _nameController.text = response['name'] ?? '';
        _phoneController.text = response['phone'] ?? '';
        _addressController.text = response['address'] ?? '';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      setState(() => _isLoading = true);

      await _supabase.from('profiles').upsert({
        'id': user.id,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'email': _email,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกข้อมูลโปรไฟล์สำเร็จ!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบบัญชี'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบบัญชีนี้? การกระทำนี้ไม่สามารถย้อนกลับได้ ข้อมูลและแอคเคาท์ของคุณจะถูกลบออกจากระบบถาวร'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบบัญชี'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => _isLoading = true);
      final user = _supabase.auth.currentUser;

      if (user != null) {
        // ลบข้อมูลโปรไฟล์ในตาราง profiles
        await _supabase.from('profiles').delete().eq('id', user.id);
      }

      // ออกจากระบบ
      await _supabase.auth.signOut();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการลบบัญชี: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขโปรไฟล์', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF7C3AED),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Color(0xFFEDE9FE),
                      child: Icon(Icons.person, size: 60, color: Color(0xFF7C3AED)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('ชื่อ - นามสกุล', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'กรอกชื่อของคุณ',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7C3AED))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('เบอร์โทรศัพท์', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'กรอกเบอร์โทรศัพท์',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7C3AED))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('อีเมล (ไม่สามารถแก้ไขได้)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: TextEditingController(text: _email),
                    enabled: false,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('ที่อยู่สำหรับจัดส่ง', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _addressController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'กรอกที่อยู่ของคุณ',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7C3AED))),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _saveProfile,
                      child: const Text('บันทึกข้อมูล', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _deleteAccount,
                      child: const Text('ลบบัญชี (Delete Account)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}