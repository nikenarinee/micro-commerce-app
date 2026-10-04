import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  // ฟังก์ชันดึงข้อมูลสินค้าจาก Supabase
  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    final response = await Supabase.instance.client.from('products').select();
    return List<Map<String, dynamic>>.from(response);
  }

  // ฟังก์ชันเปิด Dialog สำหรับ "เพิ่ม" หรือ "แก้ไข" สินค้า
  void _showProductDialog({Map<String, dynamic>? productToEdit}) {
    final isEditing = productToEdit != null;
    final nameController = TextEditingController(text: isEditing ? productToEdit['name'] : '');
    final priceController = TextEditingController(text: isEditing ? productToEdit['price'].toString() : '');
    final descController = TextEditingController(text: isEditing ? productToEdit['description'] : '');
    final imageController = TextEditingController(text: isEditing ? productToEdit['image_url'] : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'แก้ไขสินค้า' : 'เพิ่มสินค้าใหม่'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'ชื่อสินค้า'),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'ราคา (บาท)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'รายละเอียดสินค้า'),
                ),
                TextField(
                  controller: imageController,
                  decoration: const InputDecoration(labelText: 'URL รูปภาพสินค้า'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                final description = descController.text.trim();
                final imageUrl = imageController.text.trim();

                if (name.isEmpty) return;

                try {
                  if (isEditing) {
                    // อัปเดตข้อมูลสินค้า (Update)
                    await Supabase.instance.client
                        .from('products')
                        .update({
                          'name': name,
                          'price': price,
                          'description': description,
                          'image_url': imageUrl,
                        })
                        .eq('id', productToEdit['id']);
                  } else {
                    // เพิ่มสินค้าใหม่ (Create)
                    await Supabase.instance.client.from('products').insert({
                      'name': name,
                      'price': price,
                      'description': description,
                      'image_url': imageUrl,
                    });
                  }

                  if (!mounted) return;
                  Navigator.pop(context);
                  setState(() {}); // รีเฟรชหน้าจอ
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEditing ? 'แก้ไขสินค้าสำเร็จ!' : 'เพิ่มสินค้าสำเร็จ!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: Text(isEditing ? 'บันทึกการแก้ไข' : 'บันทึก'),
            ),
          ],
        );
      },
    );
  }

  // ฟังก์ชันลบสินค้า (Delete)
  Future<void> _deleteProduct(int id) async {
    try {
      await Supabase.instance.client.from('products').delete().eq('id', id);
      setState(() {}); // รีเฟรชหน้าจอ
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบสินค้าสำเร็จ')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบไม่สำเร็จ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Micro Commerce - รายการสินค้า'),
        actions: [
          // ปุ่มเพิ่มสินค้า
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showProductDialog(),
            tooltip: 'เพิ่มสินค้า',
          ),
          // ปุ่มออกจากระบบ
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
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
            return const Center(child: Text('ยังไม่มีสินค้าในระบบ'));
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: product['image_url'] != null && product['image_url'].toString().isNotEmpty
                      ? Image.network(
                          product['image_url'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported),
                        )
                      : const Icon(Icons.shopping_bag, size: 50),
                  title: Text(
                    product['name'] ?? 'ไม่มีชื่อสินค้า',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(product['description'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '฿${product['price']}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      // ปุ่มแก้ไขสินค้า
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showProductDialog(productToEdit: product),
                      ),
                      // ปุ่มลบสินค้า
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // แสดง Popup ยืนยันการลบ
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('ยืนยันการลบ'),
                              content: Text('คุณต้องการลบ "${product['name']}" ใช่หรือไม่?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('ยกเลิก'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _deleteProduct(product['id']);
                                  },
                                  child: const Text('ลบ', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}