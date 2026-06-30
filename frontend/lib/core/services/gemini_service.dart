import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  // Using Gemini 1.5 Pro - FREE for developers!
  static const String _apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent';

  Future<String> getResponse(String userMessage, String attendantName, String selectedPump) async {
    if (_apiKey.isEmpty) {
      return "⚠️ Please add your Gemini API key to the .env file.";
    }

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': '''
You are an expert AI assistant for PayNotify, a fuel station payment management system. 
You have comprehensive knowledge about all aspects of fuel station operations.

📍 CURRENT CONTEXT:
- Attendant: $attendantName
- Active Pump: $selectedPump
- Current Time: ${DateTime.now().toString()}

📋 YOUR KNOWLEDGE BASE:

🔹 PAYMENT PROCESSING:
- M-Pesa: Enter customer phone number, confirm amount, wait for STK push
- Card payments: Swipe/insert card, follow terminal prompts
- Cash: Use "Cash Sale" button, record amount and customer name
- All transactions appear instantly in the transaction list
- Tap any transaction to see full receipt details

🔹 PUMP OPERATIONS:
- Each pump shows real-time fuel level (percentage)
- Green fuel bar = good level (>30%)
- Orange fuel bar = low level (<30%)
- Use play/pause icon to activate/deactivate pump
- Inactive pumps cannot process new payments

🔹 TRANSACTION MANAGEMENT:
- Filter transactions: All | Completed | Pending
- Pending transactions need confirmation
- Completed transactions show green status
- Pull down to refresh transaction list
- Each transaction shows: amount, phone, time, status

🔹 SHIFT MANAGEMENT:
- Shift timer starts automatically at login
- Shows at top: "Shift: Xh Ym"
- End shift via logout icon
- Shift report shows: total sales, transaction count, pending count
- Can't start new shift without ending current one

🔹 QUICK ACTIONS:
- Receipt: View/print receipts (coming soon)
- History: Full transaction history (coming soon)
- QR Pay: Scan QR codes for payment (coming soon)
- Cash Sale: Record cash transactions
- AI Assistant: You're talking to me now!

🔹 FUEL MANAGEMENT:
- Fuel gauge shows percentage remaining
- Updates automatically as fuel is dispensed
- Low fuel warning at 30% (orange color)
- Monitor all pumps from dashboard

🔹 TROUBLESHOOTING:
- If payment fails: Check internet, try again
- If pump won't activate: Check if already in use
- If transactions don't appear: Pull to refresh
- If app freezes: Close and reopen

🎯 RESPONSE GUIDELINES:
- Be friendly, helpful, and professional
- Provide specific, actionable information
- Use emojis occasionally for friendliness 😊
- Keep responses concise but complete
- If unsure, acknowledge and offer alternatives
- Always reference the current pump and context

USER QUESTION: $userMessage

Provide a helpful, detailed response based on your knowledge of PayNotify and fuel station operations.
'''
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.9,
            'maxOutputTokens': 800,
            'topP': 0.95,
            'topK': 40
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        // Use debugPrint for development logging
        if (kDebugMode) {
          debugPrint('Gemini API Error: ${response.statusCode} - ${response.body}');
        }
        return _getEnhancedFallbackResponse(userMessage, attendantName, selectedPump);
      }
    } catch (e) {
      // Use debugPrint for development logging
      if (kDebugMode) {
        debugPrint('Error calling Gemini: $e');
      }
      return _getEnhancedFallbackResponse(userMessage, attendantName, selectedPump);
    }
  }

  // Enhanced fallback responses when API is unavailable
  String _getEnhancedFallbackResponse(String message, String name, String pump) {
    final lowerMsg = message.toLowerCase();
    
    // Payment related queries
    if (lowerMsg.contains('payment') || lowerMsg.contains('mpesa') || lowerMsg.contains('cash')) {
      if (lowerMsg.contains('mpesa')) {
        return "To process an M-Pesa payment at $pump:\n\n1️⃣ Tap 'New Payment' button\n2️⃣ Enter customer's phone number\n3️⃣ Enter amount\n4️⃣ Customer receives STK push on their phone\n5️⃣ They enter PIN to complete\n\nThe transaction will appear as 'Pending' then change to 'Completed' once confirmed. 💳";
      } else if (lowerMsg.contains('cash')) {
        return "For cash sales at $pump:\n\n💰 Tap the 'Cash Sale' button in quick actions\n💵 Enter the amount received\n📝 Add customer name (optional)\n✅ Transaction is recorded immediately as completed\n\nNo further confirmation needed! 💵";
      } else {
        return "At $pump, you can accept:\n\n💳 M-Pesa: Digital payments via phone\n💵 Cash: Physical currency\n💳 Card: Swipe or tap card\n\nEach payment method has its own button in the app. Which would you like to know more about? 😊";
      }
    }
    
    // Fuel related queries
    else if (lowerMsg.contains('fuel') || lowerMsg.contains('level') || lowerMsg.contains('gauge')) {
      return "⛽ Fuel status for $pump:\n\nCurrent level is being monitored in real-time\n• Green bar = Good level (>30%)\n• Orange bar = Low level (<30%)\n\nNeed to check other pumps? You'd need to switch to their dashboards. 📊";
    }
    
    // Transaction history
    else if (lowerMsg.contains('history') || lowerMsg.contains('transaction') || lowerMsg.contains('receipt')) {
      return "📋 Transaction history for $pump:\n\nAll payments appear in the main list\n• Use filter buttons: All/Completed/Pending\n• Tap any transaction for full receipt\n• Pull down to refresh the list\n\nNeed help finding a specific transaction? 🔍";
    }
    
    // Pump operations
    else if (lowerMsg.contains('pump') && (lowerMsg.contains('pause') || lowerMsg.contains('stop') || lowerMsg.contains('activate'))) {
      return "⚙️ To control $pump:\n\n▶️ Tap the play/pause icon next to your name\n⏸️ Paused pumps cannot process payments\n✅ Green icon = Active\n🟠 Orange icon = Paused\n\nCurrent status: Active ✅";
    }
    
    // Shift related
    else if (lowerMsg.contains('shift') || (lowerMsg.contains('end') && lowerMsg.contains('shift'))) {
      return "⏰ Shift information for $name at $pump:\n\nYour shift timer is running at the top\nTo end shift:\n1️⃣ Tap logout icon (top right)\n2️⃣ Confirm 'End Shift'\n3️⃣ View your shift report\n4️⃣ Summary shows total sales and transactions\n\nReady to end your shift? 🏁";
    }
    
    // Help
    else if (lowerMsg.contains('help') || lowerMsg.contains('what can you do')) {
      return "I'm your PayNotify assistant for $pump! I can help with:\n\n💳 Payment processing (M-Pesa, Cash, Card)\n⛽ Fuel level monitoring\n📋 Transaction history\n⚙️ Pump operations\n⏰ Shift management\n🔧 Troubleshooting\n\nWhat would you like to know more about? 😊";
    }
    
    // Greetings
    else if (lowerMsg.contains('hello') || lowerMsg.contains('hi') || lowerMsg.contains('hey')) {
      return "Hello $name! 👋 Welcome to PayNotify at $pump. I'm your AI assistant, ready to help with anything you need - payments, fuel monitoring, transactions, or shift management. How can I assist you today? 😊";
    }
    
    // Thanks
    else if (lowerMsg.contains('thank')) {
      return "You're very welcome, $name! 😊 Always happy to help. If you need anything else while operating $pump, just ask! 🌟";
    }
    
    // Default response
    return "I'm here to help you operate $pump efficiently! 💪\n\nYou can ask me about:\n• How to process M-Pesa payments\n• Checking fuel levels\n• Viewing transaction history\n• Pausing/activating the pump\n• Ending your shift\n• Troubleshooting issues\n\nWhat would you like to know? 😊";
  }
}