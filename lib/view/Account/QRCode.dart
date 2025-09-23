import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../theme/custom_themes/appbar_theme.dart';
import '../../theme/base_themes/colors.dart';
import 'package:lumra_project/view/navbar_widget.dart';

class Qrcode extends StatelessWidget {
  const Qrcode({super.key});

  @override
  Widget build(BuildContext context) {
    final String userUid = FirebaseAuth.instance.currentUser?.uid ?? "no-user";

    return Scaffold(
      backgroundColor: BColors.light,
      appBar: AppBar(
        title: const Text("QR Code"),
        backgroundColor: BAppBarTheme.lightAppBarTheme.backgroundColor,
        elevation: BAppBarTheme.lightAppBarTheme.elevation,
        iconTheme: BAppBarTheme.lightAppBarTheme.iconTheme,
        titleTextStyle: BAppBarTheme.lightAppBarTheme.titleTextStyle,
        centerTitle: true,
      ),
      body: Center(
        child: Transform.translate(
          offset: const Offset(0, -40),
          child: Container(
            padding: const EdgeInsets.all(60),
            decoration: BoxDecoration(
              color: BColors.buttonPrimary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(
                  data: userUid,
                  version: QrVersions.auto,
                  size: 230.0,
                  gapless: true,
                  foregroundColor: Colors.white,
                  embeddedImage: AssetImage('assets/images/logo.png'),
                  embeddedImageStyle: QrEmbeddedImageStyle(size: Size(60, 60)),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const NavbarAdhd(),
    );
  }
}
