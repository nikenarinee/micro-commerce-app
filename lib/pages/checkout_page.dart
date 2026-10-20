import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_service.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _supabase = Supabase.instance.client;
  String? _slipUrl;
  bool _isUploading = false;
  bool _isSubmitting = false;

  // ฟังก์ชันอัปโหลดสลิปโอนเงินไป Supabase Storage
  Future<void> _pickAndUploadSlip() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final fileBytes = await pickedFile.readAsBytes();
      final fileExt = pickedFile.name.split('.').last;
      final fileName = 'slip_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await _supabase.storage.from('product-images').uploadBinary(
            fileName,
            fileBytes,
            fileOptions: FileOptions(contentType: 'image/$fileExt'),
          );

      final publicUrl = _supabase.storage.from('product-images').getPublicUrl(fileName);

      setState(() {
        _slipUrl = publicUrl;
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปโหลดสลิปสำเร็จ!')),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('อัปโหลดสลิปไม่สำเร็จ: $e')),
        );
      }
    }
  }

  // ฟังก์ชันยืนยันคำสั่งซื้อ
  Future<void> _submitOrder() async {
    if (_slipUrl == null || _slipUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาแนบรูปสลิปโอนเงินก่อนยืนยันคำสั่งซื้อ')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = _supabase.auth.currentUser;
      final cartService = CartService();
      final items = cartService.items;
      
      double totalPrice = 0;
      for (var item in items) {
        double price = double.tryParse(item['price'].toString()) ?? 0;
        int qty = int.tryParse(item['quantity'].toString()) ?? 1;
        totalPrice += (price * qty);
      }

      // แปลงรายการสินค้าเป็น JSON เพื่อเก็บลงฐานข้อมูล
      final itemsJson = items.map((item) => {
            'product_name': item['name'],
            'price': item['price'],
            'quantity': item['quantity'],
            'size': item['size'],
            'color': item['color'],
          }).toList();

      // บันทึกลงตาราง orders
      await _supabase.from('orders').insert({
        'user_email': user?.email ?? 'Guest',
        'total_price': totalPrice,
        'status': 'รอตรวจสอบ',
        'slip_url': _slipUrl,
        'items': itemsJson,
      });

      // เคลียร์ตะกร้าสินค้า
      cartService.items.clear();

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('สั่งซื้อสำเร็จ!'),
          content: const Text('ระบบได้รับคำสั่งซื้อและสลิปของคุณแล้ว กรุณารอแอดมินตรวจสอบและอนุมัติรายการ'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
              onPressed: () {
                Navigator.pop(context); // ปิด Dialog
                Navigator.pop(context); // กลับหน้าตะกร้า
                Navigator.pop(context); // กลับหน้าหลัก
              },
              child: const Text('ตกลง', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('ยืนยันคำสั่งซื้อและชำระเงิน', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ช่องทางการชำระเงิน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text(
                    'โอนเงินผ่านบัญชีธนาคาร: 123-4-56789-0 (ธนาคารไทยพาณิชย์)\nชื่อบัญชี: Micro Commerce Shop',
                    style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  const Text('แนบหลักฐานการชำระเงิน (สลิปโอนเงิน)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _isUploading ? null : _pickAndUploadSlip,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _isUploading
                          ? const Center(child: CircularProgressIndicator())
                          : _slipUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(_slipUrl!, fit: BoxFit.cover),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('แตะเพื่ออัปโหลดรูปสลิปโอนเงิน', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting ? null : _submitOrder,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ยืนยันคำสั่งซื้อ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}