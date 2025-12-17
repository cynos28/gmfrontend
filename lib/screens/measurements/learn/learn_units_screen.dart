import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/screens/measurements/learn/units_lessons/length_lesson_screen.dart';
import 'package:ganithamithura/screens/measurements/learn/units_lessons/capacity_lesson_screen.dart';
import 'package:ganithamithura/screens/measurements/learn/units_lessons/mass_lesson_screen.dart';

class LearnUnitsScreen extends StatelessWidget {
  const LearnUnitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 24),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Learn About Units',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(AppColors.textBlack),
                        ),
                      ),
                      Text(
                        'Meet the measurement families!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(AppColors.subText1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Introduction Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFB74D),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            '👋',
                            style: TextStyle(fontSize: 50),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome!',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFE65100),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Today we learn about three families:\n• Length family 📏\n• Water family 💧\n• Weight family ⚖️',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.brown[800],
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Three Family Cards
                    _buildFamilyCard(
                      title: 'Length Family',
                      subtitle: 'Metre & Centimetre',
                      emoji: '📏',
                      bigUnit: 'Metre (m)',
                      smallUnit: 'Centimetre (cm)',
                      bigExample: 'Door height',
                      smallExample: 'Finger width',
                      relationship: '1 metre = 100 centimetres',
                      color1: const Color(0xFFFF6B6B),
                      color2: const Color(0xFFFF8E53),
                      onTap: () {
                        Get.to(() => const LengthLessonScreen());
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildFamilyCard(
                      title: 'Capacity Family',
                      subtitle: 'Litre & Millilitre',
                      emoji: '💧',
                      bigUnit: 'Litre (L)',
                      smallUnit: 'Millilitre (mL)',
                      bigExample: 'Juice bottle',
                      smallExample: 'Medicine spoon',
                      relationship: '1 litre = 1000 millilitres',
                      color1: const Color(0xFF4E54C8),
                      color2: const Color(0xFF8F94FB),
                      onTap: () {
                        Get.to(() => const CapacityLessonScreen());
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildFamilyCard(
                      title: 'Mass Family',
                      subtitle: 'Kilogram, Gram & Milligram',
                      emoji: '⚖️',
                      bigUnit: 'Kilogram (kg)',
                      smallUnit: 'Gram (g)',
                      bigExample: 'Bag of rice',
                      smallExample: 'Small chocolate',
                      relationship: '1 kilogram = 1000 grams',
                      color1: const Color(0xFF38EF7D),
                      color2: const Color(0xFF11998E),
                      onTap: () {
                        Get.to(() => const MassLessonScreen());
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Simple Rule Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF66BB6A),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.tips_and_updates,
                                color: Color(0xFF2E7D32),
                                size: 32,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Simple Rule!',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildRuleItem(
                            '✖️',
                            'Big → Small',
                            'Multiply',
                            '2 m = 2 × 100 = 200 cm',
                          ),
                          const SizedBox(height: 12),
                          _buildRuleItem(
                            '➗',
                            'Small → Big',
                            'Divide',
                            '500 cm = 500 ÷ 100 = 5 m',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyCard({
    required String title,
    required String subtitle,
    required String emoji,
    required String bigUnit,
    required String smallUnit,
    required String bigExample,
    required String smallExample,
    required String relationship,
    required Color color1,
    required Color color2,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color1, color2],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildUnitBox(
                          '👑',
                          bigUnit,
                          bigExample,
                          color1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildUnitBox(
                          '👶',
                          smallUnit,
                          smallExample,
                          color2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color1.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color1.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Color(AppColors.textBlack),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          relationship,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(AppColors.textBlack),
                          ),
                        ),
                      ],
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

  Widget _buildUnitBox(String emoji, String unit, String example, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(height: 8),
          Text(
            unit,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            example,
            style: const TextStyle(
              fontSize: 11,
              color: Color(AppColors.subText2),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String direction, String action, String example) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      direction,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(AppColors.textBlack),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '→ $action',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  example,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(AppColors.subText2),
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
