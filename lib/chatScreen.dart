import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<ChatMessageData> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final Map<String, String> _userNameCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
  }

  Future<void> _loadInitialMessages() async {
    try {
      final snapshot =
          await _databaseRef.orderByChild('timestamp').limitToLast(50).once();

      if (snapshot.snapshot.value == null) {
        setState(() => _isLoading = false);
        _setupRealtimeListener();
        return;
      }

      final messages =
          Map<String, dynamic>.from(snapshot.snapshot.value as Map);

      final List<ChatMessageData> tempMessages = [];

      for (var entry in messages.entries) {
        final messageData = Map<String, dynamic>.from(entry.value);
        final senderId = messageData['senderId'] ?? '';
        final senderName = await _getUserName(senderId);

        tempMessages.add(ChatMessageData(
          key: entry.key,
          text: messageData['text'] ?? '',
          senderId: senderId,
          senderName: senderName,
          timestamp: messageData['timestamp'] ?? 0,
          reaction: messageData['reaction'] ?? {},
        ));
      }

      tempMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      setState(() {
        _messages.addAll(tempMessages);
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      _setupRealtimeListener();
    } catch (e) {
      print('Error loading messages: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupRealtimeListener() {
    _databaseRef.onChildAdded.listen((event) async {
      final messageData =
          Map<String, dynamic>.from(event.snapshot.value as Map);
      final senderId = messageData['senderId'];
      final senderName = await _getUserName(senderId);

      final newMessage = ChatMessageData(
        key: event.snapshot.key!,
        text: messageData['text'] ?? '',
        senderId: senderId,
        senderName: senderName,
        timestamp: messageData['timestamp'] ?? 0,
        reaction: messageData['reaction'] ?? {},
      );

      if (!_messages.any((m) => m.key == newMessage.key)) {
        setState(() => _messages.add(newMessage));
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    _databaseRef.onChildChanged.listen((event) {
      final updatedData =
          Map<String, dynamic>.from(event.snapshot.value as Map);
      final index = _messages.indexWhere((m) => m.key == event.snapshot.key);

      if (index != -1) {
        final updatedMessage =
            _messages[index].copyWith(reaction: updatedData['reaction'] ?? {});
        setState(() => _messages[index] = updatedMessage);
      }
    });
  }

  Future<String> _getUserName(String senderId) async {
    if (_userNameCache.containsKey(senderId)) {
      return _userNameCache[senderId]!;
    }

    try {
      final doc = await _firestore.collection('users').doc(senderId).get();
      if (doc.exists) {
        final firstName = doc.data()?['firstName'] ?? 'Unknown';
        _userNameCache[senderId] = firstName;
        return firstName;
      }
    } catch (e) {
      print('Error fetching username: $e');
    }

    _userNameCache[senderId] = 'Unknown';
    return 'Unknown';
  }

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      final message = {
        'text': _controller.text.trim(),
        'senderId': _auth.currentUser?.uid,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'reaction': {},
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

  void _addReaction(String messageKey, String emoji) {
    final uid = _auth.currentUser?.uid ?? '';
    if (messageKey.isEmpty || uid.isEmpty) return;

    _databaseRef.child(messageKey).child('reaction').update({uid: emoji});
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
      decoration: const BoxDecoration(color: Colors.black),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF9CFF33)),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Chat Room',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: const Color(0xFF121212),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF9CFF33)))
          : _messages.isEmpty
              ? const Center(
                  child: Text('No messages yet. Be the first to send one!',
                      style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return ChatBubble(
                      message: message,
                      isMe: message.senderId == _auth.currentUser?.uid,
                      onReact: (emoji) => _addReaction(message.key, emoji),
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
              color: Colors.black26, blurRadius: 10, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
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
  final String key;
  final String text;
  final String senderId;
  final String senderName;
  final int timestamp;
  final Map reaction;

  ChatMessageData({
    required this.key,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    required this.reaction,
  });

  ChatMessageData copyWith({Map? reaction}) {
    return ChatMessageData(
      key: key,
      text: text,
      senderId: senderId,
      senderName: senderName,
      timestamp: timestamp,
      reaction: reaction ?? this.reaction,
    );
  }
}

class ChatBubble extends StatelessWidget {
  final ChatMessageData message;
  final bool isMe;
  final Function(String) onReact;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateTime.fromMillisecondsSinceEpoch(message.timestamp);
    final formattedTime = DateFormat('HH:mm').format(time);

    final reactions = message.reaction.values.toSet().toList();

    return GestureDetector(
      onLongPress: () => _showReactionPopup(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isMe
                            ? [const Color(0xFF9CFF33), const Color(0xFF3B731C)]
                            : [
                                const Color(0xFF2A2A2A),
                                const Color(0xFF1A1A1A)
                              ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft:
                            isMe ? const Radius.circular(20) : Radius.zero,
                        bottomRight:
                            isMe ? Radius.zero : const Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(message.senderName,
                            style: TextStyle(
                                color: isMe ? Colors.white70 : Colors.grey[300],
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(message.text,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(formattedTime,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
                  children: reactions
                      .map((emoji) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(emoji,
                                style: const TextStyle(fontSize: 20)),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showReactionPopup(BuildContext context) {
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '👎'];
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (ctx) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: emojis
              .map((e) => GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      onReact(e);
                    },
                    child: Text(e, style: const TextStyle(fontSize: 26)),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
