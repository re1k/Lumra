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
      const double barHeight = 80;
      const double side = 16;
      const double vMargin = 10;
      final double floatOffset = (bottomInset > 0 ? bottomInset : 8) + vMargin;

      return Scaffold(
        extendBody: true,
        backgroundColor: barBg,
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main content - no bottom padding since navbar floats
            IndexedStack(index: index, children: pages),

            // Floating transparent navbar with glass effect
            Positioned(
              left: side,
              right: side,
              bottom: floatOffset,
              child: Container(
                height: barHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
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
        final maxLabelWidth = (perItem - 16).clamp(60.0, 140.0);

        return Row(
          children: List.generate(items.length, (i) {
            final item = items[i];
            final selected = i == currentIndex;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  //fire item-specific tap hook (Activities will use this)
                  onTap(i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? primary.withOpacity(0.15)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  transform: Matrix4.identity()..scale(selected ? 1.0 : 0.95),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 24,
                        color: selected ? primary : Colors.grey[600],
                      ),
                      const SizedBox(height: 4),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxLabelWidth),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.0,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w700,
                            color: selected ? primary : Colors.grey[800],
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                            ),
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
