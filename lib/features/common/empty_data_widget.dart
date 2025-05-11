import 'package:flutter/material.dart';

class EmptyDataWidget extends StatelessWidget {
  final String message;
  final String? callToAction; // Mensaje opcional como "Presiona + para agregar"
  final IconData icon;

  const EmptyDataWidget({
    Key? key,
    required this.message,
    this.callToAction,
    this.icon = Icons.inbox_outlined, // Un ícono genérico por defecto
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
            if (callToAction != null && callToAction!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                callToAction!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[500]),
              ),
            ]
          ],
        ),
      ),
    );
  }
}