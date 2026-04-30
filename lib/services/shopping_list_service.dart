import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShoppingListService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference get _listRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("Usuário não autenticado");
    return _db.collection('users').doc(uid).collection('shopping_list');
  }

  Future<void> saveList(List<Map<String, dynamic>> items) async {
    final batch = _db.batch();
    
    // Limpar lista atual
    final current = await _listRef.get();
    for (var doc in current.docs) {
      batch.delete(doc.reference);
    }

    // Adicionar novos itens
    for (var item in items) {
      batch.set(_listRef.doc(), {
        'name': item['name'],
        'quantity': item['quantity'],
        'checked': item['checked'],
        'recipe': item['recipe'],
        'updated_at': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> getListStream() {
    return _listRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'],
          'quantity': data['quantity'],
          'checked': data['checked'] ?? false,
          'recipe': data['recipe'],
        };
      }).toList();
    });
  }

  Future<List<Map<String, dynamic>>> getList() async {
    final snapshot = await _listRef.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'name': data['name'],
        'quantity': data['quantity'],
        'checked': data['checked'] ?? false,
        'recipe': data['recipe'],
      };
    }).toList();
  }
}
