import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';

class NumberPuzzle extends StatefulWidget {
  const NumberPuzzle({super.key});

  @override
  State<NumberPuzzle> createState() => _NumberPuzzleState();
}

class _NumberPuzzleState extends State<NumberPuzzle> {
  
 List<String> _iteams = List.generate(16, (index) => index==0? '': index.toString());
  void _changeIndex(int i) {
    final int _emptyIndex = _iteams.lastIndexOf('');
    int _previousItem = i - 1;
    int _nextItem = i + 1;
    int _previousRow = i - 4;
    int _nextRow = i + 4;

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

   @override
   void initState(){
    _iteams.shuffle();
    super.initState();

   }

  @override
  Widget build(BuildContext context) {
  

    return Scaffold(
     appBar: AppBar(
        backgroundColor: BColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
            ),
             ),
       body: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: GridView.count(
            crossAxisCount:4,
             children: [
              for (int i=0 ; i<16 ; i++)
              InkWell(
              onTap: (){
             _changeIndex(i);
              },
                child: Container(
                  margin: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: _iteams[i].isEmpty?Colors.white :  BColors.primary , borderRadius: BorderRadius.circular(10)),
                  child: Center(
                    child: Text('${_iteams[i]}' ,
                     style: const TextStyle(fontSize: 20 , fontWeight: FontWeight.bold , color: Colors.white
                    ), 
                    ),
                  ),
                )
              )
          ],

            
          ),
        ),
      ),
    );
  }
}