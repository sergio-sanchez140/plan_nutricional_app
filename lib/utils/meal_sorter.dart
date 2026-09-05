class MealSorter {
  static int getCategoryOrder(String category) {
    final t = category.toLowerCase().trim();

    // 1. Mañana
    if (t.contains('desayuno') || t.contains('breakfast')) return 10;

    // 2. Media mañana (AQUÍ METEMOS EL ALMUERZO)
    if (t.contains('media mañana') ||
        t.contains('mañana') ||
        t.contains('almuerzo'))
      return 20;

    // 3. Mediodía (SOLO COMIDA)
    if (t.contains('comida') || t.contains('lunch')) return 30;

    // 4. Tarde
    if (t.contains('merienda') || t.contains('snack') || t.contains('tarde'))
      return 40;

    // 5. Noche
    if (t.contains('cena') || t.contains('dinner')) return 50;

    // Extras (Recenas, etc)
    return 60;
  }
}
