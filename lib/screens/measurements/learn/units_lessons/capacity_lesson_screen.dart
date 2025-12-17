import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';

class CapacityLessonScreen extends StatefulWidget {
  const CapacityLessonScreen({super.key});

  @override
  State<CapacityLessonScreen> createState() => _CapacityLessonScreenState();
}

class _CapacityLessonScreenState extends State<CapacityLessonScreen> {
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
                  colors: [Color(0xFF4E54C8), Color(0xFF8F94FB)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4E54C8).withOpacity(0.3),
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
                          Text('💧', style: TextStyle(fontSize: 24)),
                          SizedBox(width: 8),
                          Text(
                            'Capacity Family',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Litre & Millilitre',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
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
                        color: index <= _currentStep
                            ? const Color(0xFF4E54C8)
                            : Colors.grey[300],
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
                          side: const BorderSide(color: Color(0xFF4E54C8), width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Previous',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4E54C8),
                          ),
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
                        backgroundColor: const Color(0xFF4E54C8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentStep < 2 ? 'Next' : 'Finish',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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
        return _buildWhatIsCapacity();
      case 1:
        return _buildRelationship();
      case 2:
        return _buildConversions();
      default:
        return _buildWhatIsCapacity();
    }
  }

  Widget _buildWhatIsCapacity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What is Capacity? 💧',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(AppColors.textBlack),
          ),
        ),
        const SizedBox(height: 20),
        
        _buildInfoCard(
          '👑',
          'Big Brother: Litre (L)',
          'Used for big amounts of liquid',
          [
            '🥤 Juice bottle',
            '🥛 Milk packet',
            '💧 Water bottle',
          ],
          const Color(0xFF4E54C8),
        ),
        
        const SizedBox(height: 16),
        
        _buildInfoCard(
          '👶',
          'Small Baby: Millilitre (mL)',
          'Used for tiny amounts of liquid',
          [
            '💊 Medicine spoon (5 mL)',
            '🥄 Small spoon (15 mL)',
            '💧 Eye drops (1-2 mL)',
          ],
          const Color(0xFF8F94FB),
        ),
      ],
    );
  }

  Widget _buildRelationship() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'The Magic Number! ✨',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(AppColors.textBlack),
          ),
        ),
        const SizedBox(height: 20),
        
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4E54C8), Color(0xFF8F94FB)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            children: [
              Text(
                '1 litre = 1000 millilitres',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
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
          '🥤',
          'Think of it like this:',
          'If you pour 1 litre of water into 1000 tiny drops, each drop is 1 millilitre!',
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
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(AppColors.textBlack),
          ),
        ),
        const SizedBox(height: 20),
        
        _buildConversionCard(
          '→',
          'Litres to Millilitres',
          'Multiply by 1000',
          ['1 L = 1000 mL', '2 L = 2000 mL', '3 L = 3000 mL'],
          const Color(0xFF4E54C8),
        ),
        
        const SizedBox(height: 16),
        
        _buildConversionCard(
          '←',
          'Millilitres to Litres',
          'Divide by 1000',
          ['1000 mL = 1 L', '2000 mL = 2 L', '500 mL = 0.5 L'],
          const Color(0xFF8F94FB),
        ),
        
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF90CAF9), width: 2),
          ),
          child: const Row(
            children: [
              Text('🎉', style: TextStyle(fontSize: 40)),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Great! You now understand litres and millilitres!',
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
        color: const Color(0xFFE3F2FD),
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
