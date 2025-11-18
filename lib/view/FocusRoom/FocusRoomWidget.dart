import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BreaksWheel extends StatefulWidget {
  const BreaksWheel({
    super.key,
    required this.options, //  [0,1,2,3,4]
    required this.initialValue, // 3 (can be null -> first option but we have to find another way of 0 "NO BREAK")
    required this.onChanged,
    this.height = 220,
    this.itemExtent = 48.0,
    this.pillRadius = 28.0,
  });

  final List<int> options;
  final int? initialValue;
  final ValueChanged<int> onChanged;
  final double height;
  final double itemExtent;
  final double pillRadius;

  @override
  State<BreaksWheel> createState() => _BreaksWheelState();
}

class _BreaksWheelState extends State<BreaksWheel> {
  late FixedExtentScrollController _scroll;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = _indexForValue(widget.initialValue);
    _scroll = FixedExtentScrollController(initialItem: _currentIndex);
  }

  @override
  void didUpdateWidget(covariant BreaksWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If options changed (duration changed), keep selection sane
    final wanted = _indexForValue(widget.initialValue);
    if (wanted != _currentIndex) {
      _currentIndex = wanted;
      _scroll.jumpToItem(_currentIndex);
    }
  }

  int _indexForValue(int? value) {
    if (widget.options.isEmpty) return 0;
    if (value == null) return 0;
    final idx = widget.options.indexOf(value);
    return idx >= 0 ? idx : 0;
  }

  void _animateTo(int index) {
    if (index < 0 || index >= widget.options.length) return;
    _scroll.animateToItem(
      index,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.options.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'No valid breaks for this duration',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    final pillHeight = widget.itemExtent * 1.1;

    return SizedBox(
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: Container(
              height: pillHeight,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.08),
                borderRadius: BorderRadius.circular(widget.pillRadius),
              ),
            ),
          ),

          // Wheel
          NotificationListener<ScrollNotification>(
            onNotification: (_) => false,
            child: ListWheelScrollView.useDelegate(
              controller: _scroll,
              itemExtent: widget.itemExtent,
              physics: const FixedExtentScrollPhysics(),
              diameterRatio: 2.0, // flatter wheel feel
              perspective: 0.002,
              squeeze: 1.0,
              onSelectedItemChanged: (index) {
                HapticFeedback.selectionClick();
                setState(() => _currentIndex = index);
                widget.onChanged(widget.options[index]);
              },
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (context, index) {
                  if (index < 0 || index >= widget.options.length) return null;
                  final value = widget.options[index];
                  final selected = index == _currentIndex;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _animateTo(index), // tap to center
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 120),
                        style: TextStyle(
                          fontFamily: 'K2D',
                          fontSize: selected ? 28 : 22,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: Colors.black.withOpacity(
                            selected ? 0.85 : 0.45,
                          ),
                        ),
                        child: Text('$value'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
