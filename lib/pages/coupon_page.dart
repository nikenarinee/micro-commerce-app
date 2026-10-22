import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CouponPage extends StatefulWidget {
  const CouponPage({super.key});

  @override
  State<CouponPage> createState() => _CouponPageState();
}

class _CouponPageState extends State<CouponPage> {
  final _supabase = Supabase.instance.client;
  List<int> _claimedCouponIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClaimedCoupons();
  }

  // ดึงรายการ ID คูปองที่ลูกค้าคนนี้เคยเก็บไปแล้ว
  Future<void> _fetchClaimedCoupons() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _supabase
          .from('user_coupons')
          .select('coupon_id')
          .eq('user_id', user.id);

      final List<dynamic> data = response;
      setState(() {
        _claimedCouponIds = data.map((e) => e['coupon_id'] as int).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ฟังก์ชันกดเก็บคูปอง
  Future<void> _claimCoupon(Map<String, dynamic> coupon) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนเก็บคูปอง')),
      );
      return;
    }

    final int couponId = coupon['id'];
    final int usageLimit = coupon['usage_limit'] ?? 10;
    final int claimedCount = coupon['claimed_count'] ?? 0;

    // เช็กสิทธิ์คงเหลือ
    if (claimedCount >= usageLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('สิทธิ์โค้ดส่วนลดนี้หมดแล้ว')),
      );
      return;
    }

    try {
      // 1. บันทึกลงตาราง user_coupons
      await _supabase.from('user_coupons').insert({
        'user_id': user.id,
        'coupon_id': couponId,
        'is_used': false,
      });

      // 2. อัปเดตจำนวนที่ถูกเก็บในตาราง coupons (+1)
      await _supabase.from('coupons').update({
        'claimed_count': claimedCount + 1,
      }).eq('id', couponId);

      setState(() {
        _claimedCouponIds.add(couponId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เก็บโค้ด "${coupon['code']}" สำเร็จ!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('ศูนย์รวมโค้ดส่วนลด', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF7C3AED),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('coupons')
                  .stream(primaryKey: ['id'])
                  .eq('is_active', true),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final now = DateTime.now();
                // กรองเฉพาะคูปองที่ยังไม่หมดอายุ
                final coupons = snapshot.data!.where((coupon) {
                  if (coupon['expires_at'] == null) return true;
                  final expiresAt = DateTime.parse(coupon['expires_at']);
                  return expiresAt.isAfter(now);
                }).toList();

                if (coupons.isEmpty) {
                  return const Center(
                    child: Text('ยังไม่มีโค้ดส่วนลดที่ใช้งานได้ในขณะนี้', style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: coupons.length,
                  itemBuilder: (context, index) {
                    final coupon = coupons[index];
                    final int couponId = coupon['id'];
                    final int limit = coupon['usage_limit'] ?? 10;
                    final int claimed = coupon['claimed_count'] ?? 0;
                    final bool isClaimed = _claimedCouponIds.contains(couponId);
                    final bool isFull = claimed >= limit;
                    final expiresAt = coupon['expires_at'] != null
                        ? DateTime.parse(coupon['expires_at'])
                        : null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          // ฝั่งซ้าย: แสดงเปอร์เซ็นต์ส่วนลด
                          Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              color: Color(0xFF7C3AED),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: Color(0xFF7C3AED) == null ? MainAxisAlignment.center : MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${coupon['discount_percent']}%',
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                                const Text('ส่วนลด', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                          // ฝั่งขวา: รายละเอียดและปุ่มเก็บ
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'โค้ด: ${coupon['code']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ใช้ไปแล้ว $claimed/$limit สิทธิ์',
                                    style: TextStyle(fontSize: 12, color: isFull ? Colors.red : Colors.grey[600]),
                                  ),
                                  if (expiresAt != null)
                                    Text(
                                      'หมดอายุ: ${expiresAt.day}/${expiresAt.month}/${expiresAt.year + 543}',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isClaimed || isFull ? Colors.grey[300] : const Color(0xFF7C3AED),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      ),
                                      onPressed: isClaimed || isFull ? null : () => _claimCoupon(coupon),
                                      child: Text(
                                        isClaimed
                                            ? 'เก็บแล้ว'
                                            : isFull
                                                ? 'สิทธิ์เต็ม'
                                                : 'เก็บโค้ด',
                                        style: TextStyle(
                                          color: isClaimed || isFull ? Colors.grey[600] : Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}