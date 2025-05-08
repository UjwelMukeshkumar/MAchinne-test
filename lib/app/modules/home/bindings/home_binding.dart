import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:get/get_instance/src/bindings_interface.dart';
import 'package:machineteest/app/modules/home/controllers/home_controller.dart';
import 'package:machineteest/app/services/location_service.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Register LocationService first
    Get.put<LocationService>(
      LocationService(),
      permanent: true,
    ); // or Get.lazyPut<LocationService>(() => LocationService());
    Get.lazyPut<HomeController>(() => HomeController());
  }
}
