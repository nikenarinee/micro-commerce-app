import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerOrdersPage extends StatefulWidget {
  final String? initialFilter; // เพิ่มตัวแปรรับค่าสถานะจากหน้าโปรไฟล์

  const CustomerOrdersPage({super.key, this.initialFilter});

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage> {
  final _supabase = Supabase.instance.client;
  String _selectedFilter = 'ทั้งหมด';

  // รายการสถานะสำหรับทำแท็บกรองแบบ Shopee
  final List<String> _statuses = ['ทั้งหมด', 'รอตรวจสอบ', 'รอจัดส่ง', 'กำลังจัดส่ง', 'สำเร็จ'];

  @override
  void initState() {
    super.initState();
    // ถ้ามีการส่งค่า initialFilter มาจากหน้าโปรไฟล์ ให้เซ็ตเป็นค่าเริ่มต้นทันที
    if (widget.initialFilter != null && _statuses.contains(widget.initialFilter)) {
      _selectedFilter = widget.initialFilter!;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMyOrders() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // ปรับ Query ดึงข้อมูลตามอีเมล หรือจะเปลี่ยนเป็น user_id ตามตารางจริงของคุณนลินี
      var query = _supabase
          .from('orders')
          .select()
          .eq('user_email', user.email as Object);

      if (_selectedFilter != 'ทั้งหมด') {
        if (_selectedFilter == 'รอจัดส่ง') {
          query = query.ilike('status', '%รอจัดส่ง%');
        } else {
          query = query.eq('status', _selectedFilter);
        }
      }

      final response = await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('ประวัติการสั่งซื้อของฉัน', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // แถบแท็บสถานะด้านบน (สไตล์ Shopee)
          Container(
            color: Colors.white,
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _statuses.length,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemBuilder: (context, index) {
                final status = _statuses[index];
                final isSelected = _selectedFilter == status;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    selectedColor: const Color(0xFFEDE9FE),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF7C3AED) : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = status;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // ส่วนแสดงรายการออร์เดอร์
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchMyOrders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
                }

                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return const Center(
                    child: Text('ยังไม่มีประวัติการสั่งซื้อในสถานะนี้', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final status = order['status'] ?? 'รอตรวจสอบ';
                    final totalPrice = order['total_price'] ?? 0;
                    final slipUrl = order['slip_url'];
                    final createdAt = order['created_at'] != null 
                        ? DateTime.parse(order['created_at']).toLocal().toString().split('.')[0] 
                        : '';

                    // จัดการรหัสออเดอร์ให้ปลอดภัย ไม่ให้ติด RangeError
                    final rawId = order['id']?.toString() ?? '';
                    final displayId = rawId.length > 8 ? rawId.substring(0, 8) : rawId;

                    // กำหนดสีและข้อความของสถานะ
                    Color statusColor = Colors.orange;
                    if (status == 'อนุมัติแล้ว' || status == 'สำเร็จ') {
                      statusColor = Colors.green;
                    } else if (status == 'ปฏิเสธ') {
                      statusColor = Colors.red;
                    } else if (status == 'รอจัดส่ง') {
                      statusColor = Colors.blue;
                    } else if (status == 'กำลังจัดส่ง') {
                      statusColor = Colors.purple;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'คำสั่งซื้อ # $displayId',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                          const Divider(height: 20),
                          Text('วันที่สั่งซื้อ: $createdAt', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text(
                            'ยอดชำระทั้งหมด: ฿$totalPrice',
                            style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (slipUrl != null && slipUrl.toString().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('หลักฐานการโอนเงิน'),
                                    content: Image.network(slipUrl),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('ปิด'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.receipt, size: 18),
                              label: const Text('ดูสลิปที่แนบ'),
                            ),
                          ],
                        ],
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