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

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _controller = NameController();
    _controller.addListener(_onControllerChange);
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
                        color: BColors.black,
                        fontFamily: 'K2D',
                      ),
                    ),
                    const SizedBox(height: 24),
                    // First Name Field
                    Text(
                      'First Name',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: BColors.black,
                        fontFamily: 'K2D',
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    // First Name Field Container with Character Counter
                    Stack(
                      children: [
                        TextFormField(
                          controller: _controller.firstNameController,
                          focusNode: _controller.firstNameFocusNode,
                          textInputAction: TextInputAction.next,
                          maxLength: 16,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z ]'),
                            ),
                          ],
                          onTapOutside: (event) =>
                              FocusScope.of(context).unfocus(),
                          onFieldSubmitted: (_) => FocusScope.of(
                            context,
                          ).requestFocus(_controller.lastNameFocusNode),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'Sarah',
                            hintStyle: TextStyle(color: BColors.darkGrey),
                            errorText: _controller.firstNameFieldTouched
                                ? _controller.firstNameError
                                : null,
                          ),
                          onChanged: (value) {
                            _controller.updateFirstName(value);
                          },
                          onTap: () {
                            _controller.onFirstNameFieldTouched();
                          },
                        ),
                        // Character Counter positioned at top-right
                        Positioned(
                          top: 8,
                          right: 12,
                          child: ValueListenableBuilder<int>(
                            valueListenable:
                                _controller.firstNameCharacterCount,
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
                    const SizedBox(height: 24),
                    // Last Name Field
                    Text(
                      'Last Name',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: BColors.black,
                        fontFamily: 'K2D',
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    // Last Name Field Container with Character Counter
                    Stack(
                      children: [
                        TextFormField(
                          controller: _controller.lastNameController,
                          focusNode: _controller.lastNameFocusNode,
                          textInputAction: TextInputAction.done,
                          maxLength: 16,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z ]'),
                            ),
                          ],
                          onTapOutside: (event) =>
                              FocusScope.of(context).unfocus(),
                          onFieldSubmitted: (_) =>
                              _controller.lastNameFocusNode.unfocus(),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'Aljohani',
                            hintStyle: TextStyle(color: BColors.darkGrey),
                            errorText: _controller.lastNameFieldTouched
                                ? _controller.lastNameError
                                : null,
                          ),
                          onChanged: (value) {
                            _controller.updateLastName(value);
                          },
                          onTap: () {
                            _controller.onLastNameFieldTouched();
                          },
                        ),
                        // Character Counter positioned at top-right
                        Positioned(
                          top: 8,
                          right: 12,
                          child: ValueListenableBuilder<int>(
                            valueListenable: _controller.lastNameCharacterCount,
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
                      // Save first and last name to GetX Controller
                      _flowController.updateFromNameScreen(
                        controller.firstNameController.text,
                        controller.lastNameController.text,
                      );
                      controller.saveFirstName();
                      controller.saveLastName();
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
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    super.dispose();
  }
}
// fix conflicts!!!