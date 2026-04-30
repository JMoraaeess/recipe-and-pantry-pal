import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/auth_service.dart';
import '../main.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _canResendEmail = false;
  Timer? _timer;
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  void _startVerificationCheck() {
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkEmailVerified(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified({bool manual = false}) async {
    if (manual) setState(() => _isLoading = true);
    
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        _timer?.cancel();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AuthWrapper()),
          );
        }
      } else if (manual && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("E-mail ainda não verificado. Verifique sua caixa de entrada!"), backgroundColor: Color(0xFFC84C2C)),
        );
      }
    } catch (e) {
      print("Erro ao verificar e-mail: $e");
    } finally {
      if (manual && mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendVerificationEmail() async {
    try {
      await _authService.sendEmailVerification();
      setState(() => _canResendEmail = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Link reenviado com sucesso!"), backgroundColor: Color(0xFF5D8A66)),
      );
      await Future.delayed(const Duration(seconds: 30));
      if (mounted) setState(() => _canResendEmail = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao enviar: $e"), backgroundColor: const Color(0xFFC84C2C)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.mail, color: Color(0xFFC84C2C), size: 80),
              const SizedBox(height: 32),
              Text(
                "Verifique seu e-mail",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.headlineLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Enviamos um link de confirmação para o seu e-mail.\nPor favor, verifique sua caixa de entrada.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _checkEmailVerified(manual: true),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D8A66)),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("JÁ VERIFIQUEI O E-MAIL"),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: _canResendEmail ? _sendVerificationEmail : null,
                  icon: const Icon(LucideIcons.send),
                  label: Text(_canResendEmail ? "REENVIAR LINK" : "AGUARDE PARA REENVIAR"),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => _authService.signOut(),
                child: Text(
                  "Cancelar e voltar ao login",
                  style: GoogleFonts.inter(color: const Color(0xFFC84C2C), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
