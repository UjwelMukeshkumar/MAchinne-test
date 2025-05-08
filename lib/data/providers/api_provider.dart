import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:machineteest/data/models/user_model.dart';

class ApiProvider {
  static const String baseUrl = 'https://reqres.in/api';

  // Fetch users from the API
  Future<List<UserModel>> getUsers({int page = 2}) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users?page=$page'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> users = data['data'];

        return users.map((user) => UserModel.fromJson(user)).toList();
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  // Get a single user by ID
  Future<UserModel> getUserById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$id'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UserModel.fromJson(data['data']);
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }
}
