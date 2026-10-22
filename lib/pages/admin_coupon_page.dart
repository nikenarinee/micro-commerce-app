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
  final _limitController = TextEditingController(text: '10'); // ค่าเริ่มต้น 10 สิทธิ์
  DateTime? _selectedDate;
  bool _isLoading = false;

  // ฟังก์ชันดึงรายการคูปองทั้งหมดแบบ Future
  Future<List<Map<String, dynamic>>> _fetchCoupons() async {
    final response = await _supabase
        .from('coupons')
        .select()
        .order('id', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // ฟังก์ชันเพิ่มโค้ดส่วนลดใหม่ลง Supabase พร้อมจำกัดสิทธิ์และวันหมดอายุ
  Future<void> _addCoupon() async {
    final code = _codeController.text.trim().toUpperCase();
    final percent = int.tryParse(_percentController.text.trim()) ?? 0;
    final limit = int.tryParse(_limitController.text.trim()) ?? 10;

    if (code.isEmpty || percent <= 0 || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลและเลือกวันหมดอายุให้ครบถ้วน')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _supabase.from('coupons').insert({
        'code': code,
        'discount_percent': percent,
        'usage_limit': limit,
        'claimed_count': 0,
        'expires_at': _selectedDate!.toIso8601String(),
        'is_active': true,
      });

      _codeController.clear();
      _percentController.clear();
      _limitController.text = '10';
      setState(() {
        _selectedDate = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เพิ่มโค้ดส่วนลดเรียบร้อยแล้ว!'),
            backgroundColor: Color(0xFF7C3AED),
          ),
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('จัดการโค้ดส่วนลด (แอดมิน)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF7C3AED),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {}); // ดึงลงเพื่อรีเฟรชรายการคูปอง
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                        labelText: 'รหัสโค้ด (เช่น FLASH50)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _percentController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'ส่วนลด (%)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _limitController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'จำนวนสิทธิ์',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate == null
                              ? 'ยังไม่ได้เลือกวันหมดอายุ'
                              : 'หมดอายุ: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year + 543}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                _selectedDate = pickedDate;
                              });
                            }
                          },
                          child: const Text('เลือกวันหมดอายุ', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isLoading ? null : () async {
                          await _addCoupon();
                          setState(() {}); // รีเฟรชหน้าจอหลังเพิ่มสำเร็จ
                        },
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
              
              // ใช้ FutureBuilder แทน StreamBuilder เพื่อความเสถียรและโหลดไวไม่หมุนค้าง
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchCoupons(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
                  }

                  final coupons = snapshot.data ?? [];

                  if (coupons.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('ยังไม่มีโค้ดส่วนลดในระบบ', style: TextStyle(color: Colors.grey))),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: coupons.length,
                    itemBuilder: (context, index) {
                      final coupon = coupons[index];
                      final limit = coupon['usage_limit'] ?? 10;
                      final claimed = coupon['claimed_count'] ?? 0;
                      final expiresAt = coupon['expires_at'] != null 
                          ? DateTime.parse(coupon['expires_at']) 
                          : null;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: const Icon(Icons.confirmation_number, color: Color(0xFF7C3AED)),
                          title: Text(coupon['code'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            'ส่วนลด ${coupon['discount_percent']}% | ใช้ไปแล้ว $claimed/$limit สิทธิ์\nหมดอายุ: ${expiresAt != null ? '${expiresAt.day}/${expiresAt.month}/${expiresAt.year + 543}' : 'ไม่ระบุ'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await _supabase.from('coupons').delete().eq('id', coupon['id']);
                              setState(() {}); // รีเฟรชรายการหลังลบ
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('ลบโค้ดส่วนลดเรียบร้อยแล้ว')),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}