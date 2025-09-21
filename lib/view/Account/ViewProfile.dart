import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/Account/UserController.dart';
import '../../theme/base_themes/colors.dart';
import '../../theme/custom_themes/text_theme.dart';
import '../../theme/custom_themes/appbar_theme.dart'; 

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
                _buildTextField("Name", userController.nameController),
                _buildTextField("Email", userController.emailController),
                _buildGenderField(),
                _buildDobField(context),
                const SizedBox(height: 30),

                
                const SizedBox(height: 20),
               
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Gender", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: BColors.borderPrimary, width: 2),
              ),
              child: DropdownButton<String>(
                value: ['Male', 'Female'].contains(userController.gender.value)
                    ? userController.gender.value
                    : null,
                isExpanded: true,
                underline: const SizedBox(),
                items: ['Male', 'Female']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                hint: const Text("Select Gender"),
                onChanged: (v) => userController.gender.value = v ?? '',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDobField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Date of Birth", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            InkWell(
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
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey, width: 2),
                ),
                child: Text("${userController.dob.value.toLocal()}".split(' ')[0]),
              ),
            ),
          ],
        ),
      ),
    );
  }


}