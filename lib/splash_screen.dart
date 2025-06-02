import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    print('SplashScreen initialized');
  }

  @override
  Widget build(BuildContext context) {
    print('SplashScreen build method called');
    return Container(
      color: Colors.red,
      child: const Center(
        child: Text(
          'SPLASH TEST',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}
