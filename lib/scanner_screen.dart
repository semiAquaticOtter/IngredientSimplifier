// import 'dart:math';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'result_screen.dart';
import 'dart:async';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_keychain/flutter_keychain.dart';
// import 'package:testapp/old-main.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Text recog',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ScannerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  bool _isPermissionGranted = false;
  late final Future<void> _future;
  CameraController? _cameraController;
  final textRecognizer = TextRecognizer();
  String _APIkey = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _stopCamera();
    _future = _requestCameraPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    super.dispose();
    textRecognizer.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      _startCamera();
    }
  }

  Future<void> _cameraSelected(CameraDescription camera) async {
    _cameraController = CameraController(
      camera,
      ResolutionPreset.max,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        return Stack(children: [
          if (_isPermissionGranted)
            FutureBuilder<List<CameraDescription>>(
              future: availableCameras(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  _initCameraController(snapshot.data!);
                  return Center(
                      child: CustomPaint(
                          foregroundPainter: null,
                          child: CameraPreview(_cameraController!)));
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
          Scaffold(
              appBar: AppBar(
                title: const Text('Text Recognition'),
                actions: [
                  PopupMenuButton(
                    itemBuilder: (context){
                      return [
                        PopupMenuItem(
                          child: TextField(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter OpenAI API key.'
                            ),
                            onChanged: (input) async {
                              await FlutterKeychain.put(key: "key", value: "value");
                            },
                          )
                        )
                      ];
                    }
                  )
                ],
              ),
              backgroundColor: _isPermissionGranted ? Colors.transparent : null,
              body: _isPermissionGranted
                  ? Column(
                      children: [
                        Expanded(child: Container()),
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.only(bottom: 30),
                          child: Center(
                            child: ElevatedButton(
                              onPressed: _takeAndCropPicture,
                              style: ElevatedButton.styleFrom(
                                fixedSize: const Size(50, 50),
                                shape: const CircleBorder(),
                              ),
                              child: Icon(Icons.circle_outlined),
                            ),
                          ),
                        )
                      ],
                    )
                  : Center(
                      child: Container(
                        padding: const EdgeInsets.only(left: 24, right: 24),
                        child: const Text(
                          'camera permission denied',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ))
        ]); //
      },
    );
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    _isPermissionGranted = status == PermissionStatus.granted;
  }

  void _stopCamera() {
    if (_cameraController != null) {
      _cameraController?.dispose();
    }
  }

  void _startCamera() {
    if (_cameraController != null) {
      _cameraSelected(_cameraController!.description);
    }
  }

  void _initCameraController(List<CameraDescription> cameras) {
    if (_cameraController != null) {
      return;
    }

    // Select the first rear camera.
    CameraDescription? camera;
    for (var i = 0; i < cameras.length; i++) {
      final CameraDescription current = cameras[i];
      if (current.lensDirection == CameraLensDirection.back) {
        camera = current;
        break;
      }
    }

    if (camera != null) {
      _cameraSelected(camera);
    }
  }

  Future<void> _scanImage(CroppedFile? croppedImage) async {
    if (_cameraController == null) return;

    final navigator = Navigator.of(context);

    navigator.push(
        MaterialPageRoute(
          builder: (BuildContext context) =>
              const Center(child: SizedBox(width: 65, height: 65, child: CircularProgressIndicator())),
        ),
    );

    try {

      final file = File(croppedImage!.path);

      final inputImage = InputImage.fromFile(file);
      final recognizedText = await textRecognizer.processImage(inputImage);

      navigator.pop();
      await navigator.push(
        MaterialPageRoute(
          builder: (BuildContext context) =>
              ResultScreen(text: recognizedText.text),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred when scanning text'),
        ),
      );
    }
  }

void logYellow(String msg) {
  developer.log('\x1B[33m$msg\x1B[0m');
}

Future<void> _takeAndCropPicture() async {
  logYellow('enterd function');

  try {
    logYellow('check if camera controller is null');
    if (_cameraController == null) return;
    logYellow('take picture');
    final pickedImage = await _cameraController!.takePicture();
    logYellow('setting imageCropper');
    final imageCropper = ImageCropper();
    logYellow('cropping');
    try {
      final croppedImage = await imageCropper.cropImage(
      sourcePath: pickedImage.path,
      aspectRatioPresets: [ 
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
      ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: const Color.fromARGB(255, 20, 20, 29),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false
        )
      ]
    ); 
    logYellow('after crop');
    if (croppedImage != null) {
      _scanImage(croppedImage);
    } 
    } catch (e) {
      logYellow('==========');
      debugPrint(e as String?);
      logYellow('==========');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error'),
        ),
      );
  }
}
}