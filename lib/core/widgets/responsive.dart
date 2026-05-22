import 'package:flutter/material.dart';

/// Mobile-first breakpoints used across the app.
class AppBreakpoints {
  static const double phone = 600;
  static const double tablet = 900;

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isPhone(BuildContext context) => width(context) < phone;

  /// Viewport under 900px — drawer, bottom nav, stacked layouts.
  static bool isMobile(BuildContext context) => width(context) < tablet;

  static bool isTablet(BuildContext context) {
    final w = width(context);
    return w >= phone && w < tablet;
  }

  /// Viewport 900px and wider — sidebar, multi-column layouts.
  static bool isDesktop(BuildContext context) => !isMobile(context);

  static bool useDrawerNav(BuildContext context) => isMobile(context);

  static bool useBottomNav(BuildContext context) => isMobile(context);

  static EdgeInsets pagePadding(BuildContext context) {
    if (isPhone(context)) return const EdgeInsets.all(12);
    if (isMobile(context)) return const EdgeInsets.all(16);
    return const EdgeInsets.all(24);
  }

  static int gridColumns(
    BuildContext context, {
    int phoneCols = 2,
    int tabletCols = 3,
    int desktopCols = 4,
  }) {
    if (isPhone(context)) return phoneCols;
    if (isMobile(context)) return tabletCols;
    return desktopCols;
  }

  static double dialogContentWidth(BuildContext context) {
    final w = width(context);
    if (isPhone(context)) return w - 32;
    if (isMobile(context)) return w * 0.92;
    return 420;
  }

  static double formMaxWidth(BuildContext context) {
    if (isPhone(context)) return double.infinity;
    return 440;
  }

  /// Drawer width capped for small phones.
  static double drawerWidth(BuildContext context) {
    final w = width(context);
    return w < 360 ? w * 0.88 : 280;
  }
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

  static double productThumb(BuildContext context) =>
      _scale(context, min: 40, max: 64, fraction: 0.11);

  static double cartThumb(BuildContext context) =>
      (productThumb(context) * 0.78).clamp(32, 52);

  static double listThumb(BuildContext context) =>
      (productThumb(context) * 0.9).clamp(40, 56);

  static double categoryChip(BuildContext context) =>
      (productThumb(context) * 0.22).clamp(10, 14);

  static double categoryList(BuildContext context) =>
      (productThumb(context) * 0.3).clamp(12, 18);

  static double drawerAvatar(BuildContext context) =>
      _scale(context, min: 24, max: 32, fraction: 0.07);

  static int posGridColumns(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < AppBreakpoints.phone) return 1;
    if (w < 720) return 2;
    if (w < 1100) return 3;
    return 4;
  }

  static double posTileAspectRatio(BuildContext context, {int? columns}) {
    final cols = columns ?? posGridColumns(context);
    final thumb = productThumb(context);
    final rowHeight = thumb + 36;
    final spacing = 8.0 * (cols - 1);
    final pad = AppBreakpoints.pagePadding(context).horizontal + 8;
    final cellWidth = (MediaQuery.sizeOf(context).width - pad - spacing) / cols;
    return (cellWidth / rowHeight).clamp(1.8, 3.6);
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
