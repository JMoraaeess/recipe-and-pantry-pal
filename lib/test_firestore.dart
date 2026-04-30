
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  final auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;
  
  final user = auth.currentUser;
  if (user == null) {
    print("ERRO: Nenhum usuário logado");
    return;
  }
  
  print("Usuário logado: ${user.uid}");
  
  final pantryRef = db.collection('users').doc(user.uid).collection('pantry');
  
  print("Tentando adicionar item de teste...");
  try {
    await pantryRef.add({
      'name': 'Teste Script',
      'quantity': '1',
      'category': 'Mercearia',
      'createdAt': FieldValue.serverTimestamp(),
    });
    print("SUCESSO: Item adicionado!");
  } catch (e) {
    print("ERRO ao adicionar item: $e");
  }
  
  final snapshot = await pantryRef.get();
  print("Total de itens na despensa: ${snapshot.docs.length}");
  for (var doc in snapshot.docs) {
    print("- ${doc['name']}");
  }
}
