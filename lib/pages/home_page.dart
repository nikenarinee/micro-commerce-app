import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_page.dart';
import 'profile_page.dart';
import 'cart_page.dart';
import 'product_detail_page.dart';
import 'cart_service.dart'; // นำเข้า CartService เพื่อใช้งานตะกร้า

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _supabase = Supabase.instance.client;
  String _searchQuery = ''; // ตัวแปรเก็บคำค้นหา
  String _selectedCategory = 'ทั้งหมด'; // หมวดหมู่ที่เลือกปัจจุบัน

  final List<String> _categories = ['ทั้งหมด', 'เสื้อผ้า', 'รองเท้า', 'เล็บปลอม'];

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    var query = _supabase.from('products').select();
    
    // ถ้ามีการพิมพ์ค้นหา ให้กรองชื่อสินค้าด้วย ilike
    if (_searchQuery.isNotEmpty) {
      query = query.ilike('name', '%$_searchQuery%');
    }

    final response = await query;
    List<Map<String, dynamic>> products = List<Map<String, dynamic>>.from(response);

    // กรองหมวดหมู่จากชื่อสินค้าโดยตรง
    if (_selectedCategory != 'ทั้งหมด') {
      products = products.where((product) {
        final name = (product['name'] ?? '').toString().toLowerCase();

        if (_selectedCategory == 'เสื้อผ้า' || _selectedCategory == 'เสื้อ') {
          return name.contains('เสื้อ') || 
                 name.contains('เดรส') || 
                 name.contains('ชุด') || 
                 name.contains('กางเกง') || 
                 name.contains('กระโปรง');
        } else if (_selectedCategory == 'รองเท้า') {
          return name.contains('รองเท้า') || name.contains('ส้นสูง') || name.contains('ผ้าใบ');
        } else if (_selectedCategory == 'เล็บปลอม') {
          return name.contains('เล็บ') || name.contains('เล็บปลอม');
        }

        return name.contains(_selectedCategory.toLowerCase());
      }).toList();
    }

    return products;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Container(
            color: const Color(0xFF7C3AED),
            padding: const EdgeInsets.only(top: 45, left: 16, right: 16, bottom: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value; // อัปเดตคำค้นหาทุกครั้งที่พิมพ์
                                  });
                                },
                                decoration: const InputDecoration(
                                  hintText: 'ค้นหาสินค้า...',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.camera_alt, color: Colors.grey, size: 20),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ปุ่มโปรไฟล์ (รูปคน)
                    IconButton(
                      icon: const Icon(Icons.person, color: Colors.white),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      ),
                      tooltip: 'โปรไฟล์ของฉัน',
                    ),
                    // ตะกร้าสินค้า
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shopping_cart, color: Colors.white),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CartPage()),
                          ).then((_) => setState(() {})), // พอกลับมาจากหน้าตะกร้าให้อัปเดตจอ
                        ),
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${CartService().items.length}', // แสดงจำนวนสินค้าในตะกร้าจริง
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // ปุ่มแชท
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF67E8F9)),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatPage()),
                      ),
                    ),
                    // (นำปุ่ม Logout ออกจากหน้าหลักแล้ว ย้ายไปไว้ที่หน้า Profile แทน)
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.qr_code_scanner, color: Color(0xFF7C3AED)),
                          SizedBox(width: 8),
                          Text('โค้ดส่วนลด 50%', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('เก็บโค้ด', style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // แถบเลือกหมวดหมู่สินค้า (Category Chips)
          Container(
            height: 50,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: const Color(0xFF7C3AED),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: Colors.grey[200],
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
                }
                final products = snapshot.data;
                if (products == null || products.isEmpty) {
                  return const Center(child: Text('ไม่พบสินค้าในหมวดหมู่นี้', style: TextStyle(color: Colors.grey)));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
                      ).then((_) => setState(() {})),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                child: product['image_url'] != null && product['image_url'].toString().isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                        child: Image.network(
                                          product['image_url'],
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
                                        ),
                                      )
                                    : const Center(child: Icon(Icons.shopping_bag, size: 40, color: Colors.grey)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['name'] ?? 'ไม่มีชื่อสินค้า',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '฿${product['price']}',
                                        style: const TextStyle(
                                          color: Color(0xFF059669),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                        ),
                                      ),
                                      // ปุ่มกดเพิ่มสินค้าลงตะกร้า (ทำงานจริง)
                                      InkWell(
                                        onTap: () {
                                          CartService().addItem(product);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('เพิ่ม "${product['name']}" ลงตะกร้าแล้ว'),
                                              duration: const Duration(seconds: 1),
                                            ),
                                          );
                                          setState(() {}); // อัปเดตหน้าจอเพื่อเปลี่ยนตัวเลขบนไอคอนตะกร้า
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF7C3AED),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.add, color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}