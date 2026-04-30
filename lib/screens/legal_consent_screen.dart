import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';

class LegalConsentScreen extends StatefulWidget {
  final VoidCallback onAccepted;

  const LegalConsentScreen({super.key, required this.onAccepted});

  @override
  State<LegalConsentScreen> createState() => _LegalConsentScreenState();
}

class _LegalConsentScreenState extends State<LegalConsentScreen> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.shieldCheck, size: 80, color: Color(0xFFB33E24)),
              const SizedBox(height: 32),
              Text(
                'Quase lá!',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Para continuar usando o Meu Cozinheiro, precisamos que você leia e aceite nossos termos.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              
              // Links legais
              _buildLegalLink(
                icon: LucideIcons.fileText,
                title: 'Termos de Uso',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
              ),
              const SizedBox(height: 12),
              _buildLegalLink(
                icon: LucideIcons.lock,
                title: 'Política de Privacidade',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen())),
              ),
              
              const Spacer(),
              
              // Checkbox de aceite
              Row(
                children: [
                  Checkbox(
                    value: _accepted,
                    onChanged: (v) => setState(() => _accepted = v!),
                    activeColor: const Color(0xFFB33E24),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _accepted = !_accepted),
                      child: Text(
                        'Eu li e aceito os termos e a política de privacidade.',
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Botão Continuar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _accepted ? widget.onAccepted : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB33E24),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'CONCORDAR E CONTINUAR',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegalLink({required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.black45),
            const SizedBox(width: 12),
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black87)),
            const Spacer(),
            const Icon(LucideIcons.chevronRight, size: 16, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
