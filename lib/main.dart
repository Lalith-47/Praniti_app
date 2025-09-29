import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/network/api_client.dart';
import 'core/database/cosmos_db_service.dart';
import 'shared/widgets/app_router.dart';
import 'shared/widgets/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Initialize API Client
  final apiClient = ApiClient();
  apiClient.initialize();
  
  // Initialize Cosmos DB Service
  final cosmosDbService = CosmosDbService();
  cosmosDbService.initialize();
  
  runApp(
    const ProviderScope(
      child: PranitiApp(),
    ),
  );
}

class PranitiApp extends ConsumerWidget {
  const PranitiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}