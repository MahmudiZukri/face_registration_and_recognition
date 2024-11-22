import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:face_registration_and_recognition/locator.dart';
import 'package:face_registration_and_recognition/widgets/custom_progress_indicator.dart';
import 'package:face_registration_and_recognition/widgets/face_painter.dart';
import 'package:face_registration_and_recognition/widgets/auth_action_button.dart';
import 'package:face_registration_and_recognition/widgets/camera_header.dart';
import 'package:face_registration_and_recognition/services/camera.service.dart';
import 'package:face_registration_and_recognition/services/ml_service.dart';
import 'package:face_registration_and_recognition/services/face_detector_service.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/material.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  RegistrationPageState createState() => RegistrationPageState();
}

class RegistrationPageState extends State<RegistrationPage> {
  String? imagePath;
  Face? faceDetected;
  Size? imageSize;

  bool _detectingFaces = false;
  bool pictureTaken = false;

  bool _initializing = false;
  bool _isLoading = false;

  bool _saving = false;
  bool _bottomSheetVisible = false;

  // service injection
  final FaceDetectorService _faceDetectorService =
      locator<FaceDetectorService>();
  final CameraService _cameraService = locator<CameraService>();
  final MLService _mlService = locator<MLService>();

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  _start() async {
    setState(() => _initializing = true);
    await _cameraService.initialize();
    setState(() => _initializing = false);

    _frameFaces();
  }

  Future<bool> onShot() async {
    if (faceDetected == null) {
      showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
            content: Text('No face detected!'),
          );
        },
      );

      return false;
    } else {
      _saving = true;
      _isLoading = true;

      XFile? file = await _cameraService.takePicture();
      imagePath = file?.path;

      setState(() {
        _isLoading = false;
        _bottomSheetVisible = true;
        pictureTaken = true;
      });
      _mlService.addMoreFaces(
        predictedData: _mlService.predictedData,
      );

      return true;
    }
  }

  _frameFaces() {
    imageSize = _cameraService.getImageSize();

    _cameraService.cameraController?.startImageStream((image) async {
      if (_cameraService.cameraController != null) {
        if (_detectingFaces) return;

        _detectingFaces = true;

        try {
          await _faceDetectorService.detectFacesFromImage(image);

          if (_faceDetectorService.faces.isNotEmpty) {
            setState(() {
              faceDetected = _faceDetectorService.faces[0];
            });
            if (_saving) {
              _mlService.setCurrentPrediction(image, faceDetected);
              setState(() {
                _saving = false;
              });
            }
          } else {
            debugPrint('face is null');
            setState(() {
              faceDetected = null;
            });
          }

          _detectingFaces = false;
        } catch (e) {
          debugPrint('Error _faceDetectorService face => $e');
          _detectingFaces = false;
        }
      }
    });
  }

  _reload() {
    setState(() {
      _bottomSheetVisible = false;
      pictureTaken = false;
    });
    _start();
  }

  _onBackPressed() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const double mirror = math.pi;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    late Widget body;
    if (_initializing) {
      body = const Center(
        child: CustomProgressIndicator(),
      );
    }

    if (!_initializing && pictureTaken) {
      body = SizedBox(
        width: width,
        height: height,
        child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(mirror),
            child: FittedBox(
              fit: BoxFit.cover,
              child: Image.file(File(imagePath!)),
            )),
      );
    }

    if (!_initializing && !pictureTaken) {
      body = Transform.scale(
        scale: 1.0,
        child: AspectRatio(
          aspectRatio: MediaQuery.of(context).size.aspectRatio,
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.fitHeight,
              child: SizedBox(
                width: width,
                height:
                    width * _cameraService.cameraController!.value.aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    CameraPreview(_cameraService.cameraController!),
                    CustomPaint(
                      painter: FacePainter(
                          face: faceDetected, imageSize: imageSize!),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          body,
          CameraHeader(
            "REGISTRATION",
            onBackPressed: () {
              _onBackPressed();
              _mlService.clearPredictedDatas();
            },
          )
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: !_bottomSheetVisible
          ? AuthActionButton(
              onPressed: onShot,
              isLogin: false,
              reload: _reload,
              isLoading: _isLoading,
            )
          : const SizedBox(),
    );
  }
}
