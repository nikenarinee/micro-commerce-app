import 'package:flutter/material.dart';
import 'checkout_page.dart'; // เดี๋ยวเราจะสร้างหน้านี้ต่อครับ

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // จำลองรายการสินค้าในตะกร้า (ในอนาคตสามารถเชื่อมฐานข้อมูลหรือ state management ได้)
  final List<Map<String, dynamic>> _cartItems = [
    {
      'name': 'เสื้อยืดวินเทจ',
      'price': 290,
      'size': 'M',
      'color': 'ดำ',
      'quantity': 1,
      'image_url': '',
    },
    {
      'name': 'เสื้อยืดลายพิเศษ',
      'price': 250,
      'size': 'L',
      'color': 'ขาว',
      'quantity': 2,
      'image_url': '',
    },
  ];

  double get _totalPrice {
    double total = 0;
    for (var item in _cartItems) {
      total += (item['price'] * item['quantity']);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('ตะกร้าสินค้าของฉัน', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _cartItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('ไม่มีสินค้าในตะกร้าของคุณ', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
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
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.shopping_bag, color: Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ไซส์: ${item['size']} | สี: ${item['color']}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '฿${item['price']}',
                                    style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (item['quantity'] > 1) item['quantity']--;
                                        });
                                      },
                                      child: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.grey),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text('${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          item['quantity']++;
                                        });
                                      },
                                      child: const Icon(Icons.add_circle_outline, size: 20, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _cartItems.removeAt(index);
                                    });
                                  },
                                  child: const Text('ลบ', style: TextStyle(color: Colors.red, fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // สรุปยอดและปุ่มชำระเงิน
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ยอดรวมทั้งสิ้น', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(
                            '฿$_totalPrice',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF7C3AED)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CheckoutPage()),
                            );
                          },
                          child: const Text(
                            'ดำเนินการชำระเงิน',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}