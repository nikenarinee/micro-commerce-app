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
  bool _isLoadingProfile = true;

  // ข้อมูลที่อยู่ผู้ใช้
  String _userAddress = '';
  String _userPhone = '';

  // เลือกวิธีการชำระเงิน ('transfer' = โอนเงิน, 'cod' = เก็บเงินปลายทาง)
  String _paymentMethod = 'transfer';

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

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // ดึงข้อมูลโปรไฟล์ผู้ใช้ (ที่อยู่และเบอร์โทร) จาก Supabase
  Future<void> _fetchUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final data = await _supabase
            .from('profiles')
            .select('address, phone')
            .eq('id', user.id)
            .maybeSingle();

        if (data != null) {
          setState(() {
            _userAddress = data['address'] ?? '';
            _userPhone = data['phone'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      setState(() => _isLoadingProfile = false);
    }
  }

  // Dialog สำหรับแก้ไข/กรอกที่อยู่จัดส่ง
  void _showEditAddressDialog() {
    final addressController = TextEditingController(text: _userAddress);
    final phoneController = TextEditingController(text: _userPhone);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('จัดการที่อยู่ในการจัดส่ง', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'เบอร์โทรศัพท์',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ที่อยู่จัดส่งสินค้า',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
              onPressed: () async {
                final newPhone = phoneController.text.trim();
                final newAddress = addressController.text.trim();

                final user = _supabase.auth.currentUser;
                if (user != null) {
                  try {
                    await _supabase.from('profiles').upsert({
                      'id': user.id,
                      'phone': newPhone,
                      'address': newAddress,
                    });
                  } catch (e) {
                    debugPrint('Error saving profile: $e');
                  }
                }

                setState(() {
                  _userPhone = newPhone;
                  _userAddress = newAddress;
                });

                if (mounted) Navigator.pop(context);
              },
              child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
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

    if (_userAddress.isEmpty || _userPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกที่อยู่และเบอร์โทรศัพท์สำหรับจัดส่งก่อนยืนยัน')),
      );
      return;
    }

    if (_paymentMethod == 'transfer' && (_slipUrl == null || _slipUrl!.isEmpty)) {
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

      final itemsJson = items.map((item) => {
            'product_name': item['name'],
            'price': item['price'],
            'quantity': item['quantity'],
            'size': item['size'],
            'color': item['color'],
          }).toList();

      await _supabase.from('orders').insert({
        'user_email': user?.email ?? 'Guest',
        'total_price': totalPrice,
        'status': _paymentMethod == 'cod' ? 'รอจัดส่ง (เก็บเงินปลายทาง)' : 'รอตรวจสอบ',
        'payment_method': _paymentMethod == 'cod' ? 'เก็บเงินปลายทาง' : 'โอนเงินผ่านธนาคาร',
        'slip_url': _paymentMethod == 'cod' ? null : _slipUrl,
        'address': _userAddress,
        'phone': _userPhone,
        'items': itemsJson,
      });

      cartService.items.clear();

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('สั่งซื้อสำเร็จ!'),
          content: Text(_paymentMethod == 'cod'
              ? 'ระบบได้รับคำสั่งซื้อเรียบร้อยแล้ว ร้านค้าจะเร่งจัดส่งสินค้าโดยเร็วที่สุด'
              : 'ระบบได้รับคำสั่งซื้อและสลิปของคุณแล้ว กรุณารอแอดมินตรวจสอบและอนุมัติรายการ'),
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
            // --- ส่วนที่อยู่จัดส่ง ---
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
                      const Row(
                        children: [
                          Icon(Icons.location_on, color: Color(0xFF7C3AED), size: 20),
                          SizedBox(width: 6),
                          Text('ที่อยู่ในการจัดส่ง', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      InkWell(
                        onTap: _showEditAddressDialog,
                        child: Text(
                          _userAddress.isEmpty ? 'เพิ่มที่อยู่' : 'แก้ไข',
                          style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _isLoadingProfile
                      ? const Center(child: CircularProgressIndicator())
                      : _userAddress.isEmpty
                          ? const Text('ยังไม่ได้บันทึกที่อยู่จัดส่ง กรุณากดเพิ่มที่อยู่', style: TextStyle(color: Colors.red, fontSize: 13))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('เบอร์โทรศัพท์: $_userPhone', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('ที่อยู่: $_userAddress', style: TextStyle(color: Colors.grey[800], fontSize: 13)),
                              ],
                            ),
                ],
              ),
            ),

            // --- ส่วนรายการสินค้า ---
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

            // --- ส่วนเลือกวิธีการชำระเงิน ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('เลือกวิธีการชำระเงิน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('โอนเงินผ่านธนาคาร (แนบสลิป)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    value: 'transfer',
                    groupValue: _paymentMethod,
                    activeColor: const Color(0xFF7C3AED),
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('ชำระเงินปลายทาง (COD)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    value: 'cod',
                    groupValue: _paymentMethod,
                    activeColor: const Color(0xFF7C3AED),
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                      });
                    },
                  ),
                  const Divider(height: 20),

                  // แสดง QR Code และข้อมูลโอนเงินเมื่อเลือก "โอนเงินผ่านธนาคาร"
                  if (_paymentMethod == 'transfer') ...[
                    const Text(
                      'โอนเงินผ่านบัญชีธนาคาร: 123-4-56789-0 (ธนาคารไทยพาณิชย์)\nชื่อบัญชี: Micro Commerce Shop',
                      style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    
                    // --- ส่วนแสดง QR Code สำหรับสแกนจ่าย ---
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            const Text('สแกน QR Code เพื่อชำระเงิน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('ยอดที่ต้องชำระ: ฿$_totalPrice', style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.w900, fontSize: 16)),
                            const SizedBox(height: 12),
                            // รูป QR Code (สามารถเปลี่ยน URL เป็น QR Code จริงของร้านคุณได้)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                'https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=MicroCommerceShop',
                                height: 160,
                                width: 160,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.qr_code_2, size: 100, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: const Text(
                        'ชำระเงินสดกับพนักงานขนส่งเมื่อได้รับสินค้า',
                        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
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