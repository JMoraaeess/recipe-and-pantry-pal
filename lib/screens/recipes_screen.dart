import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../services/premium_service.dart';
import 'recipe_detail_screen.dart';
import 'add_recipe_screen.dart';
import '../widgets/chef_hat_pattern.dart';
import 'premium_paywall_screen.dart';
import 'buy_credits_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final _recipeService = RecipeService();
  final _premiumService = PremiumService();
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String? _selectedCategory;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Tudo', 'icon': LucideIcons.layoutGrid},
    {'name': 'Favoritos', 'icon': LucideIcons.star},
    {'name': 'Salgados', 'icon': LucideIcons.utensils},
    {'name': 'Doces', 'icon': LucideIcons.cake},
    {'name': 'Bebidas', 'icon': LucideIcons.cupSoda},
    {'name': 'Fitness', 'icon': LucideIcons.dumbbell},
  ];

  Future<void> _toggleFavorite(Recipe recipe) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).collection('recipes').doc(recipe.id).update({
      'is_favorite': !recipe.isFavorite,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: _selectedCategory == null && !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSearching) {
          setState(() {
            _isSearching = false;
            _searchQuery = "";
            _searchController.clear();
          });
        } else if (_selectedCategory != null) {
          setState(() => _selectedCategory = null);
        }
      },
      child: Scaffold(
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
                  leadingWidth: _selectedCategory != null ? 120 : 80,
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedCategory != null)
                        IconButton(
                          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
                          onPressed: () => setState(() => _selectedCategory = null),
                        ),
                      if (_selectedCategory == null) const SizedBox(width: 12),
                      StreamBuilder<bool>(
                        stream: _premiumService.isPremiumStream(),
                        builder: (context, premiumSnap) {
                          final isPro = premiumSnap.data ?? false;
                          return StreamBuilder<int>(
                            stream: _premiumService.adTokensStream(),
                            builder: (context, snapshot) {
                              final tokens = snapshot.data ?? 0;
                              return GestureDetector(
                                onTap: () {
                                  if (!isPro) {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyCreditsScreen()));
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPro ? Colors.amber.withOpacity(0.3) : Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: isPro ? Border.all(color: Colors.amber.withOpacity(0.5), width: 1) : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isPro ? LucideIcons.crown : LucideIcons.gem,
                                        color: isPro ? Colors.amber : Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isPro ? 'PRO' : tokens.toString(),
                                        style: GoogleFonts.inter(
                                          color: isPro ? Colors.amber : Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  title: _isSearching
                      ? TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "Buscar receitas...",
                            hintStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                          ),
                          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                        )
                      : Text(
                          _selectedCategory ?? "Minhas Receitas",
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                        ),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: Icon(_isSearching ? LucideIcons.x : LucideIcons.search, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          if (_isSearching) {
                            _searchQuery = "";
                            _searchController.clear();
                          }
                          _isSearching = !_isSearching;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ],
                ),
                if (_selectedCategory == null && !_isSearching)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                      child: Text(
                        "O que vamos cozinhar hoje?",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          fontSize: 22,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                StreamBuilder<List<Recipe>>(
                  stream: _recipeService.getRecipes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                    }
                    
                    final allRecipes = snapshot.data ?? [];
                    final filteredRecipes = allRecipes.where((r) {
                      final matchesCategory = _selectedCategory == null || _selectedCategory == 'Tudo'
                          ? true
                          : _selectedCategory == 'Favoritos'
                              ? r.isFavorite
                              : r.category == _selectedCategory;
                      final matchesSearch = r.title.toLowerCase().contains(_searchQuery);
                      return matchesCategory && matchesSearch;
                    }).toList();

                    if (_selectedCategory == null && !_isSearching) {
                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildAddRecipeCard(isDark),
                            _buildCategoryGrid(isDark),
                          ]),
                        ),
                      );
                    }

                    return _buildRecipeList(filteredRecipes, isDark);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddRecipeCard(bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddRecipeScreen()),
      ),
      child: Container(
        width: double.infinity,
        height: 130,
        decoration: BoxDecoration(
          color: const Color(0xFFB33E24),
          borderRadius: BorderRadius.circular(24),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: const Color(0xFFB33E24).withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -15,
              bottom: -25,
              child: Opacity(
                opacity: 0.15,
                child: Transform.rotate(
                  angle: -0.2,
                  child: const Icon(LucideIcons.chefHat, size: 140, color: Colors.white),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Nova Receita',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Adicione receitas do YouTube ou fotos',
                          style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.plus, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat = _categories[index];
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat['name']),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
                  boxShadow: isDark ? [] : [
                    BoxShadow(
                      color: const Color(0xFFB33E24).withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(cat['icon'], color: Theme.of(context).colorScheme.primary, size: 28),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        cat['name'],
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold, 
                          fontSize: 15, 
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecipeList(List<Recipe> recipes, bool isDark) {
    if (recipes.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.searchX, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                "Nenhuma receita encontrada",
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildRecipeCard(recipes[index], isDark),
          childCount: recipes.length,
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe))),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
          boxShadow: isDark ? [] : [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Container(
                    height: 110,
                    width: double.infinity,
                    color: const Color(0xFF5D8A66).withOpacity(0.1),
                    child: _buildThumbnail(recipe),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(recipe),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.star,
                        color: recipe.isFavorite ? Colors.amber : Colors.white70,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: _buildStatusBadge(recipe.status),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe.category.toUpperCase(),
                    style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        recipe.sourceType == 'video' ? LucideIcons.playCircle : LucideIcons.globe,
                        size: 10,
                        color: const Color(0xFFB33E24).withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (recipe.sourceType ?? 'site').toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 9, 
                          color: const Color(0xFFB33E24).withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = const Color(0xFF42A5F5);
    if (status == 'reservada') color = const Color(0xFFB33E24);
    if (status == 'concluida') color = const Color(0xFF5D8A66);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildThumbnail(Recipe recipe) {
    if (recipe.thumbnailUrl != null && recipe.thumbnailUrl!.isNotEmpty) {
      return Image.network(
        recipe.thumbnailUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildYoutubeFallback(recipe),
      );
    }
    return _buildYoutubeFallback(recipe);
  }

  Widget _buildYoutubeFallback(Recipe recipe) {
    if (recipe.source != null && recipe.source!.contains('youtube')) {
      final videoId = _extractYoutubeId(recipe.source!);
      if (videoId != null) {
        return Image.network(
          'https://img.youtube.com/vi/$videoId/mqdefault.jpg',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _defaultThumbnail(recipe),
        );
      }
    }
    return _defaultThumbnail(recipe);
  }

  Widget _defaultThumbnail(Recipe recipe) {
    return Center(
      child: Icon(
        recipe.category == 'Salgados' ? LucideIcons.utensils : LucideIcons.cake,
        color: const Color(0xFF5D8A66).withOpacity(0.3),
        size: 40,
      ),
    );
  }

  String? _extractYoutubeId(String url) {
    final regExp = RegExp(
      r"(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|shorts\/|watch\?v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})",
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }
}
