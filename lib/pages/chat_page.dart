import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  // ฟังก์ชันส่งข้อความเข้า Supabase
  Future<void> _sendMessage({String? imageUrl, String? textContent}) async {
    final text = textContent ?? _messageController.text.trim();
    if (text.isEmpty && imageUrl == null) return;

    final user = _supabase.auth.currentUser;
    final email = user?.email ?? 'anonymous@shop.com';

    try {
      await _supabase.from('messages').insert({
        'sender_email': email,
        'text': text.isEmpty ? null : text,
        'image_url': imageUrl,
      });

      if (textContent == null) {
        _messageController.clear();
      }

      // เลื่อนหน้าจอลงล่างสุดอัตโนมัติ
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ส่งข้อความไม่สำเร็จ: $e')),
        );
      }
    }
  }

  // ฟังก์ชันเลือกรูปภาพ อัปโหลดไป Storage แล้วส่งเข้าแชท
  Future<void> _pickAndSendImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final fileBytes = await image.readAsBytes();
      final fileExt = image.name.split('.').last;
      final fileName = 'chat_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // อัปโหลดรูปไปที่ Bucket 'product-images'
      await _supabase.storage.from('product-images').uploadBinary(
        fileName,
        fileBytes,
        fileOptions: FileOptions(contentType: 'image/$fileExt'),
      );

      final publicUrl = _supabase.storage.from('product-images').getPublicUrl(fileName);

      if (mounted) Navigator.pop(context); // ปิด Loading

      await _sendMessage(imageUrl: publicUrl, textContent: '');
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('อัปโหลดรูปไม่สำเร็จ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = _supabase.auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('แชทกับร้านค้า', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('messages')
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: true),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(child: Text('ยังไม่มีข้อความสนทนา', style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final senderEmail = msg['sender_email'] ?? '';
                    final isMe = senderEmail == currentUserEmail;
                    final text = msg['text'];
                    final imageUrl = msg['image_url'];

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFFEDE9FE) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (imageUrl != null && imageUrl.toString().isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                ),
                              ),
                              if (text != null && text.toString().isNotEmpty) const SizedBox(height: 8),
                            ],
                            if (text != null && text.toString().isNotEmpty)
                              Text(
                                text,
                                style: const TextStyle(color: Colors.black87, fontSize: 15),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: Color(0xFF7C3AED)),
                  onPressed: _pickAndSendImage,
                  tooltip: 'ส่งรูปภาพ',
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'พิมพ์ข้อความ...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF7C3AED)),
                  onPressed: () => _sendMessage(),
                  tooltip: 'ส่งข้อความ',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}