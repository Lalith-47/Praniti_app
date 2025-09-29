import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/student/screens/student_dashboard.dart';
import '../../features/mentor/screens/mentor_dashboard.dart';
import '../../features/chat/screens/chat_screen.dart' as chat_screens;
import '../../features/quiz/screens/quiz_screen.dart';
import '../../features/quiz/screens/quiz_list_screen.dart';
import '../../features/student/screens/results_screen.dart';
import '../../features/mentor/screens/analytics_screen.dart';
import '../../features/mentor/screens/students_screen.dart';
import '../../features/shared/screens/splash_screen.dart';
import '../../features/shared/screens/error_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final user = authState.user;
      
      // Show splash screen while loading
      if (isLoading) {
        return '/splash';
      }
      
      // Redirect to login if not authenticated
      if (!isAuthenticated) {
        if (state.uri.path == '/login' || state.uri.path == '/register') {
          return null; // Allow access to auth screens
        }
        return '/login';
      }
      
      // Redirect based on user role
      if (isAuthenticated && user != null) {
        if (state.uri.path == '/login' || state.uri.path == '/register' || state.uri.path == '/splash') {
          if (user.isMentor) {
            return '/mentor';
          } else if (user.isStudent) {
            return '/student';
          }
        }
      }
      
      return null; // No redirect needed
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Authentication Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // Student Routes
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentDashboard(),
        routes: [
          GoRoute(
            path: 'profile',
            builder: (context, state) => const StudentProfileScreen(),
          ),
          GoRoute(
            path: 'quizzes',
            builder: (context, state) => const QuizListScreen(),
          ),
          GoRoute(
            path: 'quiz/:quizId',
            builder: (context, state) {
              final quizId = state.pathParameters['quizId']!;
              return QuizScreen(quizId: quizId);
            },
          ),
          GoRoute(
            path: 'results',
            builder: (context, state) => const ResultsScreen(),
          ),
          GoRoute(
            path: 'mentor',
            builder: (context, state) => const StudentMentorScreen(),
          ),
        ],
      ),
      
      // Mentor Routes
      GoRoute(
        path: '/mentor',
        builder: (context, state) => const MentorDashboard(),
        routes: [
          GoRoute(
            path: 'students',
            builder: (context, state) => const StudentsScreen(),
          ),
          GoRoute(
            path: 'analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: 'sessions',
            builder: (context, state) => const MentorSessionsScreen(),
          ),
        ],
      ),
      
      
      // Chat Routes
      GoRoute(
        path: '/chat',
        builder: (context, state) => const chat_screens.ChatListScreen(),
        routes: [
          GoRoute(
            path: 'room/:roomId',
            builder: (context, state) {
              final roomId = state.pathParameters['roomId']!;
              return chat_screens.ChatScreen(roomId: roomId);
            },
          ),
        ],
      ),
      
      // Error Route
      GoRoute(
        path: '/error',
        builder: (context, state) {
          final error = state.extra as String?;
          return ErrorScreen(error: error);
        },
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(
      error: state.error?.toString(),
    ),
  );
});

// Placeholder screens - these will be implemented
class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Student Profile Screen')),
    );
  }
}

class StudentQuizScreen extends StatelessWidget {
  const StudentQuizScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Student Quiz Screen')),
    );
  }
}

class StudentResultsScreen extends StatelessWidget {
  const StudentResultsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Student Results Screen')),
    );
  }
}

class StudentMentorScreen extends StatelessWidget {
  const StudentMentorScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Student Mentor Screen')),
    );
  }
}

class MentorStudentsScreen extends StatelessWidget {
  const MentorStudentsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Mentor Students Screen')),
    );
  }
}

class MentorAnalyticsScreen extends StatelessWidget {
  const MentorAnalyticsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Mentor Analytics Screen')),
    );
  }
}

class MentorSessionsScreen extends StatelessWidget {
  const MentorSessionsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Mentor Sessions Screen')),
    );
  }
}



