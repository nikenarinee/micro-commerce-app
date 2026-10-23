import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class AdminVideoPage extends StatefulWidget {
  const AdminVideoPage({super.key});

  @override
  State<AdminVideoPage> createState() => _AdminVideoPageState();
}

class _AdminVideoPageState extends State<AdminVideoPage> {
  final _supabase = Supabase.instance.client;
  
  final _titleController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _thumbnailUrlController = TextEditingController();
  
  String? _selectedProductId;
  List<Map<String, dynamic>> _products = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  // ดึงรายการสินค้ามาใส่ใน Dropdown เพื่อผูกกับวิดีโอ
  Future<void> _fetchProducts() async {
    try {
      final response = await _supabase.from('products').select('id, name');
      setState(() {
        _products = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      // จัดการข้อผิดพลาดถ้ามี
    }
  }

  // 📤 ฟังก์ชันอัปโหลดไฟล์วิดีโอหรือรูปภาพจากเครื่องขึ้น Supabase Storage
  Future<String?> _uploadFileToStorage(bool isVideo) async {
    final picker = ImagePicker();
    
    if (isVideo) {
      // เลือกไฟล์วิดีโอ
      final XFile? pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile == null) return null;

      setState(() => _isUploading = true);
      try {
        final bytes = await pickedFile.readAsBytes();
        final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
        
        await _supabase.storage.from('product-images').uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(contentType: 'video/mp4'),
        );

        return _supabase.storage.from('product-images').getPublicUrl(fileName);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('อัปโหลดวิดีโอไม่สำเร็จ: $e')));
        }
        return null;
      } finally {
        setState(() => _isUploading = false);
      }
    } else {
      // เลือกไฟล์รูปภาพหน้าปก
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile == null) return null;

      setState(() => _isUploading = true);
      try {
        final bytes = await pickedFile.readAsBytes();
        final ext = pickedFile.name.split('.').last;
        final fileName = 'thumb_${DateTime.now().millisecondsSinceEpoch}.$ext';

        await _supabase.storage.from('product-images').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$ext'),
        );

        return _supabase.storage.from('product-images').getPublicUrl(fileName);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('อัปโหลดภาพปกไม่สำเร็จ: $e')));
        }
        return null;
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  // 💾 บันทึกข้อมูลวิดีโอลงตาราง videos
  Future<void> _saveVideo() async {
    final title = _titleController.text.trim();
    final videoUrl = _videoUrlController.text.trim();
    final thumbnailUrl = _thumbnailUrlController.text.trim();

    if (title.isEmpty || videoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อคลิปและอัปโหลดวิดีโอ')),
      );
      return;
    }

    try {
      await _supabase.from('videos').insert({
        'title': title,
        'video_url': videoUrl,
        'thumbnail_url': thumbnailUrl.isNotEmpty ? thumbnailUrl : null,
        'product_id': _selectedProductId,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกวิดีโอรีวิวเรียบร้อย!')),
      );

      _titleController.clear();
      _videoUrlController.clear();
      _thumbnailUrlController.clear();
      setState(() => _selectedProductId = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[150],
      appBar: AppBar(
        title: const Text('จัดการวิดีโอรีวิวสินค้า', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF7C3AED),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('เพิ่มวิดีโอใหม่', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // ชื่อคลิป
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'ชื่อคลิป / หัวข้อรีวิว',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),

              // ช่องและปุ่มอัปโหลดวิดีโอ
              TextField(
                controller: _videoUrlController,
                decoration: InputDecoration(
                  labelText: 'ลิงก์วิดีโอ (เลือกจากเครื่องหรือกรอก URL)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF7C3AED)),
                onPressed: _isUploading ? null : () async {
                  final url = await _uploadFileToStorage(true);
                  if (url != null) {
                    setState(() => _videoUrlController.text = url);
                  }
                },
                icon: const Icon(Icons.video_file),
                label: Text(_isUploading ? 'กำลังอัปโหลด...' : 'เลือกไฟล์วิดีโอจากเครื่อง'),
              ),
              const SizedBox(height: 16),

              // ช่องและปุ่มอัปโหลดภาพปก
              TextField(
                controller: _thumbnailUrlController,
                decoration: InputDecoration(
                  labelText: 'ลิงก์ภาพหน้าปก (ถ้ามี)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF7C3AED)),
                onPressed: _isUploading ? null : () async {
                  final url = await _uploadFileToStorage(false);
                  if (url != null) {
                    setState(() => _thumbnailUrlController.text = url);
                  }
                },
                icon: const Icon(Icons.image),
                label: const Text('เลือกภาพปกจากเครื่อง'),
              ),
              const SizedBox(height: 16),

              // Dropdown เลือกสินค้าที่ผูกกับวิดีโอ
              DropdownButtonFormField<String>(
                value: _selectedProductId,
                decoration: InputDecoration(
                  labelText: 'เลือกสินค้าที่ผูกกับวิดีโอนี้',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: _products.map((prod) {
                  return DropdownMenuItem<String>(
                    value: prod['id'].toString(),
                    child: Text(prod['name'] ?? ''),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedProductId = val);
                },
              ),
              const SizedBox(height: 24),

              // ปุ่มบันทึก
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isUploading ? null : _saveVideo,
                  child: Text(
                    _isUploading ? 'กำลังอัปโหลดไฟล์...' : 'บันทึกวิดีโอ',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}