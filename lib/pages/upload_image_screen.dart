import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadImageScreen extends StatefulWidget {
  @override
  _UploadImageScreenState createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  File? _imageFile;
  Uint8List? _webImageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // ฟังก์ชันเลือกรูปภาพจากเครื่อง
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (kIsWeb) {
          pickedFile.readAsBytes().then((value) {
            setState(() {
              _webImageBytes = value;
            });
          });
        } else {
          _imageFile = File(pickedFile.path);
        }
      });
    }
  }

  // ฟังก์ชันอัปโหลดรูปขึ้น Supabase Storage
  Future<void> _uploadImage() async {
    if (_imageFile == null && _webImageBytes == null) return;

    setState(() => _isLoading = true);

    try {
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'uploads/$fileName';

      if (kIsWeb) {
        // สำหรับรันบนเว็บ
        await Supabase.instance.client.storage
            .from('product-images')
            .uploadBinary(path, _webImageBytes!);
      } else {
        // สำหรับรันบนมือถือ (iOS / Android)
        await Supabase.instance.client.storage
            .from('product-images')
            .upload(path, _imageFile!);
      }

      // ดึง Public URL ของรูปภาพที่อัปโหลด
      final imageUrl = Supabase.instance.client.storage
          .from('product-images')
          .getPublicUrl(path);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('อัปโหลดรูปภาพสำเร็จ! URL: $imageUrl')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('อัปโหลดรูปภาพสินค้า')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // แสดงตัวอย่างรูปภาพที่เลือก
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _imageFile != null
                  ? Image.file(_imageFile!, fit: BoxFit.cover)
                  : (_webImageBytes != null
                      ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
                      : Center(child: Text('ยังไม่ได้เลือกรูปภาพ'))),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.image),
              label: Text('เลือกรูปภาพจากคลัง'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _uploadImage,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('อัปโหลดไปยัง Supabase'),
            ),
          ],
        ),
      ),
    );
  }
}