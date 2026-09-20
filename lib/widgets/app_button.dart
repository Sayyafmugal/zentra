import 'package:flutter/material.dart';

enum AppButtonVariant { primary, outlined, text }

/// One button component for the whole app instead of every screen
/// hand-rolling its own ElevatedButton/OutlinedButton with a bespoke
/// loading-spinner swap.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final disabled = isLoading || onPressed == null;
    final child = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: variant == AppButtonVariant.primary
                  ? Colors.white
                  : Theme.of(context).colorScheme.primary,
            ),
          )
        : icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(label)],
          )
        : Text(label);

    final Widget button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
        onPressed: disabled ? null : onPressed,
        child: child,
      ),
      AppButtonVariant.outlined => OutlinedButton(
        onPressed: disabled ? null : onPressed,
        child: child,
      ),
      AppButtonVariant.text => TextButton(onPressed: disabled ? null : onPressed, child: child),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
