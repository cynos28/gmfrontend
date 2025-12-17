import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';

class MassLessonScreen extends StatefulWidget {
  const MassLessonScreen({super.key});

  @override
  State<MassLessonScreen> createState() => _MassLessonScreenState();
}

class _MassLessonScreenState extends State<MassLessonScreen> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF38EF7D), Color(0xFF11998E)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38EF7D).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('⚖️', style: TextStyle(fontSize: 24)),
                          SizedBox(width: 8),
                          Text(
                            'Mass Family',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Kilogram, Gram & Milligram',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Progress
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: index <= _currentStep ? const Color(0xFF38EF7D) : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildStepContent(),
              ),
            ),
            
            // Navigation
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentStep--),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF38EF7D), width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Previous',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF38EF7D)),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentStep < 2) {
                          setState(() => _currentStep++);
                        } else {
                          Get.back();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF38EF7D),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _currentStep < 2 ? 'Next' : 'Finish',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildWhatIsMass();
      case 1:
        return _buildRelationship();
      case 2:
        return _buildConversions();
      default:
        return _buildWhatIsMass();
    }
  }

  Widget _buildWhatIsMass() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What is Mass (Weight)? ⚖️',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(AppColors.textBlack)),
        ),
        const SizedBox(height: 20),
        
        _buildInfoCard(
          '👑',
          'Big Brother: Kilogram (kg)',
          'Used for heavy things',
          ['🍚 Bag of rice', '🍎 Many fruits', '📦 Heavy boxes'],
          const Color(0xFF38EF7D),
        ),
        
        const SizedBox(height: 16),
        
        _buildInfoCard(
          '👦',
          'Middle Child: Gram (g)',
          'Used for light things',
          ['🍫 Small chocolate', '✏️ One pen', '🍪 One cookie'],
          const Color(0xFF11998E),
        ),
        
        const SizedBox(height: 16),
        
        _buildInfoCard(
          '👶',
          'Tiny Baby: Milligram (mg)',
          'Used for very tiny things',
          ['💊 Medicine tablet', '🧂 Pinch of salt', '✨ Too small to feel'],
          const Color(0xFF0B7A6F),
        ),
      ],
    );
  }

  Widget _buildRelationship() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'The Magic Numbers! ✨',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(AppColors.textBlack)),
        ),
        const SizedBox(height: 20),
        
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF38EF7D), Color(0xFF11998E)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            children: [
              Text(
                '1 kilogram = 1000 grams',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                '1 gram = 1000 milligrams',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Remember: 1000!',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        _buildExample(
          '🧱',
          'Think of building blocks:',
          'If you break 1 kilogram into 1000 equal pieces, each piece is 1 gram!\n\nIf you break 1 gram into 1000 tiny dust pieces, each dust piece is 1 milligram!',
        ),
      ],
    );
  }

  Widget _buildConversions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How to Convert! 🔄',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(AppColors.textBlack)),
        ),
        const SizedBox(height: 20),
        
        _buildConversionCard(
          '→',
          'Kilograms to Grams',
          'Multiply by 1000',
          ['1 kg = 1000 g', '2 kg = 2000 g', '5 kg = 5000 g'],
          const Color(0xFF38EF7D),
        ),
        
        const SizedBox(height: 16),
        
        _buildConversionCard(
          '←',
          'Grams to Kilograms',
          'Divide by 1000',
          ['1000 g = 1 kg', '2000 g = 2 kg', '500 g = 0.5 kg'],
          const Color(0xFF11998E),
        ),
        
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFB74D), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  const Text(
                    'For Grade 5 Students:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFE65100)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'You can also convert between grams and milligrams:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                '• 1 g = 1000 mg\n• 2 g = 2000 mg\n• 500 mg = 0.5 g',
                style: TextStyle(fontSize: 14, color: Colors.brown[800], fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF66BB6A), width: 2),
          ),
          child: const Row(
            children: [
              Text('🎉', style: TextStyle(fontSize: 40)),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Awesome! You now know all about kilograms, grams, and milligrams!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String emoji, String title, String subtitle, List<String> examples, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
                    Text(subtitle, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...examples.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(e, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              )),
        ],
      ),
    );
  }

  Widget _buildExample(String emoji, String title, String content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversionCard(String arrow, String title, String action, List<String> examples, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(arrow, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
                    Text(action, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...examples.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Text(e, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
