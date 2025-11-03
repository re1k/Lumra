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
    final r = role.value;
    if (r != null) {
      final items = navConfig[r]!;
      if (i >= 0 && i < items.length) {
        final label = items[i].label.toLowerCase();
        if (label == 'activities' && Get.isRegistered<Activitycontroller>()) {
          Get.find<Activitycontroller>()
              .onActivitiesTabTapped(); //show if a new overflow happened
        }
      }
    }

    currentIndex.value = i;
  }
}
