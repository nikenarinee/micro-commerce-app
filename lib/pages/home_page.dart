import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_page.dart';
import 'profile_page.dart';
import 'customer_orders_page.dart';
import 'cart_page.dart';
import 'product_detail_page.dart';
import 'cart_service.dart';
import 'coupon_page.dart';
import 'mall_page.dart';
import 'video_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  String _searchQuery = '';
  String _selectedCategory = 'ทั้งหมด';
  final List<String> _categories = ['ทั้งหมด', 'เสื้อผ้า', 'รองเท้า', 'เล็บปลอม'];

  String _selectedPriceSort = 'none';
  double? _minPrice;
  double? _maxPrice;

  Widget _buildBodyContent() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTabContent();
      case 1:
        return const MallPage();
      case 2:
        return const VideoPage();
      case 3:
        return const CustomerOrdersPage();
      case 4:
        return const ProfilePage();
      default:
        return _buildHomeTabContent();
    }
  }

  void _showPriceRangeDialog() {
    final TextEditingController minController = TextEditingController(
      text: _minPrice != null ? _minPrice.toString() : '',
    );
    final TextEditingController maxController = TextEditingController(
      text: _maxPrice != null ? _maxPrice.toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('กรอกช่วงราคา (บาท)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: minController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ราคาต่ำสุด',
                  border: OutlineInputBorder(),
                  prefixText: '฿ ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ราคาสูงสุด',
                  border: OutlineInputBorder(),
                  prefixText: '฿ ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _minPrice = null;
                  _maxPrice = null;
                });
                Navigator.pop(context);
              },
              child: const Text('ล้างค่า', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
              onPressed: () {
                setState(() {
                  _minPrice = double.tryParse(minController.text);
                  _maxPrice = double.tryParse(maxController.text);
                });
                Navigator.pop(context);
              },
              child: const Text('ตกลง', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHomeTabContent() {
    return NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  color: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.only(top: 45, left: 16, right: 16, bottom: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.search, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      onChanged: (value) {
                                        setState(() {
                                          _searchQuery = value;
                                        });
                                      },
                                      decoration: const InputDecoration(
                                        hintText: 'ค้นหาสินค้า...',
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CartPage()),
                                ).then((_) => setState(() {})),
                              ),
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${CartService().items.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: Supabase.instance.client
                                .from('messages')
                                .select()
                                .eq('is_read', false),
                            builder: (context, snapshot) {
                              int unreadCount = 0;
                              if (snapshot.hasData) {
                                unreadCount = snapshot.data!.length;
                              }

                              return Stack(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF67E8F9)),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const ChatPage()),
                                    ).then((_) => setState(() {})),
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: 6,
                                      top: 6,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CouponPage()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Row(
                                children: [
                                  Icon(Icons.confirmation_number, color: Color(0xFF7C3AED)),
                                  SizedBox(width: 8),
                                  Text('ศูนย์รวมโค้ดส่วนลด (เก็บโค้ด)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                                ],
                              ),
                              Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF7C3AED)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const BannerCarousel(),
              ],
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverCategoryDelegate(
              child: Container(
                color: Colors.grey[100],
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  children: [
                    ..._categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          selectedColor: const Color(0xFF7C3AED),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          backgroundColor: Colors.white,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                        ),
                      );
                    }),
                    const SizedBox(width: 4),
                    const VerticalDivider(color: Colors.grey, indent: 8, endIndent: 8),
                    const SizedBox(width: 4),
                    Container(
                      height: 40,
                      margin: const EdgeInsets.only(right: 8),
                      child: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'custom_price') {
                            _showPriceRangeDialog();
                          } else {
                            setState(() {
                              _selectedPriceSort = value;
                            });
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'none',
                            child: Row(
                              children: [
                                Icon(Icons.sort, size: 18, color: Colors.grey),
                                SizedBox(width: 8),
                                Text('ค่าเริ่มต้น (ปกติ)'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'low_to_high',
                            child: Row(
                              children: [
                                Icon(Icons.arrow_upward, size: 18, color: Color(0xFF7C3AED)),
                                SizedBox(width: 8),
                                Text('ราคา: ถูกสุดไปแพงสุด'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'high_to_low',
                            child: Row(
                              children: [
                                Icon(Icons.arrow_downward, size: 18, color: Color(0xFF7C3AED)),
                                SizedBox(width: 8),
                                Text('ราคา: แพงสุดไปถูกสุด'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'custom_price',
                            child: Row(
                              children: [
                                Icon(Icons.tune, size: 18, color: Colors.green),
                                SizedBox(width: 8),
                                Text('ระบุช่วงราคา (ต่ำสุด - สูงสุด)'),
                              ],
                            ),
                          ),
                        ],
                        child: Chip(
                          backgroundColor: (_selectedPriceSort != 'none' || _minPrice != null || _maxPrice != null)
                              ? const Color(0xFF7C3AED).withOpacity(0.2)
                              : Colors.white,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.filter_list,
                                size: 16,
                                color: (_selectedPriceSort != 'none' || _minPrice != null || _maxPrice != null)
                                    ? const Color(0xFF7C3AED)
                                    : Colors.black87,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _minPrice != null || _maxPrice != null
                                    ? 'ราคา: ฿${_minPrice ?? 0} - ${_maxPrice ?? '∞'}'
                                    : _selectedPriceSort == 'low_to_high'
                                        ? 'ถูกสุด'
                                        : _selectedPriceSort == 'high_to_low'
                                            ? 'แพงสุด'
                                            : 'จัดเรียงราคา',
                                style: TextStyle(
                                  color: (_selectedPriceSort != 'none' || _minPrice != null || _maxPrice != null)
                                      ? const Color(0xFF7C3AED)
                                      : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ];
      },
      body: ProductGridView(
        searchQuery: _searchQuery,
        selectedCategory: _selectedCategory,
        priceSort: _selectedPriceSort,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _buildBodyContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF7C3AED),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'หน้าแรก'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), activeIcon: Icon(Icons.storefront), label: 'Mall'),
          BottomNavigationBarItem(icon: Icon(Icons.ondemand_video_outlined), activeIcon: Icon(Icons.ondemand_video), label: 'วิดีโอ'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'คำสั่งซื้อ'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'ฉัน'),
        ],
      ),
    );
  }
}

class _SliverCategoryDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverCategoryDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  double get maxExtent => 50.0;

  @override
  double get minExtent => 50.0;

  @override
  bool shouldRebuild(covariant _SliverCategoryDelegate oldDelegate) => false;
}

class ProductGridView extends StatefulWidget {
  final String searchQuery;
  final String selectedCategory;
  final String priceSort;
  final double? minPrice;
  final double? maxPrice;

  const ProductGridView({
    super.key,
    required this.searchQuery,
    required this.selectedCategory,
    required this.priceSort,
    this.minPrice,
    this.maxPrice,
  });

  @override
  State<ProductGridView> createState() => _ProductGridViewState();
}

class _ProductGridViewState extends State<ProductGridView> {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    var query = _supabase.from('products').select();
    
    if (widget.searchQuery.isNotEmpty) {
      query = query.ilike('name', '%${widget.searchQuery}%');
    }

    final response = await query;
    List<Map<String, dynamic>> products = List<Map<String, dynamic>>.from(response);

    if (widget.selectedCategory != 'ทั้งหมด') {
      products = products.where((product) {
        final name = (product['name'] ?? '').toString().toLowerCase();

        if (widget.selectedCategory == 'เสื้อผ้า' || widget.selectedCategory == 'เสื้อ') {
          return name.contains('เสื้อ') || name.contains('เดรส') || name.contains('ชุด') || name.contains('กางเกง') || name.contains('กระโปรง');
        } else if (widget.selectedCategory == 'รองเท้า') {
          return name.contains('รองเท้า') || name.contains('ส้นสูง') || name.contains('ผ้าใบ');
        } else if (widget.selectedCategory == 'เล็บปลอม') {
          return name.contains('เล็บ') || name.contains('เล็บปลอม');
        }

        return name.contains(widget.selectedCategory.toLowerCase());
      }).toList();
    }

    if (widget.minPrice != null) {
      products = products.where((p) => ((p['price'] ?? 0) as num).toDouble() >= widget.minPrice!).toList();
    }
    if (widget.maxPrice != null) {
      products = products.where((p) => ((p['price'] ?? 0) as num).toDouble() <= widget.maxPrice!).toList();
    }

    if (widget.priceSort == 'low_to_high') {
      products.sort((a, b) => ((a['price'] ?? 0) as num).compareTo((b['price'] ?? 0) as num));
    } else if (widget.priceSort == 'high_to_low') {
      products.sort((a, b) => ((b['price'] ?? 0) as num).compareTo((a['price'] ?? 0) as num));
    }

    return products;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        }
        final products = snapshot.data;
        if (products == null || products.isEmpty) {
          return const Center(child: Text('ไม่พบสินค้าในช่วงราคานี้', style: TextStyle(color: Colors.grey)));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
              ).then((_) => setState(() {})),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: product['image_url'] != null && product['image_url'].toString().isNotEmpty
                            ? ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: Image.network(
                                  product['image_url'].toString().split(',').first.trim(),
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
                                ),
                              )
                            : const Center(child: Icon(Icons.shopping_bag, size: 40, color: Colors.grey)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'] ?? 'ไม่มีชื่อสินค้า',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '฿${product['price']}',
                                style: const TextStyle(
                                  color: Color(0xFF059669),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  CartService().addItem(product);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('เพิ่ม "${product['name']}" ลงตะกร้าแล้ว'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                  setState(() {});
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C3AED),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.add, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _supabase = Supabase.instance.client;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<Map<String, dynamic>> _banners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  Future<void> _fetchBanners() async {
    try {
      final response = await _supabase.from('banners').select().order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _banners = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextPage() {
    if (_banners.isNotEmpty) {
      int next = (_currentPage + 1) % _banners.length;
      _pageController.animateToPage(next, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevPage() {
    if (_banners.isNotEmpty) {
      int prev = (_currentPage - 1 + _banners.length) % _banners.length;
      _pageController.animateToPage(prev, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
    }

    if (_banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemCount: _banners.length,
                  itemBuilder: (context, index) {
                    final banner = _banners[index];
                    final rawUrl = (banner['image_url'] ?? '').toString();
                    final imageUrl = rawUrl.contains(',') ? rawUrl.split(',').first.trim() : rawUrl.trim();

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                                        ),
                                      ),
                                    )
                                  : Container(color: Colors.grey[300]),
                            ),
                            Positioned.fill(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                ),
                                alignment: Alignment.bottomLeft,
                                child: Text(
                                  banner['title'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  left: 24,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black.withOpacity(0.35),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.white),
                        onPressed: _prevPage,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 24,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black.withOpacity(0.35),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
                        onPressed: _nextPage,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _banners.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == index ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentPage == index ? const Color(0xFF7C3AED) : Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}