import 'package:flutter/material.dart';
import 'package:private_photo/enter_pin_screen.dart';
import 'package:private_photo/set_pin_screen.dart';
import 'db_helper.dart';
import 'permission_helper.dart';

void main() {
  runApp(const PrivatePhotoApp());
}

class PrivatePhotoApp extends StatefulWidget {
  const PrivatePhotoApp({super.key});

  @override
  State<PrivatePhotoApp> createState() => _PrivatePhotoAppState();
}

class _PrivatePhotoAppState extends State<PrivatePhotoApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _askPermissions();
    });
  }

  void _askPermissions() async {
    bool granted = await PermissionHelper.requestPermissions();
    if (!granted) {
      // Show dialog if permissions denied
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
            'Camera, photos, and storage permissions are required to use this app. '
            'Please enable them in settings if denied.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await PermissionHelper.requestPermissions();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Private Photo App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: FutureBuilder(
        future: DBHelper().isPinSet(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.data == true) {
            return const EnterPinScreen();
          } else {
            return const SetPinScreen();
          }
        },
      ),
    );
  }
}
