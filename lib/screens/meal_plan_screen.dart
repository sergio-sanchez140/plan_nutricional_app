import 'package:flutter/material.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({Key? key}) : super(key: key);

  @override
  _MealPlanScreenState createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  // Ejemplo de comidas del día
  final Map<String, List<Map<String, dynamic>>> meals = {
    "Desayuno": [
      {"name": "Avena con frutas", "calories": 350, "protein": 12, "carbs": 50, "fat": 10, "image": "assets/images/foods/avena-frutos-rojos.png"},
    ],
    "Almuerzo": [
      {"name": "Pollo con quinoa", "calories": 500, "protein": 40, "carbs": 60, "fat": 15, "image": "assets/images/foods/pollo-quinoa.png"},
    ],
    "Cena": [
      {"name": "Salmón y vegetales", "calories": 450, "protein": 35, "carbs": 30, "fat": 18, "image": "assets/images/foods/salmon-vegetables.png"},
    ],
    "Snacks": [
      {"name": "Yogur con nueces", "calories": 200, "protein": 10, "carbs": 20, "fat": 8, "image": "assets/images/foods/yogurt-nueces.png"},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Mi Plan – Lunes 5 Sep",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: meals.entries.map((entry) {
            String mealType = entry.key;
            List<Map<String, dynamic>> mealList = entry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mealType,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 10),
                Column(
                  children: mealList.map((meal) => _mealCard(meal)).toList(),
                ),
                SizedBox(height: 20),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _mealCard(Map<String, dynamic> meal) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Imagen de la comida
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                meal["image"],
                //width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meal["name"],
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 6),
                  Text(
                      "${meal["calories"]} kcal | P: ${meal["protein"]}g C: ${meal["carbs"]}g F: ${meal["fat"]}g"),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Aquí podrías abrir un modal para cambiar comida
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[400],
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: Text("Cambiar"),
                      ),
                      SizedBox(width: 10),
                      IconButton(
                        icon: Icon(Icons.check_circle_outline,
                            color: Colors.green),
                        onPressed: () {
                          // Marcar comida como completada con animación
                        },
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}