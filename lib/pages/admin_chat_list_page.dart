import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_page.dart';

class AdminChatListPage extends StatefulWidget {
  const AdminChatListPage({super.key});

  @override
  State<AdminChatListPage> createState() => _AdminChatListPageState();
}

class _AdminChatListPageState extends State<AdminChatListPage> {
  final _supabase = Supabase.instance.client;

  // ----------------------------------------------------
  // 🔍 [จุดที่ 1]: ฟังก์ชันดึงรายชื่อลูกค้าและเช็กสถานะการอ่าน
  // ดึงข้อมูลข้อความทั้งหมด เรียงจากใหม่ไปเก่า 
  // เพื่อเอามาคัดกรองข้อความล่าสุด และเช็กว่ามีข้อความที่ยังไม่ได้อ่าน (is_read == false) หรือไม่
  // ----------------------------------------------------
  Future<List<Map<String, dynamic>>> _fetchChatUsers() async {
    try {
      final response = await _supabase
          .from('messages')
          .select('sender_email, text, created_at, is_read')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> rawList = List<Map<String, dynamic>>.from(response);
      final Map<String, Map<String, dynamic>> latestUserMessages = {};

      // วนลูปกรองเอาเฉพาะข้อความล่าสุดของลูกค้าแต่ละคน
      for (var msg in rawList) {
        final email = msg['sender_email']?.toString() ?? 'ลูกค้าไม่ระบุชื่อ';
        
        // ข้ามข้อความที่เป็นของ admin ออก
        if (email.contains('admin')) continue; 

        if (!latestUserMessages.containsKey(email)) {
          latestUserMessages[email] = msg;
        } else {
          // ถ้ามีลูกค้ารายนี้อยู่แล้ว แต่ถ้ามีข้อความไหนยังไม่ได้อ่าน ให้ถือว่าแชทนี้ยังไม่ได้อ่าน (Unread)
          if (msg['is_read'] == false) {
            latestUserMessages[email]!['is_read'] = false;
          }
        }
      }

      return latestUserMessages.values.toList();
    } catch (e) {
      return [];
    }
  }

  // ----------------------------------------------------
  // 🔄 [จุดที่ 2]: ฟังก์ชันอัปเดตสถานะข้อความให้เป็น "อ่านแล้ว" (is_read = true)
  // เมื่อแอดมินคลิกเข้าไปในห้องแชทของลูกค้ารายนั้นๆ
  // ----------------------------------------------------
  Future<void> _markAsRead(String userEmail) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('sender_email', userEmail)
          .eq('is_read', false);
      
      // รีเฟรชหน้าจอรายการแชทเพื่อให้สีเปลี่ยนเป็นสีขาวและจุดแดงหายไป
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error updating read status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('แชทกับลูกค้า', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchChatUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(
              child: Text('ยังไม่มีรายการแชทจากลูกค้า', style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userChat = users[index];
              final userEmail = userChat['sender_email'] ?? 'ลูกค้า';
              final lastMsg = userChat['text'] ?? 'ส่งรูปภาพ...';
              
              // เช็กสถานะการอ่านจากข้อมูลที่ดึงมา
              final bool isUnread = userChat['is_read'] == false;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  // ----------------------------------------------------
                  // 🎨 [จุดที่ 3]: เปลี่ยนสีพื้นหลังตามสถานะการอ่าน
                  // ถ้ายังไม่อ่าน (isUnread == true) ให้เป็นสีเทา (Colors.grey[200])
                  // ถ้าอ่านแล้ว ให้เป็นสีขาวปกติ (Colors.white)
                  // ----------------------------------------------------
                  color: isUnread ? Colors.grey[200] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF7C3AED),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      // ----------------------------------------------------
                      // 🔴 [จุดที่ 4]: แสดงจุดแดง (Red Dot) แจ้งเตือนที่รูปโปรไฟล์
                      // เฉพาะเมื่อข้อความยังไม่ได้อ่าน
                      // ----------------------------------------------------
                      if (isUnread)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    userEmail,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.w900 : FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    lastMsg,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isUnread ? Colors.black87 : Colors.grey[600],
                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () async {
                    // เมื่อแอดมินคลิกเข้ามาอ่าน ให้ทำการอัปเดตสถานะในฐานข้อมูลเป็นอ่านแล้ว
                    await _markAsRead(userEmail);

                    // พาไปหน้าแชทคุยกับลูกค้าคนนี้
                    if (!context.mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(targetUserEmail: userEmail),
                      ),
                    );

                    // พอกลัมาจากหน้าแชท ให้รีเฟรชหน้าจอรายการนี้อีกรอบเพื่อให้ตัวเลขเป็น 0
                    setState(() {});
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}