import 'package:flutter/material.dart';
import 'welcome.dart';
import 'login.dart'; 


// ignore: use_key_in_widget_constructors
class PermissionsScreen extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _PermissionsScreenState createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool micAccess = false;
  bool notificationsAccess = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF8BBD0), // light pink
              Color(0xFFF48FB1), // soft pastel
              Color(0xFFF06292), // warm pink
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.04,
              horizontal: screenWidth * 0.07,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                IconButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => WelcomeScreen()),
                    );
                  },
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                ),

                SizedBox(height: screenHeight * 0.02),

                // Title
                Center(
                  child: Text(
                    "Thank you for choosing\nBaby Monitor",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.065,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                Center(
                  child: Text(
                    "Before you start using it, please give permissions:",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.06),

                // Microphone permission
                _buildPermissionTile(
                  icon: Icons.mic,
                  title: "App needs to monitor baby’s cry. Please give access to microphone",
                  value: micAccess,
                  onChanged: (val) => setState(() => micAccess = val),
                ),
                SizedBox(height: screenHeight * 0.03),

                // Notifications permission
                _buildPermissionTile(
                  icon: Icons.notifications,
                  title:
                      "Allow notifications to simplify pairing devices and to receive push alerts",
                  value: notificationsAccess,
                  onChanged: (val) => setState(() => notificationsAccess = val),
                ),

                const Spacer(),

                // Start Button
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => LoginPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent.shade200,
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02,
                        horizontal: screenWidth * 0.25,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      "Start using Baby Monitor",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: Colors.pinkAccent,
        ),
      ],
    );
  }
}
