
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../model/Account/ProfileModel.dart';

class UserController extends GetxController {
  final FirebaseFirestore db ;
  final String userId ;

  UserController(this.db, this.userId);

  final user = Rxn<UserModel>();


 late TextEditingController nameController = TextEditingController();
  late TextEditingController usernameController = TextEditingController();
  late TextEditingController emailController = TextEditingController();
   var role = ''.obs;
  var gender = ''.obs;
  var dob = DateTime.now().obs;

@override
void onInit() {
  super.onInit();
  nameController = TextEditingController();
  usernameController = TextEditingController();
  emailController = TextEditingController();
  
  _watchUser();
}

void _watchUser() {
  db.collection('users').doc(userId).snapshots().listen((doc) {
    if (doc.exists) {
      user.value = UserModel.fromDoc(doc);

     
      nameController.text = user.value!.name;
      role.value = user.value!.role;
      emailController.text = user.value!.email;
      gender.value = user.value!.gender;
      dob.value = user.value!.dob;
    }
  });
}

  void updateUserFromControllers() {
    if (user.value == null) return;
    final updatedUser = user.value!.copyWith(
      name: nameController.text,
      email: emailController.text,
      gender: gender.value,
      dob: dob.value,
      role: role.value,

    );
    db.collection('users').doc(userId).update(updatedUser.toJson());
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    super.onClose();
  }
}
