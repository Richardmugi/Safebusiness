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
  if (mounted) setState(() {});
}


  void _switchCamera() async {
    if (_cameras.length < 2) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initializeCamera();
  }

  Future<void> _loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/models/facenet.tflite');
    setState(() => _modelLoaded = true);
  }


  Future<void> _captureAndCheckFace() async {
  if (_cameraController == null || !_cameraController!.value.isInitialized || !_modelLoaded) return;
  setState(() => _isLoading = true);

  try {
    final file = await _cameraController!.takePicture();

    if (_isIOS) {
      debugPrint('🔧 iOS Check-in: Applying orientation fix before face detection...');
      final image = img.decodeImage(await File(file.path).readAsBytes());
      if (image != null) {
        debugPrint('📷 Decoded image size: ${image.width}x${image.height}');
        final fixedImage = img.bakeOrientation(image);
        final correctedPath = '${file.path}_fixed.jpg';
        await File(correctedPath).writeAsBytes(img.encodeJpg(fixedImage));
        
        final inputImage = InputImage.fromFilePath(correctedPath);
        final faces = await _faceDetector.processImage(inputImage);

        if (faces.isEmpty) {
          debugPrint("🚫 No face detected (iOS, after fix). Trying rotated fallback...");
          await _tryWithRotatedImageCheckin(file.path);
          return;
        }

        await _processCheckinFace(fixedImage, faces.first);
        return;
      }
    }

    // Android or fallback
    final inputImage = InputImage.fromFilePath(file.path);
    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No face detected in selfie"),
          backgroundColor: mainColor,
        ),
      );
      return;
    }

    final image = img.decodeImage(await File(file.path).readAsBytes());
    if (image == null) throw Exception("Failed to decode image");

    await _processCheckinFace(image, faces.first);

  } catch (e) {
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

Future<void> _tryWithRotatedImageCheckin(String imagePath) async {
  try {
    final bytes = await File(imagePath).readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      debugPrint("❌ Failed to decode image for rotation");
      return;
    }

    final rotated = img.copyRotate(image, angle: 90);
    final rotatedPath = '${imagePath}_rotated_checkin.jpg';
    await File(rotatedPath).writeAsBytes(img.encodeJpg(rotated));

    final inputImage = InputImage.fromFilePath(rotatedPath);
    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isNotEmpty) {
      debugPrint("✅ Face detected after rotation (iOS check-in)");
      await _processCheckinFace(rotated, faces.first);

      // Delete temp image
      await File(rotatedPath).delete();
      return;
    } else {
      debugPrint("🚫 Still no face detected after rotation (iOS check-in)");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("iOS: No face detected even after rotation"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  } catch (e) {
    debugPrint("❌ Error in rotated image check-in: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("❌ Error processing rotated image for check-in"),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Future<void> _processCheckinFace(img.Image image, Face face) async {
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

  List<double> currentEmbedding = List<double>.from(output[0]);
  final normCurrent = _normalize(currentEmbedding);

  final storedEmbedding = await _loadStoredEmbedding();
  if (storedEmbedding == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("No registered face found. Please register first."),
        backgroundColor: mainColor,
      ),
    );
    return;
  }

  final normStored = _normalize(storedEmbedding);
  final distance = _euclideanDistance(normCurrent, normStored);
  debugPrint("🧠 Euclidean Distance: $distance");

  if (distance < 0.6) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ Face matched! Check-in successful"),
        backgroundColor: mainColor,
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("❌ Face does not match! Check-in failed"),
        backgroundColor: mainColor,
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
)
    );
  }
}