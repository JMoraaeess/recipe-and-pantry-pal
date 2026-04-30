import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';

class EditRecipeScreen extends StatefulWidget {
  final Recipe recipe;

  const EditRecipeScreen({super.key, required this.recipe});

  @override
  State<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends State<EditRecipeScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _instructionsController;
  late TextEditingController _categoryController;
  late List<Ingredient> _ingredients;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.recipe.title);
    _descController = TextEditingController(text: widget.recipe.description);
    _instructionsController = TextEditingController(text: widget.recipe.instructions);
    _categoryController = TextEditingController(text: widget.recipe.category);
    _ingredients = List.from(widget.recipe.ingredients);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _instructionsController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_titleController.text.isEmpty) return;
    
    setState(() => _isSaving = true);
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      await _db.collection('users')
          .doc(uid)
          .collection('recipes')
          .doc(widget.recipe.id)
          .update({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'category': _categoryController.text.trim(),
        'ingredients': _ingredients.map((e) => e.toJson()).toList(),
        'instructions': _instructionsController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Receita atualizada! 👨‍🍳"), backgroundColor: Color(0xFF5D8A66)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar: $e"), backgroundColor: const Color(0xFFC84C2C)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: Text("Editar Receita", style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: _isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC84C2C))) 
              : const Icon(LucideIcons.check),
            onPressed: _isSaving ? null : _handleSave,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(_titleController, "Título da Receita", LucideIcons.book),
            const SizedBox(height: 16),
            _buildTextField(_categoryController, "Categoria (ex: Doces, Carnes)", LucideIcons.tag),
            const SizedBox(height: 16),
            _buildTextField(_descController, "Descrição Curta", LucideIcons.fileText),
            const SizedBox(height: 24),
            
            Text("Ingredientes", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildIngredientsSection(),
            
            const SizedBox(height: 24),
            Text("Modo de Preparo", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _instructionsController,
              maxLines: 8,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFC84C2C), size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildIngredientsSection() {
    return Column(
      children: [
        ..._ingredients.asMap().entries.map((entry) {
          int idx = entry.key;
          Ingredient ing = entry.value;
          return Card(
            elevation: 0,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              dense: true,
              title: Text(ing.name),
              subtitle: Text(ing.quantity),
              trailing: IconButton(
                icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                onPressed: () => setState(() => _ingredients.removeAt(idx)),
              ),
            ),
          );
        }).toList(),
        OutlinedButton.icon(
          onPressed: _showAddIngredientDialog,
          icon: const Icon(LucideIcons.plus, size: 16),
          label: const Text("ADICIONAR INGREDIENTE"),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFC84C2C),
          ),
        ),
      ],
    );
  }

  void _showAddIngredientDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Novo Ingrediente", style: GoogleFonts.playfairDisplay()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nome (ex: Farinha)"),
              autofocus: true,
            ),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: "Quantidade (ex: 500g, 2 xícaras)"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && quantityController.text.isNotEmpty) {
                setState(() {
                  _ingredients.add(Ingredient(
                    name: nameController.text.trim(),
                    quantity: quantityController.text.trim(),
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text("ADICIONAR"),
          ),
        ],
      ),
    );
  }
}
