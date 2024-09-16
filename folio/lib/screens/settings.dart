import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF8F4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A2E2B)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF4A2E2B),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Nunito',
          ),
        ),
        centerTitle: true,
      ),
      body: SizedBox(
        child: Center(
          child: Container(
            color: const Color(0xFFFDF8F4),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.notifications, color: Color(0xFF4A2E2B)),
                  title: const Text(
                    'Notifications',
                    style: TextStyle(
                      color: Color(0xFF4A2E2B),
                      fontSize: 18,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  trailing: Switch(
                    value: _notificationOn,
                    onChanged: (value) {
                      setState(() {
                        _notificationOn = value;
                      });
                    },
                    activeColor: const Color(0xFFF790AD),
                    activeTrackColor: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.chat, color: Color(0xFF4A2E2B)),
                  title: Text(
                    'Contact Us',
                    style: TextStyle(
                      color: Color(0xFF4A2E2B),
                      fontSize: 18,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF790AD)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 12),
                    ),
                    child: const Text(
                      'Sign out',
                      style: TextStyle(
                        color: Color(0xFFF790AD),
                        fontSize: 16,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ),
                const Spacer(), // Pushes "Delete account" to the bottom
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        top: 200), // Adjust the padding as needed
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF790AD),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 12),
                        minimumSize: const Size(280, 48),
                      ),
                      child: const Text(
                        'Delete account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ),
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
