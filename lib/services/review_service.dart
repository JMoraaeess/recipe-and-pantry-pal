import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewService {
  static final InAppReview _inAppReview = InAppReview.instance;
  static const String _keyLaunchCount = 'review_launch_count';
  static const String _keyReviewShown = 'review_shown_version';
  
  // Limiares para exibir a avaliação
  static const int _launchThreshold = 5;

  static Future<void> checkAndRequestReview() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Incrementar contador de aberturas
    int launchCount = prefs.getInt(_keyLaunchCount) ?? 0;
    launchCount++;
    await prefs.setInt(_keyLaunchCount, launchCount);

    bool reviewShown = prefs.getBool(_keyReviewShown) ?? false;

    // Se já passou do limite e ainda não mostramos nesta instalação
    if (launchCount >= _launchThreshold && !reviewShown) {
      if (await _inAppReview.isAvailable()) {
        // Aguarda um pouco antes de mostrar para não interromper o splash
        await Future.delayed(const Duration(seconds: 3));
        await _inAppReview.requestReview();
        await prefs.setBool(_keyReviewShown, true);
      }
    }
  }

  // Método para forçar a abertura da loja caso o requestReview não funcione ou queira um botão manual
  static Future<void> openStoreListing() async {
    await _inAppReview.openStoreListing(
      appStoreId: '...', // ID da App Store para iOS
      microsoftStoreId: '...', // ID para Windows
    );
  }
}
