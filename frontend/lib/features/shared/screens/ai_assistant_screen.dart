import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/services/gemini_service.dart';

// MARK: - Constants
class _AIConstants {
  static const Color primaryDark = Color(0xFF0B3D2E);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color errorRed = Color(0xFFE74C3C);
  static const Color aiMessageBg = Color(0xFFE8F5E9);
  static const Color userMessageBg = Color(0xFFE3F2FD);
}

// MARK: - Message Model
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  bool isTyping;
  final String? error;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isTyping = false,
    this.error,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isTyping,
    String? error,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isTyping: isTyping ?? this.isTyping,
      error: error ?? this.error,
    );
  }
}

// MARK: - Quick Action
class QuickAction {
  final String title;
  final String prompt;
  final IconData icon;
  final Color color;

  const QuickAction({
    required this.title,
    required this.prompt,
    required this.icon,
    required this.color,
  });
}

// MARK: - Main Screen
class AIAssistantScreen extends StatefulWidget {
  final String? attendantName;
  final String? selectedPump;
  final bool isManager;
  final String? managerName;

  const AIAssistantScreen({
    super.key,
    this.attendantName,
    this.selectedPump,
    this.isManager = false,
    this.managerName,
  });

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen>
    with SingleTickerProviderStateMixin {
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();
  
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Quick actions for different user types
  late List<QuickAction> _quickActions;
  
  final List<QuickAction> _managerQuickActions = [
    const QuickAction(
      title: 'Sales Summary',
      prompt: 'Show me today\'s sales summary',
      icon: Icons.trending_up,
      color: Colors.green,
    ),
    const QuickAction(
      title: 'Top Customers',
      prompt: 'Who are my top customers this month?',
      icon: Icons.people,
      color: Colors.blue,
    ),
    const QuickAction(
      title: 'Expense Report',
      prompt: 'Summarize my expenses for this week',
      icon: Icons.money_off,
      color: Colors.red,
    ),
    const QuickAction(
      title: 'Low Fuel Alert',
      prompt: 'Which pumps have low fuel levels?',
      icon: Icons.local_gas_station,
      color: Colors.orange,
    ),
    const QuickAction(
      title: 'Employee Performance',
      prompt: 'Show me employee performance summary',
      icon: Icons.assessment,
      color: Colors.purple,
    ),
    const QuickAction(
      title: 'Generate Report',
      prompt: 'Generate a full business report for today',
      icon: Icons.description,
      color: Colors.teal,
    ),
  ];
  
  final List<QuickAction> _attendantQuickActions = [
    const QuickAction(
      title: 'Process Payment',
      prompt: 'How do I process an M-Pesa payment?',
      icon: Icons.payment,
      color: Colors.green,
    ),
    const QuickAction(
      title: 'Check Fuel Level',
      prompt: 'What is the current fuel level?',
      icon: Icons.local_gas_station,
      color: Colors.blue,
    ),
    const QuickAction(
      title: 'End Shift',
      prompt: 'How do I end my shift?',
      icon: Icons.logout,
      color: Colors.orange,
    ),
    const QuickAction(
      title: 'Cash Sale',
      prompt: 'How to record a cash sale?',
      icon: Icons.money,
      color: Colors.teal,
    ),
    const QuickAction(
      title: 'Transaction History',
      prompt: 'Show me my recent transactions',
      icon: Icons.history,
      color: Colors.purple,
    ),
    const QuickAction(
      title: 'Pump Issues',
      prompt: 'What should I do if pump is not working?',
      icon: Icons.build,
      color: Colors.red,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _quickActions = widget.isManager ? _managerQuickActions : _attendantQuickActions;
    _addWelcomeMessage();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    final welcomeText = widget.isManager
        ? '''Hello ${widget.managerName ?? 'Manager'}! 👋

I'm your AI assistant for PayNotify. I can help you with:

📊 **Business Insights**
- Sales reports and trends
- Customer analytics
- Expense tracking
- Fuel level monitoring

👥 **Employee Management**
- Performance reviews
- Shift scheduling
- Leave management

💰 **Financial Reports**
- Daily/weekly/monthly summaries
- Expense breakdowns
- Revenue analysis

⚙️ **Operations**
- Station settings
- Fuel price updates
- Notification management

What would you like to know today?'''
        : '''Hello ${widget.attendantName ?? 'Attendant'}! 👋

I'm your AI assistant for PayNotify. I can help you with:

💰 **Payments**
- Process M-Pesa payments
- Record cash sales
- Handle card payments
- Payment troubleshooting

⛽ **Pump Operations**
- Check fuel levels
- Activate/pause pump
- Report pump issues

📋 **Shift Management**
- Start/end shift
- View shift summary
- Check transaction history

💡 **Quick Help**
- How-to guides
- Troubleshooting
- Best practices

How can I assist you with your shift at ${widget.selectedPump ?? 'your pump'} today?''';
    
    _messages.add(ChatMessage(
      id: 'welcome',
      text: welcomeText,
      isUser: false,
      timestamp: DateTime.now(),
    ));
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

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    
    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
      _isLoading = true;
      
      // Add typing indicator
      _messages.add(ChatMessage(
        id: 'typing_${DateTime.now().millisecondsSinceEpoch}',
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        isTyping: true,
      ));
    });
    
    _scrollToBottom();
    
    try {
      // Get AI response
      final response = await _geminiService.getResponse(
        message,
        widget.attendantName ?? widget.managerName ?? 'User',
        widget.selectedPump ?? 'Unknown',
      );
      
      if (!mounted) return;
      
      // Remove typing indicator
      setState(() {
        _messages.removeWhere((m) => m.isTyping == true);
        
        // Add AI response
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        
        _isLoading = false;
      });
      
      _scrollToBottom();
      HapticFeedback.lightImpact();
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _messages.removeWhere((m) => m.isTyping == true);
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: 'Sorry, I encountered an error. Please try again later.',
          isUser: false,
          timestamp: DateTime.now(),
          error: e.toString(),
        ));
        _isLoading = false;
      });
    }
  }

  void _sendQuickAction(String prompt) {
    _sendMessage(prompt);
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear the conversation history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
                _isLoading = false;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chat cleared'),
                  backgroundColor: _AIConstants.accentGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                color: _AIConstants.primaryDark,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Assistant',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.isManager 
                      ? (widget.managerName ?? 'Manager')
                      : (widget.attendantName ?? 'Attendant'),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: _AIConstants.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearChat,
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Error Banner
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red.shade700),
                    onPressed: () => setState(() => _errorMessage = null),
                  ),
                ],
              ),
            ),
          
          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          
          // Quick Actions
          if (_messages.length <= 3)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickActions.length,
                      itemBuilder: (context, index) {
                        final action = _quickActions[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _buildQuickActionChip(action),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          
          // Input Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(_messageController.text),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _AIConstants.primaryDark,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    color: Colors.white,
                    onPressed: _isLoading
                        ? null
                        : () => _sendMessage(_messageController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    if (message.isTyping) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: _AIConstants.primaryDark.withValues(alpha: 0.1),
              child: const Icon(Icons.smart_toy, size: 16, color: _AIConstants.primaryDark),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _AIConstants.aiMessageBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(_AIConstants.primaryDark),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('AI is thinking...'),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: _AIConstants.primaryDark.withValues(alpha: 0.1),
              child: const Icon(Icons.smart_toy, size: 16, color: _AIConstants.primaryDark),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? _AIConstants.userMessageBg : _AIConstants.aiMessageBg,
                borderRadius: BorderRadius.circular(
                  message.isUser ? 20 : 20,
                ).copyWith(
                  topLeft: message.isUser ? const Radius.circular(20) : Radius.zero,
                  topRight: message.isUser ? Radius.zero : const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  if (message.error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Error: ${message.error}',
                      style: TextStyle(
                        fontSize: 11,
                        color: _AIConstants.errorRed,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 16,
              backgroundColor: _AIConstants.primaryDark,
              child: Text(
                (widget.isManager 
                    ? (widget.managerName?.substring(0, 1) ?? 'M')
                    : (widget.attendantName?.substring(0, 1) ?? 'A')).toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(QuickAction action) {
    return GestureDetector(
      onTap: () => _sendQuickAction(action.prompt),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: action.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: action.color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: action.color, size: 24),
            const SizedBox(height: 8),
            Text(
              action.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: action.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}