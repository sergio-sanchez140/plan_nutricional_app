class Meal {
  final int id;
  final int planId;
  final String name;
  final String cantidad;
  final double carbs;
  final double protein;
  final double fat;
  final double calorias;
  bool completed;
  final String image;

  Meal({
    required this.id,
    required this.planId,
    required this.name,
    required this.cantidad,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.calorias,
    required this.completed,
    required this.image,
  });

  factory Meal.fromJson(Map<String, dynamic> json, String image) {
    final macros = json['macros'] as Map<String, dynamic>? ?? {};

    return Meal(
      id: json['id'] ?? 0,
      planId: json['plan_id'] ?? 0,
      name: json['nombre'] ?? 'Comida',
      cantidad: json['cantidad'] ?? '',
      carbs: (macros['carbohidratos_g'] ?? 0).toDouble(),
      protein: (macros['proteinas_g'] ?? 0).toDouble(),
      fat: (macros['grasas_g'] ?? 0).toDouble(),
      calorias: (json['calorias'] ?? 0).toDouble(),
      completed: json['completed'] ?? false,
      image: image,
    );
  }
}