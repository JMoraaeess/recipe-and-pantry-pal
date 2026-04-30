import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'pantry_screen.dart';
import 'add_recipe_screen.dart';
import 'recipes_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';
import 'premium_paywall_screen.dart';
import 'buy_credits_screen.dart';
import 'loading_recipe_screen.dart';
import 'shopping_list_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_handler/share_handler.dart';
import 'dart:async';

class MainHub extends StatefulWidget {
  const MainHub({super.key});

  @override
  State<MainHub> createState() => _MainHubState();
}

class _MainHubState extends State<MainHub> {
  int _currentIndex = 0;
  late PageController _pageController;
  final AuthService _authService = AuthService();
  StreamSubscription? _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _requestPermissions();
    _initSharingIntent();
  }

  Future<void> _initSharingIntent() async {
    final handler = ShareHandler.instance;
    
    // Captura inicial (se o app for aberto via compartilhamento)
    final initialMedia = await handler.getInitialSharedMedia();
    if (initialMedia != null && (initialMedia.content?.isNotEmpty ?? false)) {
      _handleSharedText(initialMedia.content!);
    }

    // Listener para o app em segundo plano
    _intentDataStreamSubscription = handler.sharedMediaStream.listen((SharedMedia media) {
      if (media.content?.isNotEmpty ?? false) {
        _handleSharedText(media.content!);
      }
    });
  }

  void _handleSharedText(String text) {
    // Extrai apenas a URL do texto compartilhado (ex: "Veja este vídeo: https://youtube...")
    final urlMatch = RegExp(r'(https?://[^\s]+)').firstMatch(text);
    final url = urlMatch?.group(0) ?? text;

    // Garantir que a navegação ocorra após o build estar pronto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Abre a tela de carregamento para a IA processar o link antes de mostrar o formulário
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoadingRecipeScreen(url: url)),
        );
      }
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    // Solicita permissões essenciais no início do hub
    await [
      Permission.camera,
      Permission.notification,
    ].request();
  }
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final List<Widget> screens = [
      const RecipesScreen(),
      const PantryScreen(),
      const ShoppingListScreen(),
    ];

    // Segurança máxima: garantir que o index esteja SEMPRE entre 0 e o máximo de abas
    final safeIndex = _currentIndex.clamp(0, screens.length - 1);
    
    if (_currentIndex != safeIndex) {
      print("[DEBUG] Corrigindo _currentIndex inválido: $_currentIndex para $safeIndex");
      // Opcional: atualizar o estado se estiver errado, mas o clamp já resolve o build
    }

    return Scaffold(
      drawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFB33E24),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Meu Cozinheiro",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Seu assistente de elite",
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildDrawerItem(LucideIcons.user, "Meu Perfil", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
            }),
            _buildDrawerItem(LucideIcons.settings, "Configurações", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen()));
            }),
            _buildDrawerItem(LucideIcons.helpCircle, "Ajuda & Suporte", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => HelpSupportScreen()));
            }),
            _buildDrawerItem(LucideIcons.info, "Sobre o App", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => AboutScreen()));
            }),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _buildDrawerItem(LucideIcons.crown, "Seja PRO", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPaywallScreen()));
            }, color: Colors.amber[700]),
            _buildDrawerItem(LucideIcons.gem, "Comprar Créditos", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyCreditsScreen()));
            }, color: const Color(0xFF5D8A66)),
            const Spacer(),
            Text(
              "v1.0.4-beta",
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildDrawerItem(LucideIcons.logOut, "Sair", () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Sair"),
                  content: const Text("Deseja realmente sair da sua conta?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCELAR")),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true), 
                      child: const Text("SAIR", style: TextStyle(color: Color(0xFFB33E24))),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _authService.signOut();
              }
            }, color: const Color(0xFFB33E24)),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: screens,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.all(
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFB33E24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: safeIndex,
            onDestinationSelected: (index) {
              _pageController.animateToPage(
                index, 
                duration: const Duration(milliseconds: 400), 
                curve: Curves.easeInOutQuart,
              );
            },
            backgroundColor: const Color(0xFFB33E24),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            indicatorColor: Colors.white.withOpacity(0.2),
            destinations: [
              NavigationDestination(
                icon: Icon(LucideIcons.bookOpen, color: Colors.white),
                selectedIcon: Icon(LucideIcons.bookOpen, color: Colors.white),
                label: 'Receitas',
              ),
              NavigationDestination(
                icon: Icon(LucideIcons.package, color: Colors.white),
                selectedIcon: Icon(LucideIcons.package, color: Colors.white),
                label: 'Despensa',
              ),
              NavigationDestination(
                icon: Icon(LucideIcons.shoppingCart, color: Colors.white),
                selectedIcon: Icon(LucideIcons.shoppingCart, color: Colors.white),
                label: 'Compras',
              ),
            ],
          ),
        ),
      ),

    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Theme.of(context).textTheme.bodyMedium?.color, size: 20),
      title: Text(title, style: GoogleFonts.inter(color: color ?? Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
