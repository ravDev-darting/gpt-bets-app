import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final DatabaseReference _databaseRef =
      FirebaseDatabase.instance.ref().child('messages');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    _databaseRef.onChildAdded.listen((event) {
      final messageData = event.snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _messages.add(ChatMessage(
          text: messageData['text'],
          isMe: messageData['senderId'] == _auth.currentUser?.uid,
        ));
      });
    });
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      final message = {
        'text': _controller.text,
        'senderId': _auth.currentUser?.uid,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      _databaseRef.push().set(message);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Color(0xFF59A52B),
        title: Text(
          'Chat Room',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Image

          Center(
            child: Opacity(
              opacity: 0.5,
              child: Image.asset(
                'assets/lT.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Chat UI
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _messages[index];
                  },
                ),
              ),
              _buildMessageInput(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      color: Color(0xFF1E1E1E),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              style: TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Color(0xFF59A52B)),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isMe;

  const ChatMessage({super.key, required this.text, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? Color(0xFF59A52B) : Color(0xFF2E2E2E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: isMe ? Radius.circular(16) : Radius.circular(0),
            bottomRight: isMe ? Radius.circular(0) : Radius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: isMe ? Colors.white : Colors.white),
        ),
      ),
    );
  }
}
