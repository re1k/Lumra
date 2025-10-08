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
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: BColors.white,
      appBar: AppBar(
        title: Text(
          "Activities",
          style: t.titleLarge?.copyWith(
            fontFamily: 'K2D',
            fontSize: BSizes.fontSizeLg,
            fontWeight: FontWeight.bold,
            color: BColors.white,
          ),
        ),
        backgroundColor: BAppBarTheme.lightAppBarTheme.backgroundColor,
        elevation: BAppBarTheme.lightAppBarTheme.elevation,
        iconTheme: BAppBarTheme.lightAppBarTheme.iconTheme,
        centerTitle: true,
      ),

      body: StreamBuilder<List<Activitymodel>>(
        stream: activityController.activities$(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snap.data!;
          return ListView.separated(
            // Margin between cards and screen edges = 24 px
            padding: EdgeInsets.fromLTRB(
              BSizes.defaultSpace,
              BSizes.sm,
              BSizes.defaultSpace,
              BSizes.xl,
            ),
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(height: BSizes.SpaceBtwItems),
            itemBuilder: (context, i) => _ActivityTile(
              item: items[i],
              textTheme: t,
              onToggle: () => activityController.toggle(items[i]),
            ),
          );
        },
      ),
    );
  }
}

/// Activity Tile
class _ActivityTile extends StatelessWidget {
  final Activitymodel item;
  final TextTheme textTheme;
  final VoidCallback onToggle;

  const _ActivityTile({
    required this.item,
    required this.textTheme,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyles.byKey(item.category);
    final isDone = item.isChecked;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: isDone ? 0.65 : 1.0,
      child: Container(
        // Each activity card container
        decoration: BoxDecoration(
          color: isDone
              ? BColors.darkGrey.withOpacity(0.01)
              : BColors.lightGrey,
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
                            style: textTheme.labelMedium?.copyWith(
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontFamily: 'K2D',
                            fontSize: BSizes.fontSizeMd,
                            color: isDone
                                ? BColors.darkGrey
                                : BColors.textprimary,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
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
                          style: textTheme.bodyMedium?.copyWith(
                            fontFamily: 'K2D',
                            fontSize: BSizes.fontSizeSm,
                            color: BColors.darkGrey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  //Checkbox
                  Padding(
                    padding: EdgeInsets.only(left: BSizes.xs + 2, top: 2),
                    child: Checkbox.adaptive(
                      value: isDone,
                      onChanged: (_) => onToggle(),
                      activeColor: BColors.primary, // checkmark color
                      checkColor: BColors.textwhite, // inside check color
                      side: BorderSide(
                        color: isDone
                            ? BColors.darkGrey
                            : BColors.borderPrimary,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),

              SizedBox(height: BSizes.sm + 4),

              // Bottom row: timer (right-aligned)
              if (item.time.trim().isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: BSizes.sm + 2,
                        vertical: BSizes.xs + 2,
                      ),
                      decoration: BoxDecoration(
                        color: BColors.secondry.withOpacity(0.40),
                        borderRadius: BorderRadius.circular(
                          BSizes.borderRadiusLg,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: BSizes.iconSm + 2,
                            color: BColors.primary,
                          ),
                          SizedBox(width: BSizes.xs + 2),
                          Text(
                            item.time, // like "10 min"
                            style: const TextStyle(
                              fontFamily: 'K2D',
                              fontSize: BSizes.fontSizeSm,
                              color: BColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _titleCase(String s) {
  if (s.isEmpty) return s;
  final lower = s.toLowerCase().trim();
  return lower[0].toUpperCase() + lower.substring(1);
}
