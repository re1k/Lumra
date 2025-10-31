import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';
import 'package:lumra_project/theme/custom_themes/appbar_theme.dart';

class NumberPuzzle extends StatefulWidget {
  const NumberPuzzle({super.key});

  @override
  State<NumberPuzzle> createState() => _NumberPuzzleState();
}

class _NumberPuzzleState extends State<NumberPuzzle> {
  int _gridSize = 4;
  List<String> _iteams = [];
  String _selectedDifficulty = 'Medium';

  void _generateItems() {
    int total = _gridSize * _gridSize;
    _iteams = List.generate(
      total,
      (index) => index == 0 ? '' : index.toString(),
    );
    _iteams.shuffle();
    setState(() {});
  }

  bool _isPuzzleComplete() {
    for (int i = 0; i < _iteams.length - 1; i++) {
      if (_iteams[i] != (i + 1).toString()) {
        return false;
      }
    }
    return _iteams.last == '';
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

    if (_isPuzzleComplete()) {
      _showPuzzleCompleteAlert();
    }
  }

  void _showPuzzleCompleteAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Congratulations! ",
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontFamily: 'K2D',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: BColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "You completed the puzzle!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: BSizes.fontSizeMd,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _generateItems();
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    }

    return BColors.primary;
  }

  void _setDifficulty(String difficulty, int size) {
    setState(() {
      _selectedDifficulty = difficulty;
      _gridSize = size;
      _generateItems();
    });
  }

  Widget _difficultyButton(String label, int size) {
    final bool isSelected = _selectedDifficulty == label;

    return ElevatedButton(
      onPressed: () => _setDifficulty(label, size),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? BColors.secondry : BColors.primary,
        foregroundColor: Colors.white,
        elevation: isSelected ? 0 : 6,
        shadowColor: Colors.black.withOpacity(0.25),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide.none,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isSelected ? BColors.primary : Colors.white,
        ),
      ),
    );
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

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BSizes.defaultSpace,
            ),
            child: Container(
              padding: const EdgeInsets.all(BSizes.md),
              decoration: BoxDecoration(
                color: BColors.lightGrey,
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
              child: const Text(
                "Click the numbered tiles to rearrange them in the correct order, leaving the empty space at the end. \n"
                "Select a difficulty level to begin your puzzle challenge!",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _difficultyButton('Easy', 3),
              const SizedBox(width: 20),
              _difficultyButton('Medium', 4),
              const SizedBox(width: 20),
              _difficultyButton('Hard', 5),
            ],
          ),

          const SizedBox(height: 10),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
        ],
      ),
    );
  }
}
