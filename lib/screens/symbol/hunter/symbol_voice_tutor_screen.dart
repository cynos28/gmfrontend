import 'dart:convert';
import 'package:ganithamithura/config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:ganithamithura/screens/symbol/hunter/symbol_voice_success_screen.dart'; // Import Success Screen
import 'dart:async';
import 'dart:math' as math;

class SymbolVoiceTutorScreen extends StatefulWidget {
  final int grade;
  final int level;
  final String sublevel;

  const SymbolVoiceTutorScreen({
    super.key,
    required this.grade,
    required this.level,
    this.sublevel = "Starter",
  });

  @override
  State<SymbolVoiceTutorScreen> createState() => _SymbolVoiceTutorScreenState();
}

class _SymbolVoiceTutorScreenState extends State<SymbolVoiceTutorScreen> with SingleTickerProviderStateMixin {
  WebSocketChannel? _channel;
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // State
  String _questionText = "Waiting for teacher..."; // The story/scenario
  String _expression = ""; // The math formula (2 + 2 = ?)
  String? _imageUrl;
  bool _isConnected = false;
  String? _feedbackMessage;
  bool _isChecking = false;

  // Voice State
  bool _isListening = false;
  bool _speechAvailable = false;
  String _lastWords = '';

  // Message Queue
  final List<Map<String, dynamic>> _messageQueue = [];
  bool _isProcessingQueue = false;
  bool _isLoadingQuestion = false;

  Timer? _typewriterTimer;
  String _displayedQuestionText = "";

  // Stats
  int _questionsAnswered = 0;
  int _correctAnswers = 0;

  @override
  void initState() {
    super.initState();
    
    // Animation for pulsing mic/avatar
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initTts();
    _initSpeech();
    _connectWebSocket();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          print('Speech Status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (errorNotification) => print('Speech Error: $errorNotification'),
      );
      if (mounted) {
        setState(() {
          _speechAvailable = available;
        });
      }
    } catch (e) {
      print("Speech initialization failed: $e");
    }
  }

  void _connectWebSocket() {
    // const String serverHost = '127.0.0.1'; 
    // String url = 'ws://$serverHost:8000/ws/voice-tutor/${widget.grade}/${widget.level}/${widget.sublevel}';
    String url = '${AppConfig.wsUrl}/ws/voice-tutor/${widget.grade}/${widget.level}/${widget.sublevel}';


    try {
      print('Connecting to $url');
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _channel!.stream.listen((message) {
        final data = jsonDecode(message);
        _messageQueue.add(data);
        _processQueue();
      }, onError: (error) {
        print('WebSocket Error: $error');
        setState(() {
          _isConnected = false;
          _questionText = "Connection Error";
          _displayedQuestionText = "Connection Error";
        });
      }, onDone: () {
        setState(() {
           _isConnected = false;
        });
      });

      setState(() {
        _isConnected = true;
      });
    } catch (e) {
      print('Connection Exception: $e');
    }
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue || _messageQueue.isEmpty) return;
    _isProcessingQueue = true;

    while (_messageQueue.isNotEmpty) {
      final data = _messageQueue.removeAt(0);

      if (data['type'] == 'feedback') {
        _handleFeedback(data);
        String text = data['text'] ?? "Correct!"; 
        int waitMillis = (text.length * 100) + 1500; 
        await Future.delayed(Duration(milliseconds: waitMillis));
        
        setState(() {
          _isLoadingQuestion = true;
          _imageUrl = null;
          _expression = ""; // Clear expression for next q
          _feedbackMessage = null;
          _lastWords = ""; 
          // Keep question text or clear it? Better to clear or show "Next..."
           _questionText = "";
           _displayedQuestionText = "";
        });

      } else if (data['type'] == 'speak') {
          if (_imageUrl != null) {
            try {
               await precacheImage(NetworkImage(_imageUrl!), context);
            } catch (e) {
               print("Image failed to load: $e");
            }
          }
          
          setState(() {
            _isLoadingQuestion = false;
            _feedbackMessage = null; 
            if (_isChecking) _isChecking = false; 
            _lastWords = "";
          });

          _handleServerMessage(data);
      } else {
        _handleServerMessage(data);
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _isProcessingQueue = false;
  }

  void _handleFeedback(Map<String, dynamic> data) async {
    bool isCorrect = data['isCorrect'] ?? false;
    String text = data['text'] ?? (isCorrect ? "Correct!" : "Try again");
    
    // Increment Stats
    if (isCorrect) {
       _correctAnswers++;
    }
    _questionsAnswered++;

    setState(() {
      _isChecking = false;
      _feedbackMessage = text; 
    });
    
    await _speak(text);

    // Check if 5 questions DONE
    if (_questionsAnswered >= 5) {
       // Wait a moment for the speech to finish/user to register
       await Future.delayed(const Duration(seconds: 2));
       
       // Stop services
       _channel?.sink.close();
       flutterTts.stop();
       _speech.stop();
       
       // Navigate to Success
       Get.off(() => SymbolVoiceSuccessScreen(
         totalQuestions: 5, 
         correctAnswers: _correctAnswers
       ));
    }
  }

  void _handleServerMessage(Map<String, dynamic> data) {
    if (data['type'] == 'speak') {
      String text = data['text'];
      setState(() {
        _feedbackMessage = null;
        _questionText = text; // STORE IT
      });
      _speak(text);
      _startTypewriter(text);
    } else if (data['type'] == 'expression') {
      setState(() {
        _expression = data['text'];
      });
    } else if (data['type'] == 'image') {
       String rawUrl = data['url'];
       // String fixedUrl = rawUrl.replaceFirst("localhost", "127.0.0.1").replaceFirst("192.168.8.118", "127.0.0.1");
       String fixedUrl = rawUrl.replaceFirst("localhost", AppConfig.serverIp);
       fixedUrl = fixedUrl.replaceFirst("127.0.0.1", AppConfig.serverIp);
       
       print("Loading image: $fixedUrl");
       setState(() {
         _imageUrl = fixedUrl;
       });
    }
  }

  void _startTypewriter(String text) {
    _typewriterTimer?.cancel();
    setState(() {
      _displayedQuestionText = "";
    });
    int index = 0;
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (index < text.length) {
        setState(() {
          _displayedQuestionText = text.substring(0, index + 1);
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

  void _listen() async {
    if (!_speechAvailable) {
       print("Initializing speech...");
       await _initSpeech(); 
       if (!_speechAvailable) {
         print("Speech not available after init");
         return;
       }
    }

    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) => print('Speech Status Update: $status'),
        onError: (error) => print('Speech Error Update: $error'),
      );
      
      if (available) {
        setState(() {
          _isListening = true;
          _lastWords = "";
        });
        print("Started listening...");
        _speech.listen(
          onResult: (val) {
            print("Speech Result: ${val.recognizedWords} (Final: ${val.finalResult})");
            setState(() {
              _lastWords = val.recognizedWords;
            });
            
            if (val.finalResult && _lastWords.isNotEmpty) {
               print("Final result received, waiting to send...");
               // Reduced delay to make it snappier
               Future.delayed(const Duration(milliseconds: 500), () {
                 // Removed _isListening check to ensure we send even if status changed
                 if (!_isChecking) { 
                    print("Sending input from final result: $_lastWords");
                    _sendInput(_lastWords);
                    _speech.stop();
                    setState(() => _isListening = false);
                 }
               });
            }
          },
        );
      } else {
        print("Speech initialization returned false");
      }
    } else {
      // Manual Stop - Send what we have!
      print("Manual stop triggered. Last words: $_lastWords");
      setState(() => _isListening = false);
      _speech.stop();
      if (_lastWords.isNotEmpty && !_isChecking) {
         print("Sending input from manual stop: $_lastWords");
         _sendInput(_lastWords);
      }
    }
  }

  void _sendInput(String value) {
    print("Attempting to send input: $value");
    if (_channel != null && _isConnected) {
      setState(() {
        _isChecking = true;
        _feedbackMessage = null;
      });
      String numberValue = _wordToNumber(value);
      print("Sending to WebSocket: $numberValue");
      _channel!.sink.add(jsonEncode({
        "type": "input",
        "value": numberValue
      }));
    } else {
      print("Cannot send: Channel null or not connected");
    }
  }

  String _wordToNumber(String word) {
    final numbers = {
      'zero': '0', 'one': '1', 'two': '2', 'three': '3', 'four': '4',
      'five': '5', 'six': '6', 'seven': '7', 'eight': '8', 'nine': '9',
      'ten': '10'
    };
    String lower = word.toLowerCase().trim();
    for (var key in numbers.keys) {
      if (lower.contains(key)) return numbers[key]!;
    }
    return word; 
  }

  @override
  void dispose() {
    _channel?.sink.close(status.goingAway);
    flutterTts.stop();
    _speech.stop();
    _typewriterTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Blue Header Background
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)], 
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          // 2. Safe Area Content
          SafeArea(
            child: Column(
              children: [
                // Header Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () => Get.back(),
                      ),
                      Expanded(
                        child: Text(
                          'Voice Tutor',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        backgroundImage: const AssetImage('assets/images/user_avatar.png'),
                         onBackgroundImageError: (_, __) {},
                        child: const Icon(Icons.person, color: Colors.grey, size: 24),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Main Content Area (Scrollable if needed, but fitting to screen is better)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        
                        // Teacher/Image Area (Centered)
                        Center(
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      spreadRadius: 2
                                    )
                                  ]
                                ),
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.white,
                                  backgroundImage: const AssetImage('assets/symbols/teacher1.png'),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // QUESTION CARD (The Story)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0), // Light Orange/Peach
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                            ]
                          ),
                          child: Column(
                            children: [
                               if (_imageUrl != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(_imageUrl!, height: 120, fit: BoxFit.contain),
                                  ),
                                ),
                              
                              Text(
                                _displayedQuestionText.isNotEmpty ? _displayedQuestionText : "Listening to teacher...",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),

                        // MATH EXPRESSION CARD
                        if (_expression.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9), // Light Green
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _expression,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.rubik( // Rubik is good for math
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        
                        // FEEDBACK AREA
                        if (_feedbackMessage != null)
                           Padding(
                             padding: const EdgeInsets.only(top: 20.0),
                             child: Container(
                               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                               decoration: BoxDecoration(
                                 color: _feedbackMessage!.contains("Correct") || _feedbackMessage!.contains("Great") 
                                     ? Colors.green[100] 
                                     : Colors.red[100],
                                 borderRadius: BorderRadius.circular(16),
                               ),
                               child: Text(
                                 _feedbackMessage!,
                                 textAlign: TextAlign.center,
                                 style: GoogleFonts.poppins(
                                   fontSize: 16,
                                   fontWeight: FontWeight.w600,
                                   color: _feedbackMessage!.contains("Correct") || _feedbackMessage!.contains("Great")
                                     ? Colors.green[800]
                                     : Colors.red[800],
                                 ),
                               ),
                             ),
                           ),

                        const Spacer(),
                        
                        // MIC BUTTON & STATUS
                        Center(
                          child: GestureDetector(
                            onTap: _listen,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: _isListening ? 90 : 80,
                              width: _isListening ? 90 : 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isListening ? Colors.redAccent : const Color(0xFF6200EA),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isListening ? Colors.redAccent : const Color(0xFF6200EA)).withOpacity(0.4),
                                    blurRadius: _isListening ? 25 : 15,
                                    spreadRadius: _isListening ? 8 : 2,
                                  )
                                ],
                              ),
                              child: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isListening ? "Listening..." : (_isChecking ? "Checking..." : "Tap to Answer"),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Loading Overlay
          if (_isLoadingQuestion)
             Positioned.fill(
               child: Container(
                 color: Colors.white.withOpacity(0.8),
                 child: const Center(
                   child: CircularProgressIndicator(color: Color(0xFF6200EA)),
                 ),
               ),
             ),
        ],
      ),
    );
  }
}
