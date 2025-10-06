import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../model/Activity/ActivityModel.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';

class Activitycontroller {

final FirebaseFirestore db;
final AuthController authController = Get.find<AuthController>();

Activitycontroller(this.db);

final Activity = Rxn<Activitymodel>();
    final RxBool isChecked = false.obs;
  late  TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController categoryController;
  late TextEditingController timeController;




  void init() {
    titleController = TextEditingController();
    descriptionController = TextEditingController();
    categoryController = TextEditingController();
    timeController = TextEditingController();

    final uid = authController.currentUser?.uid;
    if (uid != null) {
      _watchUser(uid);
    }
  }


void _watchUser(String uid) {
  db.collection('users').doc(uid).snapshots().listen((doc) {
    if (doc.exists) {
      Activity.value = Activitymodel.fromDoc(doc);
      
      // TextEditingControllers
      titleController.text = Activity.value?.title ?? '';
      descriptionController.text = Activity.value?.description ?? '';
      categoryController.text = Activity.value?.category ?? '';
      timeController.text = Activity.value?.time ?? '';

      // RxBool for checkbox
      isChecked.value = Activity.value?.isChecked ?? false;
    }
  });
}



bool markActivityDone(Activitymodel activity) {


return false;

}

Future<bool> hasActivity() async {
  final uid = authController.currentUser?.uid;
 QuerySnapshot<Map<String, dynamic>> snapshot = await db
      .collection('users')
      .doc(uid)
      .collection('activities')
      .get();

 if (snapshot.docs.isNotEmpty) {
    return true; // has activity
  } else {
    return false; // empty
  }
}



void getinitialActivity (int totalpoints) async {
  //get total points in the users collection
 final uid = authController.currentUser?.uid;
DocumentSnapshot<Map<String, dynamic>> userDoc = await db.collection('users').doc().get();
int totalPoints = userDoc.data()?['totalPoints'] ?? 0;

// retrive all initialActivities based on the total points
QuerySnapshot<Map<String, dynamic>> snapshot = await db.collection('initialActivities').get();

 List<Activitymodel> allActivities = snapshot.docs .map((doc) => Activitymodel.fromDoc(doc)).toList();
         List<Activitymodel> filteredActivities = [];

    if (totalPoints >= 5 && totalPoints <= 8) {
         filteredActivities = allActivities.where((activity) =>
             activity.title == 'Short Walk' ||
              activity.title == 'Light Yoga' ||
             activity.title == 'Small Art'
         ).toList();
     } else if (totalPoints >= 9 && totalPoints <= 12) {
        filteredActivities = allActivities.where((activity) =>
            activity.title == 'Short Run' ||
            activity.title == 'Brain Games' ||
            activity.title == 'Cooking'
         ).toList();
     } else if (totalPoints >= 13 && totalPoints <= 16) {
        filteredActivities = allActivities.where((activity) =>
        activity.title == 'Team Sports' ||
        activity.title == 'Fun Exercises' ||
        activity.title == 'Journaling'
        ).toList();
    } else if (totalPoints >= 17 && totalPoints <= 20) {
        filteredActivities = allActivities.where((activity) =>
        activity.title == 'Advanced Yoga' ||
        activity.title == 'Large Puzzle' ||
        activity.title == 'Gardening'
       ).toList();
     }

}










}