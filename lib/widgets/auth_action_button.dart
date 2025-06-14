// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:face_registration_and_recognition/database_helper.dart';
import 'package:face_registration_and_recognition/locator.dart';
import 'package:face_registration_and_recognition/models/user.dart';
import 'package:face_registration_and_recognition/pages/home_page.dart';
import 'package:face_registration_and_recognition/pages/profile_page.dart';
import 'package:face_registration_and_recognition/services/camera.service.dart';
import 'package:face_registration_and_recognition/services/ml_service.dart';
import 'package:face_registration_and_recognition/widgets/app_button.dart';
import 'package:face_registration_and_recognition/widgets/custom_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'app_text_field.dart';

class AuthActionButton extends StatefulWidget {
  const AuthActionButton({
    super.key,
    required this.onPressed,
    required this.isLogin,
    required this.reload,
    required this.isLoading,
  });
  final Function onPressed;
  final bool isLogin;
  final Function reload;
  final bool isLoading;

  @override
  _AuthActionButtonState createState() => _AuthActionButtonState();
}

class _AuthActionButtonState extends State<AuthActionButton> {
  final MLService _mlService = locator<MLService>();
  final CameraService _cameraService = locator<CameraService>();

  final TextEditingController _userTextEditingController =
      TextEditingController(text: '');
  final TextEditingController _passwordTextEditingController =
      TextEditingController(text: '');

  User? predictedUser;

  Future _signUp(context) async {
    DatabaseHelper databaseHelper = DatabaseHelper.instance;
    List<List> predictedDatas = _mlService.predictedDatas;

    String user = _userTextEditingController.text;
    String password = _passwordTextEditingController.text;
    User userToSave = User(
      user: user,
      password: password,
      modelData: predictedDatas,
    );
    await databaseHelper.insert(userToSave);
    _mlService.setPredictedData([]);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => const MyHomePage()));
  }

  Future _signIn(context) async {
    String password = _passwordTextEditingController.text;
    if (predictedUser!.password == password) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => ProfilePage(
                    predictedUser!.user,
                    imagePath: _cameraService.imagePath!,
                  )));
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
            content: Text('Wrong password!'),
          );
        },
      );
    }
  }

  Future<User?> _predictUser() async {
    User? userAndPass = await _mlService.predict();
    return userAndPass;
  }

  Future onTap() async {
    try {
      bool faceDetected = await widget.onPressed();
      if (faceDetected) {
        if (widget.isLogin) {
          var user = await _predictUser();
          if (user != null) {
            predictedUser = user;
          }
        }
        PersistentBottomSheetController bottomSheetController =
            Scaffold.of(context)
                .showBottomSheet((context) => signSheet(context));
        bottomSheetController.closed.whenComplete(() => widget.reload());
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.isLoading
        ? const CustomProgressIndicator()
        : InkWell(
            onTap: () async {
              await onTap();
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFF54B435),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              width: MediaQuery.of(context).size.width * 0.8,
              height: 60,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'CAPTURE',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Icon(Icons.camera_alt, color: Colors.white)
                ],
              ),
            ),
          );
  }

  signSheet(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          widget.isLogin && predictedUser != null
              ? Text(
                  'Welcome back, ${predictedUser!.user}.',
                  style: const TextStyle(fontSize: 20),
                )
              : widget.isLogin
                  ? const Text(
                      'User not found 😞',
                      style: TextStyle(fontSize: 20),
                    )
                  : Container(),
          Column(
            children: [
              !widget.isLogin
                  ? AppTextField(
                      controller: _userTextEditingController,
                      labelText: "Your Name",
                    )
                  : Container(),
              const SizedBox(height: 10),
              widget.isLogin && predictedUser == null
                  ? Container()
                  : AppTextField(
                      controller: _passwordTextEditingController,
                      labelText: "Password",
                      isPassword: true,
                    ),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 8),
              Text(' Current Faces : ${_mlService.predictedDatas.length}'),
              const SizedBox(height: 10),
              widget.isLogin && predictedUser != null
                  ? AppButton(
                      text: 'LOGIN',
                      onPressed: () async {
                        _signIn(context);
                      },
                      icon: const Icon(
                        Icons.login,
                        color: Colors.white,
                      ),
                    )
                  : !widget.isLogin
                      ? Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                text: 'ADD MORE FACES',
                                onPressed: () async {
                                  Navigator.pop(context);
                                },
                                icon: const Icon(
                                  Icons.face,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14.0),
                            Expanded(
                              child: AppButton(
                                text: 'REGISTER',
                                onPressed: () async {
                                  await _signUp(context);
                                },
                                icon: const Icon(
                                  Icons.person_add,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
