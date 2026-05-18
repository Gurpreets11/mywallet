import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            const SizedBox(height: 20),

            Text(
              "Settings",

              textAlign: TextAlign.center,

              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),


          ],
        ),
      ),
    );
  }
}
