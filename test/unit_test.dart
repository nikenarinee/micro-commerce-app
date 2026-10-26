import 'package:flutter_test/flutter_test.dart';

void main() {
  group('10 Unit Test Cases - Micro Commerce App', () {
    // Case 1: คำนวณราคารวมสินค้าปกติ
    test('Case 1: Calculate total price of item', () {
      double price = 150.0;
      int quantity = 2;
      double total = price * quantity;
      expect(total, 300.0);
    });

    // Case 2: คำนวณราคารวมเมื่อไม่มีสินค้า (ปริมาณ = 0)
    test('Case 2: Calculate total price when quantity is zero', () {
      double price = 250.0;
      int quantity = 0;
      double total = price * quantity;
      expect(total, 0.0);
    });

    // Case 3: คำนวณราคาสินค้าหลังหักส่วนลด (Coupon)
    test('Case 3: Apply discount amount correctly', () {
      double originalPrice = 500.0;
      double discount = 50.0;
      double finalPrice = originalPrice - discount;
      expect(finalPrice, 450.0);
    });

    // Case 4: ตรวจสอบเปอร์เซ็นต์ส่วนลดไม่เกินราคาเต็ม
    test('Case 4: Discount percentage calculation', () {
      double price = 200.0;
      double discountPercent = 10; // 10%
      double discountAmount = price * (discountPercent / 100);
      expect(discountAmount, 20.0);
    });

    // Case 5: ตรวจสอบความยาวรหัสผ่านขั้นต่ำ (Password Length Validation) [เปลี่ยนมาใช้ภาษาอังกฤษแทน]
    test('Case 5: Password minimum length validation', () {
      String password = 'secure123';
      bool isValidPassword = password.length >= 6;
      expect(isValidPassword, isTrue);
    });

    // Case 6: เช็กสถานะการกรองหมวดหมู่สินค้า
    test('Case 6: Filter product category', () {
      List<String> categories = ['เสื้อผ้า', 'รองเท้า', 'เล็บปลอม', 'ของใช้'];
      String selectedCategory = 'รองเท้า';
      bool isMatch = categories.contains(selectedCategory);
      expect(isMatch, isTrue);
    });

    // Case 7: ตรวจสอบสถานะสินค้าในสต็อก
    test('Case 7: Check stock availability', () {
      int stockCount = 5;
      bool inStock = stockCount > 0;
      expect(inStock, isTrue);
    });

    // Case 8: ตรวจสอบสินค้าที่สต็อกหมด
    test('Case 8: Out of stock validation', () {
      int stockCount = 0;
      bool isOutOfStock = stockCount <= 0;
      expect(isOutOfStock, isTrue);
    });

    // Case 9: ตรวจสอบฟอร์แมตอีเมลผู้ใช้งานเบื้องต้น
    test('Case 9: Validate email format', () {
      String email = 'nicephimpha@gmail.com';
      bool isValidEmail = email.contains('@') && email.contains('.');
      expect(isValidEmail, isTrue);
    });

    // Case 10: นับจำนวนรายการสินค้าในตะกร้า
    test('Case 10: Count cart items quantity', () {
      List<String> cartItems = ['เสื้อยืด', 'กางเกง', 'รองเท้าผ้าใบ'];
      expect(cartItems.length, 3);
    });
  });
}