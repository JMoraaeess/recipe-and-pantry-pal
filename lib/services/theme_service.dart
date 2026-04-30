import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'theme_mode';
  
  // Notificador global para o modo de tema (Inicia como sistema por padrão)
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  // Inicializar o serviço carregando a preferência salva
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_themeKey);
    
    if (savedMode != null) {
      themeMode.value = ThemeMode.values.firstWhere(
        (m) => m.toString() == savedMode,
        orElse: () => ThemeMode.system,
      );
    }
  }

  static void setTheme(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.toString());
  }

  // Atalho para o toggle (legado, agora usamos setTheme)
  static void toggleTheme(bool isDarkMode) {
    setTheme(isDarkMode ? ThemeMode.dark : ThemeMode.light);
  }
}
