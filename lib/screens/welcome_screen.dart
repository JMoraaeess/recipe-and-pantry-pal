import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const WelcomeScreen({super.key, required this.onComplete});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: LucideIcons.chefHat,
      emoji: '👨‍🍳',
      title: 'Bem-vindo ao\nMeu Cozinheiro!',
      description: 'O seu chef particular com Inteligência Artificial. Prepare-se para uma experiência gastronômica organizada e sem estresse!',
      color: Color(0xFFB33E24),
    ),
    _OnboardingPage(
      icon: LucideIcons.sparkles,
      emoji: '✨',
      title: 'Extraia Receitas\ncom IA',
      description: 'Viu uma receita incrível no YouTube? Basta copiar o link e nossa IA extrai todos os detalhes para você em segundos!',
      color: Color(0xFF5D8A66),
    ),
    _OnboardingPage(
      icon: LucideIcons.shoppingCart,
      emoji: '🛒',
      title: 'Lista de Compras\nInteligente',
      description: 'Importe os ingredientes das receitas direto para sua lista. Nós limpamos as quantidades e nomes para facilitar sua ida ao mercado!',
      color: Color(0xFF42A5F5),
    ),
    _OnboardingPage(
      icon: LucideIcons.package,
      emoji: '🥘',
      title: 'Controle sua\nDespensa',
      description: 'Comprou o que precisava? Envie os itens da lista direto para a despensa e controle validades para nunca mais desperdiçar comida!',
      color: Color(0xFFE67E22),
    ),
    _OnboardingPage(
      icon: LucideIcons.gem,
      emoji: '💎',
      title: 'Ganhou\n5 Diamantes!',
      description: 'Use seus diamantes para extrair receitas com IA. Você pode ganhar mais assistindo vídeos ou se tornando um membro PRO!',
      color: Color(0xFF9B59B6),
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final page = _pages[index];
              return _buildPage(page);
            },
          ),

          // Skip button
          if (_currentPage < _pages.length - 1)
            Positioned(
              top: 60,
              right: 20,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  'Pular',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Page indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 32 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? Colors.white : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                // Next / Start button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _pages[_currentPage].color,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                        shadowColor: Colors.black26,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1 ? 'VAMOS COZINHAR! 🔥' : 'PRÓXIMO',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            page.color,
            page.color.withOpacity(0.8),
            page.color.withOpacity(0.6),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Emoji grande
              Text(
                page.emoji,
                style: const TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 40),
              // Título
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              // Descrição
              Text(
                page.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.6,
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String emoji;
  final String title;
  final String description;
  final Color color;

  const _OnboardingPage({
    required this.icon,
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
  });
}
