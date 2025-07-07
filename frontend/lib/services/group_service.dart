import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../core/constants/app_constants.dart';
import '../data/datasources/api_client.dart';
import '../data/services/group_api_service.dart';

class GroupService {
  final GroupApiService _groupApiService = GroupApiService(apiClient: ApiClient());

  Future<bool> createGroup(String groupName, String? description) async {
    final response = await _groupApiService.createGroup(name: groupName, description: description);
    return response.success;
  }

  Future<bool> joinGroup(String groupCode) async {
    final response = await _groupApiService.joinGroup(groupCode: groupCode);
    return response.success;
  }
}
