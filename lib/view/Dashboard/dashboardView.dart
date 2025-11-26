import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/Dashboard/dashboardController.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/view/Activity/ActivityWidgets/categoryStyle.dart';
import 'package:lumra_project/theme/custom_themes/appbar_theme.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? _selectedCategory;
  double? _selectedCount;

  // toggle state between daily and weekly
  bool showDaily = true;

  // NEW: Scroll controller for the continuous weekly chart
  final ScrollController _weeklyScrollController = ScrollController();
  
  // Track scrolling state for arrows (True means we are at W1/Start)
  bool _isAtStart = true;

  final DashboardController dashController = Get.put(
    DashboardController(FirebaseFirestore.instance),
  );
  
  // PageController for Daily (kept for compatibility)
  late final PageController _weeklyPageController;
  int _weeklyPage = 0;

  @override
  void initState() {
    super.initState();
    _weeklyPageController = PageController();
    
    // Listen to scroll changes to update arrows visibility
    _weeklyScrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (!_weeklyScrollController.hasClients) return;
    
    final offset = _weeklyScrollController.offset;
    // Check if at start with a small tolerance (e.g. 5 pixels)
    bool atStart = offset <= 5;
    
    if (_isAtStart != atStart) {
      setState(() {
        _isAtStart = atStart;
      });
    }
  }

  @override
  void dispose() {
    _weeklyPageController.dispose();
    _weeklyScrollController.removeListener(_scrollListener);
    _weeklyScrollController.dispose();
    super.dispose();
  }

  // Helper: compute week of month for a given date
  int weekOfMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    return ((date.day + firstDay.weekday - 1) / 7).ceil();
  }

  //  button for weekly + daily
  Widget _toggleButton(String label, bool isDailyButton) {
    bool isActive = showDaily == isDailyButton;
    return GestureDetector(
      onTap: () {
        setState(() => showDaily = isDailyButton);
        
        // FIX: When switching to Weekly, force jump to end and update arrow state
        if (!isDailyButton) { 
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_weeklyScrollController.hasClients) {
              _weeklyScrollController.jumpTo(
                _weeklyScrollController.position.maxScrollExtent
              );
              // We jumped to end, so we are NOT at start. Update state to show Left Arrow.
              setState(() {
                _isAtStart = false; 
              });
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? BColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'K2D',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : BColors.textprimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final DateTime now = DateTime.now();
    final String currentMonth = DateFormat('MMMM').format(now);
    final int currentWeek = weekOfMonth(now);
    final int todayIndex = now.weekday == 7 ? 0 : now.weekday; 

    return Scaffold(
      backgroundColor: BColors.lightGrey,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ---------------- HEADER ----------------
              SizedBox(
                width: double.infinity,
                child: BAppBarTheme.createHeader(
                  context: context,
                  title: 'Dashboard',
                ),
              ),

              // -------------- WEEKLY  and Daily--------------
              Padding(
                padding: EdgeInsets.fromLTRB(
                  BSizes.lg,
                  0,
                  BSizes.lg,
                  BSizes.lg + 80,
                ),
                child: Transform.translate(
                  offset: const Offset(0, -14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ----------------  WEEKLY BOX ----------------
                      Container(
                        width: double.infinity,
                        height: 300,
                        decoration: BoxDecoration(
                          color: BColors.white,
                          borderRadius: BorderRadius.circular(
                            BSizes.cardRadiusLg,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Obx(() {
                            // 1. Prepare Data inside Obx
                            final weeklyScores = dashController.weeklyScores; 
                            final weeklyHistory = dashController.weeklyHistory; 
                            final currentWeekAvg = dashController.currentWeekAverage;

                            const List<String> dailyKeys = [
                              'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'
                            ];

                            // Continuous Data
                            List<double> weeklyData = [
                              ...weeklyHistory,
                              //currentWeekAvg,
                            ];

                            // Labels
                            final List<String> weeklyLabels =
                                List.generate(weeklyData.length, (i) {
                              final isLast = i == weeklyData.length - 1;
                              return isLast ? 'This week' : 'W${i + 1}';
                            });
                            

                            // Dynamic Width
                            double chartWidth = weeklyData.length * 60.0;
                            if (chartWidth < MediaQuery.of(context).size.width - 100) {
                              chartWidth = MediaQuery.of(context).size.width - 100;
                            }

                            // Initial check if we load directly into Weekly
                            if (showDaily == false && _weeklyScrollController.hasClients && _weeklyScrollController.offset == 0 && weeklyData.isNotEmpty) {
                                 WidgetsBinding.instance.addPostFrameCallback((_) {
                                   _weeklyScrollController.jumpTo(
                                      _weeklyScrollController.position.maxScrollExtent
                                   );
                                   setState(() {
                                      _isAtStart = false;
                                   });
                                 });
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ---------------- HEADER ROW ----------------
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // LEFT COLUMN: Title + Left Arrow (<)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Title
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4, bottom: 0),
                                          child: Text(
                                            showDaily
                                                ? "Daily Progress - Week $currentWeek"
                                                : "Weekly Progress",
                                            style: textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: BColors.textprimary,
                                            ),
                                          ),
                                        ),

                                        // LEFT ARROW: Goes to W1.
                                        // Only show if NOT Daily AND NOT at start (we are at This Week or middle)
                                        SizedBox(
                                          height: 24,
                                          child: (!showDaily && !_isAtStart)
                                            ? Directionality(
                                                textDirection: ui.TextDirection.ltr,
                                                child: IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  icon: const Icon(
                                                    Icons.chevron_left, 
                                                    color: BColors.primary,
                                                    size: 24,
                                                  ),
                                                  onPressed: () {
                                                    // Go to Start (W1)
                                                    _weeklyScrollController.animateTo(
                                                      0, 
                                                      duration: const Duration(milliseconds: 500), 
                                                      curve: Curves.easeInOut
                                                    );
                                                  },
                                                ),
                                              )
                                            : null,
                                        ),
                                      ],
                                    ),

                                    // RIGHT COLUMN: Toggles + Right Arrow (>)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        // Toggles
                                        Container(
                                          decoration: BoxDecoration(
                                            color: BColors.lightGrey.withOpacity(0.4),
                                            borderRadius: BorderRadius.circular(24),
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          child: Row(
                                            children: [
                                              _toggleButton("Daily", true),
                                              _toggleButton("Weekly", false),
                                            ],
                                          ),
                                        ),

                                        // RIGHT ARROW: Goes to This Week.
                                        // Only show if NOT Daily AND AT Start (we are at W1)
                                        SizedBox(
                                          height: 24,
                                          child: (!showDaily && _isAtStart)
                                            ? Directionality(
                                                textDirection: ui.TextDirection.ltr,
                                                child: IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  icon: const Icon(
                                                    Icons.chevron_right, 
                                                    color: BColors.primary,
                                                    size: 24,
                                                  ),
                                                  onPressed: () {
                                                    // Go to End (This Week)
                                                    _weeklyScrollController.animateTo(
                                                      _weeklyScrollController.position.maxScrollExtent,
                                                      duration: const Duration(milliseconds: 500), 
                                                      curve: Curves.easeInOut
                                                    );
                                                  },
                                                ),
                                              )
                                            : null,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                //  LINE CHART AREA
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // ---------------- FIXED Y-AXIS ----------------
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 32), 
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [100, 80, 60, 40, 20, 0].map((e) {
                                            return Text(
                                              e.toString(),
                                              style: const TextStyle(
                                                fontFamily: 'K2D',
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                      
                                      const SizedBox(width: 10),

                                      // ---------------- CHART CONTENT ----------------
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 6.0),
                                          child: Builder(builder: (context) {
                                            
                                            // ---- DAILY MODE ----
                                            if (showDaily) {
                                              return LineChart(
                                                LineChartData(
                                                  minY: 0, maxY: 100,
                                                  gridData: FlGridData(show: false),
                                                  borderData: FlBorderData(show: false),
                                                  titlesData: FlTitlesData(
                                                    show: true,
                                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                                    bottomTitles: AxisTitles(
                                                      sideTitles: SideTitles(
                                                        showTitles: true,
                                                        interval: 1,
                                                        reservedSize: 26,
                                                        getTitlesWidget: (value, meta) {
                                                          int i = value.toInt();
                                                          if (i < 0 || i >= dailyKeys.length) return const SizedBox.shrink();
                                                          bool isToday = (i == todayIndex);
                                                          return Padding(
                                                            padding: const EdgeInsets.only(top: 6),
                                                            child: Text(
                                                              dailyKeys[i],
                                                              style: TextStyle(
                                                                fontFamily: 'K2D',
                                                                fontSize: 11,
                                                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                                                color: isToday ? BColors.textprimary : Colors.grey,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                  lineTouchData: LineTouchData(enabled: true),
                                                  lineBarsData: [
                                                    LineChartBarData(
                                                      spots: List.generate(
                                                        dailyKeys.length,
                                                        (i) => FlSpot(i.toDouble(), i < weeklyScores.length ? weeklyScores[i] : 0.0),
                                                      ),
                                                      isCurved: true,
                                                      barWidth: 3,
                                                      color: BColors.primary,
                                                      dotData: FlDotData(show: true),
                                                      belowBarData: BarAreaData(
                                                        show: true,
                                                        gradient: LinearGradient(
                                                          begin: Alignment.topCenter,
                                                          end: Alignment.bottomCenter,
                                                          colors: [
                                                            BColors.primary.withOpacity(0.4),
                                                            BColors.primary.withOpacity(0.05),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }

                                            // ---- WEEKLY MODE: Continuous Series ----

                                            if (weeklyData.isEmpty || weeklyData.every((v) => v == 0.0)) {
                                              return const Center(
                                                child: Text("No weekly data yet", style: TextStyle(fontFamily: 'K2D', fontSize: 12, color: Colors.grey)),
                                              );
                                            }

                                            return SingleChildScrollView(
                                              controller: _weeklyScrollController,
                                              scrollDirection: Axis.horizontal,
                                              padding: const EdgeInsets.only(left: 10, right: 40),
                                              child: SizedBox(
                                                width: chartWidth,
                                                child: LineChart(
                                                  LineChartData(
                                                    minY: 0, maxY: 100,
                                                    minX: 0, maxX: (weeklyData.length - 1).toDouble(),
                                                    gridData: FlGridData(show: false),
                                                    borderData: FlBorderData(show: false),
                                                    titlesData: FlTitlesData(
                                                      show: true,
                                                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                                      bottomTitles: AxisTitles(
                                                        sideTitles: SideTitles(
                                                          showTitles: true,
                                                          interval: 1,
                                                          reservedSize: 36, // Space for 2 lines text
                                                          getTitlesWidget: (value, meta) {
                                                            int i = value.toInt();
                                                            if (i < 0 || i >= weeklyLabels.length) {
                                                              return const SizedBox.shrink();
                                                            }
                                                            
                                                            String label = weeklyLabels[i];
                                                            bool isCurrentWeek = label == 'This week';

                                                            if (isCurrentWeek) {
                                                              return Padding(
                                                                padding: const EdgeInsets.only(top: 10),
                                                                child: Text(
                                                                  "This\nweek",
                                                                  textAlign: TextAlign.center,
                                                                  style: TextStyle(
                                                                    fontFamily: 'K2D',
                                                                    fontSize: 10,
                                                                    height: 1.1, 
                                                                    fontWeight: FontWeight.bold,
                                                                    color: BColors.textprimary,
                                                                  ),
                                                                ),
                                                              );
                                                            }

                                                            return Padding(
                                                              padding: const EdgeInsets.only(top: 10), 
                                                              child: Text(
                                                                label,
                                                                style: const TextStyle(
                                                                  fontFamily: 'K2D',
                                                                  fontSize: 11,
                                                                  color: Colors.grey,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                    lineTouchData: LineTouchData(enabled: true),
                                                    lineBarsData: [
                                                      LineChartBarData(
                                                        spots: List.generate(
                                                          weeklyData.length,
                                                          (i) => FlSpot(i.toDouble(), weeklyData[i]),
                                                        ),
                                                        isCurved: true,
                                                        barWidth: 3,
                                                        color: BColors.primary,
                                                        dotData: FlDotData(show: true),
                                                        belowBarData: BarAreaData(
                                                          show: true,
                                                          gradient: LinearGradient(
                                                            begin: Alignment.topCenter,
                                                            end: Alignment.bottomCenter,
                                                            colors: [
                                                              BColors.primary.withOpacity(0.4),
                                                              BColors.primary.withOpacity(0.05),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),

                      const SizedBox(height: 20),
                      // ---------------- TASK (LEFT) + FOCUS ROOM + MOOD (RIGHT) ----------------
                      // ---------------- TASK (LEFT) + FOCUS ROOM + MOOD (RIGHT) ----------------
                      SizedBox(
                        height: 230,
                        child: Row(
                          children: [
                            // ======================================================
                            // LEFT SIDE — TASK BOX
                            // ======================================================
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(BSizes.md),
                                decoration: BoxDecoration(
                                  color: BColors.white,
                                  borderRadius: BorderRadius.circular(
                                    BSizes.cardRadiusLg,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.07),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Task",
                                      style: textTheme.titleMedium?.copyWith(
                                        fontFamily: 'K2D',
                                        fontWeight: FontWeight.w700,
                                        color: BColors.textprimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    Expanded(
                                      child: Obx(() {
                                        final total =
                                            dashController.totalTasks.value;
                                        final completed =
                                            dashController.checkedTasks.value;
                                        final incomplete = (total - completed)
                                            .clamp(0, total);

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Center(
                                                child: total == 0
                                                    ? const Text(
                                                        "No tasks yet",
                                                        style: TextStyle(
                                                          fontFamily: 'K2D',
                                                          fontSize: 12,
                                                          color: Colors.grey,
                                                        ),
                                                      )
                                                    : PieChart(
                                                        PieChartData(
                                                          startDegreeOffset:
                                                              -90,
                                                          centerSpaceRadius: 25,
                                                          sectionsSpace: 2,
                                                          sections: [
                                                            PieChartSectionData(
                                                              value: completed
                                                                  .toDouble(),
                                                              title: completed
                                                                  .toString(),
                                                              color: BColors
                                                                  .primary,
                                                              radius: 24,
                                                              titleStyle:
                                                                  const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                            PieChartSectionData(
                                                              value: incomplete
                                                                  .toDouble(),
                                                              title: incomplete
                                                                  .toString(),
                                                              color: BColors
                                                                  .secondry,
                                                              radius: 20,
                                                              titleStyle:
                                                                  const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Container(
                                                  width: 10,
                                                  height: 10,
                                                  color: BColors.primary,
                                                ),
                                                const SizedBox(width: 6),
                                                const Text(
                                                  "Completed",
                                                  style: TextStyle(
                                                    fontFamily: 'K2D',
                                                    fontSize: 10,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  width: 10,
                                                  height: 10,
                                                  color: BColors.secondry,
                                                ),
                                                const SizedBox(width: 6),
                                                const Text(
                                                  "Incomplete",
                                                  style: TextStyle(
                                                    fontFamily: 'K2D',
                                                    fontSize: 10,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 14),

                            // ======================================================
                            // RIGHT SIDE — FOCUS ROOM + MOOD
                            // ======================================================
                            Expanded(
                              child: Column(
                                children: [
                                  // ----------------- FOCUS ROOM (TOP) -----------------
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(BSizes.md),
                                      decoration: BoxDecoration(
                                        color: BColors.white,
                                        borderRadius: BorderRadius.circular(
                                          BSizes.cardRadiusLg,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.07),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Focus Room",
                                            style:
                                                textTheme.titleMedium?.copyWith(
                                              fontFamily: 'K2D',
                                              fontWeight: FontWeight.w700,
                                              color: BColors.textprimary,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Expanded(
                                            child: Obx(() {
                                              final minutes = dashController
                                                  .todayFocusMinutes.value;
                                              return Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      "$minutes min",
                                                      style: textTheme
                                                          .headlineSmall
                                                          ?.copyWith(
                                                        fontFamily: 'K2D',
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: BColors.primary
                                                            .withOpacity(0.7),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      minutes == 0
                                                          ? "No focus session today"
                                                          : "Today's total focus time",
                                                      style: const TextStyle(
                                                        fontFamily: 'K2D',
                                                        fontSize: 11,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // ----------------- MOOD (BOTTOM) -----------------
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(BSizes.md),
                                      decoration: BoxDecoration(
                                        color: BColors.white,
                                        borderRadius: BorderRadius.circular(
                                          BSizes.cardRadiusLg,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.07),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Obx(() {
                                        final int? mood =
                                            dashController.dailyMood.value;

                                        if (mood == null) {
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Mood",
                                                style: textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontFamily: 'K2D',
                                                  fontWeight: FontWeight.w700,
                                                  color: BColors.textprimary,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              const Expanded(
                                                child: Center(
                                                  child: Text(
                                                    "No mood yet",
                                                    style: TextStyle(
                                                      fontFamily: 'K2D',
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }

                                        IconData icon;
                                        Color color;
                                        String label;

                                        switch (mood) {
                                          case 1:
                                            icon = Icons
                                                .sentiment_very_dissatisfied;
                                            color = const Color(0xFFE57373);
                                            label = "Very sad";
                                            break;
                                          case 2:
                                            icon = Icons.sentiment_dissatisfied;
                                            color = const Color(0xFFFFB74D);
                                            label = "Sad";
                                            break;
                                          case 3:
                                            icon = Icons.sentiment_neutral;
                                            color = const Color.fromARGB(
                                                255, 246, 236, 145);
                                            label = "Neutral";
                                            break;
                                          case 4:
                                            icon = Icons.sentiment_satisfied;
                                            color = const Color(0xFF81C784);
                                            label = "Happy";
                                            break;
                                          case 5:
                                          default:
                                            icon =
                                                Icons.sentiment_very_satisfied;
                                            color = const Color(0xFF4CAF50);
                                            label = "Very happy";
                                            break;
                                        }

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Mood",
                                              style: textTheme.titleMedium
                                                  ?.copyWith(
                                                fontFamily: 'K2D',
                                                fontWeight: FontWeight.w700,
                                                color: BColors.textprimary,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Expanded(
                                              child: Center(
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 7,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: color
                                                        .withOpacity(0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            24),
                                                    border: Border.all(
                                                      color: color
                                                          .withOpacity(0.8),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        icon,
                                                        color: color,
                                                        size: 28,
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Text(
                                                        label,
                                                        style: TextStyle(
                                                          fontFamily: 'K2D',
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: color,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ---------------- ACTIVITIES BAR CHART ----------------
                      Obx(() {
                        final Map<String, double> currentData =
                            dashController.activityCounts;

                        final entries = currentData.entries
                            .where((e) => e.value > 0)
                            .toList();

                        final List<BarChartGroupData> barGroups = List.generate(
                          entries.length,
                          (i) {
                            final key = entries[i].key;
                            final value = entries[i].value;
                            final style = CategoryStyles.byKey(key);

                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: value,
                                  width: 22,
                                  color: style.iconColor.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(0),
                                ),
                              ],
                            );
                          },
                        );

                        return Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(BSizes.md),
                          decoration: BoxDecoration(
                            color: BColors.white,
                            borderRadius: BorderRadius.circular(
                              BSizes.cardRadiusLg,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.07),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Activities",
                                style: textTheme.titleMedium?.copyWith(
                                  fontFamily: 'K2D',
                                  fontWeight: FontWeight.w700,
                                  color: BColors.textprimary,
                                ),
                              ),
                              const SizedBox(height: 16),

                              if (entries.isEmpty)
                                const SizedBox(
                                  height: 100,
                                  child: Center(
                                    child: Text(
                                      "No activities Completed",
                                      style: TextStyle(
                                        fontFamily: 'K2D',
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                SizedBox(
                                  height: 260,
                                  child: BarChart(
                                    BarChartData(
                                      barTouchData: BarTouchData(
                                        enabled: true,
                                        touchTooltipData: BarTouchTooltipData(
                                          getTooltipItem:
                                              (
                                                group,
                                                groupIndex,
                                                rod,
                                                rodIndex,
                                              ) {
                                                final entry =
                                                    entries[group.x.toInt()];
                                                final key = entry.key;
                                                final value = entry.value;
                                                return BarTooltipItem(
                                                  '$key\n${value.toInt()} activities',
                                                  const TextStyle(
                                                    fontFamily: 'K2D',
                                                    fontSize: 12,
                                                    color: Colors.white,
                                                  ),
                                                );
                                              },
                                        ),
                                        touchCallback:
                                            (
                                              FlTouchEvent event,
                                              barTouchResponse,
                                            ) {
                                              setState(() {
                                                if (!event
                                                        .isInterestedForInteractions ||
                                                    barTouchResponse == null ||
                                                    barTouchResponse.spot ==
                                                        null) {
                                                  _selectedCategory = null;
                                                  _selectedCount = null;
                                                  return;
                                                }
                                                final index = barTouchResponse
                                                    .spot!
                                                    .touchedBarGroupIndex;
                                                if (index >= 0 &&
                                                    index < entries.length) {
                                                  _selectedCategory =
                                                      entries[index].key;
                                                  _selectedCount =
                                                      entries[index].value;
                                                }
                                              });
                                            },
                                      ),
                                      alignment: BarChartAlignment.spaceAround,
                                      borderData: FlBorderData(show: false),
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: false,
                                        getDrawingHorizontalLine: (value) =>
                                            FlLine(
                                              color: BColors.borderPrimary
                                                  .withOpacity(0.25),
                                              strokeWidth: 1.5,
                                            ),
                                      ),
                                      titlesData: FlTitlesData(
                                        rightTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        topTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            interval: 1,
                                            reservedSize: 32,
                                            getTitlesWidget: (value, meta) {
                                              if (value % 1 != 0) {
                                                return const SizedBox.shrink();
                                              }
                                              return Text(
                                                value.toInt().toString(),
                                                style: const TextStyle(
                                                  fontFamily: 'K2D',
                                                  fontSize: 11,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 28,
                                            getTitlesWidget: (value, meta) {
                                              int i = value.toInt();
                                              if (i < 0 ||
                                                  i >= entries.length) {
                                                return const SizedBox.shrink();
                                              }
                                              final key = entries[i].key;
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 3,
                                                ),
                                                child: Transform.rotate(
                                                  angle: -0.2,
                                                  child: Text(
                                                    key.isNotEmpty
                                                        ? "${key[0].toUpperCase()}${key.substring(1).toLowerCase()}"
                                                        : key,
                                                    style: const TextStyle(
                                                      fontFamily: 'K2D',
                                                      fontSize: 9,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      barGroups: barGroups,
                                    ),
                                  ),
                                ),

                              if (_selectedCategory != null &&
                                  _selectedCount != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '${_selectedCategory![0].toUpperCase()}${_selectedCategory!.substring(1)}: ${_selectedCount!.toInt()} activities',
                                    style: const TextStyle(
                                      fontFamily: 'K2D',
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}