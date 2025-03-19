import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
  final List<ChatMessageData> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
    _setupRealtimeListener();
  }

  Future<void> _loadInitialMessages() async {
    try {
      final snapshot =
          await _databaseRef.orderByChild('timestamp').limitToLast(50).once();
      if (snapshot.snapshot.value != null) {
        final messages = snapshot.snapshot.value as Map<dynamic, dynamic>;
        final List<ChatMessageData> tempMessages = [];

        messages.forEach((key, value) {
          final messageData = value as Map<dynamic, dynamic>;
          tempMessages.add(ChatMessageData(
            text: messageData['text'],
            senderId: messageData['senderId'],
            timestamp: messageData['timestamp'],
          ));
        });

        tempMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        setState(() {
          _messages.addAll(tempMessages);
          _isLoading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      print('Error loading messages: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupRealtimeListener() {
    _databaseRef
        .orderByChild('timestamp')
        .startAfter(_messages.isEmpty ? 0 : _messages.last.timestamp)
        .onChildAdded
        .listen((event) {
      final messageData = event.snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _messages.add(ChatMessageData(
          text: messageData['text'],
          senderId: messageData['senderId'],
          timestamp: messageData['timestamp'],
        ));
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });
  }

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      final message = {
        'text': _controller.text.trim(),
        'senderId': _auth.currentUser?.uid,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      _databaseRef.push().set(message).then((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      });
      _controller.clear();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[900]!, Colors.black],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(child: _buildChatList()),
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Chat Room',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.tealAccent[400],
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(
                  message: _messages[index],
                  isMe: _messages[index].senderId == _auth.currentUser?.uid,
                );
              },
            ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            onPressed: _sendMessage,
            backgroundColor: Colors.tealAccent[400],
            child: const Icon(Icons.send, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }
}

class ChatMessageData {
  final String text;
  final String senderId;
  final int timestamp;

  ChatMessageData({
    required this.text,
    required this.senderId,
    required this.timestamp,
  });
}

class ChatBubble extends StatelessWidget {
  final ChatMessageData message;
  final bool isMe;

  const ChatBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final time = DateTime.fromMillisecondsSinceEpoch(message.timestamp);
    final formattedTime = DateFormat('HH:mm').format(time);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isMe
                      ? [Colors.tealAccent[400]!, Colors.tealAccent[700]!]
                      : [Colors.grey[700]!, Colors.grey[800]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                  bottomRight: isMe ? Radius.zero : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
