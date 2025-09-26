import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:lumra_project/controller/Registration/caregiver_controller.dart';
import 'package:lumra_project/view/adhd_registration/widgets/segmented_progress_bar.dart';
import 'package:lumra_project/view/caregiver_registration/inbox_screen.dart';
import 'package:lumra_project/view/caregiver_registration/permission_screen.dart';

class CaregiverCameraScanScreen extends StatefulWidget {
  const CaregiverCameraScanScreen({super.key});

  @override
  State<CaregiverCameraScanScreen> createState() =>
      _CaregiverCameraScanScreenState();
}

class _CaregiverCameraScanScreenState extends State<CaregiverCameraScanScreen> {
  late CaregiverController _controller;
  MobileScannerController? scannerController;

  @override
  void initState() {
    super.initState();
    _controller = CaregiverController();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final result = await _controller.initializeCamera();
    if (result['success'] == true) {
      setState(() {
        scannerController = MobileScannerController();
      });
    } else if (result['navigate'] == true) {
      // If we reach here, permission was denied - navigate back to permission screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const CaregiverPermissionScreen(),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    scannerController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    print('_onDetect called with ${capture.barcodes.length} barcodes');
    if (capture.barcodes.isNotEmpty) {
      final String? code = capture.barcodes.first.rawValue;
      print('Detected barcode: $code');
      print(
        'Controller state: isShowingErrorDialog=${_controller.isShowingErrorDialog}',
      );

      if (code != null && mounted && !_controller.isShowingErrorDialog) {
        print('Processing barcode in controller...');
        final result = await _controller.onDetectBarcode(code);
        print('Controller returned result: $result');

        if (mounted) {
          if (result['success'] == true) {
            print('Account creation successful, navigating to inbox...');
            // Account creation was successful
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const CaregiverInboxScreen(),
              ),
            );
          } else {
            print('Account creation failed, showing error dialog...');
            // Show error dialog with the stored error message
            final errorMessage = result['errorMessage'];
            print('Error message: $errorMessage');
            print('isShowingErrorDialog: ${_controller.isShowingErrorDialog}');
            if (errorMessage != null) {
              print('Showing error dialog with message: $errorMessage');
              _controller.setShowingErrorDialog(true);
              _showErrorDialog(errorMessage);
            } else {
              print('No error message to show');
            }
          }
        }
      } else {
        print(
          'Barcode detection skipped - code: $code, mounted: $mounted, isShowingErrorDialog: ${_controller.isShowingErrorDialog}',
        );
      }
    }
  }

  void _showErrorDialog(String message) {
    print('_showErrorDialog called with message: $message');
    _controller.showErrorDialog(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => _controller,
      child: Consumer<CaregiverController>(
        builder: (context, controller, child) {
          return Scaffold(
            backgroundColor: BColors.white,
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
                        SegmentedProgressBar(currentStep: 4, totalSteps: 4),
                        const SizedBox(height: 32),
                        Text(
                          'Scan QR Code',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: BColors.black,
                            fontFamily: 'K2D',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Point your camera at the QR code from your child\'s ADHD account to link the accounts',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: BColors.black,
                            fontFamily: 'K2D',
                          ),
                        ),
                        const SizedBox(height: 40),
                        // QR Scanner Camera Preview or Loading
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: BColors.primary,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child:
                                  controller.hasPermission &&
                                      scannerController != null
                                  ? Stack(
                                      children: [
                                        MobileScanner(
                                          controller: scannerController!,
                                          onDetect: _onDetect,
                                        ),
                                        // Custom scan box overlay
                                        Center(
                                          child: Container(
                                            width: 250,
                                            height: 250,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: BColors.primary,
                                                width: 3,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Stack(
                                              children: [
                                                // Corner indicators
                                                Positioned(
                                                  top: 0,
                                                  left: 0,
                                                  child: Container(
                                                    width: 30,
                                                    height: 30,
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        top: BorderSide(
                                                          color:
                                                              BColors.primary,
                                                          width: 5,
                                                        ),
                                                        left: BorderSide(
                                                          color:
                                                              BColors.primary,
                                                          width: 5,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 0,
                                                  right: 0,
                                                  child: Container(
                                                    width: 30,
                                                    height: 30,
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        top: BorderSide(
                                                          color:
                                                              BColors.primary,
                                                          width: 5,
                                                        ),
                                                        right: BorderSide(
                                                          color:
                                                              BColors.primary,
                                                          width: 5,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  bottom: 0,
                                                  left: 0,
                                                  child: Container(
                                                    width: 30,
                                                    height: 30,
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        bottom: BorderSide(
                                                          color:
                                                              BColors.primary,
                                                          width: 5,
                                                        ),
                                                        left: BorderSide(
                                                          color:
                                                              BColors.primary,
                                                          width: 5,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  bottom: 0,
                                                  right: 0,
                                                  child: Container(
                                                    width: 30,
                                                    height: 30,
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        bottom: BorderSide(
                                                          color:
                                                              BColors.primary,
                                                          width: 5,
                                                        ),
                                                        right: BorderSide(
                                                          color:
                                                              BColors.primary,
                                                          width: 5,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                // Loading indicator inside scan box
                                                if (controller.isProcessing)
                                                  const Center(
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        CircularProgressIndicator(
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                Color
                                                              >(BColors.black),
                                                          strokeWidth: 3,
                                                        ),
                                                        SizedBox(height: 16),
                                                        Text(
                                                          'Linking...',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color:
                                                                BColors.black,
                                                            fontFamily: 'K2D',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const CircularProgressIndicator(
                                            color: BColors.primary,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Loading camera...',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.normal,
                                              color: BColors.black,
                                              fontFamily: 'K2D',
                                            ).copyWith(color: BColors.darkGrey),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
