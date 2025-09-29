import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/quiz_model.dart';
import '../services/quiz_service.dart';
import '../../../shared/widgets/common/loading_overlay.dart';
import '../../../shared/widgets/common/custom_button.dart';

class QuizListScreen extends ConsumerStatefulWidget {
  const QuizListScreen({super.key});

  @override
  ConsumerState<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends ConsumerState<QuizListScreen> {
  List<QuizModel> _quizzes = [];
  bool _isLoading = true;
  String? _error;
  String _selectedCategory = 'All';
  String _selectedDifficulty = 'All';

  final List<String> _categories = ['All', 'aptitude', 'programming', 'reasoning', 'general'];
  final List<String> _difficulties = ['All', 'easy', 'medium', 'hard'];

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    try {
      final quizService = QuizService();
      final quizzes = await quizService.getAvailableQuizzes();
      
      setState(() {
        _quizzes = quizzes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<QuizModel> get _filteredQuizzes {
    return _quizzes.where((quiz) {
      final categoryMatch = _selectedCategory == 'All' || quiz.category == _selectedCategory;
      final difficultyMatch = _selectedDifficulty == 'All' || quiz.difficulty == _selectedDifficulty;
      return categoryMatch && difficultyMatch;
    }).toList();
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'aptitude':
        return Icons.psychology;
      case 'programming':
        return Icons.code;
      case 'reasoning':
        return Icons.lightbulb;
      default:
        return Icons.quiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Quizzes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuizzes,
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        loadingText: 'Loading quizzes...',
        child: Column(
          children: [
            // Filters
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Category filter
                  Row(
                    children: [
                      const Text('Category: '),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _categories.map((category) {
                              final isSelected = _selectedCategory == category;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(category),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Difficulty filter
                  Row(
                    children: [
                      const Text('Difficulty: '),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _difficulties.map((difficulty) {
                              final isSelected = _selectedDifficulty == difficulty;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(difficulty),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedDifficulty = difficulty;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Quiz list
            Expanded(
              child: _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          CustomButton(
                            text: 'Retry',
                            onPressed: _loadQuizzes,
                          ),
                        ],
                      ),
                    )
                  : _filteredQuizzes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'No quizzes available',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your filters or check back later',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredQuizzes.length,
                          itemBuilder: (context, index) {
                            final quiz = _filteredQuizzes[index];
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: InkWell(
                                onTap: () {
                                  context.go('/student/quiz/${quiz.id}');
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              _getCategoryIcon(quiz.category),
                                              color: Theme.of(context).colorScheme.primary,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  quiz.title,
                                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  quiz.description,
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: Colors.grey[600],
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 16),
                                      
                                      // Quiz metadata
                                      Row(
                                        children: [
                                          _buildMetadataChip(
                                            Icons.access_time,
                                            '${quiz.timeLimit} min',
                                            Colors.blue,
                                          ),
                                          const SizedBox(width: 8),
                                          _buildMetadataChip(
                                            Icons.quiz,
                                            '${quiz.questions.length} questions',
                                            Colors.green,
                                          ),
                                          const SizedBox(width: 8),
                                          _buildMetadataChip(
                                            Icons.trending_up,
                                            quiz.difficulty.toUpperCase(),
                                            _getDifficultyColor(quiz.difficulty),
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 16),
                                      
                                      // Start button
                                      SizedBox(
                                        width: double.infinity,
                                        child: CustomButton(
                                          text: 'Start Quiz',
                                          onPressed: () {
                                            context.go('/student/quiz/${quiz.id}');
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
