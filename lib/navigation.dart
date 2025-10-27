import 'package:flutter/material.dart';

class AppNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTab;

  const AppNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTab,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTab,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        // replaced Trends with Tips
        BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: 'Tips'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}
