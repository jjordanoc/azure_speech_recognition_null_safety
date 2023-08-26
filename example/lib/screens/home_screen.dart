import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed("/simple");
              },
              child: Text("Simple recognition"),
            ),
            SizedBox(
              height: 30.0,
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed("/continuous");
              },
              child: Text("Continuous recognition"),
            ),
          ],
        ),
      ),
    );
  }
}
