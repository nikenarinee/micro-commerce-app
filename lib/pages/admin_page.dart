import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_page.dart'; // นำเข้าหน้าแชท

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _supabase = Supabase.instance.client;

  // ฟังก์ชันดึงสรุปยอดขายและจำนวนออเดอร์ของวันนี้จาก Supabase
  Future<Map<String, dynamic>> _fetchTodaySalesAndOrders() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

      // ดึงออเดอร์เฉพาะที่เกิดหลังจากเริ่มต้นวันนี้
      final response = await _supabase
          .from('orders')
          .select()
          .gte('created_at', startOfDay);

      final orders = List<Map<String, dynamic>>.from(response);

      double totalSales = 0.0;
      for (var order in orders) {
        final price = double.tryParse(order['total_price']?.toString() ?? '0') ?? 0.0;
        totalSales += price;
      }

      return {
        'totalSales': totalSales,
        'orderCount': orders.length,
      };
    } catch (e) {
      // หากยังไม่มีตาราง orders ให้คืนค่า default เป็น 0
      return {
        'totalSales': 0.0,
        'orderCount': 0,
      };
    }
  }

  // ฟังก์ชันดึงรายการสินค้าจาก Supabase
  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    final response = await _supabase.from('products').select();
    return List<Map<String, dynamic>>.from(response);
  }

  // ฟังก์ชันลบสินค้า
  Future<void> _deleteProduct(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบสินค้า'),
        content: const Text('คุณต้องการลบสินค้านี้ออกจากระบบใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.from('products').delete().eq('id', id);
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ลบสินค้าไม่สำเร็จ: $e')),
        );
      }
    }
  }

  // ฟังก์ชันเลือกรูปและอัปโหลดไป Supabase Storage
  Future<String?> _pickAndUploadImage(BuildContext dialogContext) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile == null) return null;

    try {
      if (!mounted) return null;
      showDialog(
        context: dialogContext,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final fileBytes = await pickedFile.readAsBytes();
      final fileExt = pickedFile.name.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await _supabase.storage.from('product-images').uploadBinary(
            fileName,
            fileBytes,
            fileOptions: FileOptions(contentType: 'image/$fileExt'),
          );

      final publicUrl = _supabase.storage.from('product-images').getPublicUrl(fileName);

      if (dialogContext.mounted) Navigator.pop(dialogContext);
      return publicUrl;
    } catch (e) {
      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('อัปโหลดรูปภาพไม่สำเร็จ: $e')),
        );
      }
      return null;
    }
  }

  // ฟอร์มสำหรับเพิ่มหรือแก้ไขสินค้า
  void _showProductDialog({Map<String, dynamic>? product}) {
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final priceController = TextEditingController(text: product?['price']?.toString() ?? '');
    String imageUrl = product?['image_url'] ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(product == null ? 'เพิ่มสินค้าใหม่' : 'แก้ไขสินค้า', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'ชื่อสินค้า',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'ราคา (บาท)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final uploadedUrl = await _pickAndUploadImage(dialogContext);
                    if (uploadedUrl != null) {
                      setDialogState(() {
                        imageUrl = uploadedUrl;
                      });
                    }
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(imageUrl, fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: Colors.grey, size: 30),
                              SizedBox(height: 4),
                              Text('แตะเพื่ออัปโหลดรูปสินค้า', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
              onPressed: () async {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text) ?? 0.0;

                if (name.isEmpty) return;

                if (product == null) {
                  await _supabase.from('products').insert({
                    'name': name,
                    'price': price,
                    'image_url': imageUrl,
                  });
                } else {
                  await _supabase.from('products').update({
                    'name': name,
                    'price': price,
                    'image_url': imageUrl,
                  }).eq('id', product['id']);
                }

                if (!mounted) return;
                Navigator.pop(dialogContext);
                setState(() {});
              },
              child: Text(product == null ? 'เพิ่ม' : 'บันทึก', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Shop Dashboard', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF7C3AED)),
            onPressed: () => setState(() {}),
            tooltip: 'รีเฟรชข้อมูล',
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF7C3AED)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatPage()),
            ),
            tooltip: 'แชทกับลูกค้า',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  'เปิดร้านอยู่',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนแสดงยอดขายและออเดอร์ใหม่ดึงข้อมูลสดจาก Supabase
            FutureBuilder<Map<String, dynamic>>(
              future: _fetchTodaySalesAndOrders(),
              builder: (context, snapshot) {
                final sales = snapshot.data?['totalSales'] ?? 0.0;
                final orders = snapshot.data?['orderCount'] ?? 0;

                return Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ยอดขายวันนี้', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                              '฿ ${sales.toStringAsFixed(0)} -',
                              style: const TextStyle(color: Color(0xFF16A34A), fontSize: 20, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ออเดอร์ใหม่', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                              '$orders รายการ',
                              style: const TextStyle(color: Color(0xFF7C3AED), fontSize: 20, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // แถบเมนูลัดเข้าแชท
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatPage()),
              ),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.forum_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ข้อความแชทจากลูกค้า',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'คลิกเพื่อเปิดกล่องข้อความและพูดคุยกับลูกค้า',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // หัวข้อจัดการสต็อกสินค้า
            const Text(
              'จัดการสต็อกสินค้า',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            // รายการสินค้าจริงจาก Supabase
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('เกิดข้อผิดพลาด: ${snapshot.error}');
                }
                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: Text('ยังไม่มีสินค้าในระบบ', style: TextStyle(color: Colors.grey))),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: product['image_url'] != null && product['image_url'].toString().isNotEmpty
                                ? Image.network(
                                    product['image_url'],
                                    width: 45,
                                    height: 45,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 45, color: Colors.grey),
                                  )
                                : const Icon(Icons.shopping_bag, size: 45, color: Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['name'] ?? 'ไม่มีชื่อสินค้า',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '฿${product['price']}',
                                  style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showProductDialog(product: product),
                            tooltip: 'แก้ไข',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteProduct(product['id']),
                            tooltip: 'ลบ',
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 30),

            // ปุ่มเพิ่มสินค้าใหม่
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showProductDialog(),
                child: const Text(
                  'เพิ่มสินค้าใหม่',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}