import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/core_backend_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController messageController = TextEditingController();
  final List<ChatMessage> messages = [];
  bool isSending = false;

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add(ChatMessage(text: text, isUser: true));
      isSending = true;
    });
    messageController.clear();

    try {
      final reply = await CoreBackendService().chat(text);

      setState(() {
        messages.add(ChatMessage(text: reply, isUser: false));
        isSending = false;
      });
    } catch (e) {
      print('Error calling chatbot: $e');
      setState(() {
        messages.add(ChatMessage(text: 'Something went wrong. Try again.', isUser: false));
        isSending = false;
      });
    }
  }
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F5),
      appBar: PreferredSize(
        preferredSize:  Size.fromHeight(50.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: AppBar(
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            leading: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  child:  Icon(
                    Icons.keyboard_backspace_sharp,
                    color: Colors.black,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFFBAB49B).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            title: Text('AI Chatbot', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: msg.isUser ? const Color(0xff38796D) : const Color(0xFFE8E5DC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg.text,
                      style: GoogleFonts.poppins(
                        color: msg.isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask something...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xff38796D)),
                  onPressed: isSending ? null : sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}