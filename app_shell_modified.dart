import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'nav_config.dart';
import 'nav_controller.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<NavController>();

    return Obx(() {
      final role = nav.role.value;
      if (role == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      final items = navConfig[role]!;
      final pages = items.map((e) => e.page).toList();
      final index = nav.currentIndex.value;

      const Color primary = BColors.primary;
      const Color barBg = BColors.white;
      final Color selectedBg = primary.withOpacity(0.15);

      final bottomInset = MediaQuery.of(context).viewPadding.bottom;
      const double barHeight = 68;
      const double side = 16;
      const double vMargin = 10;
      final double floatOffset = (bottomInset > 0 ? bottomInset : 8) + vMargin;
      final double bottomPadForPages = floatOffset + barHeight + 6;

      return Scaffold(
        extendBody: true,
        backgroundColor: barBg,
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: bottomPadForPages),
              child: IndexedStack(index: index, children: pages),
            ),

            Positioned(
              left: side,
              right: side,
              bottom: floatOffset,
              child: Container(
                height: barHeight,
                decoration: BoxDecoration(
                  color: BColors.lightGrey,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: primary.withOpacity(0.4), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: _CompactNavBar(
                  items: items,
                  currentIndex: index,
                  onTap: nav.setTab,
                  primary: primary,
                  selectedBg: selectedBg,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _CompactNavBar extends StatelessWidget {
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color primary;
  final Color selectedBg;

  const _CompactNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.primary,
    required this.selectedBg,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final perItem = constraints.maxWidth / items.length;
        final maxLabelWidth = (perItem - 20).clamp(50.0, 120.0);

        return Row(
          children: List.generate(items.length, (i) {
            final item = items[i];
            final selected = i == currentIndex;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.identity()
                    ..translate(0.0, selected ? -3.0 : 0.0),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: selected ? selectedBg : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(item.icon, size: 22, color: primary),
                      ),
                      const SizedBox(height: 4),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxLabelWidth),
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.1,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
