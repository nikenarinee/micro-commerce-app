import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminBannerPage extends StatefulWidget {
  const AdminBannerPage({super.key});

  @override
  State<AdminBannerPage> createState() => _AdminBannerPageState();
}

class _AdminBannerPageState extends State<AdminBannerPage> {
  final _supabase = Supabase.instance.client;
  final _titleController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isLoading = false;

  // 📸 ฟังก์ชันเลือกและอัปโหลดรูปภาพจากเครื่องขึ้น Supabase Storage
  Future<String?> _pickAndUploadImage(BuildContext dialogContext) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile == null) return null;

    try {
      if (!mounted) return null;
      showDialog(
        context: dialogContext,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final fileBytes = await pickedFile.readAsBytes();
      final fileExt = pickedFile.name.split('.').last;
      final fileName = 'banner_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // อัปโหลดเข้า Storage bucket ชื่อ 'product-images' (หรือเปลี่ยนตามที่โปรเจกต์ใช้)
      await _supabase.storage.from('product-images').uploadBinary(
            fileName,
            fileBytes,
            fileOptions: FileOptions(contentType: 'image/$fileExt'),
          );

      final publicUrl = _supabase.storage.from('product-images').getPublicUrl(fileName);

      if (dialogContext.mounted) Navigator.pop(dialogContext);
      return publicUrl;
    } catch (e) {
      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('อัปโหลดรูปภาพไม่สำเร็จ: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _addBanner() async {
    final title = _titleController.text.trim();
    final imageUrls = _imageUrlController.text.trim();

    if (title.isEmpty || imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกหัวข้อและเลือกรูปภาพแบนเนอร์')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _supabase.from('banners').insert({
        'title': title,
        'image_url': imageUrls,
      });

      _titleController.clear();
      _imageUrlController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เพิ่มแบนเนอร์โปรโมชันสำเร็จ!')),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBanner(int id) async {
    await _supabase.from('banners').delete().eq('id', id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการแบนเนอร์โปรโมชัน'),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('เพิ่มแบนเนอร์ใหม่', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'หัวข้อโปรโมชัน (เช่น โปร 1 แถม 1)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _imageUrlController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'ลิงก์รูปภาพแบนเนอร์ (คั่นด้วย , หากมีหลายรูป)',
                        helperText: 'สามารถกดปุ่มอัปโหลดด้านล่างเพื่อเพิ่มรูปจากเครื่องได้',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final uploadedUrl = await _pickAndUploadImage(context);
                        if (uploadedUrl != null) {
                          setState(() {
                            if (_imageUrlController.text.isEmpty) {
                              _imageUrlController.text = uploadedUrl;
                            } else {
                              _imageUrlController.text = '${_imageUrlController.text}, $uploadedUrl';
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.add_a_photo, color: Color(0xFF7C3AED)),
                      label: const Text('อัปโหลดรูปเพิ่มจากเครื่อง', style: TextStyle(color: Color(0xFF7C3AED))),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isLoading ? null : _addBanner,
                        child: const Text('บันทึกแบนเนอร์', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('รายการแบนเนอร์ปัจจุบัน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _supabase.from('banners').select().order('created_at', ascending: false),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final banners = snapshot.data!;
                  if (banners.isEmpty) return const Center(child: Text('ยังไม่มีแบนเนอร์', style: TextStyle(color: Colors.grey)));

                  return ListView.builder(
                    itemCount: banners.length,
                    itemBuilder: (context, index) {
                      final item = banners[index];
                      final firstImage = (item['image_url'] ?? '').toString().split(',').first.trim();
                      return Card(
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              firstImage,
                              width: 60,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40),
                            ),
                          ),
                          title: Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteBanner(item['id']),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}