import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/recipe_service.dart';
import '../models/recipe.dart';
import 'recipe_detail_screen.dart';
import '../widgets/chef_hat_pattern.dart';
import '../services/premium_service.dart';
import '../services/ad_service.dart';
import 'premium_paywall_screen.dart';
import 'buy_credits_screen.dart';

class AddRecipeScreen extends StatefulWidget {
  final String? initialUrl;
  final Recipe? initialRecipe;
  const AddRecipeScreen({super.key, this.initialUrl, this.initialRecipe});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  // ---- IA / Import ----
  final _urlController = TextEditingController();
  final _pasteController = TextEditingController();
  final _recipeService = RecipeService();
  final _premiumService = PremiumService();
  final _adService = AdService();
  bool _isImporting = false;
  String _importMode = 'url'; // 'url' | 'paste'
  bool _extracted = false;
  bool _usedAI = false;

  // ---- Manual form ----
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _sourceController = TextEditingController();
  final _instructionsController = TextEditingController();
  String _category = 'Salgados';
  List<Ingredient> _ingredients = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _adService.loadRewardedAd();
    
    if (widget.initialRecipe != null) {
      _usedAI = true;
      // Usar WidgetsBinding para garantir que o contexto está pronto para o SnackBar
      WidgetsBinding.instance.addPostFrameCallback((_) => _fillForm(widget.initialRecipe!));
    } else if (widget.initialUrl != null) {
      _urlController.text = widget.initialUrl!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleImportUrl());
    }
  }

  @override
  void didUpdateWidget(AddRecipeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialUrl != null && widget.initialUrl != oldWidget.initialUrl) {
      _urlController.text = widget.initialUrl!;
      _handleImportUrl();
    }
  }

  // ---- AI extraction (restricted) ----
  Future<void> _handleImportUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    // Verificar Premium/Tokens antes de processar
    final isPremium = await _premiumService.isPremium();
    final tokens = await _premiumService.getAdTokens();

    if (!isPremium && tokens <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("A extração com IA é um recurso Premium. Assine ou veja um vídeo para ganhar 1 crédito! 💎"),
            backgroundColor: Color(0xFFB33E24),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PremiumPaywallScreen()),
        );
      }
      return;
    }

    // Verificar Limite de Uso Justo (50/dia)
    final canSave = await _premiumService.canSaveRecipeToday();
    if (!canSave) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Limite diário de 50 receitas atingido! Tente amanhã. 👨‍🍳"),
            backgroundColor: Color(0xFFC84C2C),
          ),
        );
      }
      return;
    }

    setState(() => _isImporting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final recipe = await _recipeService.extractRecipe(url);
      if (recipe != null && mounted) {
        _usedAI = true;
        await _premiumService.incrementDailyRecipeCount();
        _fillForm(recipe);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text(e.toString().contains('bloqueou')
              ? 'O YouTube bloqueou o link. Cole a descrição abaixo!'
              : 'Erro: $e'),
          backgroundColor: const Color(0xFFC84C2C),
          duration: const Duration(seconds: 5),
        ));
        setState(() => _importMode = 'paste');
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _handleImportPaste() async {
    final text = _pasteController.text.trim();
    if (text.isEmpty) return;

    // Verificar Premium/Tokens antes de processar
    final isPremium = await _premiumService.isPremium();
    final tokens = await _premiumService.getAdTokens();

    if (!isPremium && tokens <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("A extração com IA é um recurso Premium. Assine ou veja um vídeo para ganhar 1 crédito! 💎"),
            backgroundColor: Color(0xFFB33E24),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PremiumPaywallScreen()),
        );
      }
      return;
    }

    // Verificar Limite de Uso Justo (50/dia)
    final canSave = await _premiumService.canSaveRecipeToday();
    if (!canSave) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Limite diário de 50 receitas atingido! Tente amanhã. 👨‍🍳"),
            backgroundColor: Color(0xFFC84C2C),
          ),
        );
      }
      return;
    }

    setState(() => _isImporting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final recipe = await _recipeService.extractRecipe('', manualText: text);
      if (recipe != null && mounted) {
        _usedAI = true;
        _fillForm(recipe);
        _pasteController.clear();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: const Color(0xFFC84C2C),
        ));
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _fillForm(Recipe recipe) {
    setState(() {
      _titleController.text = recipe.title;
      _descController.text = recipe.description;
      _instructionsController.text = recipe.instructions;
      _category = recipe.category.isNotEmpty ? recipe.category : 'Salgados';
      _ingredients = List.from(recipe.ingredients);
      _urlController.text = recipe.source ?? '';
      _extracted = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receita extraída! Revise e salve.'), backgroundColor: Color(0xFF5D8A66)),
    );
  }

  Future<void> _handleSave() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o nome da receita.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      // Subtrai token de IA APENAS na hora de salvar, caso a IA tenha sido usada
      if (_usedAI) {
        final isPremium = await _premiumService.isPremium();
        if (!isPremium) {
          await _premiumService.spendAdToken();
        }
      }

      final recipe = Recipe(
        id: '',
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _category,
        ingredients: _ingredients,
        instructions: _instructionsController.text.trim(),
        source: (_urlController.text.trim().isNotEmpty ? _urlController.text.trim() : _sourceController.text.trim()),
        status: 'nova',
        isFavorite: false,
      );
      final newId = await _recipeService.saveRecipe(recipe, recipe.source);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${recipe.title}" foi adicionada às suas receitas.'), backgroundColor: const Color(0xFF5D8A66)),
        );
        
        // Criar o objeto completo com o ID gerado para abrir a tela de detalhes
        final savedRecipe = Recipe(
          id: newId,
          userId: recipe.userId,
          title: recipe.title,
          description: recipe.description,
          category: recipe.category,
          ingredients: recipe.ingredients,
          instructions: recipe.instructions,
          source: recipe.source,
          status: 'nova',
          isFavorite: false,
        );

        // Ir direto para a tela da receita salva (substituindo o formulário)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: savedRecipe)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: const Color(0xFFC84C2C)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descController.clear();
    _sourceController.clear();
    _instructionsController.clear();
    _urlController.clear();
    _pasteController.clear();
    setState(() {
      _ingredients = [];
      _category = 'Salgados';
      _importMode = 'url';
      _extracted = false;
      _usedAI = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const ChefHatPattern(),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: const Color(0xFFB33E24),
                elevation: 0,
                automaticallyImplyLeading: false,
                leading: IconButton(
                  icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  "Nova Receita",
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                ),
                centerTitle: true,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_extracted) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'Importar com IA',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: const Color(0xFFB33E24),
                            ),
                          ),
                        ),
                        
                        // Import Card
                        StreamBuilder<Map<String, dynamic>>(
                          stream: _premiumService.premiumStatusStream(),
                          builder: (context, snapshot) {
                            final status = snapshot.data ?? {'isPremium': false, 'tokens': 0, 'adsWatched': 0};
                            final bool isPremium = status['isPremium'];
                            final int tokens = status['tokens'];
                            final int adsWatched = status['adsWatched'];
                            final int adsRemaining = PremiumService.dailyAdLimit - adsWatched;
                            
                            final bool isBlocked = !isPremium && tokens <= 0;

                            if (isBlocked) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C2C2C), // Fundo escuro
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(LucideIcons.sparkles, color: Colors.amber, size: 40),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Recurso Premium',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Você precisa de Créditos (Diamantes) para extrair receitas com IA.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          if (adsRemaining <= 0) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Limite diário de anúncios atingido! Tente amanhã ou assine o PRO.')),
                                            );
                                            return;
                                          }
                                          
                                          bool adLoadingDialogVisible = true;
                                          bool rewardGranted = false;

                                          // Mostrar indicador de carregamento
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.amber)),
                                          );

                                          await _adService.showRewardedAd(
                                            onRewardEarned: () async {
                                              rewardGranted = true;
                                              try {
                                                await _premiumService.addAdToken();
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Você ganhou 1 crédito! 💎'), backgroundColor: Color(0xFF5D8A66)),
                                                  );
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text(e.toString().contains('LIMITE_DIARIO') ? 'Limite diário atingido!' : 'Erro ao creditar')),
                                                  );
                                                }
                                              }
                                            },
                                            onAdFailed: () {
                                              if (adLoadingDialogVisible && mounted) {
                                                Navigator.pop(context); // fecha loading
                                                adLoadingDialogVisible = false;
                                              }
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Nenhum anúncio disponível no momento. Tente novamente.')),
                                                );
                                              }
                                            },
                                            onAdClosed: () {
                                              if (adLoadingDialogVisible && mounted) {
                                                Navigator.pop(context); // fecha loading
                                                adLoadingDialogVisible = false;
                                              }
                                              if (!rewardGranted && mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Você fechou o vídeo antes de receber a recompensa.')),
                                                );
                                              }
                                            },
                                          );
                                        },
                                        icon: const Icon(LucideIcons.playCircle, size: 18),
                                        label: Text('Ver Vídeo Patrocinado ($adsRemaining restantes)'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(0xFFB33E24),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPaywallScreen()));
                                        },
                                        icon: const Icon(LucideIcons.crown, size: 18),
                                        label: const Text('Seja PRO (Ilimitado)'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.amber,
                                          foregroundColor: Colors.black87,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyCreditsScreen()));
                                        },
                                        icon: const Icon(LucideIcons.gem, size: 18),
                                        label: const Text('Comprar Pacote de Créditos'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF4A4A4A),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: const Color(0xFFB33E24)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFB33E24).withOpacity(0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: _urlController,
                                    decoration: InputDecoration(
                                      hintText: 'Cole o link aqui...',
                                      filled: true,
                                      fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : Colors.white,
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFFB33E24)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFFB33E24), width: 2),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isImporting ? null : _handleImportUrl,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFB33E24),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: _isImporting
                                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                          : const Text('Processar com IA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Cole o link do vídeo ou o link do site com a sua receita',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFFB33E24).withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'Preencher Manualmente',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: const Color(0xFFB33E24),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Manual Form
                      _buildLabel('Nome da Receita *'),
                      _buildInput(_titleController, 'Ex: Bolo de Cenoura'),
                      const SizedBox(height: 16),
                      _buildLabel('Descrição'),
                      _buildInput(_descController, 'Uma breve descrição'),
                      const SizedBox(height: 16),
                      _buildLabel('Link ou fonte (opcional)'),
                      _buildInput(_sourceController, 'https://...'),
                      const SizedBox(height: 16),
                      
                      _buildLabel('Categoria'),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['Salgados', 'Doces', 'Bebidas', 'Fitness'].map((cat) {
                            final sel = _category == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: sel,
                                onSelected: (_) => setState(() => _category = cat),
                                selectedColor: const Color(0xFFB33E24),
                                backgroundColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : Colors.white,
                                labelStyle: GoogleFonts.inter(
                                  color: sel ? Colors.white : const Color(0xFFB33E24), 
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(color: const Color(0xFFB33E24).withOpacity(sel ? 1 : 0.2)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Ingredientes', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFFB33E24))),
                          ElevatedButton.icon(
                            onPressed: _showAddIngredientDialog,
                            icon: const Icon(LucideIcons.plus, size: 14, color: Colors.white),
                            label: Text('Adicionar', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB33E24),
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._ingredients.asMap().entries.map((e) {
                        final ing = e.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : Colors.white, 
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(ing.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
                                      const SizedBox(height: 4),
                                      Text(ing.quantity, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () => setState(() => _ingredients.removeAt(e.key)),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Icon(LucideIcons.x, size: 20, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      
                      const SizedBox(height: 24),
                      _buildLabel('Modo de Preparo'),
                      TextField(
                        controller: _instructionsController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: 'Descreva o passo a passo...',
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16), 
                            borderSide: const BorderSide(color: Color(0xFFB33E24)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16), 
                            borderSide: const BorderSide(color: Color(0xFFB33E24), width: 2),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: const Color(0xFFB33E24),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                            shadowColor: const Color(0xFFB33E24).withOpacity(0.4),
                          ),
                          child: _saving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text('Salvar Receita', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(String mode, IconData icon, String label) {
    final selected = _importMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _importMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFB33E24) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFB33E24).withOpacity(selected ? 1 : 0.2)),
        ),
        child: Row(children: [
          Icon(icon, size: 14, color: selected ? Colors.white : const Color(0xFFB33E24)),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: selected ? Colors.white : const Color(0xFFB33E24))),
        ]),
      ),
    );
  }

  Widget _buildLabel(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), 
          borderSide: const BorderSide(color: Color(0xFFB33E24)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), 
          borderSide: const BorderSide(color: Color(0xFFB33E24), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _showAddIngredientDialog() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Novo Ingrediente', style: GoogleFonts.playfairDisplay()),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome (ex: Farinha)'), autofocus: true),
          TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantidade (ex: 500g)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && qtyCtrl.text.isNotEmpty) {
                setState(() => _ingredients.add(Ingredient(name: nameCtrl.text.trim(), quantity: qtyCtrl.text.trim())));
                Navigator.pop(context);
              }
            },
            child: const Text('ADICIONAR'),
          ),
        ],
      ),
    );
  }
}
