import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/premium_service.dart';

class BuyCreditsScreen extends StatefulWidget {
  const BuyCreditsScreen({super.key});

  @override
  State<BuyCreditsScreen> createState() => _BuyCreditsScreenState();
}

class _BuyCreditsScreenState extends State<BuyCreditsScreen> with SingleTickerProviderStateMixin {
  final _premiumService = PremiumService();
  bool _isProcessing = false;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _buyPackage() async {
    setState(() => _isProcessing = true);
    // Simula o tempo de processamento da loja (Google Play)
    await Future.delayed(const Duration(seconds: 2));
    
    await _premiumService.buyAdTokens(10);
    
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Compra concluída! Você recebeu 10 diamantes. 💎"),
          backgroundColor: Color(0xFF5D8A66),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12100F),
      body: Stack(
        children: [
          // Fundo com brilho animado
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Positioned(
                top: -80,
                left: -80,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D8A66).withOpacity(0.08 + (_glowController.value * 0.12)),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      // Saldo atual
                      StreamBuilder<int>(
                        stream: _premiumService.adTokensStream(),
                        builder: (context, snapshot) {
                          final tokens = snapshot.data ?? 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.gem, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Saldo: $tokens',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        // Diamante animado
                        AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, child) {
                            return Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5D8A66).withOpacity(0.15 + (_glowController.value * 0.1)),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF5D8A66).withOpacity(0.15 + (_glowController.value * 0.15)),
                                    blurRadius: 30 + (_glowController.value * 20),
                                    spreadRadius: 5 + (_glowController.value * 10),
                                  )
                                ],
                              ),
                              child: const Text('💎', style: TextStyle(fontSize: 60)),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        Text(
                          "Recarregar Diamantes",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Cada diamante permite extrair 1 receita usando Inteligência Artificial.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: Colors.white60,
                          ),
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // Card do pacote único
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF1A1817),
                                const Color(0xFF1A1817).withOpacity(0.95),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFF5D8A66),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF5D8A66).withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                // Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5D8A66),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "PACOTE ÚNICO",
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                
                                // Diamantes
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('💎', style: TextStyle(fontSize: 36)),
                                    const SizedBox(width: 12),
                                    Text(
                                      "10",
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 48,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Diamantes",
                                      style: GoogleFonts.inter(
                                        color: Colors.white70,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                
                                // Info
                                Text(
                                  "Extraia até 10 receitas de vídeos ou links",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: Colors.white54,
                                    fontSize: 14,
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Preço e botão
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isProcessing ? null : _buyPackage,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF5D8A66),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 4,
                                      shadowColor: const Color(0xFF5D8A66).withOpacity(0.4),
                                    ),
                                    child: Text(
                                      "COMPRAR POR R\$ 4,90",
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Opção de Ganhar Grátis (Vídeo)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.playCircle, color: Color(0xFF42A5F5), size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Ganhe Grátis",
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          "Assista um vídeo curto e ganhe 1 diamante",
                                          style: GoogleFonts.inter(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    // Simula o anúncio por enquanto
                                    setState(() => _isProcessing = true);
                                    await Future.delayed(const Duration(seconds: 3));
                                    try {
                                      await _premiumService.addAdToken();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("Parabéns! Você ganhou 1 diamante. 💎"),
                                            backgroundColor: Color(0xFF42A5F5),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("Limite diário de vídeos atingido. Tente amanhã!"),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (mounted) setState(() => _isProcessing = false);
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF42A5F5)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text(
                                    "ASSISTIR VÍDEO",
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF42A5F5),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Info extras
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow(LucideIcons.shield, "Compra segura via Google Play"),
                              const SizedBox(height: 12),
                              _buildInfoRow(LucideIcons.infinity, "Diamantes não expiram"),
                              const SizedBox(height: 12),
                              _buildInfoRow(LucideIcons.zap, "Crédito instantâneo na sua conta"),
                            ],
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
          
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF5D8A66)),
                    const SizedBox(height: 16),
                    Text(
                      "Processando compra...",
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 18),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
        ),
      ],
    );
  }
}
