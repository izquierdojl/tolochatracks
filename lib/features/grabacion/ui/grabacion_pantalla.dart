import 'package:flutter/material.dart';

class GrabacionPantalla extends StatelessWidget {
  const GrabacionPantalla({super.key});

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
              Icons.fiber_manual_record_outlined,
              size: 64,
              color: tema.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Grabación GPS',
              style: tema.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'La grabación de rutas se implementa en el siguiente change.',
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
