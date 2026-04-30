import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_recipe_screen.dart';
import '../models/recipe.dart';
import '../models/pantry_item.dart';
import '../services/pantry_service.dart';
import '../services/units_service.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'shopping_list_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _pantryService = PantryService();
  final _unitsService = UnitsService();
  
  bool _isUpdating = false;
  List<PantryItem> _pantryItems = [];
  Map<String, bool> _stockStatus = {}; 
  YoutubePlayerController? _ytController;

  @override
  void initState() {
    super.initState();
    _fetchPantryItems();
    _initYoutube();
  }

  void _initYoutube() {
    if (widget.recipe.source != null && widget.recipe.source!.isNotEmpty) {
      final videoId = YoutubePlayer.convertUrlToId(widget.recipe.source!);
      if (videoId != null) {
        _ytController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

  Future<void> _fetchPantryItems() async {
    final items = await _pantryService.getPantryItems();
    if (mounted) {
      setState(() {
        _pantryItems = items;
        _checkStock();
      });
    }
  }

  void _checkStock() {
    final Map<String, bool> status = {};
    for (var ing in widget.recipe.ingredients) {
      final normalizedIng = _unitsService.normalize(ing.quantity, ing.name);
      
      final pItem = _pantryItems.firstWhere(
        (p) => p.name.toLowerCase() == ing.name.toLowerCase(),
        orElse: () => PantryItem(
          id: '', userId: '', name: '', quantity: '', 
          numericValue: 0, unit: '', category: '', 
          reservedValue: 0, createdAt: DateTime.now()
        ),
      );

      double available = pItem.numericValue - pItem.reservedValue;
      status[ing.name] = pItem.id.isNotEmpty && available >= normalizedIng.value;
    }
    setState(() => _stockStatus = status);
  }

  Future<void> _updateRecipeStatus(String status) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    await _db.collection('users')
        .doc(uid)
        .collection('recipes')
        .doc(widget.recipe.id)
        .update({'status': status});
  }

  Future<void> _handleReserve() async {
    setState(() => _isUpdating = true);
    try {
      await _pantryService.reserveIngredients(widget.recipe.ingredients);
      await _updateRecipeStatus('reservada');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ingredientes reservados na despensa!"), backgroundColor: Color(0xFFC84C2C)),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint("Erro ao reservar: $e");
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _handleComplete() async {
    setState(() => _isUpdating = true);
    try {
      await _pantryService.consumeIngredients(widget.recipe.ingredients);
      await _updateRecipeStatus('concluida');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Receita concluída! Estoque atualizado."), backgroundColor: Color(0xFF5D8A66)),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint("Erro ao concluir: $e");
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _handleCancel() async {
    setState(() => _isUpdating = true);
    try {
      await _pantryService.unreserveIngredients(widget.recipe.ingredients);
      await _updateRecipeStatus('nova');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Preparo cancelado. Ingredientes liberados."), backgroundColor: Colors.orange),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint("Erro ao cancelar: $e");
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (newStatus == 'reservada') {
      await _handleReserve();
    } else if (newStatus == 'concluida') {
      await _handleComplete();
    } else if (newStatus == 'nova') {
      await _handleCancel();
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Excluir Receita", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: const Text("Tem certeza que deseja excluir esta receita? Esta ação não pode ser desfeita."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC84C2C)),
            child: const Text("EXCLUIR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (widget.recipe.status == 'reservada') {
          await _pantryService.unreserveIngredients(widget.recipe.ingredients);
        }
        
        final uid = _auth.currentUser?.uid;
        if (uid != null) {
          await _db.collection('users').doc(uid).collection('recipes').doc(widget.recipe.id).delete();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Receita excluída.")),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        debugPrint("Erro ao excluir: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(),
                  const SizedBox(height: 40),
                  _buildIngredientsList(),
                  const SizedBox(height: 40),
                  _buildVideoPlayer(),
                  const SizedBox(height: 40),
                  _buildInstructions(),
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildActionPanel(),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: const Color(0xFFC84C2C),
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            widget.recipe.isFavorite ? LucideIcons.star : LucideIcons.star,
            color: widget.recipe.isFavorite ? Colors.amber : Colors.white,
          ),
          onPressed: () async {
            final uid = _auth.currentUser?.uid;
            if (uid != null) {
              await _db.collection('users')
                  .doc(uid)
                  .collection('recipes')
                  .doc(widget.recipe.id)
                  .update({'is_favorite': !widget.recipe.isFavorite});
              
              setState(() {
                widget.recipe.isFavorite = !widget.recipe.isFavorite;
              });
            }
          },
        ),
        if (widget.recipe.status != 'concluida')
          IconButton(
            icon: const Icon(LucideIcons.checkCircle2, color: Colors.white),
            onPressed: _isUpdating ? null : () => _updateStatus('concluida'),
          ),
        IconButton(
          icon: const Icon(LucideIcons.edit, color: Colors.white),
          onPressed: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => EditRecipeScreen(recipe: widget.recipe)),
            );
            if (result == true) {
              if (mounted) Navigator.pop(context, true); 
            }
          },
        ),
        IconButton(
          icon: const Icon(LucideIcons.share2, color: Colors.white),
          onPressed: () {
            final recipe = widget.recipe;
            final ingredients = recipe.ingredients.map((i) => '• ${i.name} — ${i.quantity}').join('\n');
            final text = '🧑‍🍳 ${recipe.title}\n\n'
                '📋 Ingredientes:\n$ingredients\n\n'
                '👨‍🍳 Modo de Preparo:\n${recipe.instructions}\n\n'
                '✨ Extraído pelo app Meu Cozinheiro — receitas com IA!\n'
                'Baixe: https://play.google.com/store/apps/details?id=com.meucozinheiro.app';
            SharePlus.instance.share(ShareParams(text: text));
          },
        ),
        IconButton(
          icon: const Icon(LucideIcons.trash2, color: Colors.white),
          onPressed: _handleDelete,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.recipe.thumbnailUrl != null && widget.recipe.thumbnailUrl!.isNotEmpty)
              Image.network(
                widget.recipe.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFFC84C2C)),
              )
            else
              Container(
                color: const Color(0xFFC84C2C),
                child: Center(
                  child: Icon(
                    widget.recipe.category == 'Salgados' ? LucideIcons.utensils : LucideIcons.cake,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStatusChip(widget.recipe.status),
            const SizedBox(width: 12),
            Text(
              widget.recipe.category.toUpperCase(),
              style: const TextStyle(color: Color(0xFF5D8A66), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          widget.recipe.title,
          style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.bold, height: 1.1),
        ),
        if (widget.recipe.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            widget.recipe.description,
            style: TextStyle(color: Colors.grey[700], fontSize: 16, height: 1.6),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = const Color(0xFF42A5F5);
    String label = "NOVA";
    if (status == 'reservada') { color = const Color(0xFFC84C2C); label = "PREPARANDO"; }
    if (status == 'concluida') { color = const Color(0xFF5D8A66); label = "CONCLUÍDA"; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color, 
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }

  Widget _buildIngredientsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Ingredientes",
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...widget.recipe.ingredients.map((ing) {
          final hasStock = _stockStatus[ing.name] ?? false;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: null,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Icon(
                  hasStock ? LucideIcons.checkCircle2 : LucideIcons.shoppingCart, 
                  size: 20, 
                  color: hasStock ? const Color(0xFF5D8A66) : Colors.red[300]
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    ing.name, 
                    style: TextStyle(
                      fontWeight: FontWeight.w500, 
                      fontSize: 15,
                      color: hasStock ? Colors.black87 : Colors.grey[700]
                    )
                  ),
                ),
                Text(
                  ing.quantity,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC84C2C), fontSize: 15),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "MODO DE PREPARO",
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFB33E24),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.recipe.instructions,
          style: GoogleFonts.inter(
            fontSize: 16,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    if (_ytController == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "VÍDEO DA RECEITA",
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFB33E24),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: YoutubePlayer(
              controller: _ytController!,
              showVideoProgressIndicator: true,
              progressIndicatorColor: const Color(0xFFB33E24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionPanel() {
    if (widget.recipe.status == 'concluida') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          if (widget.recipe.status == 'nova')
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isUpdating ? null : () => _updateStatus('reservada'),
                icon: const Icon(LucideIcons.packageCheck, size: 20),
                label: const Text("PREPARAR", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: const Color(0xFFC84C2C),
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: const Color(0xFFC84C2C).withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          if (widget.recipe.status == 'reservada')
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUpdating ? null : () => _updateStatus('nova'),
                icon: const Icon(LucideIcons.xCircle, size: 20),
                label: const Text("CANCELAR", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: const Color(0xFFC84C2C).withOpacity(0.1),
                  foregroundColor: const Color(0xFFC84C2C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          if (widget.recipe.status != 'concluida') const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                final missingIngs = widget.recipe.ingredients.where((ing) => !(_stockStatus[ing.name] ?? false)).toList();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShoppingListScreen(
                      initialIngredients: missingIngs,
                      recipeTitle: widget.recipe.title,
                    ),
                  ),
                );
              },
              icon: const Icon(LucideIcons.shoppingCart, size: 20),
              label: const Text(
                "LISTA DE COMPRAS", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                textAlign: TextAlign.center,
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                backgroundColor: const Color(0xFFFAF7F2),
                foregroundColor: const Color(0xFFB33E24),
                elevation: 0,
                side: const BorderSide(color: Color(0xFFB33E24), width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
