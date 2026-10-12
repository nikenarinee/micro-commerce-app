import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // รายการข้อความและรูปภาพในแชท
  final List<Map<String, dynamic>> _messages = [
    {'text': 'สวัสดีครับ สินค้าตัวนี้พร้อมส่งไหมครับ?', 'imagePath': null, 'isMe': true},
    {'text': 'สวัสดีค่ะ พร้อมส่งจ้า จัดส่งพรุ่งนี้เลยค่ะ', 'imagePath': null, 'isMe': false},
  ];

  // ฟังก์ชันส่งข้อความ
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'text': _messageController.text.trim(),
        'imagePath': null,
        'isMe': true,
      });
      _messageController.clear();
    });
  }

  // ฟังก์ชันเลือกรูปภาพจากเครื่อง
  Future<void> _pickAndSendImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _messages.add({
          'text': null,
          'imagePath': image.path, // เก็บ Path หรือ URL รูปภาพ
          'isMe': true,
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['isMe'] as bool;
                final text = msg['text'] as String?;
                final imagePath = msg['imagePath'] as String?;

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
                        // แสดงรูปภาพถ้ามีการแนบรูปมา
                        if (imagePath != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb
                                ? Image.network(imagePath, width: 200, height: 200, fit: BoxFit.cover)
                                : Image.file(File(imagePath), width: 200, height: 200, fit: BoxFit.cover),
                          ),
                          if (text != null && text.isNotEmpty) const SizedBox(height: 8),
                        ],
                        // แสดงข้อความถ้ามีข้อความ
                        if (text != null && text.isNotEmpty)
                          Text(
                            text,
                            style: const TextStyle(color: Colors.black87, fontSize: 15),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // แถบพิมพ์ข้อความและส่งรูป
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
                  onPressed: _pickAndSendImage, // กดเลือกรูปภาพ
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
                  onPressed: _sendMessage, // กดส่งข้อความ
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