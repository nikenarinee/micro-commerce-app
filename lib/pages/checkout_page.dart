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

  // ดึงรายการสินค้าจาก CartService
  List<Map<String, dynamic>> get _checkoutItems => CartService().items;

  double get _totalPrice {
    double total = 0;
    for (var item in _checkoutItems) {
      double price = double.tryParse(item['price'].toString()) ?? 0;
      int qty = int.tryParse(item['quantity'].toString()) ?? 1;
      total += (price * qty);
    }
    return total;
  }

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
    if (_checkoutItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มีสินค้าในตะกร้าสำหรับสั่งซื้อ')),
      );
      return;
    }

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
      
      double totalPrice = _totalPrice;

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
            // ส่วนแสดงรายการสินค้าที่สั่งซื้อ (สามารถปรับแก้/ลบได้)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('รายการสินค้าที่สั่งซื้อ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('(${_checkoutItems.length} รายการ)', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  const Divider(height: 20),
                  _checkoutItems.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: Text('ไม่มีสินค้าในรายการ', style: TextStyle(color: Colors.grey))),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _checkoutItems.length,
                          itemBuilder: (context, index) {
                            final item = _checkoutItems[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  // รูปสินค้า
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: item['image_url'] != null && item['image_url'].toString().isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: Image.network(item['image_url'], fit: BoxFit.cover),
                                          )
                                        : const Icon(Icons.shopping_bag, size: 24, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 12),
                                  // ชื่อและรายละเอียดไซส์/สี
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'ไซส์: ${item['size'] ?? '-'} | สี: ${item['color'] ?? '-'}',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '฿${item['price']}',
                                          style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // ปุ่มจัดการจำนวนและปุ่มลบ
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                if (item['quantity'] > 1) {
                                                  item['quantity']--;
                                                }
                                              });
                                            },
                                            child: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.grey),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                            child: Text('${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                item['quantity']++;
                                              });
                                            },
                                            child: const Icon(Icons.add_circle_outline, size: 18, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            _checkoutItems.removeAt(index);
                                          });
                                        },
                                        child: const Text('ลบ', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ยอดรวมสุทธิ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        '฿$_totalPrice',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF7C3AED)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ส่วนช่องทางการชำระเงินและอัปโหลดสลิป
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
                onPressed: (_isSubmitting || _checkoutItems.isEmpty) ? null : _submitOrder,
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