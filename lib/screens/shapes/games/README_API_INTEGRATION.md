# Shapes Games - API Integration

This directory contains the API-integrated screens for the shapes learning games.

## 📁 Files

### API-Integrated Screens (NEW)
- **match_shapes_2d_api.dart** - Shape matching game with API (Levels 1 & 3)
- **answer_questions_2d_api.dart** - Quiz game with API (Levels 2 & 4)
- **pattern_matching_api.dart** - Pattern matching game with API (Levels 5 & 6)

### Original Screens (LEGACY)
- **match_shapes_2d.dart** - Original shape matching (hardcoded data)
- **answer_questions_2d.dart** - Original quiz (hardcoded data)
- **pattern_matching_l5.dart** - Original pattern matching (hardcoded data)

## 🚀 Usage

### Import API Screens
```dart
import 'package:ganithamithura/screens/shapes/games/match_shapes_2d_api.dart';
import 'package:ganithamithura/screens/shapes/games/answer_questions_2d_api.dart';
import 'package:ganithamithura/screens/shapes/games/pattern_matching_api.dart';
```

### Navigate to Games
```dart
// Level 1 - Match 2D Shapes
Get.to(() => const Match2DShapesAPIScreen(gameId: 'level1'));

// Level 2 - 2D Shape Quiz
Get.to(() => const Questions2DShapesAPIScreen(gameId: 'level2'));

// Level 3 - Match 3D Shapes
Get.to(() => const Match2DShapesAPIScreen(gameId: 'level3'));

// Level 4 - 3D Shape Quiz
Get.to(() => const Questions2DShapesAPIScreen(gameId: 'level4'));

// Level 5 - 2D Pattern Matching
Get.to(() => const PatternMatchingAPIScreen(gameId: 'level5'));

// Level 6 - 3D Pattern Matching
Get.to(() => const PatternMatchingAPIScreen(gameId: 'level6'));
```

## 🎮 Game Level Mapping

| Level | Screen | Game ID | Type |
|-------|--------|---------|------|
| 1 | Match2DShapesAPIScreen | level1 | 2D Shape Matching |
| 2 | Questions2DShapesAPIScreen | level2 | 2D Shape Quiz |
| 3 | Match2DShapesAPIScreen | level3 | 3D Shape Matching |
| 4 | Questions2DShapesAPIScreen | level4 | 3D Shape Quiz |
| 5 | PatternMatchingAPIScreen | level5 | 2D Pattern Matching |
| 6 | PatternMatchingAPIScreen | level6 | 3D Pattern Matching |

## ✨ Features

### Common Features
- ✅ Dynamic content loading from API
- ✅ Real-time answer validation
- ✅ Score calculation
- ✅ Star rating system (0-3 stars)
- ✅ Loading states
- ✅ Error handling with retry
- ✅ Try again functionality
- ✅ Results screen

### Screen-Specific Features

#### Match Shapes
- Drag-and-drop interaction
- Visual feedback
- Color-coded validation
- Dynamic shape grid

#### Questions
- Question progression
- Multiple choice
- Instant feedback
- Progress bar

#### Pattern Matching
- Visual patterns
- Image-based options
- Missing shape identification
- Step-by-step progression

## 📋 Requirements

### Backend
- Shapes service running
- MongoDB with games collection
- Authentication service

### Configuration
```dart
// lib/utils/constants.dart
static const String baseUrl = 'http://your-backend:8000';
```

### Authentication
```dart
// Token must be stored in SharedPreferences
final prefs = await SharedPreferences.getInstance();
await prefs.setString('auth_token', 'your-jwt-token');
```

## 🔌 API Endpoints

### Start Game
```
GET /shapes/game/start?game_id=level1
Authorization: Bearer <token>
```

### Check Answers
```
POST /shapes/game/check-answers
Authorization: Bearer <token>

{
  "game_id": "level1",
  "answers": {"1": "Circle", "2": "Square"}
}
```

## 🧪 Testing

### Quick Test
1. Ensure backend is running
2. Configure BASE_URL
3. Navigate to a game:
   ```dart
   Get.to(() => const Match2DShapesAPIScreen(gameId: 'level1'));
   ```
4. Complete the game
5. Verify results

## 📚 Documentation

Complete documentation available in project root:
- **SHAPES_DOCUMENTATION_INDEX.md** - Documentation index
- **SHAPES_API_QUICK_REFERENCE.md** - Quick start guide
- **SHAPES_INTEGRATION_GUIDE.md** - Complete guide
- **SHAPES_ARCHITECTURE.md** - Architecture diagrams
- **SHAPES_INTEGRATION_SUMMARY.md** - Implementation summary

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Failed to load game | Check backend URL and connection |
| Authentication required | Verify token in SharedPreferences |
| Images not loading | Check asset paths in pubspec.yaml |
| Type casting errors | Verify game_id matches game type |

## 🔄 Migration from Legacy Screens

### Old Way (Hardcoded)
```dart
Get.to(() => const Match2DShapesScreen());
```

### New Way (API)
```dart
Get.to(() => const Match2DShapesAPIScreen(gameId: 'level1'));
```

## 📦 Dependencies

Required in pubspec.yaml:
```yaml
dependencies:
  http: ^1.1.0
  get: ^4.6.6
  shared_preferences: ^2.2.2
```

## 🎯 Next Steps

1. Update game selection screen to use new API screens
2. Test all 6 levels with backend
3. Add progress tracking
4. Implement caching for offline mode

## 📞 Support

- Check documentation in project root
- Review error logs
- Test with backend running
- Verify authentication

---

**Status**: ✅ Production Ready  
**Version**: 1.0  
**Last Updated**: January 3, 2026
