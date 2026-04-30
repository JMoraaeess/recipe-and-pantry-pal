import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsis;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _googleSignIn = gsis.GoogleSignIn.instance;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final gsis.GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) return null;

      final gsis.GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // No v7.0.0+, o accessToken deve ser solicitado via authorizationClient
      final authResult = await googleUser.authorizationClient.authorizeScopes(['email', 'profile']);
      final String? accessToken = authResult.accessToken;
      final String? idToken = googleAuth.idToken;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user != null) {
        // Pegar a foto em alta resolução se disponível
        String? photoUrl = user.photoURL;
        if (photoUrl != null && photoUrl.contains('s96-c')) {
          photoUrl = photoUrl.replaceAll('s96-c', 's400-c'); // Aumenta a qualidade
        }

        // Garantir que o perfil existe no Firestore
        // Verificar se é primeiro login (usuário novo)
        final userDoc = await _db.collection('users').doc(user.uid).get();
        final isNewUser = !userDoc.exists;

        final userData = <String, dynamic>{
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'photoUrl': photoUrl,
          'isPremium': false,
          'lastLogin': FieldValue.serverTimestamp(),
        };

        // Dar 5 diamantes grátis para novos usuários
        if (isNewUser) {
          userData['adTokens'] = 5;
          userData['createdAt'] = FieldValue.serverTimestamp();
        }

        await _db.collection('users').doc(user.uid).set(
          userData, SetOptions(merge: true),
        );
        
        // Atualizar também no objeto User do Firebase Auth para o Drawer ver
        if (photoUrl != null && photoUrl != user.photoURL) {
          await user.updatePhotoURL(photoUrl);
        }
      }

      return userCredential;
    } catch (e) {
      print("Erro no Google Sign-In: $e");
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required int age,
    required String gender,
    File? profilePhoto,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final user = credential.user;
    if (user != null) {
      String? photoUrl;

      // 1. Upload da foto se existir
      if (profilePhoto != null) {
        final ref = _storage.ref().child('users').child(user.uid).child('profile_photo.jpg');
        await ref.putFile(profilePhoto);
        photoUrl = await ref.getDownloadURL();
      }

      // 2. Atualizar perfil básico do Firebase Auth
      await user.updateDisplayName(name);
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      // 3. Salvar perfil detalhado no Firestore
      await _db.collection('users').doc(user.uid).set({
        'name': name,
        'email': email,
        'age': age,
        'gender': gender,
        'photoUrl': photoUrl,
        'isPremium': false,
        'adTokens': 5, // 5 diamantes grátis para novos usuários! 💎
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 4. Enviar e-mail de verificação
      await user.sendEmailVerification();
    }
    
    return credential;
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignora erro se não tinha sessão Google ativa
    }
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
  
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
