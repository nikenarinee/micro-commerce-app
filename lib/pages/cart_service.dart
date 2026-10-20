class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<Map<String, dynamic>> items = [];

  // ตัวแปรเก็บข้อมูลส่วนลดปัจจุบัน
  bool hasDiscountCoupon = false;
  String appliedCouponCode = '';
  int discountPercent = 0;

  // ฟังก์ชันเพิ่มแบบปกติ (จากหน้า Home)
  void addItem(Map<String, dynamic> product) {
    final existingIndex = items.indexWhere((item) => item['id'] == product['id']);
    if (existingIndex >= 0) {
      items[existingIndex]['quantity'] = (items[existingIndex]['quantity'] ?? 1) + 1;
    } else {
      final newItem = Map<String, dynamic>.from(product);
      newItem['quantity'] = 1;
      newItem['size'] = newItem['size'] ?? 'M';
      newItem['color'] = newItem['color'] ?? 'ดำ';
      items.add(newItem);
    }
  }

  // ฟังก์ชันเพิ่มแบบละเอียด (จากหน้า Detail ที่เลือกไซส์ สี และจำนวน)
  void addItemWithDetails(Map<String, dynamic> product, String size, String color, int quantity) {
    final existingIndex = items.indexWhere((item) => 
      item['id'] == product['id'] && 
      item['size'] == size && 
      item['color'] == color
    );
    
    if (existingIndex >= 0) {
      items[existingIndex]['quantity'] = (items[existingIndex]['quantity'] ?? 1) + quantity;
    } else {
      final newItem = Map<String, dynamic>.from(product);
      newItem['size'] = size;
      newItem['color'] = color;
      newItem['quantity'] = quantity;
      items.add(newItem);
    }
  }

  // ฟังก์ชันตั้งค่าการใช้โค้ดส่วนลด (รองรับทั้งส่วนลดเริ่มต้นและที่ดึงจาก Supabase)
  void applyCoupon(String code, int percent) {
    hasDiscountCoupon = true;
    appliedCouponCode = code;
    discountPercent = percent;
  }

  // ฟังก์ชันยกเลิกโค้ดส่วนลด
  void removeCoupon() {
    hasDiscountCoupon = false;
    appliedCouponCode = '';
    discountPercent = 0;
  }

  // ฟังก์ชันคำนวณมูลค่าส่วนลด (บาท) จากเปอร์เซ็นต์
  double getDiscountAmount(double totalAmount) {
    if (hasDiscountCoupon && discountPercent > 0) {
      return totalAmount * (discountPercent / 100);
    }
    return 0.0;
  }
}