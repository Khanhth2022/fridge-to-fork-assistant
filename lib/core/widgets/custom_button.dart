import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum CustomButtonType { primary, secondary, danger }

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.type = CustomButtonType.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final CustomButtonType type;

  @override
  Widget build(BuildContext context) {
    final style = _buildStyle();
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: style,
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon ?? Icons.check),
        label: Text(label),
      ),
    );
  }

  ButtonStyle _buildStyle() {
    Color bg;
    Color fg;
    switch (type) {
      case CustomButtonType.secondary:
        bg = AppColors.secondary;
        fg = Colors.white;
        break;
      case CustomButtonType.danger:
        bg = AppColors.error;
        fg = Colors.white;
        break;
      case CustomButtonType.primary:
        bg = AppColors.primary;
        fg = Colors.white;
    }

    return ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      minimumSize: const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }
}
