import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controller/Account/UserController.dart';
import '../../controller/auth/auth_controller.dart';
import '../../theme/base_themes/colors.dart';
import '../../theme/custom_themes/text_theme.dart';
import '../../theme/custom_themes/appbar_theme.dart';
import 'package:lumra_project/view/navbar_widget.dart';

class ViewProfile extends StatelessWidget {
  ViewProfile({super.key}) {
    // Initialize UserController
    if (!Get.isRegistered<UserController>()) {
      userController = Get.put(UserController(FirebaseFirestore.instance));
      userController.init();
    } else {
      userController = Get.find<UserController>();
    }

    // Initialize AuthController
    authController = Get.find<AuthController>();
  }

  late final UserController userController;
  late final AuthController authController;

  
  final enableName = false.obs;
  final enableEmail = false.obs;
  final enableDob = false.obs;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = userController.user.value;
      if (user == null) return const Center(child: CircularProgressIndicator());

      return Scaffold(
        backgroundColor: BColors.light,
        appBar: AppBar(
          title: const Text("Profile Information"),
          backgroundColor: BAppBarTheme.lightAppBarTheme.backgroundColor,
          elevation: BAppBarTheme.lightAppBarTheme.elevation,
          iconTheme: BAppBarTheme.lightAppBarTheme.iconTheme,
          titleTextStyle: BAppBarTheme.lightAppBarTheme.titleTextStyle,
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                _buildTextField(
                  label: "Name",
                  controller: userController.nameController,
                  enable: enableName,
                ),


                _buildTextField(
                  label: "Email",
                  controller: userController.emailController,
                  enable: enableEmail,
                ),


                _buildGenderField(),

                const SizedBox(height: 10),


                _buildTextField(
                  label: "Date of Birth",
                  controller: TextEditingController(
                    text: "${userController.dob.value.toLocal()}".split(' ')[0],
                  ),
                  enable: enableDob,
                  icon: Icons.calendar_today,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {},
                    label: const Text("save"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BColors.primary,
                      foregroundColor: BColors.textwhite,
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 0,
                      ),
                      textStyle: BTextTheme.lightTextTheme.headlineSmall,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ), ), ),
                )
              ],
            ),
          ),
        ),

        //bottomNavigationBar: const NavbarAdhd(),
      );
    });
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    required RxBool enable, 
    VoidCallback? onTap,
  }) {
    return Obx(() => Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(255, 5, 5, 5),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                readOnly: !enable.value,
                onTap: onTap,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: BColors.softGrey,
                  prefixIcon: icon != null ? Icon(icon) : null,
                  suffixIcon: IconButton(
                    icon: Icon(enable.value ? Icons.check : Icons.edit),
                    onPressed: () {
                      enable.value = !enable.value; // تبديل بين القراءة والتحرير
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildGenderField() {
    return Obx(() {
      final gender = userController.gender.value.toLowerCase();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Gender", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    userController.gender.value = 'male';
                  },
                  icon: const Icon(Icons.boy, size: 25),
                  label: const Text("Male"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    backgroundColor: gender == 'male'
                        ? BColors.primary
                        : Colors.grey[300],
                    foregroundColor: gender == 'male'
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    userController.gender.value = 'female';
                  },
                  icon: const Icon(Icons.girl, size: 25),
                  label: const Text("Female"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    backgroundColor: gender == 'female'
                        ? BColors.primary
                        : Colors.grey[300],
                    foregroundColor: gender == 'female'
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}

