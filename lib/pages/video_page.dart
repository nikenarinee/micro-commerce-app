import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  final _supabase = Supabase.instance.client;

  // ดึงรายการวิดีโอพร้อมข้อมูลสินค้าที่ผูกไว้ (Relational Join)
  Future<List<Map<String, dynamic>>> _fetchVideos() async {
    final response = await _supabase.from('videos').select('''
          id,
          title,
          video_url,
          thumbnail_url,
          products (
            id,
            name,
            price,
            image_url
          )
        ''').order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.ondemand_video, color: Colors.purpleAccent),
            SizedBox(width: 8),
            Text(
              'Video & Review',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchVideos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.purpleAccent),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'เกิดข้อผิดพลาด: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final videos = snapshot.data ?? [];

          if (videos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_collection_outlined,
                      size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'ยังไม่มีวิดีโอรีวิวในขณะนี้',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              final product = video['products'] as Map<String, dynamic>?;

              final productImage = product != null &&
                      product['image_url'] != null &&
                      product['image_url'].toString().isNotEmpty
                  ? product['image_url'].toString().split(',').first.trim()
                  : '';

              return Stack(
                children: [
                  // 1. พื้นหลังคลิปวิดีโอ (หรือ Thumbnail รูปภาพ)
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey[900],
                    child: video['thumbnail_url'] != null &&
                            video['thumbnail_url'].toString().isNotEmpty
                        ? Image.network(
                            video['thumbnail_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.play_circle_fill,
                                  size: 80, color: Colors.white54),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.play_circle_fill,
                                size: 80, color: Colors.white54),
                          ),
                  ),

                  // Shadow Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8)
                        ],
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // 2. ชื่อคลิปด้านล่าง
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: product != null ? 100 : 30,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video['title'] ?? 'วิดีโอรีวิวสินค้า',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // 3. การ์ดสินค้าที่ผูกไว้ใต้คลิป (กดดู/ใส่ตะกร้าได้)
                  if (product != null)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 20,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: productImage.isNotEmpty
                                  ? Image.network(
                                      productImage,
                                      width: 45,
                                      height: 45,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 45,
                                      height: 45,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.shopping_bag),
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '฿${product['price']}',
                                    style: const TextStyle(
                                      color: Color(0xFF7C3AED),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C3AED),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'สั่งซื้อ ${product['name']} เรียบร้อย!'),
                                  ),
                                );
                              },
                              child: const Text('ซื้อเลย'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}