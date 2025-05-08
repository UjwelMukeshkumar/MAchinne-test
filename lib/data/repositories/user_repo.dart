import 'dart:io';
import 'package:machineteest/data/models/user_model.dart';
import 'package:machineteest/data/providers/api_provider.dart';
import 'package:machineteest/data/providers/storage_provider.dart';

class UserRepository {
  final ApiProvider _apiProvider = ApiProvider();
  final StorageProvider _storageProvider = StorageProvider();

  // Get users from API and save to local storage
  Future<List<UserModel>> getUsers() async {
    try {
      // Fetch users from API
      final List<UserModel> apiUsers = await _apiProvider.getUsers();

      // Prepare merged users list
      final List<UserModel> mergedUsers = [];

      for (var apiUser in apiUsers) {
        // Get local user if exists
        final localUser = await _storageProvider.getUser(apiUser.id);

        // Preserve local image path if present
        if (localUser != null) {
          apiUser.localImagePath = localUser.localImagePath;
        }

        // Save or update the merged user in SQLite
        await _storageProvider.saveUser(apiUser);

        mergedUsers.add(apiUser);
      }

      return mergedUsers;
    } catch (e) {
      // If API fails, try to return local users
      final localUsers = await _storageProvider.getAllUsers();
      if (localUsers.isNotEmpty) {
        return localUsers;
      }

      // If no local users, rethrow the exception
      rethrow;
    }
  }

  // Get a single user by ID
  Future<UserModel> getUserById(int id) async {
    try {
      // Try local storage first
      UserModel? localUser = await _storageProvider.getUser(id);

      if (localUser != null) {
        return localUser;
      }

      // If not found locally, fetch from API and save
      final apiUser = await _apiProvider.getUserById(id);
      await _storageProvider.saveUser(apiUser);

      return apiUser;
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile image
  Future<UserModel> updateUserImage(int userId, File imageFile) async {
    try {
      // Save image to local storage
      final imagePath = await _storageProvider.saveImage(imageFile, userId);

      // Update user's image path in DB
      await _storageProvider.updateUserImage(userId, imagePath);

      // Fetch updated user
      final updatedUser = await _storageProvider.getUser(userId);

      if (updatedUser == null) {
        throw Exception('User not found after image update');
      }

      return updatedUser;
    } catch (e) {
      throw Exception('Failed to update user image: $e');
    }
  }
}
