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

    final currentUser = userController.user.value;
    if (currentUser != null) {
      userController.firstNameController.text = currentUser.firstName;
      userController.lastNameController.text = currentUser.lastName;
      userController.emailController.text = currentUser.email;     
      userController.dob.value = currentUser.dob;
      userController.gender.value = currentUser.gender;
    }
    
    isEditing.value = false;
  }

  late final UserController userController;
  late final AuthController authController;
  final isEditing = false.obs;
  final isenable = false.obs;
  final firstNameError = ''.obs;
  final lastNameError = ''.obs;

  
  final _formKey = GlobalKey<FormState>();
  final RxBool _triggerRebuild = false.obs;

  Future<void> _selectDateOfBirth(BuildContext context) async {
   
    final userRole = userController.role.value; 
    final int lastYear = (userRole == 'caregiver') ? 2007 : 2019;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: userController.dob.value,
      firstDate: DateTime(1955, 1, 1),
      lastDate: DateTime(lastYear, 12, 31),
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
      
      final refresh = _triggerRebuild.value; 

      if (user == null) return const Center(child: CircularProgressIndicator());

      return Scaffold(
        backgroundColor: BColors.lightGrey,
        body: Column(
          children: [
           
            BAppBarTheme.createHeader(
              context: context,
              title: 'Profile',
              showBackButton: true,
              onBackPressed: () async {
                if (await _onWillPop(context)) {
                  Navigator.pop(context);
                }
              },
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: Container(
                      width: 45,
                      height: 50,
                      decoration: BoxDecoration(
                        color: BColors.white,
                        borderRadius: BorderRadius.circular(8),
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
                        padding: EdgeInsets.zero,
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
                        onChanged: (_) => _triggerRebuild.toggle(),
                      ),
                      _buildTextField(
                        label: "Last Name",
                        controller: userController.lastNameController,
                        errorText: lastNameError,
                        onChanged: (_) => _triggerRebuild.toggle(), //  
                      ),
                      
                        _buildEmailField(
                          label: "Email",
                          controller: userController.emailController,
                        ),
                      _buildGenderField(),
                      const SizedBox(height: 10),
                      _buildDobField(
                        context: context,
                        label: "Date of Birth",
                        icon: Icons.calendar_today,
                      ),
                      const SizedBox(height: 20),
                      Obx(() {
                        if (!isEditing.value) return const SizedBox();

                        bool hasChanges = 
                            userController.firstNameController.text != user.firstName ||
                            userController.lastNameController.text != user.lastName ||
                            userController.gender.value != user.gender ||
                            userController.dob.value != user.dob;

                        
                        bool isValidInput = 
                            userController.firstNameController.text.trim().isNotEmpty &&
                            userController.lastNameController.text.trim().isNotEmpty;

                        
                        bool canSave = hasChanges && isValidInput;

                        return Center(
                          child: SizedBox(
                            width: 200,
                            child: ElevatedButton.icon(
                              onPressed: canSave ? () {
                                
                                userController.updateUserFromControllers();
                                _showConfiramtinMessage(context);
                                isEditing.value = false;
                              } : null, 
                              
                              label: const Text("Save"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canSave ? BColors.primary : Colors.grey,
                                foregroundColor: BColors.textwhite,
                                disabledBackgroundColor: Colors.grey.shade300,
                                disabledForegroundColor: Colors.grey.shade600,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 0,
                                ),
                                textStyle: BTextTheme.lightTextTheme.headlineSmall,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        );
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

 Future<bool> _onWillPop(BuildContext context) async {

    if (!isEditing.value) {
      return true; //
    }

    final user = userController.user.value;
    bool hasChanges = 
        userController.firstNameController.text != user?.firstName ||
        userController.lastNameController.text != user?.lastName ||
        userController.gender.value != user?.gender ||
        userController.dob.value != user?.dob;

    if (hasChanges) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Discard Changes"),
          content: const Text("You have unsaved changes. Are you sure you want to leave?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // 
              child: const Text(
                "Cancel",
                style: TextStyle(fontFamily: 'K2D', color: Colors.black87),
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: BColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                minimumSize: const Size(90, 40),
              ),
              onPressed: () {
             
                Navigator.of(context).pop(true); 
              },
              child: const Text("Discard", style: TextStyle(fontFamily: 'K2D',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,)),
            ),
          ],
        ),
      );

      if (shouldDiscard == true) {
         if(user != null){
             userController.firstNameController.text = user.firstName;
             userController.lastNameController.text = user.lastName;
             userController.gender.value = user.gender;
             userController.dob.value = user.dob;
         }
         isEditing.value = false;
         return true;
      } else {
        return false;
      }
      
    } else {
     
      isEditing.value = false;
      return true; 
    }
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
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Obx(() {
        
        bool isEmpty = controller.text.trim().isEmpty;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Row(
              children: [
                Text(label, style: BTextTheme.lightTextTheme.titleSmall),
                if (isEmpty && isEditing.value) 
                  const Padding(
                    padding: EdgeInsets.only(left: 4.0),
                    child: Text("*", style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            
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
              onChanged: onChanged,
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
         
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(label, style: BTextTheme.lightTextTheme.titleSmall),
              
              if (isEditing.value)
                Padding(
                  padding: const EdgeInsets.only(left: 6.0, bottom: 2.0),
                  child: Text(
                    "Not editable",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 8),

          Obx(
            () => TextField(
              controller: controller,
              readOnly: true,
              decoration: InputDecoration(
                filled: true,
               
                fillColor: isEditing.value 
                    ? Colors.grey.shade300 
                    : BColors.softGrey,
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
                
                suffixIcon: icon != null ? Icon(icon) : null, 
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
          Text("Gender", style: BTextTheme.lightTextTheme.titleSmall),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (isEditing.value) userController.gender.value = 'male';
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
                        : BColors.softGrey,
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
                    if (isEditing.value) userController.gender.value = 'female';
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
                        : BColors.softGrey,
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