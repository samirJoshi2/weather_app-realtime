import 'package:flutter/material.dart';
import 'package:weather/firebase_auth_service.dart' show FirebaseAuthServices;
import 'login_page.dart';

class WeatherPage extends StatelessWidget {
  const WeatherPage({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuthServices().signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Weather Home"),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: const Center(child: Text("Welcome to your Weather App!")),
    );
  }
}

