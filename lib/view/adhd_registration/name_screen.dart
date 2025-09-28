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

  void _safeNavigate(Function action) {
    FocusScope.of(context).unfocus();
    action();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => _controller,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: BColors.white,
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            backgroundColor: BColors.white,
            leading: Padding(
              padding: const EdgeInsets.only(top: 17),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: BColors.darkGrey),
                onPressed: () {
                  _safeNavigate(() {
                    Navigator.pop(context);
                  });
                },
              ),
            ),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 64,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SegmentedProgressBar(
                                currentStep: 1,
                                totalSteps: 7,
                              ),
                              const SizedBox(height: 32),
                              const Text(
                                'What\'s your name?',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: BColors.black,
                                  fontFamily: 'K2D',
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "We'd love to know your name to get started!",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: BColors.black,
                                  fontFamily: 'K2D',
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'First Name',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: BColors.black,
                                  fontFamily: 'K2D',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Stack(
                                children: [
                                  TextFormField(
                                    controller: _controller.firstNameController,
                                    focusNode: _controller.firstNameFocusNode,
                                    textInputAction: TextInputAction.next,
                                    maxLength: 12,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[A-Za-z]'),
                                      ),
                                    ],
                                    onTapOutside: (_) =>
                                        FocusScope.of(context).unfocus(),
                                    onFieldSubmitted: (_) =>
                                        FocusScope.of(context).requestFocus(
                                          _controller.lastNameFocusNode,
                                        ),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      hintText: 'Sarah',
                                      hintStyle: const TextStyle(
                                        color: BColors.darkGrey,
                                      ),
                                      errorText:
                                          _controller.firstNameFieldTouched
                                          ? _controller.firstNameError
                                          : null,
                                    ),
                                    onChanged: _controller.updateFirstName,
                                    onTap: _controller.onFirstNameFieldTouched,
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 12,
                                    child: ValueListenableBuilder<int>(
                                      valueListenable:
                                          _controller.firstNameCharacterCount,
                                      builder: (context, count, child) {
                                        return Text(
                                          '$count/12',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: BColors.darkGrey,
                                            fontFamily: 'K2D',
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Last Name',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: BColors.black,
                                  fontFamily: 'K2D',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Stack(
                                children: [
                                  TextFormField(
                                    controller: _controller.lastNameController,
                                    focusNode: _controller.lastNameFocusNode,
                                    textInputAction: TextInputAction.done,
                                    maxLength: 12,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[A-Za-z]'),
                                      ),
                                    ],
                                    onTapOutside: (_) =>
                                        FocusScope.of(context).unfocus(),
                                    onFieldSubmitted: (_) =>
                                        _controller.lastNameFocusNode.unfocus(),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      hintText: 'Aljohani',
                                      hintStyle: const TextStyle(
                                        color: BColors.darkGrey,
                                      ),
                                      errorText:
                                          _controller.lastNameFieldTouched
                                          ? _controller.lastNameError
                                          : null,
                                    ),
                                    onChanged: _controller.updateLastName,
                                    onTap: _controller.onLastNameFieldTouched,
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 12,
                                    child: ValueListenableBuilder<int>(
                                      valueListenable:
                                          _controller.lastNameCharacterCount,
                                      builder: (context, count, child) {
                                        return Text(
                                          '$count/12',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: BColors.darkGrey,
                                            fontFamily: 'K2D',
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 100,
                              ), // Add space for the button
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Consumer<NameController>(
                    builder: (context, controller, child) {
                      return NextButton(
                        enabled: controller.isNextButtonEnabled,
                        onPressed: () {
                          if (controller.isNextButtonEnabled) {
                            _safeNavigate(() {
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
                            });
                          }
                        },
                      );
                    },
                  ),
                ],
              );
            },
          ),
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
