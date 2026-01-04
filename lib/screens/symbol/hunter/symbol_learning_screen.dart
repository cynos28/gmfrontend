
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async'; // Added for Timer
import 'dart:io' show Platform;

class SymbolLearningScreen extends StatefulWidget {
  final int grade;
  final int level;
  final String sublevel;

  const SymbolLearningScreen({
    super.key,
    required this.grade,
    required this.level,
    this.sublevel = "Starter",
  });

  @override
  State<SymbolLearningScreen> createState() => _SymbolLearningScreenState();
}

class _SymbolLearningScreenState extends State<SymbolLearningScreen> {
  WebSocketChannel? _channel;
  final FlutterTts flutterTts = FlutterTts();
  
  // State
  String _currentText = ""; // Full text from server
  String _displayedText = "Connecting..."; // Text being animated
  String _expression = ""; 
  String? _imageUrl;
  bool _isConnected = false;
  // NEW: Feedback state
  String? _feedbackMessage;
  bool _isChecking = false;

  // NEW: Message Queue
  final List<Map<String, dynamic>> _messageQueue = [];
  bool _isProcessingQueue = false;
  bool _isLoadingQuestion = false; // Controls full page spinner

  Timer? _typewriterTimer;
  final TextEditingController _inputController = TextEditingController();

  // For Numpad
  final List<String> _numpadKeys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'C', '0', 'OK'];

  @override
  void initState() {
    super.initState();
    _initTts();
    _connectWebSocket();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5); // Slower for kids
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  void _connectWebSocket() {
    // CONFIGURATION: Set your machine's local IP here
    // Use '10.0.2.2' for Android Emulator
    // Use '127.0.0.1' for Physical Device with 'adb reverse tcp:8000 tcp:8000'
    const String serverHost = '127.0.0.1'; 
    String url = 'ws://$serverHost:8000/ws/tutor/${widget.grade}/${widget.level}/${widget.sublevel}';

    try {
      print('Connecting to $url');
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _channel!.stream.listen((message) {
        final data = jsonDecode(message);
        // Add to queue instead of handling immediately
        _messageQueue.add(data);
        _processQueue();
      }, onError: (error) {
        print('WebSocket Error: $error');
        setState(() {
          _currentText = "Connection Error. Is the server running?";
          _isConnected = false;
        });
      }, onDone: () {
        print('WebSocket Closed');
        setState(() {
           _isConnected = false;
        });
      });

      setState(() {
        _isConnected = true;
      });
    } catch (e) {
      print('Connection Exception: $e');
      setState(() {
        _currentText = "Connection Error to $url. Is the server running?";
        _isConnected = false;
      });
    }
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue || _messageQueue.isEmpty) return;
    _isProcessingQueue = true;

    while (_messageQueue.isNotEmpty) {
      final data = _messageQueue.removeAt(0);

      if (data['type'] == 'feedback') {
        _handleFeedback(data);
        
        // Dynamic wait based on feedback length
        String text = data['text'] ?? "Correct!"; 
        int waitMillis = (text.length * 100) + 1500; // 100ms per char + 1.5s buffer
        await Future.delayed(Duration(milliseconds: waitMillis));
        
        // After feedback, show loading spinner for next question
        setState(() {
          _isLoadingQuestion = true;
          _imageUrl = null; // Clear old image
          _expression = ""; // Clear old expression
          _feedbackMessage = null;
        });

      } else if (data['type'] == 'speak') {
          // New Question is starting!
          // 1. Wait for image to load if we have one (from previous 'image' msg in queue)
          if (_imageUrl != null) {
            try {
               await precacheImage(NetworkImage(_imageUrl!), context);
            } catch (e) {
               print("Image failed to load: $e");
            }
          }
          
          // 2. Ready to show UI
          setState(() {
            _isLoadingQuestion = false;
            // Clear feedback state just in case
            _feedbackMessage = null; 
          });

          // 3. Process the speak message
          _handleServerMessage(data);

      } else {
        _handleServerMessage(data);
      }
      
      // Small buffer between messages
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _isProcessingQueue = false;
  }

  void _handleFeedback(Map<String, dynamic> data) {
    bool isCorrect = data['isCorrect'] ?? false;
    String text = data['text'] ?? (isCorrect ? "Correct!" : "Try again");
    
    setState(() {
      _isChecking = false;
      _feedbackMessage = text; 
    });
    _speak(text);
    _startTypewriter(text);
  }

  void _handleServerMessage(Map<String, dynamic> data) {
    if (data['type'] == 'speak') {
      String text = data['text'];
      // Clear previous feedback when new question starts
      setState(() {
        _feedbackMessage = null;
      });
      _speak(text);
      _startTypewriter(text);
    } else if (data['type'] == 'expression') {
      setState(() {
        _expression = data['text'];
      });
    } else if (data['type'] == 'image') {
       String rawUrl = data['url'];
       // FIX: Rewrite localhost to serverHost
       // Use '10.0.2.2' for Emulator, '127.0.0.1' for ADB Reverse
       String fixedUrl = rawUrl.replaceFirst("localhost", "127.0.0.1");
       fixedUrl = fixedUrl.replaceFirst("192.168.8.118", "127.0.0.1"); // Also fix stuck IP if any

       print("Loading image: $fixedUrl"); // Debug log

       setState(() {
         _imageUrl = fixedUrl;
       });
    }
  }

  void _startTypewriter(String text) {
    _typewriterTimer?.cancel();
    
    setState(() {
      _currentText = text;
      _displayedText = "";
    });

    int index = 0;
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (index < text.length) {
        setState(() {
          _displayedText = text.substring(0, index + 1);
        });
        index++;
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  void _sendInput(String value) {
    if (_channel != null && _isConnected) {
      setState(() {
        _isChecking = true; // Start loading state
        _feedbackMessage = null;
      });
      _channel!.sink.add(jsonEncode({
        "type": "input",
        "value": value
      }));
    }
  }

  @override
  void dispose() {
    _channel?.sink.close(status.goingAway);
    flutterTts.stop();
    _typewriterTimer?.cancel();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Symbol Learning',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // FULL PAGE LOADING SPINNER
            if (_isLoadingQuestion) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3))),
                    const SizedBox(height: 20),
                    Text(
                      "Preparing next challenge...",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Tutor Area
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Optional Image Area (Top)
                              if (_imageUrl != null) ...[
                                Container(
                                  constraints: const BoxConstraints(maxHeight: 250),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                       BoxShadow(color: Colors.grey.shade200, blurRadius: 8, spreadRadius: 2)
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      _imageUrl!,
                                      fit: BoxFit.contain, // Ensure full image is visible
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return SizedBox(
                                          height: 200,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded / 
                                                    loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) => 
                                        const SizedBox(height: 100, child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey))),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Expression Display (Large & Bold)
                              if (_expression.isNotEmpty) ...[
                                Text(
                                  _expression,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF1565C0), // Darker Blue
                                  ),
                                ),
                                const SizedBox(height: 30),
                              ],

                              // Teacher & Bubble Row (Centered)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center, // Vertically center avatar with bubble
                                mainAxisAlignment: MainAxisAlignment.center, // Horizontally center the block
                                children: [
                                  // Teacher Avatar
                                  const CircleAvatar(
                                    radius: 40,
                                    backgroundImage: AssetImage('assets/symbols/teacher1.png'),
                                    backgroundColor: Color(0xFFE3F2FD),
                                  ),
                                  const SizedBox(width: 15),
                                  
                                  // Typewriter Chat Bubble
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: _feedbackMessage != null && _feedbackMessage!.contains("Correct") 
                                            ? Colors.green.shade50 
                                            : Colors.white,
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(20),
                                          bottomLeft: Radius.circular(20),
                                          bottomRight: Radius.circular(20),
                                          topLeft: Radius.circular(20), // Fully rounded for cleaner look
                                        ),
                                        border: Border.all(
                                          color: _feedbackMessage != null && _feedbackMessage!.contains("Correct")
                                            ? Colors.green
                                            : Colors.grey.shade200
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: _isChecking 
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                                              const SizedBox(width: 10),
                                              Text("Checking...", style: GoogleFonts.poppins(color: Colors.grey)),
                                            ],
                                          )
                                        : Text(
                                            _displayedText, // Animated Text
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w500,
                                              height: 1.4,
                                            ),
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Input Area (System Keyboard)
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _inputController,
                                  readOnly: _isChecking, // Disable while checking
                                  keyboardType: TextInputType.number, // Number pad
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (value) {
                                     if (value.isNotEmpty && !_isChecking) {
                                       _sendInput(value);
                                       _inputController.clear();
                                     }
                                  },
                                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: _isChecking ? "Wait..." : "Type answer...",
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: _isChecking 
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.send, color: Color(0xFF2196F3)),
                                onPressed: () {
                                   if (_inputController.text.isNotEmpty && !_isChecking) {
                                       _sendInput(_inputController.text);
                                       _inputController.clear();
                                   }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        ),
      ),
    );
  }


}
