import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../core/constants/app_constants.dart';
import '../data/datasources/api_client.dart';
import 'package:flutter/material.dart';

class TaskService {
  final ApiClient _apiClient = ApiClient();

  Future<bool> createTask(String title, DateTime? dueDate, String recurring) async {
    try {
      final response = await _apiClient.post('/tasks', data: {
        'title': title,
        'dueDate': dueDate?.toIso8601String(),
        'recurring': recurring,
      });
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Create task error: $e');
      return false;
    }
  }

  Future<bool> assignTask(String taskId, String assignedToUserId) async {
    try {
      final response = await _apiClient.post('/tasks/$taskId/assign', data: {
        'assignedTo': assignedToUserId,
      });
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Assign task error: $e');
      return false;
    }
  }

  Future<bool> markTaskDone(String taskId) async {
    try {
      final response = await _apiClient.post('/tasks/$taskId/complete');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Mark task done error: $e');
      return false;
    }
  }

  Future<List<dynamic>> listGroupTasks() async {
    try {
      final response = await _apiClient.get('/tasks/list');
      if (response.statusCode == 200) {
        final data = response.data;
        return data['tasks'] ?? [];
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('List group tasks error: $e');
      return [];
    }
  }

  Future<bool> deleteTask(String taskId) async {
    try {
      final response = await _apiClient.delete('/tasks/$taskId');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Delete task error: $e');
      return false;
    }
  }

  Future<bool> updateTask(String taskId, Map<String, dynamic> updates) async {
    try {
      final response = await _apiClient.put('/tasks/$taskId', data: updates);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update task error: $e');
      return false;
    }
  }
}
