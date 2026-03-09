import 'package:flutter/material.dart';

Route<T> noTransitionRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) => page,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );
}
