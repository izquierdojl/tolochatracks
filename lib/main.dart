import 'package:flutter/material.dart';

import 'app/shell/shell_pantalla.dart';
import 'app/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TolochaTracksApp());
}

class TolochaTracksApp extends StatelessWidget {
  const TolochaTracksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TolochaTracks',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      darkTheme: AppTheme.oscuro,
      themeMode: ThemeMode.system,
      home: const ShellPantalla(),
    );
  }
}
