import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add Firestore
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
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Firestore instance
  final List<ChatMessageData> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final Map<String, String> _userNameCache = {}; // Cache for usernames
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

        for (var entry in messages.entries) {
          final messageData = entry.value as Map<dynamic, dynamic>;
          final senderId = messageData['senderId'] as String;
          final senderName = await _getUserName(senderId); // Fetch username
          tempMessages.add(ChatMessageData(
            text: messageData['text'],
            senderId: senderId,
            senderName: senderName,
            timestamp: messageData['timestamp'],
          ));
        }

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
        .listen((event) async {
      final messageData = event.snapshot.value as Map<dynamic, dynamic>;
      final senderId = messageData['senderId'] as String;
      final senderName = await _getUserName(senderId); // Fetch username
      setState(() {
        _messages.add(ChatMessageData(
          text: messageData['text'],
          senderId: senderId,
          senderName: senderName,
          timestamp: messageData['timestamp'],
        ));
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });
  }

  Future<String> _getUserName(String senderId) async {
    // Check cache first
    if (_userNameCache.containsKey(senderId)) {
      return _userNameCache[senderId]!;
    }

    // Fetch from Firestore
    try {
      final doc = await _firestore.collection('users').doc(senderId).get();
      if (doc.exists) {
        final firstName = doc.data()?['firstName'] ?? 'Unknown';
        _userNameCache[senderId] = firstName; // Cache the result
        return firstName;
      }
    } catch (e) {
      print('Error fetching username: $e');
    }
    _userNameCache[senderId] = 'Unknown'; // Cache fallback
    return 'Unknown';
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
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(child: _buildChatList()),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF9CFF33)),
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
      color: const Color(0xFF121212),
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: const Color(0xFF9CFF33),
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
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: Colors.grey),
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
            backgroundColor: const Color(0xFF9CFF33),
            child: const Icon(Icons.send, color: Colors.black),
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
  final String senderName; // Add senderName field
  final int timestamp;

  ChatMessageData({
    required this.text,
    required this.senderId,
    required this.senderName,
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
                      ? [const Color(0xFF9CFF33), const Color(0xFF3B731C)]
                      : [const Color(0xFF2A2A2A), const Color(0xFF1A1A1A)],
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
                    message.senderName, // Display username
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[300],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
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
                      color: Colors.grey,
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
