import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fridge_to_fork_assistant/routes/route_names.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(icon: const Icon(Icons.home), label: 'Tủ bếp'),
        BottomNavigationBarItem(
          icon: const Icon(Icons.calendar_month),
          label: 'Lên menu',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.shopping_cart),
          label: 'Mua sắm',
        ),
      ],
      onTap: (index) {
        _navigateTo(context, index);
      },
    );
  }

  void _navigateTo(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RouteNames.pantryScreen);
        break;
      case 1:
        context.go(RouteNames.mealPlanner);
        break;
      case 2:
        context.go(RouteNames.shoppingListScreen);
        break;
    }
  }
}
