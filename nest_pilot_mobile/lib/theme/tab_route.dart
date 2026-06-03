import 'package:flutter/material.dart';

/// Fade-only page route used for bottom-nav tab switches.
/// Replaces the default slide animation with a quick fade so switching
/// tabs feels instant rather than a full-screen push.
PageRoute<T> tabRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 150),
  );
}
