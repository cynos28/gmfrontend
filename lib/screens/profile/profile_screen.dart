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
    Get.snackbar(
      'Saved',
      'Grade set to $_selectedGrade',
      backgroundColor: const Color(AppColors.infoColor),
      colorText: Colors.white,
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
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Student Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(AppColors.textBlack),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User Details
                  if (_currentUser != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Profile Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(AppColors.textBlack))),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Color(AppColors.primaryColor).withOpacity(0.1),
                                child: Text(
                                  _currentUser!.name.isNotEmpty ? _currentUser!.name[0].toUpperCase() : 'U',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(AppColors.primaryColor)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_currentUser!.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(_currentUser!.email, style: const TextStyle(fontSize: 14, color: Color(AppColors.subText2))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Grade selector
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Grade Level',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(AppColors.textBlack),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Select the student\'s grade (1-4).',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(AppColors.subText2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: List.generate(4, (i) {
                            final grade = i + 1;
                            final isSelected = _selectedGrade == grade;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedGrade = grade),
                              child: Container(
                                width: 72,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(AppColors.measurementColor).withOpacity(0.12)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(AppColors.measurementBorder)
                                        : const Color(AppColors.subText2).withOpacity(0.3),
                                    width: isSelected ? 2 : 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'G$grade',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? const Color(AppColors.measurementBorder)
                                          : const Color(AppColors.textBlack),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveGrade,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(AppColors.measurementBorder),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
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
