class QuizModel {
  final String id;
  final String title;
  final String description;
  final List<QuestionModel> questions;
  final String category;
  final String difficulty;
  final int timeLimit; // in minutes
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  QuizModel({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
    required this.category,
    required this.difficulty,
    required this.timeLimit,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.metadata,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      questions: (json['questions'] as List<dynamic>?)
          ?.map((q) => QuestionModel.fromJson(q))
          .toList() ?? [],
      category: json['category'] ?? '',
      difficulty: json['difficulty'] ?? 'medium',
      timeLimit: json['timeLimit'] ?? 30,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isActive: json['isActive'] ?? true,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),
      'category': category,
      'difficulty': difficulty,
      'timeLimit': timeLimit,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  QuizModel copyWith({
    String? id,
    String? title,
    String? description,
    List<QuestionModel>? questions,
    String? category,
    String? difficulty,
    int? timeLimit,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return QuizModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      questions: questions ?? this.questions,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      timeLimit: timeLimit ?? this.timeLimit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }
}

class QuestionModel {
  final String id;
  final String questionText;
  final List<OptionModel> options;
  final String correctAnswerId;
  final String explanation;
  final String? imageUrl;
  final int points;
  final String category;
  final String difficulty;

  QuestionModel({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswerId,
    required this.explanation,
    this.imageUrl,
    this.points = 1,
    this.category = 'general',
    this.difficulty = 'medium',
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] ?? '',
      questionText: json['questionText'] ?? '',
      options: (json['options'] as List<dynamic>?)
          ?.map((o) => OptionModel.fromJson(o))
          .toList() ?? [],
      correctAnswerId: json['correctAnswerId'] ?? '',
      explanation: json['explanation'] ?? '',
      imageUrl: json['imageUrl'],
      points: json['points'] ?? 1,
      category: json['category'] ?? 'general',
      difficulty: json['difficulty'] ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'options': options.map((o) => o.toJson()).toList(),
      'correctAnswerId': correctAnswerId,
      'explanation': explanation,
      'imageUrl': imageUrl,
      'points': points,
      'category': category,
      'difficulty': difficulty,
    };
  }

  QuestionModel copyWith({
    String? id,
    String? questionText,
    List<OptionModel>? options,
    String? correctAnswerId,
    String? explanation,
    String? imageUrl,
    int? points,
    String? category,
    String? difficulty,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctAnswerId: correctAnswerId ?? this.correctAnswerId,
      explanation: explanation ?? this.explanation,
      imageUrl: imageUrl ?? this.imageUrl,
      points: points ?? this.points,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}

class OptionModel {
  final String id;
  final String text;
  final bool isCorrect;

  OptionModel({
    required this.id,
    required this.text,
    this.isCorrect = false,
  });

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    return OptionModel(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isCorrect': isCorrect,
    };
  }

  OptionModel copyWith({
    String? id,
    String? text,
    bool? isCorrect,
  }) {
    return OptionModel(
      id: id ?? this.id,
      text: text ?? this.text,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}

class QuizResultModel {
  final String id;
  final String quizId;
  final String userId;
  final List<AnswerModel> answers;
  final int totalQuestions;
  final int correctAnswers;
  final double score;
  final double percentage;
  final DateTime completedAt;
  final int timeTaken; // in seconds
  final Map<String, dynamic>? analytics;

  QuizResultModel({
    required this.id,
    required this.quizId,
    required this.userId,
    required this.answers,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.score,
    required this.percentage,
    required this.completedAt,
    required this.timeTaken,
    this.analytics,
  });

  factory QuizResultModel.fromJson(Map<String, dynamic> json) {
    return QuizResultModel(
      id: json['id'] ?? json['_id'] ?? '',
      quizId: json['quizId'] ?? '',
      userId: json['userId'] ?? '',
      answers: (json['answers'] as List<dynamic>?)
          ?.map((a) => AnswerModel.fromJson(a))
          .toList() ?? [],
      totalQuestions: json['totalQuestions'] ?? 0,
      correctAnswers: json['correctAnswers'] ?? 0,
      score: (json['score'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
      completedAt: DateTime.parse(json['completedAt'] ?? DateTime.now().toIso8601String()),
      timeTaken: json['timeTaken'] ?? 0,
      analytics: json['analytics'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quizId': quizId,
      'userId': userId,
      'answers': answers.map((a) => a.toJson()).toList(),
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'score': score,
      'percentage': percentage,
      'completedAt': completedAt.toIso8601String(),
      'timeTaken': timeTaken,
      'analytics': analytics,
    };
  }

  QuizResultModel copyWith({
    String? id,
    String? quizId,
    String? userId,
    List<AnswerModel>? answers,
    int? totalQuestions,
    int? correctAnswers,
    double? score,
    double? percentage,
    DateTime? completedAt,
    int? timeTaken,
    Map<String, dynamic>? analytics,
  }) {
    return QuizResultModel(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      userId: userId ?? this.userId,
      answers: answers ?? this.answers,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      score: score ?? this.score,
      percentage: percentage ?? this.percentage,
      completedAt: completedAt ?? this.completedAt,
      timeTaken: timeTaken ?? this.timeTaken,
      analytics: analytics ?? this.analytics,
    );
  }
}

class AnswerModel {
  final String questionId;
  final String selectedOptionId;
  final bool isCorrect;
  final int points;
  final DateTime answeredAt;

  AnswerModel({
    required this.questionId,
    required this.selectedOptionId,
    required this.isCorrect,
    required this.points,
    required this.answeredAt,
  });

  factory AnswerModel.fromJson(Map<String, dynamic> json) {
    return AnswerModel(
      questionId: json['questionId'] ?? '',
      selectedOptionId: json['selectedOptionId'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
      points: json['points'] ?? 0,
      answeredAt: DateTime.parse(json['answeredAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedOptionId': selectedOptionId,
      'isCorrect': isCorrect,
      'points': points,
      'answeredAt': answeredAt.toIso8601String(),
    };
  }

  AnswerModel copyWith({
    String? questionId,
    String? selectedOptionId,
    bool? isCorrect,
    int? points,
    DateTime? answeredAt,
  }) {
    return AnswerModel(
      questionId: questionId ?? this.questionId,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      isCorrect: isCorrect ?? this.isCorrect,
      points: points ?? this.points,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }
}