import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/view/HomePage/Calendar/eventWidgets/addEventView.dart';

///LUBAH THIE GOES ON UR PAGE - Just put it inside ur Scaffold Widget EX:///
///class CalendarPage extends StatelessWidget {
/*const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Calendar')),
      body: CalendarWidget(), // her calendar content

      // Add floatingActionButton . . . . etc here , then feel free to remove this file :) */

class AddEventButtonView extends StatelessWidget {
  const AddEventButtonView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text(''),

      ///----------------------START COPYING FROM HERE LUBAH--------------------///
      floatingActionButton: FloatingActionButton(
        backgroundColor: BColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        onPressed: () {
          //made it looks like popping up from the bottom
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: BColors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            builder: (context) => FractionallySizedBox(
              heightFactor: 0.85, // to make it Covers 85% of screen height
              child: AddEventView(), //in here i added my view
            ),
          );
        },
        //the add icon
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
      ///----------------------END OF UR COPY--------------------///
    );
  }
}
