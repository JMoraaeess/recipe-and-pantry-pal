import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/pantry_item.dart';
import '../services/pantry_service.dart';
import '../services/emoji_service.dart';
import '../services/units_service.dart';
import '../services/premium_service.dart';
import '../widgets/chef_hat_pattern.dart';
import 'add_pantry_item_screen.dart';
import 'buy_credits_screen.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final _pantryService = PantryService();
  final _unitsService = UnitsService();
  final _premiumService = PremiumService();
  String? _selectedCategory;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Tudo', 'icon': LucideIcons.layoutGrid},
    {'name': 'Carnes', 'icon': LucideIcons.beef},
    {'name': 'Hortifruti', 'icon': LucideIcons.apple},
    {'name': 'Mercearia', 'icon': LucideIcons.package},
    {'name': 'Laticínios', 'icon': LucideIcons.milk},
    {'name': 'Bebidas', 'icon': LucideIcons.cupSoda},
  ];

  void _showItemDialog({PantryItem? item}) {
    final nameController = TextEditingController(text: item?.name);
    final quantityController = TextEditingController(text: item?.quantity);
    String category = item?.category ?? _selectedCategory ?? 'Mercearia';
    DateTime? expiryDate = item?.expiryDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? "Novo Item" : "Editar Item", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Nome (ex: Arroz)"),
                  autofocus: item == null,
                ),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: "Quantidade (ex: 1kg, 500g)"),
                ),
                DropdownButtonFormField<String>(
                  value: category,
                  items: ["Hortifruti", "Mercearia", "Laticínios", "Bebidas", "Temperos", "Carnes", "Outros"]
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => category = v!),
                  decoration: const InputDecoration(labelText: "Categoria"),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Vencimento", style: TextStyle(fontSize: 14)),
                  subtitle: Text(expiryDate == null ? "Não definido" : DateFormat('dd/MM/yyyy').format(expiryDate!)),
                  trailing: const Icon(LucideIcons.calendar, size: 20),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: expiryDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (picked != null) setDialogState(() => expiryDate = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && quantityController.text.isNotEmpty) {
                  await _pantryService.upsertPantryItem(
                    nameController.text.trim(),
                    quantityController.text.trim(),
                    category: category,
                    expiryDate: expiryDate,
                  );
                  if (mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB33E24), foregroundColor: Colors.white),
              child: const Text("SALVAR"),
            ),
          ],
        ),
      ),
    );
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
                            hintText: "Buscar itens...",
                            hintStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                          ),
                          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                        )
                      : Text(
                          _selectedCategory ?? "Minha Despensa",
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
                        "O que temos em estoque?",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          fontSize: 22,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                StreamBuilder<List<PantryItem>>(
                  stream: _pantryService.getPantryStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                    }
                    
                    final allItems = snapshot.data ?? [];
                    final filteredItems = allItems.where((i) {
                      final matchesCategory = (_selectedCategory == null || _selectedCategory == "Tudo")
                          ? true
                          : i.category == _selectedCategory;
                      final matchesSearch = i.name.toLowerCase().contains(_searchQuery);
                      return matchesCategory && matchesSearch;
                    }).toList();

                    if (_selectedCategory == null && !_isSearching) {
                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildAddItemCard(isDark),
                            _buildCategoryGrid(isDark),
                          ]),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      sliver: _buildItemList(filteredItems, isDark),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildAddItemCard(bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddPantryItemScreen()),
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
                  child: const Icon(LucideIcons.package, size: 120, color: Colors.white),
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
                          'Novo Item',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Adicione ingredientes que você comprou',
                          style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
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
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
              boxShadow: isDark ? [] : [
                BoxShadow(
                  color: const Color(0xFFB33E24).withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
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
                        child: Icon(cat['icon'], size: 28, color: Theme.of(context).colorScheme.primary),
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

  Widget _buildItemList(List<PantryItem> items, bool isDark) {
    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: 16),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(LucideIcons.apple, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text("Nenhum item em ${_selectedCategory!.toLowerCase()}", 
                  style: const TextStyle(color: Colors.grey)),
              ],
            ),
          )
        else
          ...items.map((item) => _buildItemCard(item, isDark)).toList(),
      ]),
    );
  }

  Widget _buildItemCard(PantryItem item, bool isDark) {
    final available = item.numericValue - item.reservedValue;
    final hasReservation = item.reservedValue > 0;
    
    bool isExpired = false;
    bool isCloseToExpiry = false;
    if (item.expiryDate != null) {
      isExpired = item.expiryDate!.isBefore(DateTime.now());
      isCloseToExpiry = !isExpired && item.expiryDate!.isBefore(DateTime.now().add(const Duration(days: 7)));
    }

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      onDismissed: (_) => _pantryService.deleteItem(item.id),
      child: GestureDetector(
        onTap: () => _showItemDialog(item: item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
            boxShadow: isDark ? [] : [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFB33E24).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    EmojiService.getEmoji(item.name),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name[0].toUpperCase() + item.name.substring(1),
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.expiryDate != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isExpired 
                                  ? (isDark ? Colors.red.withOpacity(0.2) : Colors.red[50]) 
                                  : (isCloseToExpiry 
                                      ? (isDark ? Colors.amber.withOpacity(0.2) : Colors.amber[50]) 
                                      : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100])),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isExpired 
                                    ? (isDark ? Colors.red.withOpacity(0.5) : Colors.red[100]!) 
                                    : (isCloseToExpiry 
                                        ? (isDark ? Colors.amber.withOpacity(0.5) : Colors.amber[100]!) 
                                        : (isDark ? Colors.white10 : Colors.grey[200]!))
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.calendar, size: 10, color: isExpired ? Colors.red : (isCloseToExpiry ? Colors.amber[800] : (isDark ? Colors.white38 : Colors.grey))),
                                const SizedBox(width: 4),
                                Text(
                                  isExpired ? "Vencido" : DateFormat('dd/MM').format(item.expiryDate!),
                                  style: TextStyle(
                                    fontSize: 10, 
                                    fontWeight: FontWeight.bold,
                                    color: isExpired ? Colors.red : (isCloseToExpiry ? (isDark ? Colors.amber[300] : Colors.amber[800]) : (isDark ? Colors.white70 : Colors.grey[700])),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildStatusBadge(
                          "Total: ${_unitsService.formatQuantity(item.numericValue, item.unit)}", 
                          isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200]!, 
                          isDark ? Colors.white70 : Colors.grey[700]!
                        ),
                        if (hasReservation) ...[
                          _buildStatusBadge(
                            "Reservado: ${_unitsService.formatQuantity(item.reservedValue, item.unit)}", 
                            isDark ? Colors.amber.withOpacity(0.1) : Colors.amber[50]!, 
                            isDark ? Colors.amber[300]! : Colors.amber[800]!
                          ),
                          _buildStatusBadge(
                            "Livre: ${_unitsService.formatQuantity(available < 0 ? 0 : available, item.unit)}", 
                            isDark ? const Color(0xFF5D8A66).withOpacity(0.1) : const Color(0xFF5D8A66).withOpacity(0.1), 
                            isDark ? const Color(0xFF7CAF89) : const Color(0xFF5D8A66)
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 16, color: isDark ? Colors.white30 : Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }
}
