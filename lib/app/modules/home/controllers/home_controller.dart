import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:machineteest/app/services/location_service.dart';
import 'package:machineteest/app/utils/permissionhandler.dart';
import 'package:machineteest/data/models/user_model.dart';
import 'package:machineteest/data/repositories/user_repo.dart';

class HomeController extends GetxController {
  final UserRepository _userRepository = UserRepository();
  final LocationService _locationService = Get.find<LocationService>();

  final RxList<UserModel> users = <UserModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  // Location Getters
  String get locationString => _locationService.locationDisplayString;
  String get addressString => _locationService.currentAddress.value;
  bool get isLocationLoading => _locationService.isLoading.value;
  bool get hasLocationError => _locationService.hasError.value;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
    _locationService.getCurrentLocation();
  }

  // Fetch users from repository
  Future<void> fetchUsers() async {
    try {
      isLoading.value = true;
      hasError.value = false;

      final fetchedUsers = await _userRepository.getUsers();
      users.value = fetchedUsers;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load users: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh data
  Future<void> refreshData() async {
    await fetchUsers();
    await _locationService.getCurrentLocation();
  }

  // Show image source dialog
  // In HomeController.dart

  Future<void> showImageSourceDialog(BuildContext context, int userId) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a photo'),
                onTap: () async {
                  Navigator.of(context).pop();
                  // Make sure permission is granted before opening the camera
                  bool permissionGranted =
                      await PermissionHandler.checkCameraPermission();
                  if (permissionGranted) {
                    _pickImage(ImageSource.camera, userId);
                  } else {
                    Get.snackbar(
                      'Permission Denied',
                      'Please enable camera permissions to take a photo.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  // Make sure gallery permission is granted before opening the gallery
                  bool permissionGranted =
                      await PermissionHandler.checkGalleryPermission();
                  if (permissionGranted) {
                    _pickImage(ImageSource.gallery, userId);
                  } else {
                    Get.snackbar(
                      'Permission Denied',
                      'Please enable gallery permissions to choose a photo.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Pick image from source
  // Update in HomeController.dart

  Future<void> _pickImage(ImageSource source, int userId) async {
    try {
      bool permissionGranted = false;

      if (source == ImageSource.camera) {
        permissionGranted = await PermissionHandler.checkCameraPermission();
      } else {
        permissionGranted = await PermissionHandler.checkGalleryPermission();
      }

      if (!permissionGranted) {
        throw Exception('Permission not granted');
      }

      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        await updateUserImage(userId, imageFile);
      } else {
        throw Exception('No image picked');
      }
    } catch (e) {
      print("Error picking image: $e");
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Update user image
  Future<void> updateUserImage(int userId, File imageFile) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final updatedUser = await _userRepository.updateUserImage(
        userId,
        imageFile,
      );

      final index = users.indexWhere((user) => user.id == userId);
      if (index != -1) {
        users[index] = updatedUser;
        users.refresh();
      }

      Get.back();
      Get.snackbar(
        'Success',
        'Profile image updated',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();

      Get.snackbar(
        'Error',
        'Failed to update image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
