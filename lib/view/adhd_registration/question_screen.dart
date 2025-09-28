import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/controller/Registration/question_controller.dart';
import 'package:lumra_project/controller/Registration/registration_flow_controller.dart';
import 'package:lumra_project/view/adhd_registration/widgets/segmented_progress_bar.dart';
import 'package:lumra_project/view/adhd_registration/widgets/next_button.dart';
import 'package:lumra_project/view/adhd_registration/registration_screen.dart';

class QuestionScreen extends StatefulWidget {
  final int questionIndex;

  const QuestionScreen({super.key, required this.questionIndex});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  late QuestionController _controller;
  final RegistrationFlowController _flowController =
      Get.find<RegistrationFlowController>();

  @override
  void initState() {
    super.initState();
    _controller = QuestionController();
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _controller.questionList[widget.questionIndex];
    final currentStep = 2 + widget.questionIndex;

    return ChangeNotifierProvider(
      create: (context) => _controller,
      child: Consumer<QuestionController>(
        builder: (context, controller, child) {
          final selectedAnswer = controller.getAnswerIndex(
            widget.questionIndex,
          );

          return Scaffold(
            backgroundColor: BColors.white,
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              backgroundColor: BColors.white,
              leading: Padding(
                padding: const EdgeInsets.only(top: 17),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: BColors.darkGrey),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            body: Stack(
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Progress Bar
                        SegmentedProgressBar(
                          currentStep: currentStep,
                          totalSteps: 7,
                        ),
                        const SizedBox(height: 32),
                        // Title for first question only
                        if (widget.questionIndex == 0) ...[
                          Text(
                            'Tell us about yourself!',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: BColors.black,
                              fontFamily: 'K2D',
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        // Question
                        Text(
                          currentQuestion['question'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: BColors.black,
                            fontFamily: 'K2D',
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Answer Options
                        ...currentQuestion['answers'].asMap().entries.map((
                          entry,
                        ) {
                          final index = entry.key;
                          final answer = entry.value;
                          final isSelected = selectedAnswer == index;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () {
                                controller.saveAnswer(
                                  widget.questionIndex,
                                  index,
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? BColors.primary.withValues(alpha: 0.1)
                                      : BColors.softGrey,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? BColors.primary
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: BColors.darkGrey.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? BColors.primary
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected
                                              ? BColors.primary
                                              : BColors.darkGrey,
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 12,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        answer,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                          color: BColors.black,
                                          fontFamily: 'K2D',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
                NextButton(
                  enabled: selectedAnswer != null,
                  text:
                      widget.questionIndex ==
                          _controller.questionList.length - 1
                      ? 'Next'
                      : 'Next',
                  onPressed: () {
                    if (selectedAnswer != null) {
                      // Calculate and update points for current question
                      final currentQuestionPoints = _controller
                          .getQuestionPoints(widget.questionIndex);
                      if (currentQuestionPoints != null) {
                        // Replace points for this question instead of accumulating
                        _flowController.setQuestionPoints(
                          widget.questionIndex,
                          currentQuestionPoints,
                        );
                      }

                      if (widget.questionIndex ==
                          _controller.questionList.length - 1) {
                        // Final question - navigate to registration screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegistrationScreen(),
                          ),
                        );
                      } else {
                        // Not the last question - go to next question
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuestionScreen(
                              questionIndex: widget.questionIndex + 1,
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
