import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isAdLoading = false;

  // IDs Reais do Usuário
  final String _androidUnitId = 'ca-app-pub-9567296590905523/1716110808';
  
  String get rewardedUnitId {
    if (Platform.isAndroid) {
      return _androidUnitId;
    }
    return '';
  }

  void loadRewardedAd() {
    if (_isAdLoading) return;
    _isAdLoading = true;

    RewardedInterstitialAd.load(
      adUnitId: rewardedUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          _isAdLoading = false;
          print('Anúncio Intersticial Premiado Carregado! 🎁');
        },
        onAdFailedToLoad: (error) {
          _rewardedInterstitialAd = null;
          _isAdLoading = false;
          print('Falha ao carregar anúncio intersticial premiado: $error');
        },
      ),
    );
  }

  Future<void> showRewardedAd({
    required Function() onRewardEarned,
    required Function() onAdFailed,
    required Function() onAdClosed,
  }) async {
    if (_rewardedInterstitialAd == null) {
      print('Anúncio não está pronto ainda.');
      onAdFailed();
      loadRewardedAd();
      return;
    }

    _rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedInterstitialAd = null;
        onAdClosed();
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedInterstitialAd = null;
        onAdFailed();
        loadRewardedAd();
      },
    );

    await _rewardedInterstitialAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        onRewardEarned();
      },
    );
  }
}
