import 'package:flutter/material.dart';

/// Mobile-first breakpoints. Most layouts use [isMobile] (< 900px).
class AppBreakpoints {
  static const double mobile = 900;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  static EdgeInsets pagePadding(BuildContext context) =>
      EdgeInsets.all(isMobile(context) ? 16 : 24);

  static int gridColumns(BuildContext context, {int mobile = 2, int desktop = 4}) =>
      isMobile(context) ? mobile : desktop;
}

/// Scales menu / POS image sizes from screen width.
class AppImageSizes {
  static double _scale(BuildContext context, {
    required double min,
    required double max,
    double fraction = 0.12,
  }) {
    final w = MediaQuery.sizeOf(context).width;
    return (w * fraction).clamp(min, max);
  }

  /// Product tile thumbnail (POS grid, list rows).
  static double productThumb(BuildContext context) =>
      _scale(context, min: 40, max: 64, fraction: 0.11);

  /// Cart line item thumbnail.
  static double cartThumb(BuildContext context) =>
      (productThumb(context) * 0.78).clamp(32, 52);

  /// Admin menu list leading image.
  static double listThumb(BuildContext context) =>
      (productThumb(context) * 0.9).clamp(40, 56);

  /// Category chip avatar radius.
  static double categoryChip(BuildContext context) =>
      (productThumb(context) * 0.22).clamp(10, 14);

  /// Category sidebar / drawer list avatar radius.
  static double categoryList(BuildContext context) =>
      (productThumb(context) * 0.3).clamp(12, 18);

  /// Drawer user avatar radius.
  static double drawerAvatar(BuildContext context) =>
      _scale(context, min: 24, max: 32, fraction: 0.07);

  /// POS product grid column count.
  static int posGridColumns(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 480) return 1;
    if (w < 720) return 2;
    if (w < 1100) return 3;
    return 4;
  }

  /// Grid tile aspect ratio from thumb + text row height.
  static double posTileAspectRatio(BuildContext context, {int? columns}) {
    final cols = columns ?? posGridColumns(context);
    final thumb = productThumb(context);
    final rowHeight = thumb + 36;
    final spacing = 8.0 * (cols - 1);
    final horizontalPad = 24.0;
    final cellWidth = (MediaQuery.sizeOf(context).width - horizontalPad - spacing) / cols;
    return (cellWidth / rowHeight).clamp(2.2, 3.6);
  }

  static double productLabelSize(BuildContext context) =>
      productThumb(context) < 46 ? 11 : 12;

  static double categoryChipBarHeight(BuildContext context) =>
      (categoryChip(context) * 2 + 20).clamp(40, 48);
}

/// Full-width primary button for touch targets on phones.
class MobilePrimaryButton extends StatelessWidget {
  const MobilePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon ?? Icons.login),
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
