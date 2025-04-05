import 'package:flutter/material.dart';

/// Widget base para formularios CRUD
class CrudForm extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final bool isLoading;
  final String? error;
  final GlobalKey<FormState>? formKey;

  const CrudForm({
    Key? key,
    required this.title,
    required this.children,
    required this.onSave,
    required this.onCancel,
    this.isLoading = false,
    this.error,
    this.formKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: isLoading ? null : onSave,
          ),
        ],
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null)
                Card(
                  color: Colors.red[100],
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      error!,
                      style: TextStyle(color: Colors.red[900]),
                    ),
                  ),
                ),
              ...children,
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isLoading ? null : onCancel,
                    child: Text('Cancelar'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isLoading ? null : onSave,
                    child: isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
