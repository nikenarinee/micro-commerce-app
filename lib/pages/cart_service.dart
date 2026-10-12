class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<Map<String, dynamic>> items = [];

  // เพิ่มแบบปกติ (จากหน้า Home)
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

  // เพิ่มแบบละเอียด (จากหน้า Detail ที่เลือกไซส์ สี และจำนวน)
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
}