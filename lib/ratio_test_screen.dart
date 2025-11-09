import 'package:flutter/material.dart';

class RatioTestScreen extends StatefulWidget {
  const RatioTestScreen({super.key});

  @override
  State<RatioTestScreen> createState() => _RatioTestScreenState();
}

class _RatioTestScreenState extends State<RatioTestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AspectRatio(
          aspectRatio: 7 / 5, // width : height
          // aspectRatio: 16 / 9, // width : height
          child: Container(
            color: Colors.blue,
            child: const Center(
              child: Text(
                "16:9 Aspect Ratio",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
