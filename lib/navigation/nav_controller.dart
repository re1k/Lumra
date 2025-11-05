import 'package:get/get.dart';
import 'package:lumra_project/controller/Activity/ActivityController.dart';
import 'nav_config.dart';

class NavController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final Rx<UserRole?> role = Rx<UserRole?>(null);

  void setRole(UserRole r) {
    role.value = r;
    currentIndex.value = 0; // always start on Home for a (new) role
  }

  void setTab(int i) {
    currentIndex.value = i;
  }
}
