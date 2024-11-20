import 'package:face_registration_and_recognition/services/camera.service.dart';
import 'package:face_registration_and_recognition/services/face_detector_service.dart';
import 'package:face_registration_and_recognition/services/ml_service.dart';
import 'package:get_it/get_it.dart';

final locator = GetIt.instance;

void setupServices() {
  locator.registerLazySingleton<CameraService>(() => CameraService());
  locator
      .registerLazySingleton<FaceDetectorService>(() => FaceDetectorService());
  locator.registerLazySingleton<MLService>(() => MLService());
}
