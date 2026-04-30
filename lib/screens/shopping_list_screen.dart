import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/recipe_service.dart';
import '../services/pantry_service.dart';
import '../services/units_service.dart';
import '../services/shopping_list_service.dart';
import '../services/premium_service.dart';
import '../models/pantry_item.dart';
import '../models/recipe.dart';
import 'buy_credits_screen.dart';

class ShoppingListScreen extends StatefulWidget {
  final List<Ingredient>? initialIngredients;
  final String? recipeTitle;

  const ShoppingListScreen({super.key, this.initialIngredients, this.recipeTitle});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final List<Map<String, dynamic>> _items = [];
  final _recipeService = RecipeService();
  final _pantryService = PantryService();
  final _unitsService = UnitsService();
  final _shoppingListService = ShoppingListService();
  final _premiumService = PremiumService();
  bool _isSavingToPantry = false;
  bool _isLoading = true;
  Set<String> _pantryItemNames = {};
  String _searchQuery = "";
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      final pantry = await _pantryService.getPantryItems();
      _pantryItemNames = pantry.map((p) => p.name.toLowerCase()).toSet();
      final savedItems = await _shoppingListService.getList();
      setState(() {
        _items.clear();
        _items.addAll(savedItems);
        if (widget.initialIngredients != null) {
          for (var ing in widget.initialIngredients!) {
            _addItemToList(ing.name, ing.quantity, recipeName: widget.recipeTitle, silent: true);
          }
        }
        _isLoading = false;
      });
      _persistList();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _persistList() async {
    await _shoppingListService.saveList(_items);
  }

  String _performCleaning(String name) {
    String cleaned = name.toLowerCase()
        .split(' para farofa')[0]
        .split('(para farofa)')[0]
        .split(' para salada')[0]
        .split(' para decorar')[0]
        .split(' a gosto')[0]
        .split(' para ')[0]
        .split(' gelada')[0]
        .split(' gelado')[0]
        .replaceFirst(RegExp(r'^\d+\s+'), '')
        .trim();
    
    if (cleaned.isEmpty) cleaned = name.trim();
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  Future<void> _importFromRecipe() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFFFAF7F2),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Icon(LucideIcons.chefHat, color: Color(0xFFB33E24)),
                  const SizedBox(width: 12),
                  Text("Importar de Receita", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<List<Recipe>>(
                stream: _recipeService.getRecipes(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final allRecipes = snapshot.data!;
                  final importedRecipes = _items.map((i) => i['recipe']).toSet();
                  final recipes = allRecipes.where((r) => !importedRecipes.contains(r.title)).toList();

                  if (recipes.isEmpty) {
                    return Center(child: Text("Nenhuma receita disponível.", style: GoogleFonts.inter(color: Colors.grey)));
                  }

                  return ListView.builder(
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      final r = recipes[index];
                      return ListTile(
                        title: Text(r.title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        subtitle: Text("${r.ingredients.length} ingredientes"),
                        onTap: () {
                          Navigator.pop(context);
                          _processImportedRecipe(r);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processImportedRecipe(Recipe recipe) async {
    final List<Map<String, dynamic>> newItems = [];
    for (var ing in recipe.ingredients) {
      newItems.add({'name': ing.name, 'quantity': ing.quantity, 'checked': false});
    }

    setState(() {
      for (var item in newItems) {
        _addItemToList(item['name'], item['quantity'], recipeName: recipe.title, silent: true);
      }
    });
    _persistList();
  }

  void _addItemToList(String name, String quantity, {String? recipeName, bool silent = false}) {
    String cleanedName = _performCleaning(name);
    int index = _items.indexWhere((item) => item['name'].toLowerCase() == cleanedName.toLowerCase());

    if (index == -1) {
      _items.add({
        'name': cleanedName,
        'quantity': quantity,
        'checked': false,
        'recipe': recipeName,
      });
      if (!silent) {
        setState(() {});
        _persistList();
      }
    }
  }

  Future<void> _saveCheckedToPantry() async {
    final checkedItems = _items.where((item) => item['checked'] == true).toList();
    if (checkedItems.isEmpty) return;

    setState(() => _isSavingToPantry = true);
    try {
      for (var item in checkedItems) {
        await _pantryService.upsertPantryItem(
          item['name'], 
          item['quantity'] ?? '1 un',
          expiryDate: item['expiryDate'],
        );
      }
      
      setState(() {
        _items.removeWhere((item) => item['checked'] == true);
        _loadAllData(); 
      });
      _persistList();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Itens adicionados à despensa!"), backgroundColor: Color(0xFF5D8A66)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingToPantry = false);
    }
  }

  Future<bool?> _showPantryDetailsDialog(Map<String, dynamic> item) async {
    final quantityController = TextEditingController(text: item['quantity']);
    DateTime? selectedDate = item['expiryDate'];
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(item['name'], style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: "Quantidade Final *",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onChanged: (v) => setDialogState(() {}),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) setDialogState(() => selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 20),
                      const SizedBox(width: 12),
                      Text(selectedDate == null ? "Validade (Opcional)" : "Vence em: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCELAR")),
            ElevatedButton(
              onPressed: quantityController.text.trim().isEmpty ? null : () {
                item['quantity'] = quantityController.text.trim();
                item['expiryDate'] = selectedDate;
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB33E24), foregroundColor: Colors.white),
              child: const Text("SALVAR"),
            ),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Novo Item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nome"), autofocus: true),
            TextField(controller: quantityController, decoration: const InputDecoration(labelText: "Quantidade")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                _addItemToList(nameController.text.trim(), quantityController.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB33E24), foregroundColor: Colors.white),
            child: const Text("ADICIONAR"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _items.where((item) {
      final name = item['name'].toString().toLowerCase();
      final recipe = (item['recipe'] ?? "").toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || recipe.contains(query);
    }).toList();

    bool canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Buscar na lista...",
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            )
          : Text("Lista de Compras", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: const Color(0xFFB33E24),
        foregroundColor: Colors.white,
        centerTitle: true,
        leadingWidth: 100,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canPop)
              IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                onPressed: () {
                  if (_isSearching) {
                    setState(() {
                      _isSearching = false;
                      _searchQuery = "";
                      _searchController.clear();
                    });
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            if (!canPop) const SizedBox(width: 12),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                fontSize: 12,
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
          if (!canPop)
            IconButton(
              icon: const Icon(LucideIcons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFB33E24)))
          : filteredItems.isEmpty
          ? Center(child: Text(_searchQuery.isEmpty ? "Sua lista está vazia" : "Nenhum item encontrado", style: GoogleFonts.inter(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                bool inPantry = _pantryItemNames.contains(item['name'].toLowerCase());
                bool isChecked = item['checked'] ?? false;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: IconButton(
                      icon: Icon(
                        isChecked ? LucideIcons.shoppingCart : LucideIcons.circle,
                        color: isChecked ? const Color(0xFF5D8A66) : Colors.grey[400],
                      ),
                      onPressed: () async {
                        if (!isChecked) {
                          final saved = await _showPantryDetailsDialog(item);
                          if (saved == true) {
                            setState(() => item['checked'] = true);
                            _persistList();
                          }
                        } else {
                          setState(() => item['checked'] = false);
                          _persistList();
                        }
                      },
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['name'],
                            style: GoogleFonts.inter(
                              decoration: isChecked ? TextDecoration.lineThrough : null,
                              color: isChecked ? Colors.grey : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (inPantry)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF5D8A66).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text("NA DESPENSA", style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF5D8A66), fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    subtitle: item['recipe'] != null
                        ? Text(item['recipe'], style: GoogleFonts.inter(fontSize: 11, color: isChecked ? Colors.grey[400] : const Color(0xFFB33E24).withOpacity(0.7), fontStyle: FontStyle.italic))
                        : null,
                    trailing: IconButton(
                      icon: Icon(LucideIcons.trash2, color: Colors.red[300], size: 20),
                      onPressed: () {
                        setState(() => _items.remove(item));
                        _persistList();
                      },
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 20,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBottomAction(LucideIcons.packagePlus, "Salvar na\nDespensa", const Color(0xFF5D8A66), _saveCheckedToPantry),
              _buildBottomAction(LucideIcons.bookOpen, "Importar\nReceitas", const Color(0xFFB33E24), _importFromRecipe),
              _buildBottomAction(LucideIcons.plus, "Novo\nIngrediente", const Color(0xFFB33E24), _addItem),
              _buildBottomAction(LucideIcons.trash2, "Limpar\nTudo", Colors.grey[600]!, () {
                setState(() => _items.clear());
                _persistList();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            label, 
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 9, color: color, fontWeight: FontWeight.bold, height: 1.1),
          ),
        ],
      ),
    );
  }
}
