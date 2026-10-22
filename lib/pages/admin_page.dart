import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart'; // นำเข้าไลบรารีกราฟ
import 'admin_orders_page.dart';
import 'admin_chat_list_page.dart';
import 'admin_coupon_page.dart'; // นำเข้าหน้าจัดการคูปองฝั่งแอดมิน

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _supabase = Supabase.instance.client;

  // ตัวแปรสำหรับจัดเก็บหมวดหมู่สินค้าที่เลือกกรอง
  String _selectedCategory = 'ทั้งหมด';
  final List<String> _categories = ['ทั้งหมด', 'เสื้อผ้า', 'รองเท้า', 'เล็บปลอม', 'ของใช้'];

  // ดึงยอดขายและจำนวนออเดอร์ของวันนี้
  Future<Map<String, dynamic>> _fetchTodaySalesAndOrders() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

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
      return {
        'totalSales': 0.0,
        'orderCount': 0,
      };
    }
  }

  // ดึงข้อมูลยอดขาย 7 วันล่าสุดสำหรับแสดงกราฟ
  Future<List<double>> _fetchWeeklySales() async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(const Duration(days: 6));
      final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).toIso8601String();

      final response = await _supabase
          .from('orders')
          .select('total_price, created_at')
          .eq('status', 'สำเร็จ')
          .gte('created_at', startDate);

      List<double> dailySales = [0, 0, 0, 0, 0, 0, 0];
      for (var order in response) {
        final price = double.tryParse(order['total_price']?.toString() ?? '0') ?? 0.0;
        final dateStr = order['created_at'];
        if (dateStr != null) {
          final orderDate = DateTime.parse(dateStr);
          int diffDays = orderDate.difference(DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day)).inDays;
          if (diffDays >= 0 && diffDays < 7) {
            dailySales[diffDays] += price;
          }
        }
      }
      return dailySales;
    } catch (e) {
      return [0, 0, 0, 0, 0, 0, 0];
    }
  }

  // ฟังก์ชันดึงและกรองสินค้าตามชื่อสินค้า
  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    final response = await _supabase.from('products').select();
    List<Map<String, dynamic>> products = List<Map<String, dynamic>>.from(response);

    if (_selectedCategory != 'ทั้งหมด') {
      products = products.where((product) {
        final name = (product['name'] ?? '').toString().toLowerCase();

        if (_selectedCategory == 'เสื้อผ้า') {
          return name.contains('เสื้อ') || name.contains('เดรส') || name.contains('ชุด') || name.contains('กางเกง') || name.contains('กระโปรง');
        } else if (_selectedCategory == 'รองเท้า') {
          return name.contains('รองเท้า') || name.contains('ผ้าใบ') || name.contains('คัทชู');
        } else if (_selectedCategory == 'เล็บปลอม') {
          return name.contains('เล็บ') || name.contains('เล็บปลอม');
        } else if (_selectedCategory == 'ของใช้') {
          return name.contains('ของ') || name.contains('กระเป๋า') || name.contains('หมวก') || name.contains('ทำผม');
        }
        return true;
      }).toList();
    }

    return products;
  }

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

  void _showProductDialog({Map<String, dynamic>? product}) {
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final priceController = TextEditingController(text: product?['price']?.toString() ?? '');
    final stockController = TextEditingController(text: product?['stock']?.toString() ?? '10');
    final descController = TextEditingController(text: product?['description'] ?? '');
    final imagesController = TextEditingController(text: product?['image_url'] ?? '');
    String selectedCat = product?['category'] ?? 'เสื้อผ้า';

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
                DropdownButtonFormField<String>(
                  value: selectedCat,
                  decoration: InputDecoration(
                    labelText: 'หมวดหมู่สินค้า',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: ['เสื้อผ้า', 'รองเท้า', 'เล็บปลอม', 'ของใช้'].map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedCat = val);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'ราคา (บาท)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'จำนวนสต็อก',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'รายละเอียดสินค้าเพิ่มเติม',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: imagesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'ลิงก์รูปภาพ (คั่นด้วย , หากมีหลายรูป)',
                    helperText: 'เช่น https://img1.jpg, https://img2.jpg',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final uploadedUrl = await _pickAndUploadImage(dialogContext);
                    if (uploadedUrl != null) {
                      setDialogState(() {
                        if (imagesController.text.isEmpty) {
                          imagesController.text = uploadedUrl;
                        } else {
                          imagesController.text = '${imagesController.text}, $uploadedUrl';
                        }
                      });
                    }
                  },
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('อัปโหลดรูปเพิ่มจากเครื่อง'),
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
                final stock = int.tryParse(stockController.text) ?? 0;
                final description = descController.text.trim();
                final imageUrls = imagesController.text.trim();

                if (name.isEmpty) return;

                if (product == null) {
                  await _supabase.from('products').insert({
                    'name': name,
                    'category': selectedCat,
                    'price': price,
                    'stock': stock,
                    'description': description,
                    'image_url': imageUrls,
                  });
                } else {
                  await _supabase.from('products').update({
                    'name': name,
                    'category': selectedCat,
                    'price': price,
                    'stock': stock,
                    'description': description,
                    'image_url': imageUrls,
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
          // 🎟️ ปุ่มกดเปิดไปหน้าจัดการโค้ดส่วนลดฝั่งแอดมิน
          IconButton(
            icon: const Icon(Icons.confirmation_number, color: Color(0xFF7C3AED)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminCouponPage()),
            ),
            tooltip: 'จัดการโค้ดส่วนลด',
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Color(0xFF7C3AED)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminOrdersPage()),
            ),
            tooltip: 'จัดการออเดอร์และสลิป',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF7C3AED)),
            onPressed: () => setState(() {}),
            tooltip: 'รีเฟรชข้อมูล',
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF7C3AED)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminChatListPage()),
            ),
            tooltip: 'แชทกับลูกค้า',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // การ์ดแสดงยอดขายและออเดอร์วันนี้
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
                              '฿ ${sales.toStringAsFixed(0)}',
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
            const SizedBox(height: 20),

            // กราฟแท่งแสดงยอดขาย 7 วันล่าสุด
            FutureBuilder<List<double>>(
              future: _fetchWeeklySales(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final weeklySales = snapshot.data ?? [0, 0, 0, 0, 0, 0, 0];
                double maxY = weeklySales.fold(0.0, (prev, element) => prev > element ? prev : element);
                if (maxY == 0) maxY = 1000; else maxY = maxY * 1.2;

                return Container(
                  height: 240,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('สถิติยอดขาย 7 วันล่าสุด', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: maxY,
                            barTouchData: BarTouchData(enabled: true),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    const days = ['6วันก่อน', '5วันก่อน', '4วันก่อน', '3วันก่อน', 'มะรืน', 'เมื่อวาน', 'วันนี้'];
                                    int idx = value.toInt();
                                    if (idx >= 0 && idx < days.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(days[idx], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(7, (index) {
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: weeklySales[index],
                                    color: const Color(0xFF7C3AED),
                                    width: 16,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // หัวข้อและแถบกรองหมวดหมู่สินค้า
            const Text(
              'จัดการสต็อกสินค้า',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: const Color(0xFF7C3AED),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (selected) {
                        setState(() => _selectedCategory = cat);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // รายการสินค้าตามหมวดหมู่
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
                    child: Center(child: Text('ยังไม่มีสินค้าในหมวดหมู่นี้', style: TextStyle(color: Colors.grey))),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final stock = product['stock'] ?? 0;
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
                                    product['image_url'].toString().split(',').first.trim(),
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
                                Row(
                                  children: [
                                    Text(
                                      '฿${product['price']}',
                                      style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: stock > 0 ? Colors.green[50] : Colors.red[50],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        stock > 0 ? 'คงเหลือ $stock' : 'สินค้าหมด',
                                        style: TextStyle(
                                          color: stock > 0 ? Colors.green[700] : Colors.red[700],
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
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