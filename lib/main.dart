import 'package:Simplifier/key_screen.dart';
import 'package:Simplifier/scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keychain/flutter_keychain.dart';


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  Future<bool> isKeySet() async {
    if (await FlutterKeychain.get(key: "key") == null) {
      return false;
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ignore: unrelated_type_equality_checks
      home: (isKeySet()==true)
        ? const ScannerScreen()
        : const GetKey()
    );
  }
}

