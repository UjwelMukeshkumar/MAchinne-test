import 'dart:io';
import 'package:machineteest/app/services/storage_service.dart';
import 'package:machineteest/data/models/user_model.dart';

import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';

class StorageProvider {
  final StorageService _storageService = Get.find<StorageService>();

  // Save user data to SQLite
  Future<void> saveUser(UserModel user) async {
    await _storageService.db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get a user by ID from SQLite
  Future<UserModel?> getUser(int id) async {
    final result = await _storageService.db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  // Get all users from SQLite
  Future<List<UserModel>> getAllUsers() async {
    final List<Map<String, dynamic>> result = await _storageService.db.query(
      'users',
    );
    return result.map((map) => UserModel.fromMap(map)).toList();
  }

  // Check if a user exists in SQLite
  Future<bool> hasUser(int id) async {
    final result = await _storageService.db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty;
  }

  // Save an image to local storage and return the path
  Future<String> saveImage(File imageFile, int userId) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'user_${userId}_$timestamp.jpg';
    final path = '${directory.path}/images';

    await Directory(path).create(recursive: true);
    final File localImage = await imageFile.copy('$path/$fileName');

    return localImage.path;
  }

  // Delete an image from local storage
  Future<void> deleteImage(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Update a user's local image path in SQLite
  Future<void> updateUserImage(int userId, String imagePath) async {
    final user = await getUser(userId);
    if (user != null) {
      // Delete old image if it exists
      if (user.localImagePath != null && user.localImagePath!.isNotEmpty) {
        await deleteImage(user.localImagePath!);
      }

      // Update local image path
      user.localImagePath = imagePath;
      await saveUser(user);
    }
  }
}
