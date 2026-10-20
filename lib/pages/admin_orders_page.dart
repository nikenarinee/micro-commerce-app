import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  // ดึงรายการออเดอร์
  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _orders = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดออเดอร์: $e')),
        );
      }
    }
  }

  // อนุมัติออเดอร์และตัดสต็อกอัตโนมัติ (แก้ไขจุดที่เช็คสินค้าให้รองรับ List ป้องกัน error 406)
  Future<void> _approveOrder(Map<String, dynamic> order) async {
    try {
      final orderId = order['id'];
      final items = order['items'] as List<dynamic>? ?? [];

      for (var item in items) {
        final productName = item['product_name'];
        final int buyQty = int.tryParse(item['quantity'].toString()) ?? 1;

        // เปลี่ยนมาใช้ .select() แบบดึงเป็น List เพื่อป้องกัน Error กรณีมีสินค้าชื่อซ้ำกันหลายแถว
        final List<dynamic> productRes = await _supabase
            .from('products')
            .select('id, stock')
            .eq('name', productName);

        if (productRes.isNotEmpty) {
          final product = productRes.first;
          final productId = product['id'];
          final int currentStock = int.tryParse(product['stock'].toString()) ?? 0;
          final int newStock = currentStock - buyQty;

          await _supabase.from('products').update({
            'stock': newStock >= 0 ? newStock : 0,
          }).eq('id', productId);
        }
      }

      // อัปเดตสถานะออเดอร์เป็นสำเร็จ
      await _supabase
          .from('orders')
          .update({'status': 'สำเร็จ'})
          .eq('id', orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อนุมัติออเดอร์และตัดสต็อกสำเร็จ!')),
        );
      }

      _fetchOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการอนุมัติ: $e')),
        );
      }
    }
  }

  // แสดงสลิปขนาดใหญ่
  void _showSlipDialog(String slipUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('หลักฐานการโอนเงิน'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Image.network(slipUrl),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตรวจสอบคำสั่งซื้อและสลิป', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text('ยังไม่มีคำสั่งซื้อในระบบ', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final status = order['status'] ?? 'รอตรวจสอบ';
                    final items = order['items'] as List<dynamic>? ?? [];
                    final slipUrl = order['slip_url'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('ออเดอร์ #${order['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: status == 'รอตรวจสอบ' ? Colors.orange[100] : Colors.green[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: status == 'รอตรวจสอบ' ? Colors.orange[800] : Colors.green[800],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('อีเมลลูกค้า: ${order['user_email']}', style: const TextStyle(color: Colors.grey)),
                          const Divider(height: 20),
                          const Text('รายการสินค้า:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ...items.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text('- ${item['product_name']} (${item['size']}, ${item['color']}) x${item['quantity']}')),
                                    Text('฿${(double.tryParse(item['price'].toString()) ?? 0) * (int.tryParse(item['quantity'].toString()) ?? 1)}'),
                                  ],
                                ),
                              )),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('ยอดรวมทั้งหมด:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('฿${order['total_price']}', style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (slipUrl != null && slipUrl.toString().isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: () => _showSlipDialog(slipUrl),
                              icon: const Icon(Icons.receipt_long),
                              label: const Text('ตรวจสอบสลิปโอนเงิน'),
                            ),
                          const SizedBox(height: 12),
                          if (status == 'รอตรวจสอบ')
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                onPressed: () => _approveOrder(order),
                                child: const Text('อนุมัติออเดอร์และตัดสต็อก', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}