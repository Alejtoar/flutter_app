import 'package:flutter/material.dart';

void showAppSnackBar(BuildContext context, String message, {bool isError = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green[700],
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: isError ? 4 : 3),
    ),
  );
}