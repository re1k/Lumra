import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controller/Account/UserController.dart';
import '../../controller/auth/auth_controller.dart';
import '../../theme/base_themes/colors.dart';
import '../../theme/custom_themes/text_theme.dart';
import '../../theme/custom_themes/appbar_theme.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ViewProfile extends StatelessWidget {
  ViewProfile({super.key}) {
    if (!Get.isRegistered<UserController>()) {
      userController = Get.put(UserController(FirebaseFirestore.instance));
      userController.init();
    } else {
      userController = Get.find<UserController>();
    }

    authController = Get.find<AuthController>();
  }

  late final UserController userController;
  late final AuthController authController;
  final isEditing = false.obs;
  final isenable = false.obs;
  final firstNameError = ''.obs;
  final lastNameError = ''.obs;

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: userController.dob.value,
      firstDate: DateTime(1955, 1, 1),
      lastDate: DateTime(2019, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: BColors.buttonPrimary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != userController.dob.value) {
      userController.dob.value = picked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = userController.user.value;
      if (user == null) return const Center(child: CircularProgressIndicator());

      return Scaffold(
        backgroundColor: BColors.lightGrey,
        body: Column(
          children: [
            BAppBarTheme.createHeader(
              context: context,
              title: 'Profile',
              showBackButton: true,
              onBackPressed: () => Navigator.pop(context),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: BColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      tooltip: 'edit profile',
                      icon: const Icon(
                        Icons.edit,
                        color: BColors.primary,
                        size: BSizes.iconLg,
                      ),
                      onPressed: () {
                        isEditing.value = true;
                      },
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    BSizes.lg,
                    BSizes.lg,
                    BSizes.lg,
                    BSizes.lg + 100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        label: "First Name",
                        controller: userController.firstNameController,
                        errorText: firstNameError,
                      ),
                      _buildTextField(
                        label: "Last Name",
                        controller: userController.lastNameController,
                          errorText: lastNameError,
                      ),

                      if(!isEditing.value)
                      _buildEmailField(
                        label: "Email",
                        controller: userController.emailController,
                      )  ,
                      _buildGenderField(),
                      const SizedBox(height: 10),
                      _buildDobField(
                        context: context,
                        label: "Date of Birth",
                        icon: Icons.calendar_today,
                      ),
                      const SizedBox(height: 20),
                      Obx(() {
                        return isEditing.value
                            ? SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                     bool valid = true;

                                    if (userController.firstNameController.text.trim().isEmpty) {
                                    firstNameError.value = "Should not be empty";
                                    valid = false;
                                      } else {
                                       firstNameError.value = '';
                                       }

                                    if (userController.lastNameController.text.trim().isEmpty) {
                                     lastNameError.value = "Should not be empty";
                                     valid = false;
                                      } else {
                                        lastNameError.value = '';
                                        }
                             
                                   if (valid) {
                                    userController.updateUserFromControllers();
                                    _showConfiramtinMessage(context);
                                    isEditing.value = false;

                                       }
                                        },

                                  icon: const Icon(Icons.save),
                                  label: const Text("Save"),
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
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox();
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

   void _showConfiramtinMessage(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Text(
                "Profile Updated",
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontFamily: 'K2D',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: BColors.primary,
                ),
              ),
             
              const SizedBox(height: 16),
              const Text(
                "The profile was updated successfully.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: BSizes.fontSizeMd,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }




  Widget _buildTextField({
  required String label,
  required TextEditingController controller,
  IconData? icon,
  RxString? errorText,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: BTextTheme.lightTextTheme.titleSmall),
          
         
          if (errorText != null && errorText.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: Text(
                errorText.value,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),

          TextField(
            controller: controller,
            readOnly: !isEditing.value,
            maxLength: 12,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
            ],
            decoration: InputDecoration(
              counterText: isEditing.value ? null : '',
              filled: true,
              fillColor: BColors.softGrey,
              prefixIcon: icon != null ? Icon(icon) : null,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      );
    }),
  );
}


Widget _buildEmailField({
  required String label,
  required TextEditingController controller,
  IconData? icon,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: BTextTheme.lightTextTheme.titleSmall),
        const SizedBox(height: 8),
        Obx(
          () => TextField(
            controller: controller,
            readOnly: !isenable.value , 
            decoration: InputDecoration(
              filled: true,
              fillColor: BColors.softGrey,
              
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildDobField({
    required BuildContext context,
    required String label,
    IconData? icon,
  }) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: BTextTheme.lightTextTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(
                text: DateFormat('yyyy-MM-dd').format(userController.dob.value),
              ),
              readOnly: true,
              onTap: isEditing.value ? () => _selectDateOfBirth(context) : null,
              decoration: InputDecoration(
                filled: true,
                fillColor: BColors.softGrey,
                prefixIcon: icon != null ? Icon(icon) : null,
                
                hintText: 'YYYY-MM-DD',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }


 Widget _buildGenderField() {
    return Obx(() {
      final gender = userController.gender.value.toLowerCase();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // const Text("Gender", style: BTextTheme.lightTextTheme.titleSmall ),
          Text("Gender", style: BTextTheme.lightTextTheme.titleSmall),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if(isEditing.value)
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
                    if(isEditing.value)
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
