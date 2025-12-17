import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DailyTipService {
  static String get _openAiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  // Topics for tips
  static const List<String> topics = [
    'measurements',
    'numbers',
    'symbols',
    'shapes',
  ];

  // Color schemes for different topics
  static const Map<String, Map<String, dynamic>> topicColors = {
    'measurements': {
      'background': 0xFFFF8C52, // Orange
      'icon': '📏',
    },
    'numbers': {
      'background': 0xFF9E9E9E, // Grey
      'icon': '🔢',
    },
    'symbols': {
      'background': 0xFFF06292, // Rose/Pink
      'icon': '➕',
    },
    'shapes': {
      'background': 0xFF42A5F5, // Blue
      'icon': '🔷',
    },
  };

  static String _getRandomTopic() {
    // Get random topic for variety
    final random = Random();
    return topics[random.nextInt(topics.length)];
  }

  static Map<String, dynamic> getRandomColorScheme() {
    final topic = _getRandomTopic();
    return topicColors[topic]!;
  }

  static Map<String, dynamic> getColorSchemeForTopic(String topic) {
    return topicColors[topic]!;
  }

  static Future<Map<String, dynamic>> fetchRandomTip() async {
    final topic = _getRandomTopic();
    
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAiApiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful educational assistant for children aged 6-9 years old. '
                  'Provide short, fun, and practical learning tips that are easy to understand.'
            },
            {
              'role': 'user',
              'content': 'Give me one short learning tip (maximum 2 sentences) about $topic '
                  'for children in grades 1-4. Make it fun, practical, and easy to understand. '
                  'Do not include any greetings or extra text, just the tip.'
            }
          ],
          'max_tokens': 100,
          'temperature': 0.8,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'tip': data['choices'][0]['message']['content'].trim(),
          'topic': topic,
          'colorScheme': topicColors[topic]!,
        };
      } else {
        return {
          'tip': _getFallbackTip(topic),
          'topic': topic,
          'colorScheme': topicColors[topic]!,
        };
      }
    } catch (e) {
      return {
        'tip': _getFallbackTip(topic),
        'topic': topic,
        'colorScheme': topicColors[topic]!,
      };
    }
  }

  static String _getFallbackTip(String topic) {
    final tips = {
      'measurements': [
        'When measuring with a ruler, always start from the 0 mark, not the edge! This helps you get accurate measurements every time.',
        'Remember: 1 meter is about the height of a door handle, and 1 centimeter is about the width of your finger!',
        'To remember liters and milliliters, think of a big bottle (1L) and a tiny medicine spoon (5mL). Easy peasy!',
        'A kilogram is like holding a big bag of rice, while a gram is like one small candy. Now you know the difference!',
      ],
      'numbers': [
        'When counting on your fingers, always start with your thumb! It helps you keep track better and not lose count.',
        'To learn your numbers faster, try counting everyday things like steps, toys, or cookies. Math is everywhere!',
        'Remember: numbers go on forever! There\'s always a bigger number waiting to be discovered.',
        'Practice writing numbers in the air with your finger. It\'s fun and helps you remember their shapes!',
      ],
      'symbols': [
        'The plus sign (+) is like adding friends to a party - the more, the merrier! It always makes numbers bigger.',
        'Think of minus (−) as eating cookies from a jar. You start with some and take away, leaving fewer behind!',
        'Multiplication (×) is just quick addition! Instead of adding 3+3+3+3, you can say 4×3. Same answer, faster way!',
        'Division (÷) means sharing equally with friends. If you have 12 cookies and 4 friends, everyone gets 3!',
      ],
      'shapes': [
        'Count the corners! A triangle has 3, a square has 4, and a circle has none. That\'s the easiest way to remember!',
        'Look around your room - how many rectangles can you find? Windows, doors, books... shapes are everywhere!',
        'A sphere is like a ball you can roll in any direction. A cube is like dice that has 6 flat faces!',
        'To draw a perfect circle, trace around a coin or cup. To draw a square, use a ruler for straight lines!',
      ],
    };

    final topicTips = tips[topic]!;
    final random = Random();
    return topicTips[random.nextInt(topicTips.length)];
  }

  static Map<String, dynamic> getRandomCachedTip() {
    // For immediate display while fetching from API
    final topic = _getRandomTopic();
    return {
      'tip': _getFallbackTip(topic),
      'topic': topic,
      'colorScheme': topicColors[topic]!,
    };
  }
}
