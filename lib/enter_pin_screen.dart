import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'home_screen.dart';

class EnterPinScreen extends StatefulWidget {
  const EnterPinScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EnterPinScreenState createState() => _EnterPinScreenState();
}

class _EnterPinScreenState extends State<EnterPinScreen> {
  final TextEditingController _pinController = TextEditingController();
  String? _error;

  void _checkPin() async {
    String? savedPin = await DBHelper().getPin();
    if (_pinController.text == savedPin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() {
        _error = "Incorrect Pin";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter PIN")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Enter your PIN to continue'),
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter Pin'
              ),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red),),
            const SizedBox(height: 20,),
            ElevatedButton(
              onPressed: _checkPin, 
              child: const Text("Login")
              )
          ],
        ),
        ),
    );
  }
}
