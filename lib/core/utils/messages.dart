import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/constants.dart';
import 'size_config.dart';

enum MessageType { success, error, info, warning }

class GoalioMessages {
  static void show(
    BuildContext context, {
    required String message,
    MessageType type = MessageType.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder:
          (context) => _GoalioMessageWidget(
            message: message,
            type: type,
            onDismiss: () => overlayEntry.remove(),
            duration: duration,
          ),
    );

    overlay.insert(overlayEntry);
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message: message, type: MessageType.success);
  }

  static void showError(BuildContext context, String message) {
    show(context, message: message, type: MessageType.error);
  }

  static void showInfo(BuildContext context, String message) {
    show(context, message: message, type: MessageType.info);
  }

  static void showWarning(BuildContext context, String message) {
    show(context, message: message, type: MessageType.warning);
  }
}

class _GoalioMessageWidget extends StatefulWidget {
  final String message;
  final MessageType type;
  final VoidCallback onDismiss;
  final Duration duration;

  const _GoalioMessageWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_GoalioMessageWidget> createState() => _GoalioMessageWidgetState();
}

class _GoalioMessageWidgetState extends State<_GoalioMessageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    Future.delayed(widget.duration - const Duration(milliseconds: 400), () {
      if (mounted) _controller.reverse().then((_) => widget.onDismiss());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getIcon() {
    switch (widget.type) {
      case MessageType.success:
        return Icons.check_circle_rounded;
      case MessageType.error:
        return Icons.error_rounded;
      case MessageType.warning:
        return Icons.warning_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _getColor() {
    switch (widget.type) {
      case MessageType.success:
        return GoalioColors.greenAccent;
      case MessageType.error:
        return Colors.redAccent;
      case MessageType.warning:
        return Colors.orangeAccent;
      default:
        return GoalioColors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20.h,
      left: 20.w,
      right: 20.w,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.w),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 16.h,
                  ),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20.w),
                    border: Border.all(
                      color: _getColor().withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getColor().withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: _getColor().withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_getIcon(), color: _getColor(), size: 24.w),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.type.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: _getColor(),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              widget.message,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
