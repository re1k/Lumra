import 'package:flutter/material.dart';
import 'package:lumra_project/model/user_model.dart';

class QuestionController extends ChangeNotifier {
  UserModel _user = UserModel();
  final Map<String, dynamic> _questions = {};

  UserModel get user => _user;
  Map<String, dynamic> get questions => _questions;

  final List<Map<String, dynamic>> questionList = [
    {
      'question':
          'How do you feel when sitting still for a long time (in class, at work, or at home)?',
      'answers': [
        'Comfortable, no problem',
        'Slightly restless sometimes',
        'Often restless, need short breaks',
        'Very restless, I cannot sit still',
      ],
    },
    {
      'question':
          'How often do you forget things you need to do (homework, calls, daily tasks)?',
      'answers': ['Rarely', 'Sometimes', 'Often', 'Almost always'],
    },
    {
      'question': 'What distracts you the most when you try to focus?',
      'answers': [
        'Almost nothing, I stay focused',
        'Small noises or movements',
        'Several things around me',
        'Almost everything distracts me',
      ],
    },
    {
      'question': 'When you start a task, how do you usually finish it?',
      'answers': [
        'Step by step until it\'s done',
        'I need reminders or a clear plan',
        'I switch tasks sometimes before finishing',
        'I rarely finish tasks without help',
      ],
    },
    {
      'question':
          'When you have to start a task (homework, chores, or work), how easy is it for you to begin?',
      'answers': [
        'Very easy, I start right away',
        'A little hard, but I can manage',
        'Quite hard, I often delay',
        'Very hard, I almost never start on time',
      ],
    },
  ];

  void saveAnswer(int questionIndex, int answerIndex) {
    // Store question answer with metadata
    _questions['question_$questionIndex'] = {
      'question': questionList[questionIndex]['question'],
      'answer': questionList[questionIndex]['answers'][answerIndex],
      'answerIndex': answerIndex,
      'points':
          answerIndex + 1, // Convert 0-based index to 1-based points (1-4)
    };
    // Update user model with questions data
    notifyListeners();
  }

  bool isQuestionAnswered(int questionIndex) {
    return _questions.containsKey('question_$questionIndex');
  }

  int? getAnswerIndex(int questionIndex) {
    return _questions['question_$questionIndex']?['answerIndex'];
  }

  /// Get points for a specific question (1-4)
  int? getQuestionPoints(int questionIndex) {
    return _questions['question_$questionIndex']?['points'];
  }
}
