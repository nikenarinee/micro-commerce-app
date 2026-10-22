import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'auth_page.dart';
import 'customer_orders_page.dart';

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
  String? _avatarUrl; // เก็บ URL รูปโปรไฟล์

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
        _avatarUrl = response['avatar_url'];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ฟังก์ชันเลือกรูปและอัปโหลดขึ้น Supabase Storage
  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final imageFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      
      if (imageFile == null) return;

      setState(() => _isLoading = true);
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.name.split('.').last;
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName;

      // อัปโหลดไฟล์ไปที่ Supabase Storage (สร้าง Bucket ชื่อ 'avatars' ไว้ล่วงหน้านะครับ)
      await _supabase.storage.from('avatars').uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(upsert: true, contentType: 'image/$fileExt'),
          );

      // ดึง Public URL ของรูปภาพ
      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);

      // อัปเดต URL ลงในตาราง profiles ทันที
      await _supabase.from('profiles').update({'avatar_url': imageUrl}).eq('id', user.id);

      setState(() {
        _avatarUrl = imageUrl;
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อัปโหลดรูปโปรไฟล์สำเร็จ!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปโหลดรูป: $e'), backgroundColor: Colors.red),
      );
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
        'avatar_url': _avatarUrl,
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

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
      (route) => false,
    );
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบบัญชี'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบบัญชีนี้? ข้อมูลทั้งหมดจะถูกลบออกจากระบบถาวร'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
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
        await _supabase.from('profiles').delete().eq('id', user.id);
      }
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
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('โปรไฟล์ของฉัน', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  // ส่วนรูปโปรไฟล์ กดที่รูปเพื่อเปลี่ยนได้
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFFEDE9FE),
                          backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                              ? NetworkImage(_avatarUrl!)
                              : null,
                          child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                              ? const Icon(Icons.person, size: 60, color: Color(0xFF7C3AED))
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickAndUploadImage,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF7C3AED),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // แถบสถานะการสั่งซื้อแบบ Shopee
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('การซื้อของฉัน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CustomerOrdersPage()),
                                );
                              },
                              child: const Row(
                                children: [
                                  Text('ดูประวัติการซื้อทั้งหมด', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatusItem(Icons.payment, 'ที่ต้องชำระ', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CustomerOrdersPage(initialFilter: 'รอตรวจสอบ')),
                              );
                            }),
                            _buildStatusItem(Icons.inventory_2_outlined, 'ที่ต้องจัดส่ง', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CustomerOrdersPage(initialFilter: 'รอจัดส่ง')),
                              );
                            }),
                            _buildStatusItem(Icons.local_shipping_outlined, 'ที่ต้องได้รับ', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CustomerOrdersPage(initialFilter: 'กำลังจัดส่ง')),
                              );
                            }),
                            _buildStatusItem(Icons.check_circle_outline, 'สำเร็จแล้ว', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CustomerOrdersPage(initialFilter: 'สำเร็จ')),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text('ชื่อ - นามสกุล', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('เบอร์โทรศัพท์', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF7C3AED)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout, color: Color(0xFF7C3AED)),
                      label: const Text('ออกจากระบบ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
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

  Widget _buildStatusItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap, // ใช้แค่ onTap ก็พอครับ
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF7C3AED), size: 26),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}