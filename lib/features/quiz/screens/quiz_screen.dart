import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/quiz_model.dart';
import '../services/quiz_service.dart';
import '../../../shared/widgets/common/loading_overlay.dart';
import '../../../shared/widgets/common/custom_button.dart';
import '../../auth/providers/auth_provider.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String quizId;
  
  const QuizScreen({
    super.key,
    required this.quizId,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  QuizModel? _quiz;
  List<AnswerModel> _answers = [];
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  String? _selectedOptionId;
  DateTime? _startTime;
  Timer? _timer;
  int _timeRemaining = 0;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    try {
      final quizService = QuizService();
      final quiz = await quizService.getQuizById(widget.quizId);
      
      setState(() {
        _quiz = quiz;
        _isLoading = false;
        _timeRemaining = quiz.timeLimit * 60; // Convert minutes to seconds
        _startTime = DateTime.now();
      });
      
      _startTimer();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        _submitQuiz();
      }
    });
  }

  void _selectOption(String optionId) {
    setState(() {
      _selectedOptionId = optionId;
    });
  }

  void _nextQuestion() {
    if (_selectedOptionId != null && _quiz != null) {
      final currentQuestion = _quiz!.questions[_currentQuestionIndex];
      
      final answer = AnswerModel(
        questionId: currentQuestion.id,
        selectedOptionId: _selectedOptionId!,
        isCorrect: _selectedOptionId == currentQuestion.correctAnswerId,
        points: _selectedOptionId == currentQuestion.correctAnswerId ? currentQuestion.points : 0,
        answeredAt: DateTime.now(),
      );
      
      _answers.add(answer);
      
      if (_currentQuestionIndex < _quiz!.questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _selectedOptionId = null;
        });
      } else {
        _submitQuiz();
      }
    }
  }

  Future<void> _submitQuiz() async {
    if (_quiz == null || _startTime == null) return;
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final quizService = QuizService();
      final user = ref.read(currentUserProvider);
      
      if (user == null) {
        throw Exception('User not found');
      }
      
      final timeTaken = DateTime.now().difference(_startTime!).inSeconds;
      
      final result = await quizService.submitQuizAnswers(
        quizId: widget.quizId,
        userId: user.id,
        answers: _answers,
        timeTaken: timeTaken,
      );
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(result: result),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSubmitting = false;
      });
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Loading quiz...'),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Retry',
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isLoading = true;
                  });
                  _loadQuiz();
                },
              ),
            ],
          ),
        ),
      );
    }

    if (_quiz == null) {
      return const Scaffold(
        body: Center(child: Text('Quiz not found')),
      );
    }

    final currentQuestion = _quiz!.questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _quiz!.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_quiz!.title),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: _timeRemaining < 300 ? Colors.red : Colors.blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatTime(_timeRemaining),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isSubmitting,
        loadingText: 'Submitting quiz...',
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            
            // Question counter
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} of ${_quiz!.questions.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${(progress * 100).toInt()}% Complete',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            
            // Question content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question text
                    Text(
                      currentQuestion.questionText,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Options
                    ...currentQuestion.options.map((option) {
                      final isSelected = _selectedOptionId == option.id;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _selectOption(option.id),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                  : Colors.white,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.grey[400]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    option.text,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary
                                          : null,
                                      fontWeight: isSelected ? FontWeight.w600 : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            
            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentQuestionIndex > 0)
                    Expanded(
                      child: CustomButton(
                        text: 'Previous',
                        type: ButtonType.outline,
                        onPressed: () {
                          setState(() {
                            _currentQuestionIndex--;
                            _selectedOptionId = null;
                          });
                        },
                      ),
                    ),
                  if (_currentQuestionIndex > 0) const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: _currentQuestionIndex < _quiz!.questions.length - 1
                          ? 'Next'
                          : 'Submit Quiz',
                      onPressed: _selectedOptionId != null ? _nextQuestion : null,
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
}

class QuizResultScreen extends StatelessWidget {
  final QuizResultModel result;

  const QuizResultScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = result.percentage;
    String grade;
    Color gradeColor;
    
    if (percentage >= 90) {
      grade = 'Excellent';
      gradeColor = Colors.green;
    } else if (percentage >= 80) {
      grade = 'Good';
      gradeColor = Colors.blue;
    } else if (percentage >= 70) {
      grade = 'Satisfactory';
      gradeColor = Colors.orange;
    } else {
      grade = 'Needs Improvement';
      gradeColor = Colors.red;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Result'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Result summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Grade circle
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: gradeColor.withOpacity(0.1),
                        border: Border.all(color: gradeColor, width: 4),
                      ),
                      child: Center(
                        child: Text(
                          '${percentage.toInt()}%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: gradeColor,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      grade,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: gradeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Correct',
                          '${result.correctAnswers}/${result.totalQuestions}',
                          Colors.green,
                        ),
                        _buildStatItem(
                          'Score',
                          '${result.score.toInt()}',
                          Colors.blue,
                        ),
                        _buildStatItem(
                          'Time',
                          '${result.timeTaken}s',
                          Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Detailed results
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detailed Results',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    ...result.answers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final answer = entry.value;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: answer.isCorrect
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: answer.isCorrect ? Colors.green : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: answer.isCorrect ? Colors.green : Colors.red,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Question ${index + 1}',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    answer.isCorrect ? 'Correct' : 'Incorrect',
                                    style: TextStyle(
                                      color: answer.isCorrect ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (answer.points > 0)
                                    Text(
                                      '+${answer.points} points',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Take Another Quiz',
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/student');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: 'View All Results',
                    type: ButtonType.outline,
                    onPressed: () {
                      Navigator.pushNamed(context, '/student/results');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
