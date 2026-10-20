import 'package:flutter/material.dart';
import 'checkout_page.dart';
import 'cart_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // ดึงรายการสินค้ามาจาก CartService โดยตรง
  List<Map<String, dynamic>> get _cartItems => CartService().items;

  // เซ็ตสำหรับเก็บ index ของสินค้าที่ถูกเลือกชำระเงิน
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    // เริ่มต้นให้เลือกสินค้าทุกชิ้นในตะกร้าโดยอัตโนมัติ
    _selectAllItems();
  }

  void _selectAllItems() {
    setState(() {
      _selectedIndices.clear();
      for (int i = 0; i < _cartItems.length; i++) {
        _selectedIndices.add(i);
      }
    });
  }

  // คำนวณราคารวมสินค้าเฉพาะชิ้นที่ถูกเลือก (ยังไม่หักส่วนลด)
  double get _totalPrice {
    double total = 0;
    for (int index in _selectedIndices) {
      if (index < _cartItems.length) {
        final item = _cartItems[index];
        double price = double.tryParse(item['price'].toString()) ?? 0;
        int qty = int.tryParse(item['quantity'].toString()) ?? 1;
        total += (price * qty);
      }
    }
    return total;
  }

  // คำนวณมูลค่าส่วนลดจาก CartService (คิดจากยอดเฉพาะสินค้าที่เลือก)
  double get _discountAmount {
    if (_totalPrice <= 0) return 0;
    return CartService().getDiscountAmount(_totalPrice);
  }

  // คำนวณยอดสุทธิหลังหักส่วนลด
  double get _finalPrice {
    double finalPrice = _totalPrice - _discountAmount;
    return finalPrice < 0 ? 0 : finalPrice;
  }

  // ฟังก์ชันแสดง Dialog สำหรับเปลี่ยน ไซส์ และ สี ของสินค้าในตะกร้า
  void _showEditOptionsDialog(int index) {
    final item = _cartItems[index];
    
    final List<String> availableSizes = ['S', 'M', 'L', 'XL', 'Free Size'];
    final List<String> availableColors = ['ดำ', 'ขาว', 'ชมพู', 'ฟ้า', 'ครีม', 'เทา'];

    String selectedSize = item['size'] ?? availableSizes.first;
    String selectedColor = item['color'] ?? availableColors.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('เปลี่ยนไซส์และสี', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('เลือกไซส์:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: availableSizes.map((size) {
                      final isSelected = selectedSize == size;
                      return ChoiceChip(
                        label: Text(size),
                        selected: isSelected,
                        selectedColor: const Color(0xFF7C3AED),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (selected) {
                          setDialogState(() {
                            selectedSize = size;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('เลือกสี:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: availableColors.map((color) {
                      final isSelected = selectedColor == color;
                      return ChoiceChip(
                        label: Text(color),
                        selected: isSelected,
                        selectedColor: const Color(0xFF7C3AED),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (selected) {
                          setDialogState(() {
                            selectedColor = color;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    setState(() {
                      _cartItems[index]['size'] = selectedSize;
                      _cartItems[index]['color'] = selectedColor;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('อัปเดตตัวเลือกสินค้าเรียบร้อยแล้ว'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Text('ยืนยัน', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAllSelected = _cartItems.isNotEmpty && _selectedIndices.length == _cartItems.length;

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
                // แถบปุ่มเลือกทั้งหมด
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Checkbox(
                        activeColor: const Color(0xFF7C3AED),
                        value: isAllSelected,
                        onChanged: (bool? value) {
                          if (value == true) {
                            _selectAllItems();
                          } else {
                            setState(() {
                              _selectedIndices.clear();
                            });
                          }
                        },
                      ),
                      Text('เลือกทั้งหมด (${_cartItems.length} รายการ)', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // รายการสินค้าพร้อม Checkbox
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      final isSelected = _selectedIndices.contains(index);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected ? Border.all(color: const Color(0xFF7C3AED), width: 1.5) : null,
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
                            // Checkbox สำหรับเลือกชำระเงินสินค้าชิ้นนี้
                            Checkbox(
                              activeColor: const Color(0xFF7C3AED),
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedIndices.add(index);
                                  } else {
                                    _selectedIndices.remove(index);
                                  }
                                });
                              },
                            ),
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: item['image_url'] != null && item['image_url'].toString().isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item['image_url'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.shopping_bag, color: Colors.grey),
                                      ),
                                    )
                                  : const Icon(Icons.shopping_bag, color: Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] ?? 'ไม่มีชื่อสินค้า',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: () => _showEditOptionsDialog(index),
                                    borderRadius: BorderRadius.circular(4),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'ไซส์: ${item['size'] ?? '-'} | สี: ${item['color'] ?? '-'}',
                                            style: const TextStyle(color: Color(0xFF7C3AED), fontSize: 13, fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.edit, size: 14, color: Color(0xFF7C3AED)),
                                        ],
                                      ),
                                    ),
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
                                          if (item['quantity'] > 1) {
                                            item['quantity']--;
                                          }
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
                                      _selectedIndices.remove(index);
                                      _selectAllItems();
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

                // ส่วนแสดงผลสรุปยอด, สวิตช์เปิด/ปิดคูปอง และปุ่มชำระเงิน
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
                          Text('ยอดรวมสินค้าที่เลือก (${_selectedIndices.length} รายการ)', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                          Text('฿$_totalPrice', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ส่วนเปิด/ปิดการใช้คูปองส่วนลดแบบสวิตช์ (Switch)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: CartService().hasDiscountCoupon ? Colors.purple.shade50 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: CartService().hasDiscountCoupon ? const Color(0xFF7C3AED) : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.confirmation_number_outlined,
                                  color: CartService().hasDiscountCoupon ? const Color(0xFF7C3AED) : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  CartService().hasDiscountCoupon
                                      ? 'โค้ดส่วนลด (${CartService().appliedCouponCode} -${CartService().discountPercent}%)'
                                      : 'ใช้โค้ดส่วนลด (WELCOME50)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: CartService().hasDiscountCoupon ? const Color(0xFF7C3AED) : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: CartService().hasDiscountCoupon,
                              activeColor: const Color(0xFF7C3AED),
                              onChanged: (bool value) {
                                setState(() {
                                  if (value) {
                                    CartService().applyCoupon('WELCOME50', 50);
                                  } else {
                                    CartService().removeCoupon();
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      if (CartService().hasDiscountCoupon && _totalPrice > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ส่วนลด (${CartService().appliedCouponCode} - ${CartService().discountPercent}%)',
                              style: const TextStyle(fontSize: 14, color: Colors.redAccent, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '-฿$_discountAmount',
                              style: const TextStyle(fontSize: 14, color: Colors.redAccent, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],

                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ยอดรวมทั้งสิ้น', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(
                            '฿$_finalPrice',
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
                          onPressed: _selectedIndices.isEmpty ? null : () {
                            // ส่งเฉพาะรายการที่ผู้ใช้เลือกติ๊กไปยัง CheckoutPage
                            // (หาก CheckoutPage ดึงจาก CartService ตรงๆ สามารถปรับตัวกรองได้ตามต้องการ)
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CheckoutPage()),
                            ).then((_) => setState(() {}));
                          },
                          child: Text(
                            _selectedIndices.isEmpty ? 'กรุณาเลือกสินค้าอย่างน้อย 1 ชิ้น' : 'ดำเนินการชำระเงิน (${_selectedIndices.length})',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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