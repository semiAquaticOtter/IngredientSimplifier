// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: MyApp(
        camera: firstCamera
        ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.camera
  });

  final CameraDescription camera;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  late CameraController controller;
  late Future<void> _initializeControllerFuture = checkPermission();
  bool isRequestingPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      checkPermission();
    });
  }

  Future<void> checkPermission() async {
    print('checking permissions');
    if (isRequestingPermission) {
      return;
    }
    isRequestingPermission = true;

    try {
      final permissionStatus = await Permission.camera.request();
      if (permissionStatus.isGranted) {
        controller = CameraController(widget.camera, ResolutionPreset.max);
        _initializeControllerFuture = controller.initialize(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required')),
        );
      }
    } finally {
      isRequestingPermission = false;
    }
    /*
    final permissionStatus = await Permission.camera.request();
    if (permissionStatus.isGranted) {
      controller = CameraController(widget.camera, ResolutionPreset.max);
      _initializeControllerFuture = controller.initialize();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required')),
      );
    }
    */
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
      double calculateAspectRatio(CameraValue value) {
      return 1 / value.aspectRatio;
    }

    final size = MediaQuery.of(context).size;
    final aspectRatio = size.width / size.height;
    // ignore: prefer_const_constructors
    return Scaffold(
      // ignore: prefer_const_constructors
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return AspectRatio(
              aspectRatio: aspectRatio,
              child: CameraPreview(controller),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        }
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 30.0),
        child: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await controller.takePicture();
            if (!mounted) return;

            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(imagePath: image.path),
              )
            );
          } catch (e) {
            print(e);
          }
        },
        child: const Icon(Icons.camera),
      )),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat
    );
  }
}

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      body: Image.file(File(imagePath)),
    );
  }
}