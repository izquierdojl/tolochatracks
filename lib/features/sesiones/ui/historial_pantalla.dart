import 'package:flutter/material.dart';

class HistorialPantalla extends StatelessWidget {
  const HistorialPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.route_outlined,
              size: 64,
              color: tema.colorScheme.tertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Historial de rutas',
              style: tema.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Aquí aparecerán las sesiones grabadas.',
              style: tema.textTheme.bodyMedium?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
