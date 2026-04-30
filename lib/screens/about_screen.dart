import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sobre o App")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Color(0xFFC84C2C), shape: BoxShape.circle),
              child: const Icon(LucideIcons.chefHat, color: Colors.white, size: 60),
            ),
            const SizedBox(height: 24),
            Text(
              "Meu Cozinheiro",
              style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const Text(
              "v1.0.4-beta",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            _buildInfoCard(
              context,
              "Nossa Missão",
              "Transformar o ato de cozinhar em uma experiência simples, prazerosa e organizada, unindo tecnologia e gastronomia.",
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              "Tecnologia",
              "Desenvolvido com Flutter e Firebase para garantir a melhor performance e segurança dos seus dados culinários.",
            ),
            const SizedBox(height: 40),
            const Divider(),
            _buildLink(context, "Termos de Uso", const TermsScreen()),
            _buildLink(context, "Política de Privacidade", const PrivacyScreen()),
            const SizedBox(height: 40),
            const Text(
              "© 2026 Meu Cozinheiro App\nFeito com ❤️ para quem ama cozinhar.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFFC84C2C))),
          const SizedBox(height: 12),
          Text(content, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildLink(BuildContext context, String title, Widget screen) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(LucideIcons.externalLink, size: 16),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
    );
  }
}
