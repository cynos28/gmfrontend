import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class ArHuntGameScreen extends StatefulWidget {
  const ArHuntGameScreen({super.key});

  @override
  State<ArHuntGameScreen> createState() => _ArHuntGameScreenState();
}

class _ArHuntGameScreenState extends State<ArHuntGameScreen> {
  int _currentShapeIndex = 0;
  bool _isModelLoading = true;
  bool _isListening = false;
  late stt.SpeechToText _speech;
  String _recognizedText = '';
  
  String get currentShape => shapes[_currentShapeIndex]['name'] as String;
  String get shapeDescription => shapes[_currentShapeIndex]['description'] as String;
  String get modelUrl => shapes[_currentShapeIndex]['modelUrl'] as String;
  
  final List<Map<String, dynamic>> shapes = [
    {
      'name': 'Cube',
      'description': 'A cube has 6 flat faces and 8 corners!',
      'color': Colors.blue,
      'modelUrl': 'https://modelviewer.dev/shared-assets/models/cube.gltf',
    },
    {
      'name': 'Sphere',
      'description': 'A sphere is perfectly round like a ball!',
      'color': Colors.red,
      'modelUrl': 'https://modelviewer.dev/shared-assets/models/reflective-sphere.gltf',
    },
    {
      'name': 'Cone',
      'description': 'A cone has a circular base and comes to a point!',
      'color': Colors.orange,
      'modelUrl': 'assets/models/cone.glb',
    },
    {
      'name': 'Cylinder',
      'description': 'A cylinder has 2 circular ends and a curved surface!',
      'color': Colors.cyan,
      'modelUrl': 'assets/models/cylinder.glb',
    }, 
    {
      'name': 'Pyramid',
      'description': 'A pyramid has a square base and 4 triangular faces!',
      'color': Colors.yellow,
      'modelUrl': 'assets/models/pyramid.glb',
    },
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    // Reset loading state when first loaded
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isModelLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  Future<void> _handleVoiceButton() async {
    if (_isListening) {
      // Stop listening if already active
      await _speech.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
          _recognizedText = '';
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice listening stopped'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.grey,
        ),
      );
    } else {
      // Request permission and start listening
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        await _startListening();
      } else {
        _showPermissionDeniedDialog();
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Permission'),
        content: const Text('Please enable microphone permission to use voice commands.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          // Silently stop listening without messages
          if (mounted) {
            setState(() {
              _isListening = false;
              _recognizedText = '';
            });
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isListening = false;
            _recognizedText = '';
          });
          
          // Silently ignore ALL speech recognition errors
          // Users don't need to see technical error messages
          // The voice feature will just stop listening quietly
        }
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
        _recognizedText = '';
      });

      // Safety timeout: silently stop listening after 40 seconds
      Future.delayed(const Duration(seconds: 40), () async {
        if (_isListening && mounted) {
          await _speech.stop();
          if (mounted) {
            setState(() {
              _isListening = false;
              _recognizedText = '';
            });
          }
        }
      });

      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _recognizedText = result.recognizedWords.toLowerCase();
            });

            // Process on final result OR if we have a clear match on partial results
            if (_recognizedText.isNotEmpty) {
              // Check if the recognized text (after normalization) matches any shape
              final normalizedText = _normalizeCommand(_recognizedText);
              final hasMatch = shapes.any((shape) {
                final shapeName = (shape['name'] as String).toLowerCase();
                return normalizedText.contains(shapeName);
              });

              // Process immediately if we have a match (either final or partial with clear match)
              if (result.finalResult || hasMatch) {
                _processVoiceCommand(_recognizedText);
                if (mounted) {
                  setState(() {
                    _isListening = false;
                    _recognizedText = '';
                  });
                }
              }
            }
          }
        },
        listenFor: const Duration(seconds: 40),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
      );
    } else {
      setState(() {
        _isListening = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition not available'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _processVoiceCommand(String command) {
    final normalizedCommand = _normalizeCommand(command);
    
    // Find matching shape
    final matchingIndex = shapes.indexWhere((shape) {
      final shapeName = (shape['name'] as String).toLowerCase();
      return normalizedCommand.contains(shapeName);
    });

    if (matchingIndex != -1) {
      setState(() {
        _isModelLoading = true;
        _currentShapeIndex = matchingIndex;
      });

      final shapeName = shapes[matchingIndex]['name'] as String;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Loading $shapeName...'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF7DD3C0),
        ),
      );

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _isModelLoading = false;
          });
        }
      });
    } else {
      _showShapeNotFoundDialog(command);
    }
  }

  String _normalizeCommand(String command) {
    // Normalize command and handle common mispronunciations
    String normalizedCommand = command.toLowerCase().trim();
    
    // Handle common pronunciation variations
    if (normalizedCommand.contains('spear')) {
      normalizedCommand = normalizedCommand.replaceAll('spear', 'sphere');
    }
    
    // Handle cone variations: kaun, coon, con, conn → cone
    if (normalizedCommand.contains('kaun') ||
        normalizedCommand.contains('coon') || 
        normalizedCommand == 'con' || 
        normalizedCommand.contains('conn')) {
      normalizedCommand = normalizedCommand
          .replaceAll('kaun', 'cone')
          .replaceAll('coon', 'cone')
          .replaceAll('conn', 'cone');
      // Handle standalone "con" only if it's not part of another word
      if (normalizedCommand == 'con' || 
          normalizedCommand.startsWith('con ') || 
          normalizedCommand.endsWith(' con') || 
          normalizedCommand.contains(' con ')) {
        normalizedCommand = normalizedCommand.replaceAll('con', 'cone');
      }
    }
    
    // Handle cylinder variations
    if (normalizedCommand.contains('sylinder')) {
      normalizedCommand = normalizedCommand.replaceAll('sylinder', 'cylinder');
    }
    
    return normalizedCommand;
  }

  void _showShapeNotFoundDialog(String spokenText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.mic_off,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Shape Not Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (spokenText.isNotEmpty) ...[
              Text(
                'You said: "$spokenText"',
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
            ],
            const Text(
              'Please speak clearly and use correct pronunciation.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Available shapes:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ...shapes.map((shape) {
              final name = shape['name'] as String;
              final color = shape['color'] as Color;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startListening();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7DD3C0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _loadRandomShape() {
    setState(() {
      _isModelLoading = true;
      // Cycle through shapes sequentially to ensure all shapes are seen
      _currentShapeIndex = (_currentShapeIndex + 1) % shapes.length;
    });
    // Reset loading after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isModelLoading = false;
        });
      }
    });
  }

  Color _getCurrentShapeColor() {
    return shapes[_currentShapeIndex]['color'] as Color;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xF2FFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 31,
                      height: 31,
                      decoration: BoxDecoration(
                        color: const Color(0x80D9D9D9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'AR Hunt',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  // Single voice button
                  GestureDetector(
                    onTap: _handleVoiceButton,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _isListening 
                            ? Colors.red 
                            : const Color(0xFF7DD3C0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _isListening
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.mic,
                              size: 20,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 3D Model Viewer
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Stack(
                  children: [
                    // Main 3D Model Viewer - Full clickable area
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ModelViewer(
                          key: ValueKey(modelUrl),
                          backgroundColor: const Color(0xFFEEEEEE),
                          src: modelUrl,
                          alt: 'A 3D model of $currentShape',
                          ar: true,
                          arModes: const ['scene-viewer', 'webxr', 'quick-look'],
                          autoRotate: true,
                          autoRotateDelay: 500,
                          rotationPerSecond: '30deg',
                          cameraControls: true,
                          disableZoom: false,
                          shadowIntensity: 1.0,
                          shadowSoftness: 1.0,
                          exposure: 1.0,
                          autoPlay: true,
                          cameraOrbit: '0deg 75deg 105%',
                          minCameraOrbit: 'auto auto 5%',
                          maxCameraOrbit: 'auto auto 200%',
                          touchAction: TouchAction.panY,
                          interactionPrompt: InteractionPrompt.auto,
                          interactionPromptThreshold: 500,
                        ),
                      ),
                    ),
                    
                    // Instruction text - Positioned to not block AR button
                    Positioned(
                      top: 20,
                      left: 20,
                      right: 20,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _isListening 
                                ? '🎤 Listening: "$_recognizedText"' 
                                : '👆 Touch to rotate • 🎤 Tap mic to speak • 📱 AR button',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    
                    // Corner brackets - Non-interactive
                    Positioned(
                      top: 20,
                      left: 20,
                      child: IgnorePointer(
                        child: CustomPaint(
                          size: const Size(40, 40),
                          painter: CornerBracketPainter(
                            color: const Color(0xFF7DD3C0),
                            position: CornerPosition.topLeft,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 20,
                      right: 20,
                      child: IgnorePointer(
                        child: CustomPaint(
                          size: const Size(40, 40),
                          painter: CornerBracketPainter(
                            color: const Color(0xFF7DD3C0),
                            position: CornerPosition.topRight,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: IgnorePointer(
                        child: CustomPaint(
                          size: const Size(40, 40),
                          painter: CornerBracketPainter(
                            color: const Color(0xFF7DD3C0),
                            position: CornerPosition.bottomLeft,
                          ),
                        ),
                      ),
                    ),
                    // Removed bottom-right bracket to avoid blocking AR button
                  ],
                ),
              ),
            ),
            
            // Shape info card
            Container(
              margin: const EdgeInsets.all(18),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0x33827D7D),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Shape name
                  Text(
                    currentShape,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Shape description
                  Text(
                    shapeDescription,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0x80000000),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  
                  // Try Another Shape button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _loadRandomShape,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1AD7F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.rotate(
                            angle: -math.pi / 2,
                            child: const Icon(
                              Icons.refresh,
                              color: Color(0xFFD33636),
                              size: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Try Another Shape',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD33636),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

enum CornerPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class CornerBracketPainter extends CustomPainter {
  final Color color;
  final CornerPosition position;

  CornerBracketPainter({
    required this.color,
    required this.position,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final path = Path();
    
    switch (position) {
      case CornerPosition.topLeft:
        path.moveTo(size.width, 0);
        path.lineTo(0, 0);
        path.lineTo(0, size.height);
        break;
      case CornerPosition.topRight:
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height);
        break;
      case CornerPosition.bottomLeft:
        path.moveTo(0, 0);
        path.lineTo(0, size.height);
        path.lineTo(size.width, size.height);
        break;
      case CornerPosition.bottomRight:
        path.moveTo(0, size.height);
        path.lineTo(size.width, size.height);
        path.lineTo(size.width, 0);
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
