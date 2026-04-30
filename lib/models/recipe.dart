class Ingredient {
  final String name;
  final String quantity;

  Ingredient({required this.name, required this.quantity});

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
  };
}

class Recipe {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final List<Ingredient> ingredients;
  final String instructions;
  final String? source;
  final String? thumbnailUrl;
  final String? sourceType; // 'video' ou 'site'
  final String status;
  bool isFavorite;

  Recipe({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.ingredients,
    required this.instructions,
    required this.status,
    required this.isFavorite,
    this.source,
    this.thumbnailUrl,
    this.sourceType,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Salgados',
      ingredients: (json['ingredients'] as List? ?? [])
          .map((i) => Ingredient.fromJson(i))
          .toList(),
      instructions: json['instructions'] ?? '',
      status: json['status'] ?? 'nova',
      isFavorite: json['is_favorite'] ?? false,
      source: json['source'],
      thumbnailUrl: json['thumbnail_url'],
      sourceType: json['source_type'],
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'title': title,
    'description': description,
    'category': category,
    'ingredients': ingredients.map((i) => i.toJson()).toList(),
    'instructions': instructions,
    'status': status,
    'is_favorite': isFavorite,
    'source': source,
    'thumbnail_url': thumbnailUrl,
    'source_type': sourceType,
  };
}
