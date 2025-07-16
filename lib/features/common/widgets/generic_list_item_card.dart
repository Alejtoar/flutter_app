import 'package:flutter/material.dart';

class GenericListItemCard extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final List<Widget> actions;
  final bool isSelected;
  final VoidCallback onSelect; // Callback para el Checkbox
  final Color? cardColor;
  final bool showCheckbox;

  const GenericListItemCard({
    Key? key,
    this.leading,
    required this.title,
    this.subtitle,
    this.actions = const [],
    required this.isSelected,
    required this.onSelect,
    this.cardColor,
    this.showCheckbox = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color? finalCardColor = isSelected
        ? Theme.of(context).primaryColor
        : cardColor;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          width: 1.5,
        ),
      ),
      color: finalCardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            // Checkbox para selección
            if (showCheckbox) // Si showCheckbox es true, muestra el Checkbox
              Padding(
                padding: const EdgeInsets.only(left: 8.0), // Padding para que no esté pegado al borde
                child: Checkbox(
                  value: isSelected,
                  onChanged: (val) => onSelect(),
                  activeColor: Theme.of(context).primaryColor,
                ),
              )
            else // Si no, añade un espacio para mantener el alineamiento
              const SizedBox(width: 16),
            // Contenido principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) // Mostrar leading si se provee
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: leading!,
                    ),
                  DefaultTextStyle( // Estilo para el título
                    style: Theme.of(context).textTheme.titleMedium!,
                    child: title,
                  ),
                  if (subtitle != null) // Mostrar subtítulo si se provee
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: DefaultTextStyle(
                        style: Theme.of(context).textTheme.bodySmall!,
                        child: subtitle!,
                      ),
                    ),
                ],
              ),
            ),
            // Botones de acción
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions,
                ),
              ),
          ],
        ),
      ),
    );
  }
}