import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/controller/Registration/name_controller.dart';
import 'package:lumra_project/controller/Registration/registration_flow_controller.dart';
import 'package:lumra_project/view/adhd_registration/widgets/segmented_progress_bar.dart';
import 'package:lumra_project/view/adhd_registration/widgets/next_button.dart';
import 'package:lumra_project/view/adhd_registration/question_screen.dart';

class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  late NameController _controller;
  final RegistrationFlowController _flowController =
      Get.find<RegistrationFlowController>();

  @override
  void initState() {
    super.initState();
    _controller = NameController();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => _controller,
      child: Scaffold(
        backgroundColor: BColors.white,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: BColors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: BColors.darkGrey),
            onPressed: () => Navigator.pop(context),
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
                      currentStep: 1,
                      totalSteps: 7,
                    ), // Name screen progress
                    const SizedBox(height: 32),
                    Text(
                      'What\'s your name?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: BColors.black,
                        fontFamily: 'K2D',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We\’d love to know your name to get started!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: BColors.black,
                        fontFamily: 'K2D',
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Name Field
                    Text(
                      'Name',
                      style:
                          const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: BColors.black,
                            fontFamily: 'K2D',
                          ).copyWith(
                            fontWeight: FontWeight.w500,
                            color: BColors.darkGrey,
                          ),
                    ),
                    const SizedBox(height: 8),
                    // Name Field Container with Character Counter
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: BColors.darkGrey.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _controller.nameController,
                            maxLength: 16,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z ]'),
                              ),
                            ],
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: BColors.softGrey,
                              hintText: 'Enter your name',
                              hintStyle: TextStyle(color: BColors.darkGrey),
                              counterText: '', // Hide the default counter
                              errorText: _controller.nameFieldTouched
                                  ? _controller.nameError
                                  : null,
                              errorStyle: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color:
                                      _controller.nameFieldTouched &&
                                          _controller.nameError != null
                                      ? BColors.error
                                      : Colors.grey,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color:
                                      _controller.nameFieldTouched &&
                                          _controller.nameError != null
                                      ? BColors.error
                                      : Colors.grey,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color:
                                      _controller.nameFieldTouched &&
                                          _controller.nameError != null
                                      ? BColors.error
                                      : Colors.grey,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: BColors.error,
                                  width: 1,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: BColors.error,
                                  width: 2,
                                ),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: BColors.black,
                              fontFamily: 'K2D',
                            ),
                          ),
                        ),
                        // Character Counter positioned at top-right
                        Positioned(
                          top: 8,
                          right: 12,
                          child: ValueListenableBuilder<int>(
                            valueListenable: _controller.characterCount,
                            builder: (context, count, child) {
                              return Text(
                                '$count/16',
                                style:
                                    const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.normal,
                                      color: BColors.darkGrey,
                                      fontFamily: 'K2D',
                                    ).copyWith(
                                      fontSize: 12,
                                      color: BColors.darkGrey,
                                    ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            Consumer<NameController>(
              builder: (context, controller, child) {
                return NextButton(
                  enabled: controller.isNextButtonEnabled,
                  onPressed: () {
                    if (controller.isNextButtonEnabled) {
                      // Save name to GetX Controller
                      _flowController.updateFromNameScreen(
                        controller.nameController.text,
                      );
                      controller.saveName();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const QuestionScreen(questionIndex: 0),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
