import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  final String userId = "test12";
  bool _isBotTyping = false;
  String? _animatingMessage;
  bool _isUserControllingScroll = false;

  Future<void> _reportMessage(Map<String, dynamic> message) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        String? selectedReason;
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Report Message',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                dropdownColor: Colors.black,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                items: ['Offensive', 'Spam', 'Inaccurate', 'Other']
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r,
                              style: const TextStyle(color: Colors.white)),
                        ))
                    .toList(),
                onChanged: (value) => selectedReason = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Submit'),
              onPressed: () {
                if (selectedReason != null) {
                  Navigator.pop(context, selectedReason);
                }
              },
            ),
          ],
        );
      },
    );

    if (reason != null) {
      await FirebaseFirestore.instance.collection('reports').add({
        'reported_by': userId,
        'message_content': message['content'],
        'message_timestamp': message['timestamp'].toIso8601String(),
        'reason': reason,
        'reported_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message reported successfully')),
      );
    }
  }

  CollectionReference get _firestore => FirebaseFirestore.instance
      .collection('chatbot_chats')
      .doc(userId)
      .collection('messages');

  @override
  void initState() {
    super.initState();
    _loadChatHistory();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollToBottom();
      });
    });

    _scrollController.addListener(() {
      if (_scrollController.offset !=
          _scrollController.position.maxScrollExtent) {
        _isUserControllingScroll = true;
      } else {
        _isUserControllingScroll = false;
      }
    });
  }

  Future<void> _loadChatHistory() async {
    final snapshot =
        await _firestore.orderBy('timestamp', descending: false).get();

    final loadedMessages = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'role': data['role'],
        'content': data['content'],
        'timestamp': DateTime.parse(data['timestamp']),
      };
    }).toList();

    loadedMessages.sort((a, b) =>
        (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));

    setState(() {
      _messages.clear();
      _messages.addAll(loadedMessages);
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      _scrollToBottom();
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final now = DateTime.now();
    final userMessage = {
      'role': 'user',
      'content': message,
      'timestamp': now,
    };

    setState(() {
      _messages.add(userMessage);
      _isBotTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    await _firestore.add({
      'role': 'user',
      'content': message,
      'timestamp': now.toIso8601String(),
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.34.60.87:8000/chatbot'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=utf-8'
        },
        body: jsonEncode({
          'user_id': userId,
          'new_message': message,
          'history': _messages
              .map((m) => {
                    'role': m['role'],
                    'content': m['content'],
                    'timestamp': m['timestamp'].toIso8601String(),
                  })
              .toList(),
        }),
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200) {
        final data = jsonDecode(decodedBody);
        final responseText = data['response'];
        final DateTime botTimestamp =
            DateTime.parse(data['updated_history'].last['timestamp']);

        setState(() {
          _isBotTyping = false;
        });

        await _playTypingAnimation(responseText, botTimestamp);
      } else {
        throw Exception("Server Error");
      }
    } catch (e) {
      setState(() => _isBotTyping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _playTypingAnimation(String fullText, DateTime timestamp) async {
    String visibleText = '';
    List<String> lines = fullText.split('\n');

    for (String line in lines) {
      if (line.isNotEmpty) {
        for (int i = 0; i < line.length; i++) {
          await Future.delayed(const Duration(milliseconds: 20));
          visibleText += line[i];
          setState(() {
            _animatingMessage = visibleText;
          });
          if (!_isUserControllingScroll) {
            _scrollToBottom();
          }
        }
        if (lines.indexOf(line) < lines.length - 1) {
          visibleText += '\n';
          setState(() {
            _animatingMessage = visibleText;
          });
          if (!_isUserControllingScroll) {
            _scrollToBottom();
          }
        }
      }
    }

    final botMessage = {
      'role': 'assistant',
      'content': fullText,
      'timestamp': timestamp,
    };

    setState(() {
      _messages.add(botMessage);
      _animatingMessage = null;
    });

    await _firestore.add({
      'role': 'assistant',
      'content': fullText,
      'timestamp': timestamp.toIso8601String(),
    });

    if (!_isUserControllingScroll) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildChatBubble(Map<String, dynamic> message) {
    final isUser = message['role'] == 'user';

    return GestureDetector(
      onLongPress: () {
        if (!isUser) {
          _reportMessage(message);
        }
      },
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 280),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUser ? const Color(0xFF9CFF33) : Colors.grey[900],
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 0),
              bottomRight: Radius.circular(isUser ? 0 : 16),
            ),
          ),
          child: Text(
            message['content'],
            style: GoogleFonts.poppins(
              color: isUser ? Colors.black : const Color(0xFF9CFF33),
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, top: 4, bottom: 4),
      child: Row(
        children: const [
          SpinKitThreeBounce(
            color: Color(0xFF9CFF33),
            size: 20,
          ),
          SizedBox(width: 10),
          Text("GPTBETS is typing...", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.smart_toy, color: Color(0xFF9CFF33)),
            const SizedBox(width: 10),
            Text(
              "Sports Bot",
              style: GoogleFonts.poppins(
                color: const Color(0xFF9CFF33),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.only(
                top: 10,
                bottom: MediaQuery.of(context).viewInsets.bottom + 10,
              ),
              itemCount: _messages.length +
                  (_animatingMessage != null ? 1 : 0) +
                  (_isBotTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_animatingMessage != null && index == _messages.length) {
                  return _buildChatBubble({
                    'role': 'assistant',
                    'content': _animatingMessage!,
                    'timestamp': DateTime.now(),
                  });
                } else if (_isBotTyping &&
                    index ==
                        _messages.length +
                            (_animatingMessage != null ? 1 : 0)) {
                  return _buildTypingIndicator();
                } else {
                  return _buildChatBubble(_messages[index]);
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.black,
              border: Border(
                top: BorderSide(color: Colors.grey, width: 0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF9CFF33),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: () => _sendMessage(_controller.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
