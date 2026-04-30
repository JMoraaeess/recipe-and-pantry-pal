import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'ajuda@meucozinheiro.com',
      query: 'subject=Suporte Meu Cozinheiro&body=Olá, preciso de ajuda com...',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: const Text("Guia do Aplicativo"),
        backgroundColor: const Color(0xFFB33E24),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionTitle("Central de Ajuda"),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _launchEmail,
            child: _buildHelpCard(
              context,
              LucideIcons.messageCircle,
              "Falar com Suporte",
              "Nosso time responde em até 24h úteis.",
              const Color(0xFFC84C2C),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _launchEmail,
            child: _buildHelpCard(
              context,
              LucideIcons.mail,
              "Enviar E-mail",
              "ajuda@meucozinheiro.com",
              const Color(0xFF5D8A66),
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle("Como funciona o App?"),
          const SizedBox(height: 16),
          
          _buildFeatureGuide(
            context,
            LucideIcons.chefHat,
            "Receitas e IA",
            "Viu uma receita no YouTube? Basta copiar o link e colar na aba de 'Adicionar'. Nossa IA vai extrair todos os ingredientes e o modo de preparo para você economizar tempo!",
            const Color(0xFFB33E24),
          ),
          _buildFeatureGuide(
            context,
            LucideIcons.package,
            "Controle de Despensa",
            "Mantenha seu estoque atualizado! Ao marcar que tem um ingrediente, o app avisa quais receitas você já pode cozinhar sem precisar ir ao mercado.",
            const Color(0xFF5D8A66),
          ),
          _buildFeatureGuide(
            context,
            LucideIcons.shoppingCart,
            "Lista de Compras Inteligente",
            "Adicione itens manualmente ou importe de uma receita. O app limpa os nomes automaticamente (ex: remove 'gelado' ou 'a gosto') para facilitar sua ida ao mercado.",
            const Color(0xFF42A5F5),
          ),
          _buildFeatureGuide(
            context,
            LucideIcons.gem,
            "Sistema de Diamantes",
            "Cada extração de IA consome 1 diamante. Você começa com 5 diamantes grátis e pode ganhar mais assistindo anúncios ou se tornando PRO para extrações ilimitadas.",
            const Color(0xFF9B59B6),
          ),

          const SizedBox(height: 32),
          _buildSectionTitle("Perguntas Frequentes"),
          const SizedBox(height: 16),
          _buildFAQ("Como importar do YouTube?", "Abra o vídeo no YouTube, toque em 'Compartilhar' e escolha o ícone do 'Meu Cozinheiro'. A mágica acontece sozinha!"),
          _buildFAQ("O app funciona sem internet?", "Sim! Suas receitas e listas de compras salvas ficam guardadas no celular para consulta offline."),
          _buildFAQ("Como salvar itens na despensa?", "Na lista de compras, ao marcar um item como comprado (ícone de carrinho), ele perguntará a quantidade e validade para enviar direto para sua despensa."),
          _buildFAQ("Esqueci minha senha, e agora?", "Na tela de login, clique em 'Esqueci minha senha' e enviaremos um link de recuperação para o seu e-mail."),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF262321),
      ),
    );
  }

  Widget _buildFeatureGuide(BuildContext context, IconData icon, String title, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700], height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard(BuildContext context, IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, color: Colors.grey, size: 18),
        ],
      ),
    );
  }

  Widget _buildFAQ(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(question, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(answer, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
