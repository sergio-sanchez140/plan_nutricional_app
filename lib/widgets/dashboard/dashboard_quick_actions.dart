import 'package:flutter/material.dart';
import '../quick_action_button.dart';

class DashboardQuickActions extends StatelessWidget {
  final Function(int)? onTabSelected;

  const DashboardQuickActions({super.key, this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Acciones rápidas",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            QuickActionButton(
              icon: Icons.restaurant_menu,
              label: "Plan",
              tabIndex: 1,
              onTabSelected: onTabSelected,
            ),
            QuickActionButton(
              icon: Icons.emoji_events,
              label: "Retos",
              tabIndex: 2,
              onTabSelected: onTabSelected,
            ),
            QuickActionButton(
              icon: Icons.person,
              label: "Perfil",
              tabIndex: 3,
              onTabSelected: onTabSelected,
            ),
          ],
        ),
      ],
    );
  }
}
