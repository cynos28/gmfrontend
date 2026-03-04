import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ganithamithura/utils/constants.dart';
import 'package:ganithamithura/screens/authentication/sign_in_screen.dart';
import 'package:ganithamithura/services/api/auth_service.dart';
import 'package:ganithamithura/screens/home/home_screen.dart';

/// Sign Up Screen - "Join the Fun!"
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  int _selectedGrade = 1;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await AuthService.instance.signUp(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          grade: _selectedGrade,
        );

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          if (response.success && response.user != null) {
            Get.snackbar(
              'Success',
              'Welcome ${response.user!.name}!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Color(AppColors.successColor),
              colorText: Colors.white,
            );
            
            // Navigate to home screen
            Get.offAll(
              () => const HomeScreen(),
              transition: Transition.fadeIn,
            );
          } else {
            Get.snackbar(
              'Error',
              response.message ?? 'Sign up failed',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Color(AppColors.errorColor),
              colorText: Colors.white,
            );
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          Get.snackbar(
            'Error',
            'An error occurred. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Color(AppColors.errorColor),
            colorText: Colors.white,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Title
                Text(
                  'Join the Fun!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Color(AppColors.textBlack),
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Let\'s start your learning adventure',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(AppColors.subText2),
                  ),
                ),
                const SizedBox(height: 40),

                // Illustration
                Center(
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Image.asset(
                      'assets/images/signup_illustration.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.child_care,
                          size: 100,
                          color: Color(AppColors.primaryColor).withOpacity(0.3),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Name field
                Text(
                  'Your Name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.textBlack),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'What should we call you?',
                    hintStyle: TextStyle(
                      color: Color(AppColors.subText2).withOpacity(0.5),
                    ),
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: Color(AppColors.subText2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Email field
                Text(
                  'Email Address',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.textBlack),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'your.email@example.com',
                    hintStyle: TextStyle(
                      color: Color(AppColors.subText2).withOpacity(0.5),
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: Color(AppColors.subText2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!GetUtils.isEmail(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password field
                Text(
                  'Create Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.textBlack),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Make it strong!',
                    hintStyle: TextStyle(
                      color: Color(AppColors.subText2).withOpacity(0.5),
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Color(AppColors.subText2),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Color(AppColors.subText2),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Grade Dropdown
                Text(
                  'Select Grade',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.textBlack),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedGrade,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.school_outlined,
                      color: Color(AppColors.subText2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  items: [1, 2, 3, 4].map((int grade) {
                    return DropdownMenuItem<int>(
                      value: grade,
                      child: Text('Grade $grade', style: TextStyle(color: Color(AppColors.textBlack))),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedGrade = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Sign In link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(AppColors.subText2),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.to(
                          () => const SignInScreen(),
                          transition: Transition.fadeIn,
                        );
                      },
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(AppColors.primaryColor),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Sign Up button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(AppColors.primaryColor),
                      disabledBackgroundColor:
                          Color(AppColors.primaryColor).withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Start Learning',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
