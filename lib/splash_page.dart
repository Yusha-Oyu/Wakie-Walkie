import 'dart:async';
import 'package:alarm_app/alarm_page.dart';
import 'package:flutter/material.dart';


class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    
  
  Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
        
          transitionDuration: const Duration(milliseconds:600),
          pageBuilder:(context, animation, secondaryAnimation) => const AlarmPage(),
          transitionsBuilder: (__, animation, ___, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
    
      );
    });
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B1E23), Color(0xFF2B2F36)],
          ),
        ),
        child: Center(
        child: Text(
          'WakieWalkie',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE7D28B),
            
            ),
          
        ),
      )),
    );
    
  }
}