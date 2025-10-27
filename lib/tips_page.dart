import 'package:flutter/material.dart';
import 'navigation.dart';

class TipsPage extends StatelessWidget {
  const TipsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parents Tips'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: const [
              // ...replace with your actual tips UI...
              Expanded(
                child: Center(child: Text('Parents tips content goes here')),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppNavigation(
        currentIndex: 1, // middle tab highlighted
        onTab: (index) {
          if (index == 1) return; // already on Tips
          if (index == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (index == 2) {
            Navigator.pushNamed(context, '/settings');
          }
        },
      ),
    );
  }
}
