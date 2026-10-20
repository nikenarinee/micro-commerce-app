import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminCouponPage extends StatefulWidget {
  const AdminCouponPage({super.key});

  @override
  State<AdminCouponPage> createState() => _AdminCouponPageState();
}

class _AdminCouponPageState extends State<AdminCouponPage> {
  final _supabase = Supabase.instance.client;
  final _codeController = TextEditingController();
  final _percentController = TextEditingController();
  bool _isLoading = false;

  // ฟังก์ชันเพิ่มโค้ดส่วนลดใหม่ลง Supabase
  Future<void> _addCoupon() async {
    final code = _codeController.text.trim().toUpperCase();
    final percent = int.tryParse(_percentController.text.trim()) ?? 0;

    if (code.isEmpty || percent <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกรหัสโค้ดและเปอร์เซ็นต์ส่วนลดให้ถูกต้อง')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _supabase.from('coupons').insert({
        'code': code,
        'discount_percent': percent,
        'is_active': true,
      });

      _codeController.clear();
      _percentController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เพิ่มโค้ดส่วนลดเรียบร้อยแล้ว!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด (โค้ดอาจจะซ้ำ): $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการโค้ดส่วนลด (แอดมิน)'),
        backgroundColor: const Color(0xFF7C3AED),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('สร้างโค้ดส่วนลดใหม่', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'รหัสโค้ด (เช่น SAVE20, SPECIAL50)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _percentController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'เปอร์เซ็นต์ส่วนลด (%)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
                      onPressed: _isLoading ? null : _addCoupon,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('บันทึกโค้ดส่วนลด', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('รายการโค้ดส่วนลดทั้งหมดในระบบ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _supabase.from('coupons').stream(primaryKey: ['id']),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final coupons = snapshot.data!;

                  if (coupons.isEmpty) {
                    return const Center(child: Text('ยังไม่มีโค้ดส่วนลดในระบบ'));
                  }

                  return ListView.builder(
                    itemCount: coupons.length,
                    itemBuilder: (context, index) {
                      final coupon = coupons[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.confirmation_number, color: Color(0xFF7C3AED)),
                          title: Text(coupon['code'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('ส่วนลด ${coupon['discount_percent']}%'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await _supabase.from('coupons').delete().eq('id', coupon['id']);
                            },
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
      ),
    );
  }
}