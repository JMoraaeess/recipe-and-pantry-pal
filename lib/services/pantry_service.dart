import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pantry_item.dart';
import '../models/recipe.dart';
import 'units_service.dart';
import 'notification_service.dart';

class PantryService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _unitsService = UnitsService();

  CollectionReference get _pantryRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("Usuário não autenticado");
    return _db.collection('users').doc(uid).collection('pantry');
  }

  Future<List<PantryItem>> getPantryItems() async {
    final snapshot = await _pantryRef.orderBy('name').get();
    return snapshot.docs
        .map((doc) => PantryItem.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
        .toList();
  }

  Stream<List<PantryItem>> getPantryStream() {
    return _pantryRef
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PantryItem.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
            .toList());
  }

  Future<void> upsertPantryItem(String name, String quantity, {String? category, DateTime? expiryDate}) async {
    final normalized = _unitsService.normalize(quantity, name);

    // No Firestore, procuramos pelo nome exato (ou similar se quisermos complicar, mas vamos manter simples)
    final existing = await _pantryRef
        .where('name', isEqualTo: name)
        .limit(1)
        .get();

    final data = {
      'name': name,
      'quantity': quantity,
      'numeric_value': normalized.value,
      'unit': normalized.unit,
      'category': category ?? 'Mercearia',
      'expiry_date': expiryDate?.toIso8601String().split('T')[0],
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (existing.docs.isNotEmpty) {
      await _pantryRef.doc(existing.docs.first.id).update(data);
    } else {
      await _pantryRef.add({
        ...data,
        'reserved_value': 0.0,
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> deleteItem(String id) async {
    await _pantryRef.doc(id).delete();
  }

  Future<void> reserveIngredients(List<Ingredient> ingredients) async {
    for (var ing in ingredients) {
      final normalizedIng = _unitsService.normalize(ing.quantity, ing.name);
      
      final existing = await _pantryRef.where('name', isEqualTo: ing.name).limit(1).get();

      if (existing.docs.isNotEmpty) {
        final doc = existing.docs.first;
        final currentReserved = (doc.get('reserved_value') ?? 0.0).toDouble();
        await _pantryRef.doc(doc.id).update({
          'reserved_value': currentReserved + normalizedIng.value,
        });
      }
    }
  }

  Future<void> unreserveIngredients(List<Ingredient> ingredients) async {
    for (var ing in ingredients) {
      final normalizedIng = _unitsService.normalize(ing.quantity, ing.name);
      
      final existing = await _pantryRef.where('name', isEqualTo: ing.name).limit(1).get();

      if (existing.docs.isNotEmpty) {
        final doc = existing.docs.first;
        final currentReserved = (doc.get('reserved_value') ?? 0.0).toDouble();
        double newReserved = currentReserved - normalizedIng.value;
        await _pantryRef.doc(doc.id).update({
          'reserved_value': newReserved < 0 ? 0 : newReserved,
        });
      }
    }
  }

  Future<void> consumeIngredients(List<Ingredient> ingredients) async {
    for (var ing in ingredients) {
      final normalizedIng = _unitsService.normalize(ing.quantity, ing.name);
      
      final existing = await _pantryRef.where('name', isEqualTo: ing.name).limit(1).get();

      if (existing.docs.isNotEmpty) {
        final doc = existing.docs.first;
        final totalValue = (doc.get('numeric_value') ?? 0.0).toDouble();
        final reservedValue = (doc.get('reserved_value') ?? 0.0).toDouble();
        
        double newValue = totalValue - normalizedIng.value;
        double newReserved = reservedValue - normalizedIng.value;

        if (newValue <= 0) {
          await _pantryRef.doc(doc.id).delete();
        } else {
          await _pantryRef.doc(doc.id).update({
            'numeric_value': newValue,
            'reserved_value': newReserved < 0 ? 0 : newReserved,
            'quantity': "${newValue.toStringAsFixed(0)}${doc.get('unit')}",
          });

          // Notificar se o estoque estiver baixo (menos de 20% do original ou valor baixo absoluto)
          if (newValue < 20) {
            await NotificationService.showNotification(
              title: "Estoque Baixo!",
              body: "Seu item '${doc.get('name')}' está acabando. Restam apenas ${newValue.toStringAsFixed(1)}${doc.get('unit')}.",
            );
          }
        }
      }
    }
  }

  Future<Map<String, dynamic>> checkIngredients(List<Ingredient> ingredients) async {
    int haveCount = 0;
    final pantry = await getPantryItems();
    
    for (var ing in ingredients) {
      final normalizedIng = _unitsService.normalize(ing.quantity, ing.name);
      final pantryItem = pantry.firstWhere(
        (i) => i.name.toLowerCase() == ing.name.toLowerCase(),
        orElse: () => PantryItem(id: '', userId: '', name: '', quantity: '', numericValue: 0, unit: '', category: '', reservedValue: 0, createdAt: DateTime.now()),
      );

      final available = pantryItem.numericValue - pantryItem.reservedValue;
      if (available >= normalizedIng.value && pantryItem.id.isNotEmpty) {
        haveCount++;
      }
    }

    return {
      'haveCount': haveCount,
      'totalCount': ingredients.length,
      'allAvailable': haveCount == ingredients.length,
    };
  }
}
