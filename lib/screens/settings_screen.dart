import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/theme_service.dart';
import '../services/review_service.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _darkMode = false;
  String _unit = 'Métrico (g/ml)';
  bool _isLoading = true;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    if (doc.exists && doc.data()!.containsKey('settings')) {
      final settings = doc.data()!['settings'] as Map<String, dynamic>;
      setState(() {
        _notifications = settings['notifications'] ?? true;
        _darkMode = settings['darkMode'] ?? false;
        _unit = settings['unit'] ?? 'Métrico (g/ml)';
        _isLoading = false;
      });
      // Sincronizar o tema inicial
      ThemeService.toggleTheme(_darkMode);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      'settings': {
        'notifications': _notifications,
        'darkMode': _darkMode,
        'unit': _unit,
      }
    }, SetOptions(merge: true));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Configurações salvas!"), backgroundColor: Color(0xFF5D8A66)),
      );
    }
  }

  Future<void> _handleNotificationToggle(bool value) async {
    if (value) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        setState(() => _notifications = true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Permissão de notificação negada."), backgroundColor: Colors.orange),
          );
        }
        setState(() => _notifications = false);
      }
    } else {
      setState(() => _notifications = false);
    }
  }

  void _handleDarkModeToggle(bool value) {
    setState(() => _darkMode = value);
    ThemeService.toggleTheme(value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Configurações"),
        actions: [
          IconButton(onPressed: _saveSettings, icon: const Icon(LucideIcons.save)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection("Aparência"),
          _buildThemeSelector(),
          const SizedBox(height: 24),
          _buildSection("Preferências"),
          _buildSwitchTile("Notificações de Receitas", "Avisar quando houver novidades", _notifications, _handleNotificationToggle),
          _buildListTile(LucideIcons.star, "Avaliar o App", "Diga-nos o que você está achando", onTap: () => ReviewService.openStoreListing()),
          
          const SizedBox(height: 24),
          _buildSection("Culinária"),
          _buildDropdownTile("Unidade de Medida", _unit, ['Métrico (g/ml)', 'Imperial (oz/lb)', 'Caseiro (Xícaras/Colheres)'], (v) => setState(() => _unit = v!)),
          
          const SizedBox(height: 24),
          _buildSection("Legal e Conta"),
          _buildListTile(LucideIcons.fileText, "Termos de Uso", "Nossas regras de utilização", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsScreen()))),
          _buildListTile(LucideIcons.shieldCheck, "Política de Privacidade", "Como cuidamos dos seus dados", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyScreen()))),
          _buildListTile(LucideIcons.trash2, "Excluir Conta", "Ação irreversível", color: Colors.red),
          
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: _saveSettings,
              child: const Text("SALVAR CONFIGURAÇÕES"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFC84C2C), fontSize: 13, letterSpacing: 1)),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Card(
      child: SwitchListTile(
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFFC84C2C),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, String subtitle, {Color? color, VoidCallback? onTap}) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color ?? const Color(0xFFC84C2C)),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: color)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(LucideIcons.chevronRight, size: 18),
        onTap: onTap,
      ),
    );
  }

  Widget _buildThemeSelector() {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeMode,
      builder: (context, mode, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.palette, color: Color(0xFFC84C2C), size: 18),
                    const SizedBox(width: 12),
                    Text("Tema do App", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.light, label: Text("Claro"), icon: Icon(LucideIcons.sun, size: 16)),
                    ButtonSegment(value: ThemeMode.dark, label: Text("Escuro"), icon: Icon(LucideIcons.moon, size: 16)),
                    ButtonSegment(value: ThemeMode.system, label: Text("Sistema"), icon: Icon(LucideIcons.monitor, size: 16)),
                  ],
                  selected: {mode},
                  onSelectionChanged: (Set<ThemeMode> newSelection) {
                    ThemeService.setTheme(newSelection.first);
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                      if (states.contains(WidgetState.selected)) return const Color(0xFFC84C2C);
                      return null;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                      if (states.contains(WidgetState.selected)) return Colors.white;
                      return null;
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdownTile(String title, String value, List<String> options, Function(String?) onChanged) {
    return Card(
      child: ListTile(
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
        trailing: DropdownButton<String>(
          value: value,
          underline: const SizedBox(),
          items: options.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
