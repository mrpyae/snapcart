import 'package:flutter/material.dart';

/// Centralised responsive utility for SnapCart POS.
/// Use this instead of scattering `MediaQuery.of(context).size.width < X`
/// across every file — breakpoints are now consistent everywhere.
class Responsive {
  // ── Breakpoints ────────────────────────────────────────────────
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;

  // ── Device checks ──────────────────────────────────────────────
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  // ── Value selector ─────────────────────────────────────────────
  /// Returns a value based on screen width.
  /// Provide at least [mobile] and [desktop]. [tablet] falls back to [desktop].
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context) && tablet != null) return tablet;
    return desktop;
  }

  /// Adaptive padding: tighter on mobile, roomier on desktop.
  static EdgeInsets pagePadding(BuildContext context) => EdgeInsets.all(
        isMobile(context) ? 12.0 : 20.0,
      );

  // ── Adaptive dialog / bottom-sheet ─────────────────────────────
  /// On mobile → slides up as a draggable BottomSheet (feels native).
  /// On desktop → shows as a centred Dialog.
  ///
  /// [child] receives a [ScrollController] when inside a DraggableScrollableSheet.
  static Future<T?> showAdaptiveSheet<T>({
    required BuildContext context,
    required Widget Function(BuildContext ctx, ScrollController? scroll) builder,
    double mobileSizeInitial = 0.90,
    double mobileSizeMax = 0.97,
    double mobileSizeMin = 0.45,
    double dialogMaxWidth = 520,
  }) {
    if (isMobile(context)) {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: mobileSizeInitial,
          maxChildSize: mobileSizeMax,
          minChildSize: mobileSizeMin,
          expand: false,
          builder: (ctx, scrollController) => ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: builder(ctx, scrollController),
          ),
        ),
      );
    } else {
      return showDialog<T>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: dialogMaxWidth),
            child: builder(ctx, null),
          ),
        ),
      );
    }
  }

  // ── Touch targets ──────────────────────────────────────────────
  /// Minimum 48 × 48 dp touch target on mobile (Material a11y guideline).
  static const double minTouchTarget = 48.0;

  static double buttonHeight(BuildContext context) =>
      isMobile(context) ? 48.0 : 44.0;

  // ── Typography helpers ─────────────────────────────────────────
  static double titleFontSize(BuildContext context) =>
      isMobile(context) ? 18.0 : 22.0;

  static double subtitleFontSize(BuildContext context) =>
      isMobile(context) ? 12.0 : 13.0;
}

/// A reusable bottom-sheet drag handle (pill indicator at the top).
class SheetDragHandle extends StatelessWidget {
  const SheetDragHandle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
