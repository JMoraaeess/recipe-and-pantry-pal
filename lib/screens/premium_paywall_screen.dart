import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/premium_service.dart';

import '../services/ad_service.dart';

class PremiumPaywallScreen extends StatefulWidget {
  const PremiumPaywallScreen({super.key});

  @override
  State<PremiumPaywallScreen> createState() => _PremiumPaywallScreenState();
}

class _PremiumPaywallScreenState extends State<PremiumPaywallScreen> {
  final _adService = AdService();
  final _premiumService = PremiumService();

  @override
  void initState() {
    super.initState();
    _adService.loadRewardedAd(); // Pré-carrega o anúncio
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12100F),
      body: Stack(
        children: [
          // Fundo com brilho ou gradiente
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFFB33E24).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Ícone Premium
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB33E24).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.crown, size: 60, color: Color(0xFFE66A4E)),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          "Torne-se Premium",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Desbloqueie todo o poder do Meu Cozinheiro e leve sua cozinha para o próximo nível.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // Lista de Benefícios
                        _buildBenefit(
                          LucideIcons.infinity, 
                          "Receitas Ilimitadas", 
                          "Salve quantas receitas quiser, sem limites."
                        ),
                        _buildBenefit(
                          LucideIcons.video, 
                          "IA Multimodal (Shorts)", 
                          "Nossa IA assiste o vídeo para você e extrai cada detalhe."
                        ),
                        _buildBenefit(
                          LucideIcons.bell, 
                          "Alertas de Validade", 
                          "Nunca mais perca ingredientes na geladeira."
                        ),
                        _buildBenefit(
                          LucideIcons.zap, 
                          "Acesso Prioritário", 
                          "Use os modelos de IA mais potentes sem filas."
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // Card de Preço
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFB33E24), Color(0xFFC84C2C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFB33E24).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Plano Anual",
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "R\$",
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  Text(
                                    "59",
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 48,
                                    ),
                                  ),
                                  Text(
                                    ",90/ano",
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Apenas R\$ 4,99 por mês",
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        ElevatedButton(
                          onPressed: () async {
                            // Simular compra
                            await _premiumService.upgradeToPremium();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Parabéns! Você agora é um Cozinheiro Premium! 💎"),
                                  backgroundColor: Color(0xFF5D8A66),
                                ),
                              );
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFB33E24),
                            minimumSize: const Size(double.infinity, 64),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            "ASSINAR AGORA",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        OutlinedButton.icon(
                          onPressed: () async {
                            await _showRewardedAd();
                          },
                          icon: const Icon(LucideIcons.playCircle, color: Colors.white),
                          label: Text(
                            "ASSISTIR VÍDEO PATROCINADO",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 64),
                            side: const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Talvez mais tarde",
                            style: GoogleFonts.inter(color: Colors.white38),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRewardedAd() async {
    await _adService.showRewardedAd(
      onRewardEarned: () async {
        try {
          await _premiumService.addAdToken();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Vídeo assistido! Você ganhou 1 crédito para salvar sua receita. 🎁"),
                backgroundColor: Color(0xFF5D8A66),
              ),
            );
            Navigator.pop(context); // Fecha o paywall
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Limite diário atingido! Tente amanhã. 💎"),
                backgroundColor: Color(0xFFC84C2C),
              ),
            );
          }
        }
      },
      onAdFailed: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Vídeo não está pronto ainda. Tente em alguns segundos! ⏳"),
              backgroundColor: Color(0xFFC84C2C),
            ),
          );
        }
      },
      onAdClosed: () {},
    );
  }

  Widget _buildBenefit(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFE66A4E), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
