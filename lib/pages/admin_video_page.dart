import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminVideoPage extends StatefulWidget {
  const AdminVideoPage({super.key});

  @override
  State<AdminVideoPage> createState() => _AdminVideoPageState();
}

class _AdminVideoPageState extends State<AdminVideoPage> {
  final _titleController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _thumbnailUrlController = TextEditingController();

  List<Map<String, dynamic>> _products = [];
  int? _selectedProductId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  // ดึงรายการสินค้าทั้งหมดมาแสดงใน Dropdown ให้แอดมินเลือกผูก
  Future<void> _fetchProducts() async {
    try {
      final response = await Supabase.instance.client
          .from('products')
          .select('id, name');
      setState(() {
        _products = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }
  }

  // บันทึกข้อมูลวิดีโอลง Supabase
  Future<void> _saveVideo() async {
    if (_titleController.text.trim().isEmpty ||
        _videoUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อคลิปและ URL วิดีโอ')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.from('videos').insert({
        'title': _titleController.text.trim(),
        'video_url': _videoUrlController.text.trim(),
        'thumbnail_url': _thumbnailUrlController.text.trim().isNotEmpty
            ? _thumbnailUrlController.text.trim()
            : null,
        'product_id': _selectedProductId,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เพิ่มวิดีโอเรียบร้อยแล้ว!'),
          backgroundColor: Colors.green,
        ),
      );

      _titleController.clear();
      _videoUrlController.clear();
      _thumbnailUrlController.clear();
      setState(() {
        _selectedProductId = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการวิดีโอรีวิวสินค้า'),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'เพิ่มวิดีโอใหม่',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'ชื่อคลิป / หัวข้อรีวิว',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _videoUrlController,
              decoration: const InputDecoration(
                labelText: 'URL วิดีโอ (.mp4 หรือ ลิงก์วิดีโอ)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _thumbnailUrlController,
              decoration: const InputDecoration(
                labelText: 'URL ภาพหน้าปก (ถ้ามี)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _selectedProductId,
              decoration: const InputDecoration(
                labelText: 'เลือกสินค้าที่ผูกกับวิดีโอนี้',
                border: OutlineInputBorder(),
              ),
              items: _products.map((item) {
                return DropdownMenuItem<int>(
                  value: item['id'] as int,
                  child: Text(item['name'] ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProductId = value;
                });
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveVideo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('บันทึกวิดีโอ', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}