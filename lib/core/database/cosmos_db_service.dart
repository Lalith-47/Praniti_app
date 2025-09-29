import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../errors/api_exception.dart';

class CosmosDbService {
  static final CosmosDbService _instance = CosmosDbService._internal();
  factory CosmosDbService() => _instance;
  CosmosDbService._internal();

  late String _endpoint;
  late String _key;
  late String _databaseName;

  void initialize() {
    // Parse connection string
    final connectionString = AppConstants.cosmosDbConnectionString;
    final parts = connectionString.split(';');
    
    for (final part in parts) {
      if (part.startsWith('AccountEndpoint=')) {
        _endpoint = part.substring('AccountEndpoint='.length);
      } else if (part.startsWith('AccountKey=')) {
        _key = part.substring('AccountKey='.length);
      }
    }
    
    _databaseName = AppConstants.cosmosDbDatabaseName;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': _generateAuthToken(),
    'x-ms-version': '2020-07-15',
    'x-ms-documentdb-is-upsert': 'true',
  };

  String _generateAuthToken() {
    // In a real implementation, you would generate a proper Cosmos DB auth token
    // For now, we'll use the master key directly
    return 'type=master&ver=1.0&sig=$_key';
  }

  String _buildUrl(String containerName, {String? documentId}) {
    final baseUrl = '$_endpoint/dbs/$_databaseName/colls/$containerName';
    return documentId != null ? '$baseUrl/docs/$documentId' : baseUrl;
  }

  Future<Map<String, dynamic>> createDocument(
    String containerName,
    Map<String, dynamic> document, {
    String? id,
  }) async {
    try {
      final url = _buildUrl(containerName);
      final body = {
        ...document,
        'id': id ?? document['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      };

      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw ApiException('Failed to create document: ${response.body}');
      }
    } catch (e) {
      throw ApiException('Database error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getDocument(
    String containerName,
    String documentId,
  ) async {
    try {
      final url = _buildUrl(containerName, documentId: documentId);
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw ApiException('Document not found');
      } else {
        throw ApiException('Failed to get document: ${response.body}');
      }
    } catch (e) {
      throw ApiException('Database error: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> queryDocuments(
    String containerName,
    String query, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final url = '${_buildUrl(containerName)}/docs';
      
      final queryBody = {
        'query': query,
        if (parameters != null) 'parameters': parameters.entries
            .map((e) => {'name': e.key, 'value': e.value})
            .toList(),
      };

      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(queryBody),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return List<Map<String, dynamic>>.from(result['Documents'] ?? []);
      } else {
        throw ApiException('Failed to query documents: ${response.body}');
      }
    } catch (e) {
      throw ApiException('Database error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> updateDocument(
    String containerName,
    String documentId,
    Map<String, dynamic> document,
  ) async {
    try {
      final url = _buildUrl(containerName, documentId: documentId);
      
      final response = await http.put(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(document),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException('Failed to update document: ${response.body}');
      }
    } catch (e) {
      throw ApiException('Database error: ${e.toString()}');
    }
  }

  Future<void> deleteDocument(
    String containerName,
    String documentId,
  ) async {
    try {
      final url = _buildUrl(containerName, documentId: documentId);
      
      final response = await http.delete(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode != 204) {
        throw ApiException('Failed to delete document: ${response.body}');
      }
    } catch (e) {
      throw ApiException('Database error: ${e.toString()}');
    }
  }

  // Convenience methods for specific collections
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> user) async {
    return await createDocument(AppConstants.cosmosDbContainerUsers, user);
  }

  Future<Map<String, dynamic>> getUser(String userId) async {
    return await getDocument(AppConstants.cosmosDbContainerUsers, userId);
  }

  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    return await queryDocuments(
      AppConstants.cosmosDbContainerUsers,
      'SELECT * FROM c WHERE c.role = @role',
      parameters: {'@role': role},
    );
  }

  Future<Map<String, dynamic>> createQuiz(Map<String, dynamic> quiz) async {
    return await createDocument(AppConstants.cosmosDbContainerQuizzes, quiz);
  }

  Future<List<Map<String, dynamic>>> getQuizzes() async {
    return await queryDocuments(
      AppConstants.cosmosDbContainerQuizzes,
      'SELECT * FROM c ORDER BY c.createdAt DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getMessages(String roomId) async {
    return await queryDocuments(
      AppConstants.cosmosDbContainerMessages,
      'SELECT * FROM c WHERE c.roomId = @roomId ORDER BY c.timestamp ASC',
      parameters: {'@roomId': roomId},
    );
  }

  Future<Map<String, dynamic>> createMessage(Map<String, dynamic> message) async {
    return await createDocument(AppConstants.cosmosDbContainerMessages, message);
  }

  Future<List<Map<String, dynamic>>> getSessions(String mentorId) async {
    return await queryDocuments(
      AppConstants.cosmosDbContainerSessions,
      'SELECT * FROM c WHERE c.mentorId = @mentorId ORDER BY c.scheduledAt DESC',
      parameters: {'@mentorId': mentorId},
    );
  }

  Future<Map<String, dynamic>> createSession(Map<String, dynamic> session) async {
    return await createDocument(AppConstants.cosmosDbContainerSessions, session);
  }
}
