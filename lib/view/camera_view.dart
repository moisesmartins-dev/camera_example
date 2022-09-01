import 'dart:developer';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_cropper/image_cropper.dart';

import 'check_image.dart';

class CameraView extends StatefulWidget {
  const CameraView({Key? key}) : super(key: key);

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  late CameraController cameraController;
  late List<CameraDescription> cameras;
  late XFile picture;
  bool previewImage = false;
  bool loading = false;
  bool loadingCamera = true;
  Size? size;
  double? scale;

  configCamera() {
    if (scale! < 1) scale = 1.2 / scale!;
    size = MediaQuery.of(context).size;
    scale = size!.aspectRatio * cameraController.value.aspectRatio;
  }

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  initCamera() async {
    cameras = await availableCameras();
    cameraController = CameraController(
      cameras[1],
      ResolutionPreset.max,
      imageFormatGroup: ImageFormatGroup.jpeg,
      enableAudio: false,
    );
    cameraController.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        loadingCamera = false;
      });
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            log('User denied camera access.');
            break;
          default:
            log('Handle other errors.');
            break;
        }
      }
    });
  }

  Future<XFile> takePictures() async {
    try {
      XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      log('Error occured while taking picture: $e');
      return XFile('');
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark),
        child: loadingCamera
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: previewImage
                    ? Stack(
                        alignment: FractionalOffset.center,
                        children: <Widget>[
                          Positioned.fill(
                            child: Image.file(File(picture.path)),
                          ),
                          Positioned(
                            bottom: 50,
                            child: Row(
                              children: [
                                Container(
                                  height: 55,
                                  width: 55,
                                  decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                                  child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        loading = false;
                                        previewImage = false;
                                      });
                                    },
                                    icon: const Icon(Icons.restart_alt),
                                    color: Colors.white,
                                    iconSize: 25,
                                  ),
                                ),
                                const SizedBox(width: 100),
                                Container(
                                  height: 55,
                                  width: 55,
                                  decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                                  child: IconButton(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => CheckImage(photo: picture.path)),
                                      );
                                      setState(() {
                                        loading = false;
                                        previewImage = false;
                                      });
                                    },
                                    icon: const Icon(Icons.done),
                                    color: Colors.white,
                                    iconSize: 25,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      )
                    : Stack(
                        alignment: FractionalOffset.center,
                        children: <Widget>[
                          Positioned.fill(
                            child: AspectRatio(
                                aspectRatio: cameraController.value.aspectRatio,
                                child: CameraPreview(cameraController)),
                          ),
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 30.0),
                              child: SvgPicture.asset('assets/svg/mask.svg'),
                            ),
                          ),
                          Positioned(
                            bottom: 50,
                            child: Container(
                              height: 72,
                              width: 72,
                              decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                              child: IconButton(
                                splashColor: Colors.blueAccent,
                                onPressed: () async {
                                  setState(() {
                                    loading = true;
                                  });
                                  picture = await takePictures();
                                  picture = XFile(await cropImage(pathImage: picture.path));
                                  setState(() {
                                    previewImage = true;
                                  });
                                },
                                color: Colors.white,
                                iconSize: 25,
                                icon: const Icon(Icons.photo_camera),
                              ),
                            ),
                          ),
                          Center(
                            child: Visibility(
                              visible: loading,
                              child: const CircularProgressIndicator(),
                            ),
                          )
                        ],
                      ),
              ),
      ),
    );
  }

  Future<String> cropImage({required String pathImage}) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pathImage,
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
          toolbarColor: Colors.blueAccent,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: true,
        ),
        IOSUiSettings(
          title: 'Cropper',
        ),
      ],
    );
    return croppedFile!.path;
  }
}
