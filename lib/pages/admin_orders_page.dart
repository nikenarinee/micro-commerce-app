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

  // อัปเดตสถานะออเดอร์ (เช่น เปลี่ยนเป็น รอจัดส่ง, กำลังจัดส่ง, สำเร็จ)
  Future<void> _updateOrderStatus(String orderId, String newStatus, {bool deductStock = false, Map<String, dynamic>? orderData}) async {
    try {
      // ถ้าเป็นการอนุมัติและต้องตัดสต็อก
      if (deductStock && orderData != null) {
        final items = orderData['items'] as List<dynamic>? ?? [];

        for (var item in items) {
          final productName = item['product_name'];
          final int buyQty = int.tryParse(item['quantity'].toString()) ?? 1;

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
      }

      // อัปเดตสถานะในตาราง orders
      await _supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('อัปเดตสถานะเป็น "$newStatus" สำเร็จ!'), backgroundColor: Colors.green),
        );
      }

      _fetchOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
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
                    final orderId = order['id'].toString();
                    final status = order['status'] ?? 'รอตรวจสอบ';
                    final items = order['items'] as List<dynamic>? ?? [];
                    final slipUrl = order['slip_url'];

                    Color statusColor = Colors.orange;
                    if (status == 'รอจัดส่ง') statusColor = Colors.blue;
                    if (status == 'กำลังจัดส่ง') statusColor = Colors.purple;
                    if (status == 'สำเร็จ') statusColor = Colors.green;

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
                              Text('ออเดอร์ #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
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
                                    Expanded(child: Text('- ${item['product_name']} x${item['quantity']}')),
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
                          
                          // ปุ่มจัดการเปลี่ยนสถานะตามขั้นตอน
                          if (status == 'รอตรวจสอบ')
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                onPressed: () => _updateOrderStatus(orderId, 'รอจัดส่ง'),
                                child: const Text('ยืนยันสลิป และเปลี่ยนเป็น "รอจัดส่ง"', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          if (status == 'รอจัดส่ง')
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                                onPressed: () => _updateOrderStatus(orderId, 'กำลังจัดส่ง'),
                                child: const Text('จัดส่งสินค้าแล้ว (เปลี่ยนเป็น "กำลังจัดส่ง")', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          if (status == 'กำลังจัดส่ง')
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                onPressed: () => _updateOrderStatus(orderId, 'สำเร็จ', deductStock: true, orderData: order),
                                child: const Text('ยืนยันส่งสำเร็จ และตัดสต็อกสินค้า', style: TextStyle(color: Colors.white)),
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