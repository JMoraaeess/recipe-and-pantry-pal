import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/recipe_service.dart';
import '../models/recipe.dart';
import 'add_recipe_screen.dart';
import '../widgets/chef_hat_pattern.dart';
import '../services/premium_service.dart';
import 'premium_paywall_screen.dart';

class LoadingRecipeScreen extends StatefulWidget {
  final String url;
  const LoadingRecipeScreen({super.key, required this.url});

  @override
  State<LoadingRecipeScreen> createState() => _LoadingRecipeScreenState();
}

class _LoadingRecipeScreenState extends State<LoadingRecipeScreen> with SingleTickerProviderStateMixin {
  final _recipeService = RecipeService();
  final _premiumService = PremiumService();
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _startExtraction();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startExtraction() async {
    try {
      // 1. Verificação proativa de limite
      final isPremium = await _premiumService.isPremium();
      final canAdd = await _premiumService.canAddMoreRecipes();
      final tokens = await _premiumService.getAdTokens();

      if (!isPremium && !canAdd && tokens <= 0) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PremiumPaywallScreen()),
          );
        }
        return;
      }

      final recipe = await _recipeService.extractRecipe(widget.url);
      if (recipe != null && mounted) {
        await _premiumService.incrementDailyRecipeCount();
        // Quando terminar, substitui a tela atual pela tela de AddRecipeScreen com os dados
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AddRecipeScreen(
              initialUrl: widget.url,
              initialRecipe: recipe,
            ),
          ),
        );
      } else if (mounted) {
        throw Exception("Não foi possível extrair a receita.");
      }
    } catch (e) {
      if (mounted) {
        // Se der erro, volta para a tela anterior ou mostra erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: const Color(0xFFC84C2C)),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const ChefHatPattern(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RotationTransition(
                  turns: _controller,
                  child: Container(
                    width: 120,
                    height: 120,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                      boxShadow: isDark ? [] : const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "O Meu Cozinheiro está lendo a sua receita...",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Meu Cozinheiro",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFB33E24).withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "v1.0.4-beta",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "Aguarde um momento enquanto a IA extrai todos os detalhes para você.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFFB33E24).withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    backgroundColor: isDark ? const Color(0xFF2A2725) : const Color(0xFFFAF7F2),
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
