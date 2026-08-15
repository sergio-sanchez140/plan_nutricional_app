import 'package:flutter/material.dart';

class MealsHistoryCard extends StatelessWidget {
  final List<String> historial;

  const MealsHistoryCard({super.key, required this.historial});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Comidas de hoy",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 2,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: historial.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 60, endIndent: 20),
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade50,
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 22,
                  ),
                ),
                title: Text(
                  historial[index],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
