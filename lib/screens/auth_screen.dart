import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/auth_service.dart';
import 'main_hub.dart';
import 'complete_profile_screen.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  
  String _gender = "Masculino";
  File? _imageFile;
  final _authService = AuthService();
  final _picker = ImagePicker();
  
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // MAPEAMENTO DE ERROS PARA PORTUGUÊS
  String _mapErrorToPortuguese(String code) {
    switch (code) {
      case 'user-not-found': 
      case 'invalid-credential':
        return 'E-mail não encontrado ou senha incorreta. Por favor, cadastre-se se for novo por aqui!';
      case 'wrong-password': return 'Senha incorreta. Tente novamente.';
      case 'invalid-email': return 'E-mail inválido.';
      case 'user-disabled': return 'Esta conta foi desativada.';
      case 'email-already-in-use': return 'Este e-mail já está em uso.';
      case 'operation-not-allowed': return 'Login por e-mail desativado no console.';
      case 'weak-password': return 'A senha escolhida é muito fraca.';
      case 'too-many-requests': return 'Muitas tentativas. Tente mais tarde.';
      default: return 'Erro: $code. Tente novamente.';
    }
  }

  // MEDIDOR DE FORÇA DA SENHA
  Map<String, dynamic> _getPasswordStrength(String password) {
    if (password.isEmpty) return {'label': '', 'color': Colors.transparent, 'percent': 0.0};
    if (password.length < 6) return {'label': 'Muito Curta', 'color': Colors.red, 'percent': 0.2};
    
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$&*~]').hasMatch(password)) score++;

    if (score <= 1) return {'label': 'Ruim 🔴', 'color': Colors.red, 'percent': 0.4};
    if (score == 2) return {'label': 'Boa 🟡', 'color': Colors.orange, 'percent': 0.7};
    return {'label': 'Ótima! 🟢', 'color': Colors.green, 'percent': 1.0};
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Senha obrigatória";
    if (value.length < 8) return "Mínimo 8 caracteres";
    return null;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_tabController.index == 1 && _passwordController.text != _confirmPasswordController.text) {
      _showError("As senhas não coincidem");
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      if (_tabController.index == 0) {
        await _authService.signIn(_emailController.text.trim(), _passwordController.text.trim());
      } else {
        /* Removido daqui, agora é após onboarding */
        /* if (!_acceptedTerms) {
          _showError("Você precisa aceitar os Termos de Uso e Privacidade.");
          return;
        } */
        await _authService.signUp(
          email: _emailController.text.trim(), 
          password: _passwordController.text.trim(), 
          name: _nameController.text.trim(),
          age: int.tryParse(_ageController.text) ?? 0,
          gender: _gender,
          profilePhoto: _imageFile,
        );
      }
      _navigateToMain();
    } on FirebaseAuthException catch (e) {
      _showError(_mapErrorToPortuguese(e.code));
    } catch (e) {
      _showError("Erro: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final credential = await _authService.signInWithGoogle();
      if (credential != null && credential.user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).get();
        if (mounted) {
          if (doc.exists && doc.data() != null && doc.data()!.containsKey('age')) {
            _navigateToMain();
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const CompleteProfileScreen()),
            );
          }
        }
      }
    } catch (e) {
      _showError("Erro ao entrar com Google: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.isEmpty) {
      _showError("Digite seu e-mail para receber o link de recuperação.");
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.sendPasswordResetEmail(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Link de recuperação enviado! 📧"), backgroundColor: Color(0xFF5D8A66)),
        );
      }
    } catch (e) {
      _showError("Erro ao enviar: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToMain() => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MainHub()));
  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: const Color(0xFFC84C2C)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 32),
                    _buildAuthCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const NetworkImage("https://images.unsplash.com/photo-1556910103-1c02745aae4d?auto=format&fit=crop&q=60"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9), Theme.of(context).brightness == Brightness.dark ? BlendMode.darken : BlendMode.lighten),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 5),
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
        const SizedBox(height: 12),
        Text("Meu Cozinheiro", style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.headlineLarge?.color)),
      ],
    );
  }

  Widget _buildAuthCard() {
    final strength = _getPasswordStrength(_passwordController.text);
    final passwordsMatch = _passwordController.text == _confirmPasswordController.text && _confirmPasswordController.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFFC84C2C),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFC84C2C),
            tabs: const [Tab(text: "ENTRAR"), Tab(text: "CADASTRAR")],
            onTap: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              children: [
                if (_tabController.index == 1) ...[
                  _buildGoogleButton("Cadastrar com Google"),
                  const SizedBox(height: 16),
                  _buildSeparator(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildPhotoSelector(),
                      const SizedBox(width: 16),
                      Expanded(child: _buildField(_nameController, "Nome Completo", LucideIcons.user)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildField(_ageController, "Idade", LucideIcons.calendar, isNumber: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildGenderDropdown()),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                _buildField(_emailController, "E-mail", LucideIcons.mail),
                const SizedBox(height: 12),
                _buildField(
                  _passwordController, 
                  "Senha", 
                  LucideIcons.lock, 
                  isPassword: true, 
                  onChanged: (v) => setState(() {}),
                  validator: _tabController.index == 1 ? _validatePassword : null
                ),
                
                // INDICADOR DE FORÇA DA SENHA (CADASTRAR)
                if (_tabController.index == 1 && _passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: strength['percent'],
                      backgroundColor: Colors.grey[200],
                      color: strength['color'],
                      minHeight: 4,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(strength['label'], style: GoogleFonts.inter(fontSize: 10, color: strength['color'], fontWeight: FontWeight.bold)),
                  ),
                ],

                if (_tabController.index == 0) 
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _handleForgotPassword,
                      child: Text("Esqueci minha senha", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFC84C2C), fontWeight: FontWeight.w600)),
                    ),
                  ),

                if (_tabController.index == 1) ...[
                  const SizedBox(height: 12),
                  _buildField(
                    _confirmPasswordController, 
                    "Confirmar Senha", 
                    LucideIcons.checkCircle, 
                    isPassword: true,
                    onChanged: (v) => setState(() {}),
                  ),
                  // INDICADOR DE IGUALDADE
                  if (_confirmPasswordController.text.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        passwordsMatch ? "Senhas coincidem ✅" : "As senhas não são iguais ❌",
                        style: GoogleFonts.inter(fontSize: 10, color: passwordsMatch ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                    ),
                    ),
                ],

                /* Removido, movido para LegalConsentScreen */
                /* if (_tabController.index == 1) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _acceptedTerms,
                          onChanged: (v) => setState(() => _acceptedTerms = v!),
                          activeColor: const Color(0xFFC84C2C),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(color: Colors.grey, fontSize: 11),
                              children: [
                                const TextSpan(text: "Eu aceito os "),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
                                    child: const Text("Termos de Uso", style: TextStyle(color: Color(0xFFC84C2C), fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const TextSpan(text: " e a "),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen())),
                                    child: const Text("Política de Privacidade", style: TextStyle(color: Color(0xFFC84C2C), fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ], */
                
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_tabController.index == 0 ? "ENTRAR" : "CRIAR CONTA"),
                  ),
                ),
                
                if (_tabController.index == 0) ...[
                  const SizedBox(height: 16),
                  _buildSeparator(),
                  const SizedBox(height: 16),
                  _buildGoogleButton("Continuar com Google"),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeparator() => Row(children: [const Expanded(child: Divider()), Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text("OU", style: GoogleFonts.inter(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold))), const Expanded(child: Divider())]);

  Widget _buildGoogleButton(String label) => SizedBox(width: double.infinity, height: 50, child: OutlinedButton(onPressed: _isLoading ? null : _handleGoogleSignIn, style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Image.network("https://www.google.com/favicon.ico", height: 18, errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.chrome, size: 18)), const SizedBox(width: 12), Text(label, style: GoogleFonts.inter(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w600, fontSize: 14))])));

  Widget _buildPhotoSelector() => GestureDetector(onTap: _pickImage, child: Stack(children: [CircleAvatar(radius: 28, backgroundColor: Theme.of(context).scaffoldBackgroundColor, backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null, child: _imageFile == null ? const Icon(LucideIcons.camera, color: Color(0xFFC84C2C), size: 20) : null), Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Color(0xFFC84C2C), shape: BoxShape.circle), child: const Icon(LucideIcons.plus, color: Colors.white, size: 10)))]));

  Widget _buildGenderDropdown() => Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _gender, isExpanded: true, onChanged: (v) => setState(() => _gender = v!), items: ["Masculino", "Feminino", "Outro"].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList())));

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, bool isNumber = false, Function(String)? onChanged, String? Function(String?)? validator}) => TextFormField(controller: controller, obscureText: isPassword && !_showPassword, keyboardType: isNumber ? TextInputType.number : TextInputType.emailAddress, onChanged: onChanged, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: const Color(0xFFC84C2C), size: 18), suffixIcon: isPassword ? IconButton(icon: Icon(_showPassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 18), onPressed: () => setState(() => _showPassword = !_showPassword)) : null, filled: true, fillColor: Theme.of(context).scaffoldBackgroundColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), validator: validator ?? (value) => value!.isEmpty ? "Campo obrigatório" : null);
}
