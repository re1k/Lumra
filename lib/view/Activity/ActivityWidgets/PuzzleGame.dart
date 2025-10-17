import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/theme/custom_themes/appbar_theme.dart';

// i added this comment to fix the conflicts
class NumberPuzzle extends StatefulWidget {
  const NumberPuzzle({super.key});

  @override
  State<NumberPuzzle> createState() => _NumberPuzzleState();
}

class _NumberPuzzleState extends State<NumberPuzzle> {
  int _gridSize = 4;
  List<String> _iteams = [];

  void _generateItems() {
    int total = _gridSize * _gridSize;
    _iteams = List.generate(
      total,
      (index) => index == 0 ? '' : index.toString(),
    );
    _iteams.shuffle();
    setState(() {});
  }

  void _changeIndex(int i) {
    final int _emptyIndex = _iteams.lastIndexOf('');
    int _previousItem = i - 1;
    int _nextItem = i + 1;
    int _previousRow = i - _gridSize;
    int _nextRow = i + _gridSize;

    if (_emptyIndex == _previousItem) {
      _iteams[_previousItem] = _iteams[i];
      _iteams[i] = '';
    } else if (_emptyIndex == _nextItem) {
      _iteams[_nextItem] = _iteams[i];
      _iteams[i] = '';
    } else if (_emptyIndex == _previousRow) {
      _iteams[_previousRow] = _iteams[i];
      _iteams[i] = '';
    } else if (_emptyIndex == _nextRow) {
      _iteams[_nextRow] = _iteams[i];
      _iteams[i] = '';
    }

    setState(() {});
  }

  Color _getNumberHintColor(String value) {
    if (value.isEmpty) return Colors.white;

    int num = int.parse(value);

    if (_gridSize == 3) {
      if (num >= 1 && num <= 3)
        return const Color(0xFFCDF0F9).withOpacity(0.32);
      if (num >= 4 && num <= 6)
        return const Color(0xFFE9B8A9).withOpacity(0.32);
      if (num >= 7 && num <= 9)
        return Color.fromARGB(255, 87, 185, 218).withOpacity(0.32);
    } else if (_gridSize == 4) {
      if (num >= 1 && num <= 4)
        return const Color(0xFFCDF0F9).withOpacity(0.32);
      if (num >= 5 && num <= 8)
        return const Color(0xFFE9B8A9).withOpacity(0.32);
      if (num >= 9 && num <= 12)
        return Color.fromARGB(255, 87, 185, 218).withOpacity(0.32);
      if (num >= 13 && num <= 16) return Color.fromARGB(255, 222, 187, 136);
    } else if (_gridSize == 5) {
      if (num >= 1 && num <= 5)
        return const Color(0xFFCDF0F9).withOpacity(0.32);
      if (num >= 6 && num <= 10)
        return const Color(0xFFE9B8A9).withOpacity(0.32);
      if (num >= 11 && num <= 15)
        return Color.fromARGB(255, 87, 185, 218).withOpacity(0.32);
      if (num >= 16 && num <= 20) return Color.fromARGB(255, 222, 187, 136);
      if (num >= 21 && num <= 25) return Color.fromARGB(255, 78, 134, 173);
      ;
    }

    return BColors.primary;
  }

  @override
  void initState() {
    super.initState();
    _generateItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BColors.lightGrey,
      body: Column(
        children: [
          BAppBarTheme.createHeader(
            context: context,
            title: 'Number Puzzle',
            showBackButton: true,
            onBackPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BSizes.defaultSpace,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(
                      BSizes.md,
                    ), // مسافة داخل الصندوق
                    decoration: BoxDecoration(
                      color: BColors.lightGrey, // خلفية فاتحة مثل البوكسات
                      borderRadius: BorderRadius.circular(
                        BSizes.cardRadiusLg,
                      ), // حواف دائرية
                      border: Border.all(
                        color: BColors.borderSecondary,
                      ), // حدود مشابهة للبوكسات
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x11000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      "Your game is to arrange the numbers in order from 1 to the empty square.\n"
                      "Choose the level that suits you to start the challenge!",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _gridSize = 3;
                        _generateItems();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),

                      child: const Text("Easy"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        _gridSize = 4;
                        _generateItems();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text("Medium"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        _gridSize = 5;
                        _generateItems();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text("Hard"),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: GridView.count(
                        crossAxisCount: _gridSize,
                        children: [
                          for (int i = 0; i < _iteams.length; i++)
                            InkWell(
                              onTap: () => _changeIndex(i),
                              child: Container(
                                margin: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _getNumberHintColor(_iteams[i]),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '${_iteams[i]}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 8, 8, 8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
