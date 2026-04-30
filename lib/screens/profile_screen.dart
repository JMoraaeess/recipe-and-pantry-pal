import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  bool _isLoading = false;
  final user = FirebaseAuth.instance.currentUser;
  File? _imageFile;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _nameController.text = data['name'] ?? user!.displayName ?? "";
        _ageController.text = (data['age'] ?? "").toString();
      });
    }
  }

  Future<void> _pickImage() async {
    // Solicitar permissões antes de abrir a câmera/galeria
    final cameraStatus = await Permission.camera.request();
    final storageStatus = Platform.isAndroid 
      ? await Permission.photos.request() 
      : await Permission.photos.request();

    if (cameraStatus.isGranted || storageStatus.isGranted) {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permissão de câmera/galeria necessária."), backgroundColor: Colors.orange),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      // Nota: O upload real para o Storage exigiria mais código, 
      // aqui estamos atualizando os metadados principais.
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text) ?? 0,
      });
      if (user != null) {
        await user!.updateDisplayName(_nameController.text.trim());
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Perfil atualizado com sucesso!"), backgroundColor: Color(0xFF5D8A66)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao atualizar perfil."), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Meu Perfil")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFFE8E2D8),
                      backgroundImage: _imageFile != null 
                        ? FileImage(_imageFile!) 
                        : (user?.photoURL != null ? NetworkImage(user!.photoURL!) : null),
                      child: (_imageFile == null && user?.photoURL == null) 
                        ? const Icon(LucideIcons.user, size: 50, color: Color(0xFFC84C2C)) 
                        : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Color(0xFFC84C2C), shape: BoxShape.circle),
                        child: const Icon(LucideIcons.camera, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildField("Nome Completo", _nameController, LucideIcons.user),
            const SizedBox(height: 16),
            _buildField("Idade", _ageController, LucideIcons.calendar, isNumber: true),
            const SizedBox(height: 16),
            _buildReadOnlyField("E-mail", user?.email ?? "", LucideIcons.mail),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("SALVAR ALTERAÇÕES"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFC84C2C), size: 18),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8E2D8))),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return TextField(
      controller: TextEditingController(text: value),
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey, size: 18),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
