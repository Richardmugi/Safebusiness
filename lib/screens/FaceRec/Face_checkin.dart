import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:safebusiness/screens/FaceRec/face_registration.dart';
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
  bool _isProcessing = false;
  final bool _isIOS = Platform.isIOS;
  List<Face> _detectedFaces = [];

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
    /*ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Camera Initialized"),
        backgroundColor: Colors.green,
      ),
    );*/
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
      /*ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Model Loaded Successfully"),
        backgroundColor: Colors.green,
      ),
    );*/
    } catch (e) {
      debugPrint("❌ Error loading model: $e");
      /*ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("❌ Error loading model: $e"),
        backgroundColor: Colors.red,
      ),
    );*/
    }
  }

  Future<void> _captureAndCheckFace() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        !_modelLoaded)
      return;
    setState(() => _isProcessing = true);
    try {
      final file = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(file.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (_isIOS) {
        debugPrint('iOS specific debug:');
        final image = img.decodeImage(await File(file.path).readAsBytes());
        debugPrint('Decoded image size: ${image?.width}x${image?.height}');
      }

      _detectedFaces = faces;
      if (mounted) setState(() {});
      if (faces.isEmpty) {
        String errorMsg = "No face detected in selfie";
        if (_isIOS) {
          errorMsg += " (iOS may need image rotation correction)";
          // Try with rotated image for iOS
          await _tryWithRotatedImage(file.path);
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.orange),
        );
        return;
      }

      final face = faces.first;

      final bytes = await File(file.path).readAsBytes();
      img.Image image = img.decodeImage(bytes)!;
      //image = img.bakeOrientation(image); // ✅ Fix rotation on iOS

      final x = face.boundingBox.left.toInt().clamp(0, image.width - 1);
      final y = face.boundingBox.top.toInt().clamp(0, image.height - 1);
      final w = face.boundingBox.width.toInt().clamp(0, image.width - x);
      final h = face.boundingBox.height.toInt().clamp(0, image.height - y);

      final cropped = img.copyCrop(image, x: x, y: y, width: w, height: h);
      final resized = img.copyResizeCropSquare(cropped, size: 160);

      const inputSize = 160;
      var input = List.generate(
        1,
        (_) => List.generate(
          inputSize,
          (y) => List.generate(inputSize, (x) {
            final pixel = resized.getPixel(x, y);
            return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
          }),
        ),
      );


      // Output: [1, 128] for float model
      var output = List.generate(1, (_) => List.filled(128, 0.0));
      _interpreter.run(input, output);

      List<double> currentEmbedding = List<double>.from(output[0]);
      final normCurrent = _normalize(currentEmbedding);

      final storedEmbedding = await _loadStoredEmbedding();
      if (storedEmbedding == null) {
        //_showMessage("No registered face found. Please register first.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No registered face found. Please register first."),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      //final normStored = _normalize(storedEmbedding);
      //final distance = _euclideanDistance(normCurrent, normStored);

      final similarity = _cosineSimilarity(normCurrent, storedEmbedding);
        print("✅ Cosine Similarity: $similarity");

      //print("✅ Normalized Euclidean Distance: $distance");
      print("Stored Embedding (first 5): ${storedEmbedding.take(5)}");
      print("Current Embedding (first 5): ${currentEmbedding.take(5)}");

if (similarity > 0.85) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("✅ Face matched!"), backgroundColor: Colors.green),
  );
  Navigator.pop(context, true);
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("❌ Face does not match! Check-in failed"), backgroundColor: mainColor),
  );
  Navigator.pop(context, false);
}
      /*if (distance < 0.3) {
        //_showMessage('✅ Face matched!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Face matched!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // ✅ Return success
      } else {
        //_showMessage('❌ Face does not match! Check-in failed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Face does not match! Check-in failed"),
            backgroundColor: mainColor,
          ),
        );
        Navigator.pop(context, false); // ❌ Return failure
      }*/
    } catch (e) {
      _showMessage('Error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _tryWithRotatedImage(String imagePath) async {
    try {
      debugPrint("Attempting with rotated image for iOS...");
      final bytes = await File(imagePath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        debugPrint("Failed to decode image");
        return;
      }

      // Rotate 90 degrees clockwise for iOS front camera
      final rotated = img.copyRotate(image, angle: 90);

      // Save rotated image temporarily for debugging
      final rotatedPath = '${imagePath}_rotated.jpg';
      await File(rotatedPath).writeAsBytes(img.encodeJpg(rotated));
      debugPrint("Saved rotated image to: $rotatedPath");

      // Try face detection again with rotated image
      final inputImage = InputImage.fromFilePath(rotatedPath);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        debugPrint("Face detected after rotation!");

        final face = faces.first;

        // Process the rotated image
        final x = face.boundingBox.left.toInt().clamp(0, rotated.width - 1);
        final y = face.boundingBox.top.toInt().clamp(0, rotated.height - 1);
        final w = face.boundingBox.width.toInt().clamp(0, rotated.width - x);
        final h = face.boundingBox.height.toInt().clamp(0, rotated.height - y);

        final cropped = img.copyCrop(rotated, x: x, y: y, width: w, height: h);
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
            }),
          ),
        );

        var output = List.generate(1, (_) => List.filled(128, 0.0));
        _interpreter.run(input, output);

        List<double> currentEmbedding = List<double>.from(output[0]);
        final normCurrent = _normalize(currentEmbedding);

        final storedEmbedding = await _loadStoredEmbedding();
        if (storedEmbedding == null) {
          if (!mounted) return;
          //_showMessage("No registered face found. Please register first.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("No registered face found. Please register first."),
              backgroundColor: mainColor,
            ),
          );
          return;
        }

        //final normStored = _normalize(storedEmbedding);
        //final distance = _euclideanDistance(normCurrent, normStored);

        final similarity = _cosineSimilarity(normCurrent, storedEmbedding);
        print("✅ Cosine Similarity: $similarity");

        //print("✅ Normalized Euclidean Distance: $distance");
        print("Stored Embedding (first 5): ${storedEmbedding.take(5)}");
        print("Current Embedding (first 5): ${currentEmbedding.take(5)}");

        if (similarity > 0.95) {
          if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("✅ Face matched! $similarity"), backgroundColor: Colors.green),
  );
  Navigator.pop(context, true);
} else {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("❌ Face does not match! Check-in failed: $similarity"), backgroundColor: mainColor),
  );
  Navigator.pop(context, false);
}

        /*if (distance < 0.3) {
          //_showMessage('✅ Face matched!');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✅ Face matched!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // ✅ Return success
        } else {
          //_showMessage('❌ Face does not match! Check-in failed');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ Face does not match! Check-in failed"),
              backgroundColor: mainColor,
            ),
          );
          Navigator.pop(context, false); // ❌ Return failure
        }*/
      }

      // Save the embedding
      //await _saveEmbedding(embedding);

      /*if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✅ Face registered successfully (iOS rotated)!"),
              backgroundColor: Colors.green,
            ),
          );
        }*/
      /*} else {
        debugPrint("Still no face detected after rotation");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("iOS: No face detected even after rotation"),
            backgroundColor: Colors.orange,
          ),
        );
      }*/

      // Clean up temporary file
      //await File(rotatedPath).delete();
    } catch (e, stack) {
      debugPrint("Error in rotated image processing: $e");
      debugPrint("Stack trace: $stack");
      if (mounted) setState(() => _isProcessing = false);
      {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error processing rotated image: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }  

  Future<List<double>?> _loadStoredEmbedding() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('face_embedding');
    if (data == null) return null;
    final decoded = jsonDecode(data);
    return List<double>.from(decoded);
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
  double dot = 0.0;
  double normA = 0.0;
  double normB = 0.0;

  for (int i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }

  return dot / (sqrt(normA) * sqrt(normB));
}


  /*double _euclideanDistance(List<double> e1, List<double> e2) {
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += math.pow((e1[i] - e2[i]), 2);
    }
    double distance = math.sqrt(sum);
    print("🔍 Euclidean Distance between embeddings: $distance");
    return distance;
  }*/

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

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
            child:
                _cameraController?.value.isInitialized == true
                    ? Stack(
                      children: [
                        CameraPreview(_cameraController!),
                        if (_isProcessing)
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

          // Buttons at bottom center
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ Check-In Button
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _captureAndCheckFace,
                    icon: const Icon(Icons.check),
                    label: const Text("Capture Face"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ✅ Register Face Button
                  /*ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FaceRegisterPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text("Register Face"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      minimumSize: const Size.fromHeight(50),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),*/
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
