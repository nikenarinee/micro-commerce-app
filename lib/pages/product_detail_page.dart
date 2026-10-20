import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_page.dart';
import 'cart_service.dart';
import 'auth_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  String _selectedSize = 'M';
  String _selectedColor = 'ดำ';
  int _quantity = 1;
  int _currentImageIndex = 0; // ตัวแปรเก็บ index ของรูปที่กำลังแสดง

  final List<String> _sizes = ['S', 'M', 'L', 'XL'];
  final List<String> _colors = ['ดำ', 'ขาว', 'เทา', 'กรม'];

  // ฟังก์ชันแยกรูปภาพหลายรูปออกจาก string (คั่นด้วย ,)
  List<String> _getProductImages() {
    final rawUrl = widget.product['image_url']?.toString() ?? '';
    if (rawUrl.isEmpty) return [];
    return rawUrl.split(',').map((url) => url.trim()).where((url) => url.isNotEmpty).toList();
  }

  // ฟังก์ชันเปิดดูรูปภาพขนาดใหญ่เต็มจอ
  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final price = product['price'] ?? 0;
    final description = product['description'] ?? 'ไม่มีรายละเอียดสินค้าเพิ่มเติม';
    final images = _getProductImages();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(product['name'] ?? 'รายละเอียดสินค้า', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ส่วนแสดงรูปภาพสินค้าหลายรูป (สไตล์เดียวกับตัวอย่างเว็บ)
                  if (images.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // รูปภาพหลักขนาดใหญ่ (กดเพื่อซูมได้)
                        Expanded(
                          flex: 3,
                          child: GestureDetector(
                            onTap: () => _showFullScreenImage(images[_currentImageIndex]),
                            child: Container(
                              height: 320,
                              color: Colors.grey[100],
                              child: Image.network(
                                images[_currentImageIndex],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey)),
                              ),
                            ),
                          ),
                        ),
                        // รูปภาพย่อยด้านข้าง สำหรับกดสลับดู
                        if (images.length > 1) ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 90,
                            height: 320,
                            child: ListView.builder(
                              itemCount: images.length,
                              itemBuilder: (context, index) {
                                final isSelected = _currentImageIndex == index;
                                return GestureDetector(
                                  onTap: () => setState(() => _currentImageIndex = index),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    height: 75,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF7C3AED) : Colors.transparent,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(images[index], fit: BoxFit.cover),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    )
                  else
                    Container(
                      height: 300,
                      width: double.infinity,
                      color: Colors.grey[100],
                      child: const Center(child: Icon(Icons.shopping_bag, size: 80, color: Colors.grey)),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'] ?? '',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '฿$price',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                        ),
                        const SizedBox(height: 16),
                        
                        // รายละเอียดสินค้าเพิ่มเติม
                        const Text('รายละเอียดสินค้า', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
                        ),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 10),

                        // เลือกไซส์
                        const Text('เลือกไซส์', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          children: _sizes.map((size) {
                            final isSelected = _selectedSize == size;
                            return ChoiceChip(
                              label: Text(size),
                              selected: isSelected,
                              selectedColor: const Color(0xFF7C3AED),
                              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                              onSelected: (_) => setState(() => _selectedSize = size),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // เลือกสี
                        const Text('เลือกสี', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          children: _colors.map((color) {
                            final isSelected = _selectedColor == color;
                            return ChoiceChip(
                              label: Text(color),
                              selected: isSelected,
                              selectedColor: const Color(0xFF7C3AED),
                              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                              onSelected: (_) => setState(() => _selectedColor = color),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // จำนวน
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('จำนวน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    if (_quantity > 1) setState(() => _quantity--);
                                  },
                                ),
                                Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => setState(() => _quantity++),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // แถบปุ่มด้านล่าง
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF7C3AED)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final user = Supabase.instance.client.auth.currentUser;
                      if (user == null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthPage()),
                        );
                        return;
                      }

                      final cartItem = Map<String, dynamic>.from(widget.product);
                      cartItem['size'] = _selectedSize;
                      cartItem['color'] = _selectedColor;
                      cartItem['quantity'] = _quantity;
                      if (images.isNotEmpty) cartItem['image_url'] = images.first;

                      CartService().addItemWithDetails(cartItem, _selectedSize, _selectedColor, _quantity);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('เพิ่ม "${product['name']}" ลงตะกร้าแล้ว!')),
                      );
                    },
                    child: const Text('เพิ่มลงตะกร้า', style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final user = Supabase.instance.client.auth.currentUser;
                      if (user == null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthPage()),
                        );
                        return;
                      }

                      final cartItem = Map<String, dynamic>.from(widget.product);
                      cartItem['size'] = _selectedSize;
                      cartItem['color'] = _selectedColor;
                      cartItem['quantity'] = _quantity;
                      if (images.isNotEmpty) cartItem['image_url'] = images.first;

                      CartService().addItemWithDetails(cartItem, _selectedSize, _selectedColor, _quantity);

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartPage()),
                      );
                    },
                    child: const Text('ซื้อสินค้า', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}