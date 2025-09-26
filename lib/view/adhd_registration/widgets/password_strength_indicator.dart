import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    int strength = _calculateStrength(password);
    Color strengthColor = _getStrengthColor(strength);
    String strengthText = _getStrengthText(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity, // Make it same width as TextFormField
          height: 4,
          decoration: BoxDecoration(
            color: BColors.softGrey,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (strength / 3.0).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: strengthColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          strengthText,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: BColors.darkGrey,
            fontFamily: 'K2D',
          ).copyWith(color: strengthColor),
        ),
      ],
    );
  }

  int _calculateStrength(String password) {
    if (password.isEmpty) return 0; // No strength when empty
    int rulesMet = 0;
    if (password.length >= 8) rulesMet++;
    if (password.contains(RegExp(r'[A-Z]'))) rulesMet++;
    if (password.contains(RegExp(r'[0-9]'))) rulesMet++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) rulesMet++;

    // Map to 3 states: 1=Weak, 2=Medium, 3=Strong
    if (rulesMet <= 1) return 1; // Weak: 1 rule met
    if (rulesMet == 2) return 2; // Medium: 2 rules met
    if (rulesMet == 3) return 2; // Medium: 3 rules met
    return 3; // Strong: all 4 rules met
  }

  Color _getStrengthColor(int strength) {
    switch (strength) {
      case 0:
        return BColors.softGrey; // Empty state - no password entered
      case 1:
        return Colors.red; // Weak: 1-2 rules met
      case 2:
        return Colors.orange; // Medium: 3 rules met
      case 3:
        return Colors.green; // Strong: all 4 rules met
      default:
        return BColors.softGrey;
    }
  }

  String _getStrengthText(int strength) {
    switch (strength) {
      case 0:
        return ''; // Empty state - no text
      case 1:
        return 'Weak'; // Weak: 1-2 rules
      case 2:
        return 'Medium'; // Medium: 3 rules
      case 3:
        return 'Strong'; // Strong: all 4 rules
      default:
        return '';
    }
  }
}
