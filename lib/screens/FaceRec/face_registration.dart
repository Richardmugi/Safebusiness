import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:safebusiness/utils/color_resources.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceRegisterPage extends StatefulWidget {
  const FaceRegisterPage({super.key});

  @override
  State<FaceRegisterPage> createState() => _FaceRegisterPageState();
}

class _FaceRegisterPageState extends State<FaceRegisterPage> {
  CameraController? _cameraController;
  late Interpreter _interpreter;
  bool _modelLoaded = false;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
  );
  List<Face> _detectedFaces = [];
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    _loadCameras();
    _loadModel();
  }

  Future<void> _loadCameras() async {
    _cameras = await availableCameras();
    _selectedCameraIndex = _cameras.indexWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
    );
    if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;
    await _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    _cameraController = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.medium,
    );
    await _cameraController!.initialize();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Camera Initialized"),
        backgroundColor: mainColor,
      ),
    );
    if (mounted) setState(() {});
  }

  void _switchCamera() async {
    if (_cameras.length < 2) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initializeCamera();
  }

  Future<void> _loadModel() async {
  try {
    _interpreter = await Interpreter.fromAsset('assets/models/facenet.tflite');
    setState(() => _modelLoaded = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Model Loaded Successfully"),
        backgroundColor: mainColor,
      ),
    );
  } catch (e) {
    debugPrint("❌ Error loading model: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("❌ Error loading model: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  List<double> _normalize(List<double> embedding) {
    final norm = math.sqrt(embedding.fold(0.0, (sum, val) => sum + val * val));
    return embedding.map((e) => e / norm).toList();
  }

  Future<void> _captureAndRegisterFace() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || !_modelLoaded) return;
     setState(() => _isLoading = true);
    try {
      final file = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(file.path);
      final faces = await _faceDetector.processImage(inputImage);
      _detectedFaces = faces;
      if (mounted) setState(() {});
      if (faces.isEmpty) {
        //_showMessage('No face detected in selfie');
        ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("No face detected in selfie"),
        backgroundColor: mainColor,
      ),
    );
        return;
      }

      final face = faces.first;

      final bytes = await File(file.path).readAsBytes();
      img.Image image = img.decodeImage(bytes)!;

      final x = face.boundingBox.left.toInt().clamp(0, image.width - 1);
      final y = face.boundingBox.top.toInt().clamp(0, image.height - 1);
      final w = face.boundingBox.width.toInt().clamp(0, image.width - x);
      final h = face.boundingBox.height.toInt().clamp(0, image.height - y);

      final cropped = img.copyCrop(image, x: x, y: y, width: w, height: h);
      final resized = img.copyResizeCropSquare(cropped, size: 160);

      const inputSize = 160;
      var input = List.generate(1, (_) => List.generate(inputSize, (y) =>
          List.generate(inputSize, (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          })
      ));

      var output = List.generate(1, (_) => List.filled(128, 0.0));
      _interpreter.run(input, output);

      List<double> embedding = List<double>.from(output[0]);
      embedding = _normalize(embedding);
      await _saveEmbedding(embedding);
      //_showMessage('✅ Face registered successfully!');
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ Face registered successfully!"),
        backgroundColor: mainColor,
      ),
    );
    } catch (e) {
      //_showMessage('❌ Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("❌ Error: $e"),
        backgroundColor: mainColor,
      ),
    );
    } finally {
    if (mounted) setState(() => _isLoading = false);
  }
  }

  Future<void> _saveEmbedding(List<double> embedding) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(embedding);
    await prefs.setString('face_embedding', encoded);
  }

  /*void _showMessage(String msg) {
  if (!mounted) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  });
}*/


  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInitialized = _cameraController?.value.isInitialized == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Register Face"),
        actions: [
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            tooltip: "Switch Camera",
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: Stack(
  children: [
    // Fullscreen camera view
    Positioned.fill(
      child: _cameraController?.value.isInitialized == true
          ? Stack(
              children: [
                CameraPreview(_cameraController!),
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    ),

    // Button pinned to bottom
    Positioned(
      bottom: 30,
      left: 24,
      right: 24,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _captureAndRegisterFace,
        icon: const Icon(Icons.camera_alt),
        label: const Text("Capture Selfie"),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          textStyle: const TextStyle(fontSize: 18),
        ),
      ),
    ),
  ],
),
    );
  }
}
