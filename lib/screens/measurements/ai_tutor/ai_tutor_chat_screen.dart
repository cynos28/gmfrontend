import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/models/unit_models.dart';
import 'package:ganithamithura/services/api/unit_api_service.dart';

class AiTutorChatScreen extends StatefulWidget {
  final Unit unit;

  const AiTutorChatScreen({
    super.key,
    required this.unit,
  });

  @override
  State<AiTutorChatScreen> createState() => _AiTutorChatScreenState();
}

class _AiTutorChatScreenState extends State<AiTutorChatScreen> {
  final UnitApiService _apiService = UnitApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isSending = false;

  // Quick question suggestions for kids
  final List<String> _quickQuestions = [];

  @override
  void initState() {
    super.initState();
    _loadQuickQuestions();
    _loadConversationFromDatabase();
  }
  
  void _loadQuickQuestions() {
    // Unit-specific suggested questions
    final suggestions = {
      'unit_length_1': [
        'What is a meter?',
        'How do I measure my desk?',
        'Why do we use centimeters?',
        'What\'s longer, a meter or a centimeter?',
      ],
      'unit_weight_1': [
        'What does kg mean?',
        'How do we measure weight?',
        'What\'s heavier, 1kg or 500g?',
        'How can I weigh my backpack?',
      ],
      'unit_area_1': [
        'What is area?',
        'How do I find the area of my room?',
        'What does square meter mean?',
        'Why do we measure area?',
      ],
      'unit_capacity_1': [
        'What is capacity?',
        'What does liter mean?',
        'How much water fits in a bottle?',
        'What\'s the difference between ml and liters?',
      ],
    };

    setState(() {
      _quickQuestions.addAll(
        suggestions[widget.unit.id] ?? [
          'Can you help me understand this?',
          'Tell me more about this topic',
          'How do I learn this?',
        ],
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversationFromDatabase() async {
    try {
      debugPrint('📥 Loading chat history from database for ${widget.unit.id}...');
      
      // Load from MongoDB via API
      final messages = await _apiService.loadChatHistory(unitId: widget.unit.id);
      
      if (messages.isNotEmpty) {
        setState(() {
          _messages.addAll(messages);
        });
        debugPrint('✅ Loaded ${messages.length} messages from database');
        _scrollToBottom();
      } else {
        // No messages in database, show welcome
        _addWelcomeMessage();
      }
    } catch (e) {
      debugPrint('⚠️ Error loading chat from database: $e');
      // Fallback to welcome message
      _addWelcomeMessage();
    }
  }

  Future<void> _loadConversationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('chat_history_${widget.unit.id}');
    
    if (historyJson != null) {
      try {
        final List<dynamic> historyList = json.decode(historyJson);
        setState(() {
          _messages.addAll(
            historyList.map((msg) => ChatMessage.fromJson(msg)).toList(),
          );
        });
        _scrollToBottom();
      } catch (e) {
        debugPrint('Error loading chat history: $e');
      }
    }
  }

  Future<void> _saveConversationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = json.encode(
      _messages.map((msg) => msg.toJson()).toList(),
    );
    await prefs.setString('chat_history_${widget.unit.id}', historyJson);
  }

  void _addWelcomeMessage() {
    if (_messages.isEmpty) {
      setState(() {
        _messages.add(
          ChatMessage(
            message: '',
            isUser: false,
            timestamp: DateTime.now(),
            reply: 'Hi there! 👋 I\'m your AI tutor for ${widget.unit.name}. '
                   'Ask me anything you want to learn! You can also tap the suggestions below to get started.',
          ),
        );
      });
      _saveConversationHistory();
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(
        ChatMessage(
          message: message,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _messageController.clear();
      _isSending = true;
    });

    _scrollToBottom();
    await _saveConversationHistory();

    try {
      // Prepare conversation history
      final conversationHistory = _messages
          .map((msg) => {
                'message': msg.message.isNotEmpty ? msg.message : msg.reply,
                'isUser': msg.isUser,
                'timestamp': msg.timestamp.toIso8601String(),
              })
          .toList();

      // Get AI response
      final response = await _apiService.sendChatMessage(
        unitId: widget.unit.id,
        message: message,
        conversationHistory: conversationHistory,
      );

      // Add AI response
      setState(() {
        _messages.add(
          ChatMessage(
            message: '',
            isUser: false,
            timestamp: DateTime.now(),
            reply: response.reply,
          ),
        );
        _isSending = false;
      });

      _scrollToBottom();
      await _saveConversationHistory();
    } catch (e) {
      debugPrint('❌ Chat error: $e');
      setState(() {
        _messages.add(
          ChatMessage(
            message: '',
            isUser: false,
            timestamp: DateTime.now(),
            reply: 'Oops! I had trouble connecting 🤔 Please check your internet and try again!',
          ),
        );
        _isSending = false;
      });
      await _saveConversationHistory();
    }
  }

  void _clearChat() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Clear Chat?'),
        content: const Text('This will delete all your conversation history from all devices. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Clear from database
      await _apiService.clearChatHistory(unitId: widget.unit.id);
      
      // Clear local SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_history_${widget.unit.id}');
      
      setState(() {
        _messages.clear();
      });
      _addWelcomeMessage();
      
      debugPrint('🗑️ Chat history cleared from database and local storage');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FF),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Messages
            Expanded(
              child: _buildMessageList(),
            ),
            
            // Quick Questions (show when no messages yet)
            if (_messages.length <= 1)
              _buildQuickQuestions(),
            
            // Input field
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B7FFF), Color(0xFF8CA9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B7FFF).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => Get.back(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Tutor 🤖',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.unit.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
            onPressed: _clearChat,
            tooltip: 'Clear chat',
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isSending) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final text = message.message.isNotEmpty ? message.message : (message.reply ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B7FFF), Color(0xFF8CA9FF)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF6B7FFF)
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isUser ? Colors.white : const Color(AppColors.textBlack),
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB800),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B7FFF), Color(0xFF8CA9FF)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 6),
                _buildDot(1),
                const SizedBox(width: 6),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 150)),
      builder: (context, double value, child) {
        return Opacity(
          opacity: (value * 2).clamp(0.3, 1.0),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF6B7FFF),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildQuickQuestions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 Quick Questions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(AppColors.textBlack),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickQuestions.map((question) {
              return InkWell(
                onTap: () => _sendMessage(question),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF8CA9FF).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    question,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7FFF),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F7FF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF8CA9FF).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(AppColors.textBlack),
                ),
                decoration: const InputDecoration(
                  hintText: 'Ask me anything... 🤔',
                  hintStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(AppColors.subText2),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B7FFF), Color(0xFF8CA9FF)],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B7FFF).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _isSending ? null : () => _sendMessage(_messageController.text),
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
