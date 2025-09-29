import '../../../core/database/cosmos_db_service.dart';
import '../../../core/errors/api_exception.dart';
import '../../../shared/models/quiz_model.dart';

class QuizService {
  final CosmosDbService _cosmosDb = CosmosDbService();

  Future<List<QuizModel>> getAvailableQuizzes() async {
    try {
      final quizzes = await _cosmosDb.queryDocuments(
        'Quizzes',
        'SELECT * FROM c WHERE c.isActive = true ORDER BY c.createdAt DESC',
      );
      
      return quizzes.map((q) => QuizModel.fromJson(q)).toList();
    } catch (e) {
      throw ApiException('Failed to fetch quizzes: ${e.toString()}');
    }
  }

  Future<QuizModel> getQuizById(String quizId) async {
    try {
      final quiz = await _cosmosDb.getDocument('Quizzes', quizId);
      return QuizModel.fromJson(quiz);
    } catch (e) {
      throw ApiException('Failed to fetch quiz: ${e.toString()}');
    }
  }

  Future<List<QuizModel>> getQuizzesByCategory(String category) async {
    try {
      final quizzes = await _cosmosDb.queryDocuments(
        'Quizzes',
        'SELECT * FROM c WHERE c.category = @category AND c.isActive = true ORDER BY c.createdAt DESC',
        parameters: {'@category': category},
      );
      
      return quizzes.map((q) => QuizModel.fromJson(q)).toList();
    } catch (e) {
      throw ApiException('Failed to fetch quizzes by category: ${e.toString()}');
    }
  }

  Future<List<QuizModel>> getQuizzesByDifficulty(String difficulty) async {
    try {
      final quizzes = await _cosmosDb.queryDocuments(
        'Quizzes',
        'SELECT * FROM c WHERE c.difficulty = @difficulty AND c.isActive = true ORDER BY c.createdAt DESC',
        parameters: {'@difficulty': difficulty},
      );
      
      return quizzes.map((q) => QuizModel.fromJson(q)).toList();
    } catch (e) {
      throw ApiException('Failed to fetch quizzes by difficulty: ${e.toString()}');
    }
  }

  Future<QuizResultModel> submitQuizAnswers({
    required String quizId,
    required String userId,
    required List<AnswerModel> answers,
    required int timeTaken,
  }) async {
    try {
      // Get the quiz to validate answers
      final quiz = await getQuizById(quizId);
      
      // Calculate score
      int correctAnswers = 0;
      double totalScore = 0;
      
      for (final answer in answers) {
        final question = quiz.questions.firstWhere(
          (q) => q.id == answer.questionId,
          orElse: () => throw ApiException('Question not found: ${answer.questionId}'),
        );
        
        final isCorrect = answer.selectedOptionId == question.correctAnswerId;
        if (isCorrect) {
          correctAnswers++;
          totalScore += question.points.toDouble();
        }
      }
      
      final percentage = (correctAnswers / quiz.questions.length) * 100;
      
      // Create result
      final result = QuizResultModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        quizId: quizId,
        userId: userId,
        answers: answers,
        totalQuestions: quiz.questions.length,
        correctAnswers: correctAnswers,
        score: totalScore,
        percentage: percentage,
        completedAt: DateTime.now(),
        timeTaken: timeTaken,
        analytics: {
          'category': quiz.category,
          'difficulty': quiz.difficulty,
          'averageTimePerQuestion': timeTaken / quiz.questions.length,
        },
      );
      
      // Save result to database
      await _cosmosDb.createDocument('QuizResults', result.toJson());
      
      return result;
    } catch (e) {
      throw ApiException('Failed to submit quiz: ${e.toString()}');
    }
  }

  Future<List<QuizResultModel>> getUserQuizResults(String userId) async {
    try {
      final results = await _cosmosDb.queryDocuments(
        'QuizResults',
        'SELECT * FROM c WHERE c.userId = @userId ORDER BY c.completedAt DESC',
        parameters: {'@userId': userId},
      );
      
      return results.map((r) => QuizResultModel.fromJson(r)).toList();
    } catch (e) {
      throw ApiException('Failed to fetch user results: ${e.toString()}');
    }
  }

  Future<List<QuizResultModel>> getQuizResults(String quizId) async {
    try {
      final results = await _cosmosDb.queryDocuments(
        'QuizResults',
        'SELECT * FROM c WHERE c.quizId = @quizId ORDER BY c.completedAt DESC',
        parameters: {'@quizId': quizId},
      );
      
      return results.map((r) => QuizResultModel.fromJson(r)).toList();
    } catch (e) {
      throw ApiException('Failed to fetch quiz results: ${e.toString()}');
    }
  }

  Future<QuizResultModel?> getUserQuizResult(String userId, String quizId) async {
    try {
      final results = await _cosmosDb.queryDocuments(
        'QuizResults',
        'SELECT * FROM c WHERE c.userId = @userId AND c.quizId = @quizId ORDER BY c.completedAt DESC',
        parameters: {'@userId': userId, '@quizId': quizId},
      );
      
      if (results.isNotEmpty) {
        return QuizResultModel.fromJson(results.first);
      }
      return null;
    } catch (e) {
      throw ApiException('Failed to fetch user quiz result: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getUserAnalytics(String userId) async {
    try {
      final results = await getUserQuizResults(userId);
      
      if (results.isEmpty) {
        return {
          'totalQuizzes': 0,
          'averageScore': 0.0,
          'totalTimeSpent': 0,
          'categories': <String, dynamic>{},
          'difficulties': <String, dynamic>{},
        };
      }
      
      final totalQuizzes = results.length;
      final averageScore = results.map((r) => r.percentage).reduce((a, b) => a + b) / totalQuizzes;
      final totalTimeSpent = results.map((r) => r.timeTaken).reduce((a, b) => a + b);
      
      // Group by categories
      final categories = <String, List<double>>{};
      final difficulties = <String, List<double>>{};
      
      for (final result in results) {
        final analytics = result.analytics;
        if (analytics != null) {
          final category = analytics['category'] as String?;
          final difficulty = analytics['difficulty'] as String?;
          
          if (category != null) {
            categories.putIfAbsent(category, () => []).add(result.percentage);
          }
          
          if (difficulty != null) {
            difficulties.putIfAbsent(difficulty, () => []).add(result.percentage);
          }
        }
      }
      
      // Calculate category and difficulty averages
      final categoryAverages = <String, double>{};
      final difficultyAverages = <String, double>{};
      
      categories.forEach((category, scores) {
        categoryAverages[category] = scores.reduce((a, b) => a + b) / scores.length;
      });
      
      difficulties.forEach((difficulty, scores) {
        difficultyAverages[difficulty] = scores.reduce((a, b) => a + b) / scores.length;
      });
      
      return {
        'totalQuizzes': totalQuizzes,
        'averageScore': averageScore,
        'totalTimeSpent': totalTimeSpent,
        'categories': categoryAverages,
        'difficulties': difficultyAverages,
        'recentResults': results.take(5).map((r) => r.toJson()).toList(),
      };
    } catch (e) {
      throw ApiException('Failed to fetch user analytics: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getMentorAnalytics(String mentorId) async {
    try {
      // Get all students assigned to this mentor
      final students = await _cosmosDb.queryDocuments(
        'Users',
        'SELECT * FROM c WHERE c.mentorId = @mentorId AND c.role = @role',
        parameters: {'@mentorId': mentorId, '@role': 'student'},
      );
      
      if (students.isEmpty) {
        return {
          'totalStudents': 0,
          'averageStudentScore': 0.0,
          'totalQuizzesCompleted': 0,
          'studentProgress': <String, dynamic>{},
        };
      }
      
      final totalStudents = students.length;
      int totalQuizzesCompleted = 0;
      double totalScoreSum = 0;
      final studentProgress = <String, dynamic>{};
      
      for (final student in students) {
        final studentId = student['id'] as String;
        final studentName = student['name'] as String;
        
        // Get student's quiz results
        final results = await _cosmosDb.queryDocuments(
          'QuizResults',
          'SELECT * FROM c WHERE c.userId = @userId',
          parameters: {'@userId': studentId},
        );
        
        final quizResults = results.map((r) => QuizResultModel.fromJson(r)).toList();
        totalQuizzesCompleted += quizResults.length;
        
        if (quizResults.isNotEmpty) {
          final averageScore = quizResults.map((r) => r.percentage).reduce((a, b) => a + b) / quizResults.length;
          totalScoreSum += averageScore;
          
          studentProgress[studentId] = {
            'name': studentName,
            'totalQuizzes': quizResults.length,
            'averageScore': averageScore,
            'lastQuizDate': quizResults.first.completedAt.toIso8601String(),
            'recentResults': quizResults.take(3).map((r) => r.toJson()).toList(),
          };
        } else {
          studentProgress[studentId] = {
            'name': studentName,
            'totalQuizzes': 0,
            'averageScore': 0.0,
            'lastQuizDate': null,
            'recentResults': [],
          };
        }
      }
      
      final averageStudentScore = totalStudents > 0 ? totalScoreSum / totalStudents : 0.0;
      
      return {
        'totalStudents': totalStudents,
        'averageStudentScore': averageStudentScore,
        'totalQuizzesCompleted': totalQuizzesCompleted,
        'studentProgress': studentProgress,
      };
    } catch (e) {
      throw ApiException('Failed to fetch mentor analytics: ${e.toString()}');
    }
  }

  // Create sample quizzes for testing
  Future<void> createSampleQuizzes() async {
    try {
      final sampleQuizzes = [
        QuizModel(
          id: 'aptitude-basic',
          title: 'Basic Aptitude Test',
          description: 'Test your basic aptitude skills with this comprehensive quiz.',
          category: 'aptitude',
          difficulty: 'easy',
          timeLimit: 30,
          createdAt: DateTime.now(),
          questions: [
            QuestionModel(
              id: 'q1',
              questionText: 'What is 25% of 200?',
              options: [
                OptionModel(id: 'a', text: '40'),
                OptionModel(id: 'b', text: '50'),
                OptionModel(id: 'c', text: '60'),
                OptionModel(id: 'd', text: '70'),
              ],
              correctAnswerId: 'b',
              explanation: '25% of 200 = (25/100) × 200 = 50',
              points: 1,
            ),
            QuestionModel(
              id: 'q2',
              questionText: 'If a train travels 120 km in 2 hours, what is its speed?',
              options: [
                OptionModel(id: 'a', text: '50 km/h'),
                OptionModel(id: 'b', text: '60 km/h'),
                OptionModel(id: 'c', text: '70 km/h'),
                OptionModel(id: 'd', text: '80 km/h'),
              ],
              correctAnswerId: 'b',
              explanation: 'Speed = Distance/Time = 120/2 = 60 km/h',
              points: 1,
            ),
          ],
        ),
        QuizModel(
          id: 'programming-basic',
          title: 'Basic Programming Concepts',
          description: 'Test your understanding of basic programming concepts.',
          category: 'programming',
          difficulty: 'medium',
          timeLimit: 45,
          createdAt: DateTime.now(),
          questions: [
            QuestionModel(
              id: 'q1',
              questionText: 'What is the output of: print(2 + 3 * 4)?',
              options: [
                OptionModel(id: 'a', text: '20'),
                OptionModel(id: 'b', text: '14'),
                OptionModel(id: 'c', text: '11'),
                OptionModel(id: 'd', text: '9'),
              ],
              correctAnswerId: 'b',
              explanation: 'Following order of operations: 3 * 4 = 12, then 2 + 12 = 14',
              points: 1,
            ),
          ],
        ),
      ];

      for (final quiz in sampleQuizzes) {
        try {
          await _cosmosDb.createDocument('Quizzes', quiz.toJson());
        } catch (e) {
          // Quiz might already exist, continue
        }
      }
    } catch (e) {
      throw ApiException('Failed to create sample quizzes: ${e.toString()}');
    }
  }
}
