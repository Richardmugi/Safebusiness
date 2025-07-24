import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:safebusiness/utils/color_resources.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:math' as math;

class FaceCheckInPage extends StatefulWidget {
  const FaceCheckInPage({super.key});

  @override
  State<FaceCheckInPage> createState() => _FaceCheckInPageState();
}

class _FaceCheckInPageState extends State<FaceCheckInPage> {
  CameraController? _cameraController;
  late Interpreter _interpreter;
  bool _modelLoaded = false;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
  );

  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isLoading = false;
  bool _isIOS = Platform.isIOS;

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
        backgroundColor: Colors.green,
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
      _interpreter = await Interpreter.fromAsset(
        'assets/models/facenet.tflite',
      );
      setState(() => _modelLoaded = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Model Loaded Successfully"),
          backgroundColor: Colors.green,
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

  Future<List<double>?> _loadStoredEmbedding() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('face_embedding');
    if (data == null) return null;
    final decoded = jsonDecode(data);
    return List<double>.from(decoded);
  }

  double _euclideanDistance(List<double> e1, List<double> e2) {
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += math.pow((e1[i] - e2[i]), 2);
    }
    double distance = math.sqrt(sum);
    print("🔍 Euclidean Distance between embeddings: $distance");
    return distance;
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

  List<double> _normalize(List<double> embedding) {
    double norm = math.sqrt(embedding.fold(0, (sum, val) => sum + val * val));
    return embedding.map((e) => e / norm).toList();
  }

Future<void> _captureAndCheckFace() async {
  if (_cameraController == null || !_cameraController!.value.isInitialized || !_modelLoaded) {
    return;
  }

  setState(() => _isLoading = true);
  try {
    final file = await _cameraController!.takePicture();
    double? distance;
    List<double>? currentEmbedding;

    // First try with original image
    currentEmbedding = await _processImageForEmbedding(file.path);
    
    // If no face detected on iOS, try with rotation
    if (currentEmbedding == null && _isIOS) {
      debugPrint("Trying with rotated image for iOS...");
      currentEmbedding = await _processImageForEmbedding(file.path, rotated: true);
    }

    if (currentEmbedding == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No face detected"), backgroundColor: Colors.orange),
      );
      return;
    }

    final storedEmbedding = await _loadStoredEmbedding();
    if (storedEmbedding == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No registered face found"), backgroundColor: Colors.orange),
      );
      return;
    }

    distance = _euclideanDistance(
      _normalize(currentEmbedding),
      _normalize(storedEmbedding)
    );

    debugPrint("Match distance: $distance");
    debugPrint("Current embedding (first 5): ${currentEmbedding.take(5)}");
    debugPrint("Stored embedding (first 5): ${storedEmbedding.take(5)}");

    if (distance < 0.6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Face matched!"), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Face does not match"), backgroundColor: Colors.red),
      );
    }

  } catch (e, stack) {
    debugPrint("Error: $e\n$stack");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

Future<List<double>?> _processImageForEmbedding(String imagePath, {bool rotated = false}) async {
  try {
    final bytes = await File(imagePath).readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return null;

    if (rotated) {
      image = img.copyRotate(image, angle: 90);
    } else {
      image = img.bakeOrientation(image);
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    final faces = await _faceDetector.processImage(inputImage);
    if (faces.isEmpty) return null;

    final face = faces.first;
    final box = face.boundingBox;

    // Convert coordinates for rotated image if needed
    final x = rotated ? box.top.toInt() : box.left.toInt();
    final y = rotated ? image.width - box.right.toInt() : box.top.toInt();
    final w = rotated ? box.height.toInt() : box.width.toInt();
    final h = rotated ? box.width.toInt() : box.height.toInt();

    final cropped = img.copyCrop(
      image,
      x: x.clamp(0, image.width - 1),
      y: y.clamp(0, image.height - 1),
      width: w.clamp(0, image.width - x),
      height: h.clamp(0, image.height - y),
    );

    final resized = img.copyResizeCropSquare(cropped, size: 160);

    // Generate embedding
    const inputSize = 160;
    var input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(inputSize, (x) {
          final pixel = resized.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        },
      ),
    ));

    var output = List.generate(1, (_) => List.filled(128, 0.0));
    _interpreter.run(input, output);

    return List<double>.from(output[0]);
  } catch (e) {
    debugPrint("Error processing image: $e");
    return null;
  }
}

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Face Check-In"),
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
          // Fullscreen camera preview
          Positioned.fill(
            child:
                _cameraController?.value.isInitialized == true
                    ? Stack(
                      children: [
                        CameraPreview(_cameraController!),
                        if (_isLoading)
                          Container(
                            color: Colors.black.withOpacity(0.5),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    )
                    : const Center(child: CircularProgressIndicator()),
          ),

          // Button at bottom center
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _captureAndCheckFace,
                icon: const Icon(Icons.check),
                label: const Text("Check-In"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
