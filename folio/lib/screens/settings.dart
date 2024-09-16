import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDF8F4),
      appBar: AppBar(
        backgroundColor: Color(0xFFFDF8F4),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF4A2E2B)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
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
            color: Color(0xFFFDF8F4),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: Icon(Icons.notifications, color: Color(0xFF4A2E2B)),
                  title: Text(
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
                    activeColor: Color(0xFFF790AD),
                    activeTrackColor: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                ListTile(
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
                SizedBox(height: 16),
                Center(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Color(0xFFF790AD)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    child: Text(
                      'Sign out',
                      style: TextStyle(
                        color: Color(0xFFF790AD),
                        fontSize: 16,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ),
                Spacer(), // Pushes "Delete account" to the bottom
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 200), // Adjust the padding as needed
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFF790AD),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        minimumSize: Size(280, 48),
                      ),
                      child: Text(
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