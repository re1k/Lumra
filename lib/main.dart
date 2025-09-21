import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'view/Account/AccountPage.dart';
import 'controller/Account/UserController.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final db = FirebaseFirestore.instance;
  const testUserId = "mR3DAdAchnE21Tb0Kjt3"; 
  
  Get.put(UserController(db, testUserId));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Profile Demo',
      debugShowCheckedModeBanner: false,
      home: AccountPage(), 
    );
  }
}