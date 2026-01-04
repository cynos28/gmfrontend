import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
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
  String _currentText = ""; 
  String _displayedText = "Connecting..."; 
  String _expression = ""; 
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
    const String serverHost = '127.0.0.1'; 
    String url = 'ws://$serverHost:8000/ws/voice-tutor/${widget.grade}/${widget.level}/${widget.sublevel}';

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
          _currentText = "Connection Error";
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
          _expression = "";
          _feedbackMessage = null;
          _lastWords = ""; 
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
            if (_isChecking) _isChecking = false; // Reset checking state on new question
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

  void _handleFeedback(Map<String, dynamic> data) {
    bool isCorrect = data['isCorrect'] ?? false;
    String text = data['text'] ?? (isCorrect ? "Correct!" : "Try again");
    
    // Play sound or haptic here for voice mode?
    // For now, TTS handles it
    setState(() {
      _isChecking = false;
      _feedbackMessage = text; 
    });
    _speak(text);
  }

  void _handleServerMessage(Map<String, dynamic> data) {
    if (data['type'] == 'speak') {
      String text = data['text'];
      setState(() {
        _feedbackMessage = null; // Clear feedback when new text comes
      });
      _speak(text);
      _startTypewriter(text);
    } else if (data['type'] == 'expression') {
      setState(() {
        _expression = data['text'];
      });
    } else if (data['type'] == 'image') {
       String rawUrl = data['url'];
       String fixedUrl = rawUrl.replaceFirst("localhost", "127.0.0.1").replaceFirst("192.168.8.118", "127.0.0.1");
       setState(() {
         _imageUrl = fixedUrl;
       });
    }
  }

  void _startTypewriter(String text) {
    // For voice mode, we might not show ALL text, but maybe just a subtitle.
    // Let's keep it for visual reinforcement.
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

  void _listen() async {
    if (!_speechAvailable) {
       _initSpeech(); 
       if (!_speechAvailable) return;
    }

    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _lastWords = "";
        });
        _speech.listen(
          onResult: (val) {
            setState(() {
              _lastWords = val.recognizedWords;
            });
            
            if (val.finalResult && _lastWords.isNotEmpty) {
               // Auto-send after brief pause
               Future.delayed(const Duration(milliseconds: 1200), () {
                 if (!_isChecking && _isListening) { // Ensure still "listening" context
                    _sendInput(_lastWords);
                    _speech.stop();
                    setState(() => _isListening = false);
                 }
               });
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _sendInput(String value) {
    if (_channel != null && _isConnected) {
      setState(() {
        _isChecking = true;
        _feedbackMessage = null;
      });
      String numberValue = _wordToNumber(value);
      _channel!.sink.add(jsonEncode({
        "type": "input",
        "value": numberValue
      }));
    }
  }

  String _wordToNumber(String word) {
    final numbers = {
      'zero': '0', 'one': '1', 'two': '2', 'three': '3', 'four': '4',
      'five': '5', 'six': '6', 'seven': '7', 'eight': '8', 'nine': '9',
      'ten': '10'
    };
    // Attempt to find number words in the sentence
    String lower = word.toLowerCase().trim();
    // Simple check: check if any key is in the string
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2E004E), Color(0xFF6200EA), Color(0xFFB388FF)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Back Button
              Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Get.back(),
                ),
              ),

              // Main Content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Image Viewer (Glassmorphism)
                  if (_imageUrl != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(_imageUrl!, fit: BoxFit.contain),
                      ),
                    ),
                  
                  const Spacer(),

                  // Teacher Avatar & Question
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 20 * (_isListening ? _pulseAnimation.value * 1.5 : 1.0),
                              spreadRadius: 5 * (_isListening ? _pulseAnimation.value : 0.0),
                            )
                          ]
                        ),
                        child: CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.white,
                          backgroundImage: const AssetImage('assets/symbols/teacher1.png'),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // Expression / Question Text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      _expression.isNotEmpty ? _expression : (_isLoadingQuestion ? "Thinking..." : _displayedText),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: _expression.isNotEmpty ? 42 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 4)]
                      ),
                    ),
                  ),
                  
                  // Subtitle (for feedback or text)
                  if (_feedbackMessage != null)
                     Padding(
                       padding: const EdgeInsets.only(top: 16.0),
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                         decoration: BoxDecoration(
                           color: Colors.white.withOpacity(0.9),
                           borderRadius: BorderRadius.circular(30),
                         ),
                         child: Text(
                           _feedbackMessage!,
                           style: GoogleFonts.poppins(color: Colors.deepPurple, fontSize: 16, fontWeight: FontWeight.w600),
                         ),
                       ),
                     ),

                  const Spacer(),
                  const Spacer(),

                  // Mic Button (Hero)
                  GestureDetector(
                    onTap: _listen,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: _isListening ? 100 : 90,
                      width: _isListening ? 100 : 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening ? Colors.redAccent : Colors.white,
                        boxShadow: [
                           BoxShadow(
                             color: (_isListening ? Colors.redAccent : Colors.white).withOpacity(0.5),
                             blurRadius: _isListening ? 30 : 15,
                             spreadRadius: _isListening ? 10 : 2,
                           )
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.white : const Color(0xFF6200EA),
                        size: 45,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  Text(
                    _isListening ? "Listening..." : "Tap to Speak",
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
              
              // Loading Overlay
              if (_isLoadingQuestion)
                Positioned.fill(
                  child: Container(
                    color: Colors.black45,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
