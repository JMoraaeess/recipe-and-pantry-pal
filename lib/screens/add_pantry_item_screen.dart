import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/pantry_service.dart';
import '../widgets/chef_hat_pattern.dart';

class AddPantryItemScreen extends StatefulWidget {
  const AddPantryItemScreen({super.key});

  @override
  State<AddPantryItemScreen> createState() => _AddPantryItemScreenState();
}

class _AddPantryItemScreenState extends State<AddPantryItemScreen> {
  final _pantryService = PantryService();
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  DateTime? _expiryDate;
  String _category = 'Mercearia';
  
  bool _isSaving = false;

  final List<String> _categories = [
    'Tudo', 'Carnes', 'Hortifruti', 'Mercearia', 'Laticínios', 'Bebidas'
  ];


  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFB33E24),
              onPrimary: Colors.white,
              onSurface: Color(0xFFB33E24),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _handleSave() async {
    if (_nameController.text.trim().isEmpty || _qtyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o nome e a quantidade.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _pantryService.upsertPantryItem(
        _nameController.text.trim(),
        _qtyController.text.trim(),
        category: _category,
        expiryDate: _expiryDate,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item adicionado à despensa!'), backgroundColor: Color(0xFF5D8A66)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: const Color(0xFFC84C2C)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  "Novo Item",
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

                      // Manual Form
                      _buildLabel('Nome do Item *'),
                      _buildInput(_nameController, 'Ex: Arroz Integral'),
                      const SizedBox(height: 16),
                      
                      _buildLabel('Quantidade *'),
                      _buildInput(_qtyController, 'Ex: 1kg, 500g, 2 unid'),
                      const SizedBox(height: 16),

                      _buildLabel('Data de Validade (Opcional)'),
                      GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFB33E24)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _expiryDate == null ? 'Selecionar data' : DateFormat('dd/MM/yyyy').format(_expiryDate!),
                                style: GoogleFonts.inter(
                                  color: _expiryDate == null ? Colors.grey : const Color(0xFFB33E24),
                                  fontSize: 15,
                                ),
                              ),
                              const Icon(LucideIcons.calendar, color: Color(0xFFB33E24), size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Categoria'),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categories.where((c) => c != 'Tudo').map((cat) {
                            final sel = _category == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: sel,
                                onSelected: (_) => setState(() => _category = cat),
                                selectedColor: const Color(0xFFB33E24),
                                backgroundColor: Colors.white,
                                labelStyle: GoogleFonts.inter(
                                  color: sel ? Colors.white : const Color(0xFFB33E24), 
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(color: const Color(0xFFB33E24), width: sel ? 1 : 0.5),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB33E24),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                          child: _isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text('SALVAR ITEM', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
                        ),
                      ),
                      const SizedBox(height: 100),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFFB33E24))),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
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
}
