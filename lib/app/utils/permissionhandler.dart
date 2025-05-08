import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:image_picker/image_picker.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionHandler {
  // Check and request location permission
  static Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied
      return false;
    }

    // Permissions are granted
    return true;
  }

  // Check and request camera permission
  // Update to PermissionHandler.dart

  static Future<bool> checkCameraPermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final status = await ph.Permission.camera.status;

      if (status.isDenied) {
        // Request permission if denied
        final result = await ph.Permission.camera.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        // Show dialog to guide user to app settings if permission is denied permanently
        _showPermissionSettingsDialog();
        return false;
      }

      return status.isGranted;
    }

    return false;
  }

  static void _showPermissionSettingsDialog() {
    // This method can show a dialog directing the user to the settings page
    Get.defaultDialog(
      title: "Camera Permission",
      middleText:
          "Camera permission is required to take photos. Please enable it in settings.",
      textConfirm: "Open Settings",
      onConfirm: () async {
        await ph.openAppSettings();
        Get.back();
      },
      textCancel: "Cancel",
      onCancel: () => Get.back(),
    );
  }

  // Check and request gallery permission
  static Future<bool> checkGalleryPermission() async {
    if (Platform.isAndroid) {
      // Android 13+ (SDK 33+) uses READ_MEDIA_IMAGES
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      final ph.Permission permission =
          sdkInt >= 33 ? ph.Permission.photos : ph.Permission.storage;

      final status = await permission.status;
      if (status.isDenied || status.isRestricted || status.isLimited) {
        final result = await permission.request();
        return result.isGranted;
      }
      return status.isGranted;
    } else if (Platform.isIOS) {
      final ph.Permission permission = ph.Permission.photos;
      final status = await permission.status;
      if (status.isDenied || status.isRestricted || status.isLimited) {
        final result = await permission.request();
        return result.isGranted;
      }
      return status.isGranted;
    }

    return false;
  }

  // Check multiple permissions at once
  static Future<Map<String, bool>> checkMultiplePermissions(
    List<ph.Permission> permissions,
  ) async {
    Map<String, bool> results = {};

    for (var permission in permissions) {
      final status = await permission.status;

      if (status.isDenied) {
        final result = await permission.request();
        results[permission.toString()] = result.isGranted;
      } else {
        results[permission.toString()] = status.isGranted;
      }
    }

    return results;
  }

  // Pick an image from the gallery
  static Future<XFile?> pickImageFromGallery() async {
    bool hasGalleryPermission = await checkGalleryPermission();

    if (!hasGalleryPermission) {
      return null; // Permission denied, return null
    }

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      return image;
    } catch (e) {
      // Handle any errors or exceptions
      print("Error picking image: $e");
      return null;
    }
  }

  // Take a picture with the camera
  static Future<XFile?> takePictureWithCamera() async {
    bool hasCameraPermission = await checkCameraPermission();

    if (!hasCameraPermission) {
      return null; // Permission denied, return null
    }

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      return image;
    } catch (e) {
      // Handle any errors or exceptions
      print("Error taking picture: $e");
      return null;
    }
  }
}
