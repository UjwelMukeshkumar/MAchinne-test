import 'package:get/get.dart';
import 'package:machineteest/app/modules/home/bindings/home_binding.dart';
import 'package:machineteest/app/modules/home/view/home_view.dart';

// App routes
abstract class AppRoutes {
  static const HOME = '/home';
}

class AppPages {
  static const INITIAL = AppRoutes.HOME;

  static final routes = [
    GetPage(
      name: AppRoutes.HOME,
      page: () => HomeView(),
      binding: HomeBinding(),
    ),
  ];
}
