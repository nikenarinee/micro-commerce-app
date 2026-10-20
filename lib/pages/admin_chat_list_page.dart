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

  // ดึงรายชื่ออีเมลของลูกค้าที่ไม่ซ้ำกันจากตาราง messages
  Future<List<Map<String, dynamic>>> _fetchChatUsers() async {
    try {
      final response = await _supabase
          .from('messages')
          .select('sender_email, text, created_at')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> rawList = List<Map<String, dynamic>>.from(response);
      final Map<String, Map<String, dynamic>> latestUserMessages = {};

      // กรองเอาเฉพาะข้อความล่าสุดของลูกค้าแต่ละคน
      for (var msg in rawList) {
        final email = msg['sender_email']?.toString() ?? 'ลูกค้าไม่ระบุชื่อ';
        // ข้ามข้อความที่เป็นของ admin
        if (email.contains('admin')) continue; 

        if (!latestUserMessages.containsKey(email)) {
          latestUserMessages[email] = msg;
        }
      }

      return latestUserMessages.values.toList();
    } catch (e) {
      return [];
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

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF7C3AED),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    userEmail,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Text(
                    lastMsg,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    // กดแล้วพาไปหน้าแชทคุยกับลูกค้าคนนี้
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(targetUserEmail: userEmail),
                      ),
                    );
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