import 'package:flutter/material.dart';
import 'database_helper.dart';


class BabyProfilePage extends StatefulWidget {
  const BabyProfilePage({Key? key}) : super(key: key);

  @override
  State<BabyProfilePage> createState() => _BabyProfilePageState();
}

class _BabyProfilePageState extends State<BabyProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  String? _gender;
  ImageProvider? _babyImage;

  Future<void> _pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2023),
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _dobCtrl.text = "${date.day}/${date.month}/${date.year}";
      });
    }
  }

void _saveProfile() async {
  if (_formKey.currentState!.validate()) {
    final name = _nameCtrl.text.trim();
    final dob = _dobCtrl.text.trim();
    final gender = _gender;
    final weight = double.tryParse(_weightCtrl.text.trim()) ?? 0.0;
    final height = double.tryParse(_heightCtrl.text.trim()) ?? 0.0;

    // Optional: Calculate approximate age
    int age = 0;
    try {
      final parts = dob.split('/');
      final date = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
      age = DateTime.now().year - date.year;
    } catch (_) {}

    // ✅ Save into database
    final db = DatabaseHelper.instance;
    await db.insertBabyProfile({
      'name': name,
      'age': age,
      'gender': gender,
      'weight': weight,
      'height': height,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("👶 Baby profile saved to database!"),
        backgroundColor: Colors.pinkAccent,
      ),
    );

    Navigator.pop(context);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: const Text("👶 Baby Profile"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Profile Image
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _babyImage = const AssetImage('assets/baby_placeholder.png');
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Image picker coming soon!"),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.pink.shade100,
                    backgroundImage: _babyImage,
                    child: _babyImage == null
                        ? const Icon(Icons.camera_alt,
                            color: Colors.white70, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Baby Name
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: "Baby's Name",
                            prefixIcon: const Icon(Icons.child_care),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? "Enter a name" : null,
                        ),
                        const SizedBox(height: 16),

                        // Date of Birth
                        TextFormField(
                          controller: _dobCtrl,
                          readOnly: true,
                          onTap: () => _pickDate(context),
                          decoration: InputDecoration(
                            labelText: "Date of Birth",
                            prefixIcon: const Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? "Select a date" : null,
                        ),
                        const SizedBox(height: 16),

                        // Gender Dropdown
                        DropdownButtonFormField<String>(
                          value: _gender,
                          items: const [
                            DropdownMenuItem(
                                value: "Male", child: Text("Boy")),
                            DropdownMenuItem(
                                value: "Female", child: Text("Girl")),
                            DropdownMenuItem(
                                value: "Other", child: Text("Other")),
                          ],
                          onChanged: (v) => setState(() => _gender = v),
                          decoration: InputDecoration(
                            labelText: "Gender",
                            prefixIcon: const Icon(Icons.wc),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) =>
                              v == null ? "Select gender" : null,
                        ),
                        const SizedBox(height: 16),

                        // Weight
                        TextFormField(
                          controller: _weightCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Weight (kg)",
                            prefixIcon:
                                const Icon(Icons.monitor_weight_outlined),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? "Enter weight"
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Height
                        TextFormField(
                          controller: _heightCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Height (cm)",
                            prefixIcon: const Icon(Icons.height),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_alt),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _saveProfile,
                  label: const Text(
                    "Save Profile",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
