import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import '../models/recipe.dart';
import '../services/premium_service.dart';
import '../services/network_service.dart';
import '../config.dart';

class RecipeService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _premiumService = PremiumService();

  RecipeService();

  Future<Recipe?> extractRecipe(String url, {String? manualText}) async {
    // Verificar conexão antes de tudo
    if (!await NetworkService.hasConnection()) {
      throw Exception("Sem conexão com a internet. Verifique sua rede e tente novamente.");
    }

    try {
      print("[RecipeService] Iniciando extração para: $url");
      
      String contentToAnalyze = manualText ?? "";
      String? thumbnailUrl;
      String sourceType = "site"; // Default

      // 1. Captura de Dados do YouTube (Metadados + Transcrição se possível)
      if (contentToAnalyze.isEmpty && url.isNotEmpty && (url.contains("youtube.com") || url.contains("youtu.be"))) {
        sourceType = "video";
        final yt = yt_explode.YoutubeExplode();
        try {
          // Normalizar link de Shorts ou outros formatos para obter o ID
          String? videoId;
          
          if (url.contains("/shorts/")) {
            final parts = url.split("/shorts/");
            if (parts.length > 1) {
              videoId = parts[1].split("?")[0].split("/")[0];
            }
          }
          
          videoId ??= yt_explode.VideoId.parseVideoId(url);
          
          if (videoId != null) {
            final video = await yt.videos.get(videoId);
            thumbnailUrl = video.thumbnails.highResUrl;
            
            String metadata = "TÍTULO: ${video.title}\n\nDESCRIÇÃO:\n${video.description}";
            
            String transcript = "";
            try {
              final manifest = await yt.videos.closedCaptions.getManifest(video.id);
              if (manifest.tracks.isNotEmpty) {
                final track = manifest.tracks.first;
                final captions = await yt.videos.closedCaptions.get(track);
                transcript = captions.captions.map((e) => e.text).join(" ");
              }
            } catch (e) {
              print("[RecipeService] Não foi possível obter transcrição: $e");
            }

            String commentsText = "";
            try {
              final comments = await yt.videos.comments.getComments(video);
              if (comments != null && comments.isNotEmpty) {
                final topComments = comments.take(10).map((c) => c.text).join("\n---\n");
                commentsText = "\n\nCOMENTÁRIOS:\n$topComments";
              }
            } catch (e) {
              print("[RecipeService] Erro ao buscar comentários: $e");
            }

            contentToAnalyze = "$metadata\n\nTRANSCRIÇÃO:\n$transcript$commentsText";

            if (contentToAnalyze.length < 50) {
              print("[RecipeService] Transcrição muito curta ou indisponível.");
            }
          }
        } finally {
          yt.close();
        }
      }

      // 2. Se for um link de SITE (não YouTube)
      if (contentToAnalyze.isEmpty && url.isNotEmpty && !url.contains("youtube")) {
        sourceType = "site";
        try {
          // Capturar Thumbnail do Site (Meta tags)
          final siteResponse = await http.get(Uri.parse(url));
          if (siteResponse.statusCode == 200) {
            final document = html.parse(siteResponse.body);
            final ogImage = document.querySelector('meta[property="og:image"]')?.attributes['content'];
            final twitterImage = document.querySelector('meta[name="twitter:image"]')?.attributes['content'];
            thumbnailUrl = ogImage ?? twitterImage;
          }

          // Usamos o Jina Reader para extrair conteúdo limpo do site
          final response = await http.get(Uri.parse("https://r.jina.ai/$url"));
          if (response.statusCode == 200) {
            contentToAnalyze = response.body;
          }
        } catch (e) {
          print("[RecipeService] Jina ou Scraping falhou: $e");
        }
      }

      if (contentToAnalyze.isEmpty) {
        throw Exception("Não foi possível ler o conteúdo do link. Tente copiar e colar o texto manualmente.");
      }

      // 3. Análise com IA via Supabase Edge Function
      print("[RecipeService] Chamando Edge Function para processar texto...");
      final response = await http.post(
        Uri.parse("${SupabaseConfig.url}/functions/v1/extract-recipe"),
        headers: {
          "Content-Type": "application/json",
          "apikey": SupabaseConfig.anonKey,
          "Authorization": "Bearer ${SupabaseConfig.anonKey}"
        },
        body: jsonEncode({
          "url": url,
          "text": contentToAnalyze,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['recipe'] != null) {
          final result = data['recipe'];
          return Recipe(
            id: '',
            userId: _auth.currentUser?.uid ?? '',
            title: result['title'] ?? '',
            description: result['description'] ?? '',
            category: result['category'] ?? 'Salgados',
            ingredients: (result['ingredients'] as List?)?.map((i) => Ingredient(
              name: i['name'] ?? '',
              quantity: i['quantity'] ?? '',
            )).toList() ?? [],
            instructions: result['instructions'] ?? '',
            status: 'nova',
            isFavorite: false,
            source: url,
            sourceType: sourceType,
            thumbnailUrl: thumbnailUrl,
          );
        } else if (data['error'] != null) {
          throw Exception(data['error']);
        }
      } else {
        throw Exception("Erro no servidor da IA: ${response.statusCode}");
      }
      return null;

    } catch (e) {
      print("[RecipeService] Erro geral: $e");
      rethrow;
    }
  }


  // Métodos de Banco de Dados (Firestore)
  Future<String> saveRecipe(Recipe recipe, String? sourceUrl) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("Usuário não autenticado");

    final docRef = await _db.collection('users').doc(uid).collection('recipes').add({
      ...recipe.toJson(),
      'source': sourceUrl,
      'status': 'nova',
      'is_favorite': false,
      'created_at': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Stream<List<Recipe>> getRecipes() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _db.collection('users')
        .doc(uid)
        .collection('recipes')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Recipe.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
}
