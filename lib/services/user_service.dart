import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String _gradeKey = 'student_grade';

  /// Save selected grade (1-4)
  static Future<void> saveGrade(int grade) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_gradeKey, grade);
  }

  /// Get saved grade; defaults to 1 if not set
  static Future<int> getGrade() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_gradeKey) ?? 1;
  }
}
