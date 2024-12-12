import 'package:flutter/material.dart';
import 'home_screen.dart';

class HomeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
              (route) => false,
        );
      },
      child: Text('Go to Home Screen'),
    );
  }
}
