import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/services/user_service.dart';
import 'package:ganithamithura/services/api/auth_service.dart';
import 'package:ganithamithura/models/user.dart';
import 'package:ganithamithura/screens/authentication/sign_in_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedGrade = 1;
  bool _loading = true;
  User? _currentUser;

  // Grade-specific information
  final Map<int, Map<String, dynamic>> _gradeInfo = {
    1: {
      'color': const Color(0xFF4CAF50),
      'image': 'assets/vectors/stitch1.png',
      'title': 'Grade 1',
      'subtitle': 'Beginner',
      'description': 'Simple counting, comparing, and basic identification',
      'ageRange': 'Ages 6-7',
      'difficulty': 'Very Simple',
    },
    2: {
      'color': const Color(0xFF2196F3),
      'image': 'assets/vectors/stitch2.png',
      'title': 'Grade 2',
      'subtitle': 'Elementary',
      'description': 'Basic calculations, simple measurements, and comparisons',
      'ageRange': 'Ages 7-8',
      'difficulty': 'Simple',
    },
    3: {
      'color': const Color(0xFF9C27B0),
      'image': 'assets/vectors/stitch3.png',
      'title': 'Grade 3',
      'subtitle': 'Intermediate',
      'description': 'Multi-step problems, conversions, and reasoning',
      'ageRange': 'Ages 8-9',
      'difficulty': 'Moderate',
    },
    4: {
      'color': const Color(0xFFFF5722),
      'image': 'assets/vectors/stitch4.png',
      'title': 'Grade 4',
      'subtitle': 'Advanced',
      'description': 'Complex word problems with critical thinking',
      'ageRange': 'Ages 9-10',
      'difficulty': 'Challenging',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await AuthService.instance.getCurrentUser();
    final grade = await UserService.getGrade();
    setState(() {
      _currentUser = user;
      _selectedGrade = user?.grade ?? grade;
      _loading = false;
    });
  }

  Future<void> _saveGrade() async {
    await UserService.saveGrade(_selectedGrade);
    final gradeInfo = _gradeInfo[_selectedGrade]!;
    Get.snackbar(
      'Grade Updated!',
      'Now set to ${gradeInfo['title']} (${gradeInfo['subtitle']})',
      backgroundColor: (gradeInfo['color'] as Color).withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(AppColors.textBlack)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.textBlack),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF7FAFA),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Student Settings',
                    style: TextStyle(
                      fontSize: 24, // Increased
                      fontWeight: FontWeight.w800,
                      color: Color(AppColors.textBlack),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select your grade level to get questions matched to your learning stage.',
                    style: TextStyle(
                      fontSize: 16, // Increased
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Grade selection cards
                  ...List.generate(4, (i) {
                    final grade = i + 1;
                    final info = _gradeInfo[grade]!;
                    final isSelected = _selectedGrade == grade;
                    final color = info['color'] as Color;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedGrade = grade),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(20), // Increased
                          decoration: BoxDecoration(
                            color: isSelected ? color.withOpacity(0.08) : Colors.white,
                            borderRadius: BorderRadius.circular(20), // Increased
                            border: Border.all(
                              color: isSelected ? color : Colors.grey.withOpacity(0.2),
                              width: isSelected ? 3 : 2, // Increased
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Row(
                            children: [
                              // Grade vector character
                              AnimatedScale(
                                scale: isSelected ? 1.2 : 0.9,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.elasticOut,
                                child: Container(
                                  width: 70, // Increased
                                  height: 70, // Increased
                                  decoration: BoxDecoration(
                                    color: isSelected ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Image.asset(
                                    info['image'] as String,
                                    colorBlendMode: isSelected ? null : BlendMode.saturation,
                                    color: isSelected ? null : Colors.grey,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              // Grade info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          info['title'] as String,
                                          style: TextStyle(
                                            fontSize: 22, // Increased
                                            fontWeight: FontWeight.w800,
                                            color: isSelected ? color : const Color(AppColors.textBlack),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isSelected ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            info['ageRange'] as String,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected ? color : Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      info['description'] as String,
                                      style: TextStyle(
                                        fontSize: 14, // Increased
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.speed_rounded,
                                          size: 16,
                                          color: isSelected ? color : Colors.grey[600],
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          info['difficulty'] as String,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected ? color : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Checkmark
                              if (isSelected)
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                )
                              else
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.withOpacity(0.3), width: 2),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveGrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gradeInfo[_selectedGrade]!['color'] as Color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.save_rounded, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Save Grade Level',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.blue[700],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Questions will be generated based on your grade level. '
                            'Higher grades have more challenging problems!',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Logout Button
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () async {
                        await AuthService.instance.signOut();
                        Get.offAll(() => const SignInScreen());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(AppColors.errorColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
