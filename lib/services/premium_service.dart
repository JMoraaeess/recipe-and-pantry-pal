import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PremiumService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  static const int freeRecipeLimit = 5; // Reduzido de 10 para 5
  static const int dailyAdLimit = 1; // Máximo de 1 anúncio por dia
  static const int maxDailyRecipes = 50; // Limite de Uso Justo (IA)

  // Stream para monitorar em tempo real se o usuário é premium
  Stream<bool> isPremiumStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(false);

    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return false;
      return (doc.data() as Map<String, dynamic>)['isPremium'] ?? false;
    });
  }

  // Versão Future para verificações pontuais
  Future<bool> isPremium() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return false;
    return (doc.data() as Map<String, dynamic>)['isPremium'] ?? false;
  }

  // Compra de pacotes de tokens (diamantes)
  Future<void> buyAdTokens(int amount) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    await _db.collection('users').doc(uid).set({
      'adTokens': FieldValue.increment(amount),
    }, SetOptions(merge: true));
  }

  // Verifica se o usuário atingiu o limite de receitas gratuitas
  Future<bool> canAddMoreRecipes() async {
    if (await isPremium()) return true;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    // Verificar se tem Tokens de Anúncio
    final userDoc = await _db.collection('users').doc(uid).get();
    final tokens = (userDoc.data() as Map<String, dynamic>)['adTokens'] ?? 0;
    if (tokens > 0) return true;

    final snapshot = await _db.collection('users').doc(uid).collection('recipes').count().get();
    return snapshot.count! < freeRecipeLimit;
  }

  Future<int> getAdTokens() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 0;
    final doc = await _db.collection('users').doc(uid).get();
    return (doc.data() as Map<String, dynamic>)['adTokens'] ?? 0;
  }

  Stream<int> adTokensStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return 0;
      return (doc.data() as Map<String, dynamic>)['adTokens'] ?? 0;
    });
  }

  Stream<int> dailyAdsCountStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return 0;
      final data = doc.data() as Map<String, dynamic>;
      final lastAdDate = (data['lastAdDate'] as Timestamp?)?.toDate();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      if (lastAdDate == null || DateTime(lastAdDate.year, lastAdDate.month, lastAdDate.day).isBefore(today)) {
        return 0;
      }
      return data['dailyAdsCount'] ?? 0;
    });
  }

  Stream<Map<String, dynamic>> premiumStatusStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value({'isPremium': false, 'tokens': 0, 'adsWatched': 0});

    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return {'isPremium': false, 'tokens': 0, 'adsWatched': 0};
      final data = doc.data() as Map<String, dynamic>;
      
      final lastAdDate = (data['lastAdDate'] as Timestamp?)?.toDate();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      int adsWatched = data['dailyAdsCount'] ?? 0;
      if (lastAdDate == null || DateTime(lastAdDate.year, lastAdDate.month, lastAdDate.day).isBefore(today)) {
        adsWatched = 0;
      }

      return {
        'isPremium': data['isPremium'] ?? false,
        'tokens': data['adTokens'] ?? 0,
        'adsWatched': adsWatched,
      };
    });
  }

  Future<void> addAdToken() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data() as Map<String, dynamic>;
    
    final lastAdDate = (data['lastAdDate'] as Timestamp?)?.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int dailyCount = data['dailyAdsCount'] ?? 0;

    // Resetar se for um novo dia
    if (lastAdDate == null || DateTime(lastAdDate.year, lastAdDate.month, lastAdDate.day).isBefore(today)) {
      dailyCount = 0;
    }

    if (dailyCount >= dailyAdLimit) {
      throw Exception("LIMITE_DIARIO_ADS");
    }

    await _db.collection('users').doc(uid).update({
      'adTokens': FieldValue.increment(1),
      'dailyAdsCount': dailyCount + 1,
      'lastAdDate': FieldValue.serverTimestamp(),
    });
  }

  Future<void> spendAdToken() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({
      'adTokens': FieldValue.increment(-1),
    });
  }

  // Método para "simular" ou processar a compra (depois integraremos com Stripe/RevenueCat)
  Future<void> upgradeToPremium() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('users').doc(uid).update({
      'isPremium': true,
      'premiumSince': FieldValue.serverTimestamp(),
    });
  }

  // Verifica se o usuário atingiu o limite de uso justo diário (50 receitas)
  Future<bool> canSaveRecipeToday() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return true;

    final data = doc.data()!;
    final lastRecipeDate = data['lastRecipeDate'] as String?;
    final dailyCount = data['dailyRecipeCount'] as int? ?? 0;
    
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Se mudou o dia, reseta o contador
    if (lastRecipeDate != today) {
      await _db.collection('users').doc(user.uid).update({
        'lastRecipeDate': today,
        'dailyRecipeCount': 0,
      });
      return true;
    }

    return dailyCount < maxDailyRecipes;
  }

  // Incrementa o contador de uso justo
  Future<void> incrementDailyRecipeCount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final today = DateTime.now().toIso8601String().split('T')[0];

    await _db.collection('users').doc(user.uid).update({
      'lastRecipeDate': today,
      'dailyRecipeCount': FieldValue.increment(1),
    });
  }
}
