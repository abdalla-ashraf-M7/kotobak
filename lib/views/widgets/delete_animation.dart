import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class DeleteAnimation extends StatelessWidget {
  final Widget child;
  final bool isDeleting;
  final VoidCallback onDismissed;

  const DeleteAnimation({
    Key? key,
    required this.child,
    required this.isDeleting,
    required this.onDismissed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isDeleting ? 0.0 : 1.0,
      duration: Duration(milliseconds: AppConstants.deleteAnimationDuration),
      curve: Curves.easeInOutBack,
      onEnd: onDismissed,
      child: AnimatedOpacity(
        opacity: isDeleting ? 0.0 : 1.0,
        duration: Duration(milliseconds: AppConstants.deleteAnimationDuration),
        curve: Curves.easeInOut,
        child: child,
      ),
    );
  }
}
