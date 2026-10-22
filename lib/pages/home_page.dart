import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_page.dart';
import 'profile_page.dart';
import 'customer_orders_page.dart';
import 'cart_page.dart';
import 'product_detail_page.dart';
import 'cart_service.dart';
import 'coupon_page.dart'; // นำเข้าหน้าศูนย์รวมคูปองฝั่งลูกค้า

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _supabase = Supabase.instance.client;
  int _currentIndex = 0; // ตัวแปรเก็บสถานะแท็บปัจจุบัน (0 = หน้าแรก, 1 = คำสั่งซื้อ, 2 = ฉัน)

  String _searchQuery = '';
  String _selectedCategory = 'ทั้งหมด';
  final List<String> _categories = ['ทั้งหมด', 'เสื้อผ้า', 'รองเท้า', 'เล็บปลอม'];

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    var query = _supabase.from('products').select();
    
    if (_searchQuery.isNotEmpty) {
      query = query.ilike('name', '%$_searchQuery%');
    }

    final response = await query;
    List<Map<String, dynamic>> products = List<Map<String, dynamic>>.from(response);

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

  // ส่วนแสดงเนื้อหาของแต่ละแท็บ
  Widget _buildBodyContent() {
    if (_currentIndex == 1) {
      return const CustomerOrdersPage(); // แท็บที่ 1: หน้าคำสั่งซื้อ
    } else if (_currentIndex == 2) {
      return const ProfilePage(); // แท็บที่ 2: หน้าโปรไฟล์ (ฉัน)
    }

    // แท็บที่ 0: หน้าหลัก (แสดงสินค้าและ Search Bar ปกติ)
    return Column(
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
                                  _searchQuery = value;
                                });
                              },
                              decoration: const InputDecoration(
                                hintText: 'ค้นหาสินค้า...',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ตะกร้าสินค้า
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart, color: Colors.white),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartPage()),
                        ).then((_) => setState(() {})),
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
                            '${CartService().items.length}',
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
                ],
              ),
              const SizedBox(height: 12),
              // 🎟️ แบนเนอร์กดเข้าไปหน้าศูนย์รวมคูปอง
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CouponPage()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Row(
                        children: [
                          Icon(Icons.confirmation_number, color: Color(0xFF7C3AED)),
                          SizedBox(width: 8),
                          Text('ศูนย์รวมโค้ดส่วนลด (เก็บโค้ด)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                        ],
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF7C3AED)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // แถบเลือกหมวดหมู่สินค้า
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
                                        product['image_url'].toString().split(',').first.trim(),
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
                                    InkWell(
                                      onTap: () {
                                        CartService().addItem(product);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('เพิ่ม "${product['name']}" ลงตะกร้าแล้ว'),
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                        setState(() {});
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _buildBodyContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF7C3AED),
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