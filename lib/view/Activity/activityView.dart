import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';
import 'package:lumra_project/controller/Activity/ActivityController.dart';
import 'package:lumra_project/model/Activity/ActivityModel.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/custom_themes/appbar_theme.dart';
import 'package:lumra_project/view/Activity/ActivityWidgets/categoryStyle.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/view/Activity/ActivityWidgets/notInterestedConfirmation.dart';
import 'dart:async'; // Required for StreamSubscription

import "package:lumra_project/view/ChatBootADHD/ChatBotWidget.dart";

class ActivityView extends StatefulWidget {
  const ActivityView({super.key});

  @override
  State<ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends State<ActivityView> {
  late final Activitycontroller activityController;
  late final FirebaseFirestore db;
  final AuthController authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    db = FirebaseFirestore.instance;

    // Ensure Activitycontroller is registered once, then init
    activityController = Get.isRegistered<Activitycontroller>()
        ? Get.find<Activitycontroller>()
        : Get.put<Activitycontroller>(Activitycontroller(db), permanent: true);
    activityController.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BColors.lightGrey,
      body: Obx(() {
        final isAdhd = authController.userRole.value == 'adhd';

        final content = StreamBuilder<List<Activitymodel>>(
          stream: activityController.activities$(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  BAppBarTheme.createHeader(
                    context: context,
                    title: 'Activities',
                    subtitle: "Track your daily activities",
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      BSizes.defaultSpace,
                      BSizes.sm,
                      BSizes.defaultSpace,
                      BSizes.xl + 100,
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < snap.data!.length; i++) ...[
                          _ActivityTile(
                            key: ValueKey(snap.data![i].id),
                            item: snap.data![i],
                            textTheme: Theme.of(context).textTheme,
                            onToggle: () =>
                                activityController.toggle(snap.data![i]),
                            activityController: activityController,
                          ),
                          if (i < snap.data!.length - 1)
                            SizedBox(height: BSizes.SpaceBtwItems),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );

        // Overlay chatbot only for ADHD
        return Stack(
          children: [
            content,
            if (isAdhd) const ChatBotWidget(role: 'adhd'),
          ],
        );
      }),
    );
    //////////////////////////////////////LOBA AND LATIFA /////////////////////////////////////////////////////////////////////////////
    // return Scaffold(
    //   backgroundColor: BColors.lightGrey,
    //   body: StreamBuilder<List<Activitymodel>>(
    //     stream: activityController.activities$(),
    //     builder: (context, snap) {
    //       if (!snap.hasData) {
    //         return const Center(child: CircularProgressIndicator());
    //       }

    //       return SingleChildScrollView(
    //         child: Column(
    //           children: [
    //             // Header that scrolls with content
    //             BAppBarTheme.createHeader(
    //               context: context,
    //               title: 'Activities',
    //               subtitle: "Track your daily activities",
    //             ),

    //             // Main content
    //             Padding(
    //               padding: EdgeInsets.fromLTRB(
    //                 BSizes.defaultSpace,
    //                 BSizes.sm,
    //                 BSizes.defaultSpace,
    //                 BSizes.xl + 100, // Extra bottom padding for navbar
    //               ),
    //               child: Column(
    //                 children: [
    //                   for (int i = 0; i < snap.data!.length; i++) ...[
    //                     _ActivityTile(
    //                       key: ValueKey(snap.data![i].id),
    //                       item: snap.data![i],
    //                       textTheme: t,
    //                       onToggle: () =>
    //                           activityController.toggle(snap.data![i]),
    //                       activityController: activityController,
    //                     ),
    //                     if (i < snap.data!.length - 1)
    //                       SizedBox(height: BSizes.SpaceBtwItems),
    //                   ],
    //                 ],
    //               ),
    //             ),
    //           ],
    //         ),
    //       );
    //     },
    //   ),
    // );
  }
}

/// Activity Tile (NOW REACTIVE)
// Converted to StatefulWidget to listen to the completion status of Initial Activities
class _ActivityTile extends StatefulWidget {
  final Activitymodel item;
  final TextTheme textTheme;
  final VoidCallback onToggle;
  final Activitycontroller activityController;

  const _ActivityTile({
    super.key,
    required this.item,
    required this.textTheme,
    required this.onToggle,
    required this.activityController,
  });

  @override
  State<_ActivityTile> createState() => _ActivityTileState();
}

class _ActivityTileState extends State<_ActivityTile> {
  // Variable to store the current completion status for Initial Templates
  bool _isInitialItemChecked = false;
  StreamSubscription? _statusSubscription;
  final db = FirebaseFirestore.instance;
  final AuthController authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    // Start listening only if the activity is an initial template
    if (widget.item.isInitial) {
      _listenToStatus();
    } else {
      // If it's a chatbot activity, use its directly passed status
      _isInitialItemChecked = widget.item.isChecked;
    }
  }

  @override
  void didUpdateWidget(_ActivityTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ensure listening is updated if item.id changes
    if (widget.item.id != oldWidget.item.id) {
      _statusSubscription?.cancel();
      if (widget.item.isInitial) {
        _listenToStatus();
      } else {
        _isInitialItemChecked = widget.item.isChecked;
      }
    } else if (!widget.item.isInitial &&
        widget.item.isChecked != oldWidget.item.isChecked) {
      // Update chatbot status (since it doesn't listen to Firestore)
      _isInitialItemChecked = widget.item.isChecked;
    }
  }

  // Function to listen to the status of the initial activity from Firestore
  void _listenToStatus() {
    final uid = authController.currentUser?.uid;
    if (uid == null) return;

    _statusSubscription = db
        .collection('users')
        .doc(uid)
        .collection('activityStatus')
        .doc(widget.item.id)
        .snapshots()
        .listen((snap) {
          // When new data arrives (or the document is deleted)
          final checked = (snap.data()?['isChecked'] ?? false) as bool;

          if (_isInitialItemChecked != checked) {
            setState(() {
              _isInitialItemChecked = checked;
            });
          }
        });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel(); // Essential for memory cleanup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyles.byKey(widget.item.category);
    final item = widget.item;

    // The variable that reflects the correct real-time status:
    final isDone = item.isInitial ? _isInitialItemChecked : item.isChecked;
    final isChecked = item.isChecked;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isDone ? 0.65 : 1.0,
          child: Container(
            // Each activity card container
            decoration: BoxDecoration(
              color: isDone
                  ? BColors.darkGrey.withOpacity(0.01)
                  : BColors.white,
              borderRadius: BorderRadius.circular(BSizes.cardRadiusLg),
              border: Border.all(color: BColors.borderSecondary),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                BSizes.md - 2,
                BSizes.md - 2,
                BSizes.md - 2,
                BSizes.sm + 4,
              ),
              child: Column(
                children: [
                  // Top row: icon + texts + checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category icon box
                      Container(
                        width: BSizes.iconLg + 16,
                        height: BSizes.iconLg + 16,
                        decoration: BoxDecoration(
                          color: style.bgColor,
                          borderRadius: BorderRadius.circular(
                            BSizes.borderRadiusLg,
                          ),
                        ),
                        child: Icon(
                          style.icon,
                          color: style.iconColor,
                          size: BSizes.iconMd + 2,
                        ),
                      ),
                      SizedBox(width: BSizes.sm + 4),

                      // Texts
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category name chip
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: BSizes.sm,
                                vertical: BSizes.xs - 1,
                              ),
                              decoration: BoxDecoration(
                                color: BColors.secondry.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _titleCase(item.category),
                                style: widget.textTheme.labelMedium?.copyWith(
                                  fontFamily: 'K2D',
                                  fontSize: BSizes.fontSizeSm,
                                  color: BColors.primary,
                                ),
                              ),
                            ),
                            SizedBox(height: BSizes.sm),

                            // Activity Title
                            Text(
                              item.title,
                              overflow: TextOverflow.ellipsis,
                              style: widget.textTheme.titleMedium?.copyWith(
                                fontFamily: 'K2D',
                                fontSize: BSizes.fontSizeMd,
                                color: isDone
                                    ? BColors.darkGrey
                                    : BColors.textprimary, // Update color
                                decoration: isDone
                                    ? TextDecoration.lineThrough
                                    : null, // Add strikethrough
                                decorationColor: BColors.textprimary,
                                decorationThickness: 2,
                              ),
                            ),
                            SizedBox(height: BSizes.xs + 2),

                            // Activity Description
                            Text(
                              item.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: widget.textTheme.bodyMedium?.copyWith(
                                fontFamily: 'K2D',
                                fontSize: BSizes.fontSizeSm,
                                color: BColors.darkGrey,
                              ),
                            ),
                            // Required Time
                            if (item.time.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 15),

                                child: Row(
                                  children: [
                                    Text(
                                      "Required time: ",
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: widget.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontFamily: 'K2D',
                                            fontSize: BSizes.fontSizeSm,
                                            color: BColors.darkGrey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      "${item.time} minutes",
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: widget.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontFamily: 'K2D',
                                            fontSize: BSizes.fontSizeSm,
                                            color: BColors.darkGrey,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      //Checkbox
                      Padding(
                        padding: EdgeInsets.only(left: BSizes.xs + 2, top: 2),
                        child: Checkbox.adaptive(
                          value: isDone, // Use the reactive value
                          onChanged: (_) => widget.onToggle(),
                          activeColor: BColors.primary, // checkmark color
                          checkColor: BColors.textwhite, // inside check color
                          side: BorderSide(
                            color: isDone
                                ? BColors.darkGrey
                                : BColors.borderPrimary, // Update border color
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: BSizes.sm + 4),

                  // Bottom row: timer (right-aligned)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (item.time.trim().isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            if (!item.isChecked) {
                              widget.activityController.onActivityTimeTap(
                                widget.item,
                                context,
                              );
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: BSizes.sm + 2,
                              vertical: BSizes.xs + 2,
                            ),
                            decoration: BoxDecoration(
                              color: BColors.primary,
                              borderRadius: BorderRadius.circular(
                                BSizes.borderRadiusLg,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Start',
                              style: TextStyle(
                                fontFamily: 'K2D',
                                fontSize: BSizes.fontSizeSm,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isChecked)
          Positioned(
            top: -8, // moves it a bit above the box
            right: -8, // moves it a bit outside to the right
            child: GestureDetector(
              onTap: () async {
                final ok = await NotInterestedDialog.show(context);
                if (ok == true) {
                  await widget.activityController.setNotInterested(widget.item);
                }
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String _titleCase(String s) {
  if (s.isEmpty) return s;
  final lower = s.toLowerCase().trim();
  return lower[0].toUpperCase() + lower.substring(1);
}
