import 'package:flutter/material.dart';

// Muestra un diálogo de carga consistente y devuelve una función para cerrarlo.
// Esto evita problemas de 'context' y 'mounted'.
VoidCallback showLoadingDialog(BuildContext context, {String message = 'Cargando...'}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message),
            ],
          ),
        ),
      );
    },
  );

  // Devuelve una función que sabe cómo cerrar ESTE diálogo específico.
  return () {
    Navigator.of(context, rootNavigator: true).pop();
  };
}