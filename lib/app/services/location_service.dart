import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:machineteest/app/utils/permissionhandler.dart';

class LocationService extends GetxService {
  final Rx<Position?> currentPosition = Rx<Position?>(null);
  final RxString currentAddress = RxString('Fetching location...');
  final RxBool isLoading = RxBool(false);
  final RxBool hasError = RxBool(false);
  final RxString errorMessage = RxString('');

  // Initialize location service
  Future<LocationService> init() async {
    try {
      await getCurrentLocation();
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to get location: $e';
    }
    return this;
  }

  // Get the current location
  Future<void> getCurrentLocation() async {
    isLoading.value = true;
    hasError.value = false;

    try {
      final permissionGranted =
          await PermissionHandler.checkLocationPermission();

      if (!permissionGranted) {
        throw Exception('Location permission not granted');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentPosition.value = position;

      await getAddressFromLatLng(position);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to get location: $e';
      currentAddress.value = 'Location unavailable';
    } finally {
      isLoading.value = false;
    }
  }

  // Get address from latitude and longitude
  Future<void> getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        currentAddress.value =
            '${place.street}, ${place.locality}, ${place.country}';
      } else {
        currentAddress.value = 'Address not found';
      }
    } catch (e) {
      currentAddress.value = 'Failed to get address';
    }
  }

  // String representation for coordinates
  String get locationDisplayString {
    if (currentPosition.value == null) {
      return 'Location: Unknown';
    }

    return 'Lat: ${currentPosition.value!.latitude.toStringAsFixed(4)}, '
        'Long: ${currentPosition.value!.longitude.toStringAsFixed(4)}';
  }
}
