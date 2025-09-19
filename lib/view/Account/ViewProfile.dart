import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/Account/ProfileController.dart';
import '../../theme/base_themes/colors.dart';
import '../../theme/custom_themes/text_theme.dart';

class ViewProfile extends StatelessWidget {

  final UserController userController = Get.find<UserController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = userController.user.value;
      if (user == null) return const Center(child: CircularProgressIndicator());

      return Scaffold(
        backgroundColor: BColors.light,
        appBar: AppBar(
          title: Text("Edit Profile", style: BTextTheme.lightTextTheme.headlineLarge),
          backgroundColor: BColors.light,
          foregroundColor: BColors.texBlack,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField("Name", userController.nameController),
                _buildTextField("Username", userController.usernameController),
                _buildTextField("Email", userController.emailController),
                _buildGenderField(),
                _buildDobField(context),
                const SizedBox(height: 30),
                
                ElevatedButton(
                  onPressed: () {
                 if (_validateInputs(context)) {
                  userController.updateUserFromControllers();
                    Get.snackbar("Success", "Profile updated successfully",
                   snackPosition: SnackPosition.BOTTOM,
                     backgroundColor: BColors.buttonPrimary,
                     colorText: Colors.white);
                     }
                   },
                  child: const Text("Save"),
                 ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildGenderField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Obx(() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: BColors.borderPrimary, width: 2),
        ),
        child: DropdownButton<String>(
          value: userController.gender.value.isEmpty ? null : userController.gender.value,
          isExpanded: true,
          underline: const SizedBox(),
          items: ['Male', 'Female'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
          hint: const Text("Select Gender"),
          onChanged: (v) => userController.gender.value = v ?? '',
        ),
      )),
    );
  }

  Widget _buildDobField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Obx(() => InkWell(
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: userController.dob.value,
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (picked != null) userController.dob.value = picked;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey, width: 2),
          ),
          child: Text("${userController.dob.value.toLocal()}".split(' ')[0]),
        ),
      )),
    );
  }
         bool _validateInputs(BuildContext context) {
          if (userController.nameController.text.trim().isEmpty ||
            userController.usernameController.text.trim().isEmpty ||
            userController.emailController.text.trim().isEmpty ||
            userController.gender.value.isEmpty) {
            Get.snackbar("Error", "All fields are required",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
          return false;
          }

        // تحقق من صحة الإيميل
         if (!userController.emailController.text.contains("@")) {
          Get.snackbar("Error", "Invalid email address",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white);
        return false;
        }

       return true;
      }


          
}

