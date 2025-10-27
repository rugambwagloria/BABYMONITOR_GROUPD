import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'navigation.dart';
import 'trends_page.dart';

class SettingsPage extends StatefulWidget {
  final Function(String) onThemeChange;
  const SettingsPage({super.key, required this.onThemeChange});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedTheme = 'neutral';
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await DatabaseHelper.instance.getSettings();
    if (s != null && s['theme'] != null) {
      setState(() => _selectedTheme = s['theme'] as String);
    }
  }

  Future<void> _save() async {
    await DatabaseHelper.instance.setSettings({'theme': _selectedTheme});
    widget.onThemeChange(_selectedTheme);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Theme saved")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Choose a theme"),
            ListTile(
              title: const Text("Neutral (Orange / Cream)"),
              leading: Radio<String>(
                value: 'neutral',
                groupValue: _selectedTheme,
                onChanged: (v) => setState(() => _selectedTheme = v!),
              ),
            ),
            ListTile(
              title: const Text("Boy (Blue Shades)"),
              leading: Radio<String>(
                value: 'blue',
                groupValue: _selectedTheme,
                onChanged: (v) => setState(() => _selectedTheme = v!),
              ),
            ),
            ListTile(
              title: const Text("Girl (Pink Shades)"),
              leading: Radio<String>(
                value: 'pink',
                groupValue: _selectedTheme,
                onChanged: (v) => setState(() => _selectedTheme = v!),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: const Text("Save Theme")),
          ],
        ),
      ),
      bottomNavigationBar: AppNavigation(
        currentIndex: 2,
        onTab: (index) {
          if (index == 2) return; // already on Settings
          if (index == 0) {
            // Try to go back to Home (if Settings was pushed from Home)
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.pushNamed(context, '/');
            }
          } else if (index == 1) {
            // Open Parents Tips page instead of Trends
            Navigator.pushNamed(context, '/tips');
          }
        },
      ),
    );
  }
}
