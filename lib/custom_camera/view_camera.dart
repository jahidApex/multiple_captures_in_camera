import 'dart:developer';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'camera_logic.dart';

class CameraScreen extends StatefulWidget {
  final controller = Get.put<CameraLogic>(CameraLogic());

  CameraScreen({Key? key}) : super(key: key);

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  var appTemporaryPath = "autonomo/temp";
  CameraController? controller;

  File? _imageFile;

  // Initial values
  bool _isCameraInitialized = false;
  bool _isCameraPermissionGranted = false;
  bool _isRearCameraSelected = true;

  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;

  // Current values
  double _currentZoomLevel = 1.0;
  double _currentExposureOffset = 0.0;
  FlashMode? _currentFlashMode;
  List<CameraDescription> cameras = [];

  final resolutionPresets = ResolutionPreset.values;

  ResolutionPreset currentResolutionPreset = ResolutionPreset.medium;

  getPermissionStatus() async {
    cameras = await availableCameras();

    await Permission.camera.request();
    var status = await Permission.camera.status;

    if (status.isGranted) {
      log('Camera Permission: GRANTED');
      setState(() {
        _isCameraPermissionGranted = true;
      });
      onNewCameraSelected(cameras[0]);
    } else {
      log('Camera Permission: DENIED');
    }
  }

  Directory? directory;

  Future<XFile?> takePicture() async {
    final CameraController? cameraController = controller;

    if (cameraController!.value.isTakingPicture) {
      return null;
    }

    try {
      XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      if (kDebugMode) {
        print('Error occurred while taking picture: $e');
      }
      return null;
    }
  }

  void resetCameraValues() async {
    _currentZoomLevel = 1.0;
    _currentExposureOffset = 0.0;
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    final previousCameraController = controller;

    final CameraController cameraController = CameraController(
      cameraDescription,
      currentResolutionPreset,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await previousCameraController?.dispose();

    resetCameraValues();

    if (mounted) {
      setState(() {
        controller = cameraController;
      });
    }
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    try {
      await cameraController.initialize();
      await Future.wait([
        cameraController
            .getMinExposureOffset()
            .then((value) => _minAvailableExposureOffset = value),
        cameraController
            .getMaxExposureOffset()
            .then((value) => _maxAvailableExposureOffset = value),
        cameraController
            .getMaxZoomLevel()
            .then((value) => _maxAvailableZoom = value),
        cameraController
            .getMinZoomLevel()
            .then((value) => _minAvailableZoom = value),
      ]);

      _currentFlashMode = controller!.value.flashMode;
    } on CameraException catch (e) {
      if (kDebugMode) {
        print('Error initializing camera: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isCameraInitialized = controller!.value.isInitialized;
      });
    }
  }

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (controller == null) {
      return;
    }
    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    controller!.setExposurePoint(offset);
    controller!.setFocusPoint(offset);
  }

  @override
  void initState() {
    getPermissionStatus();
    super.initState();
    if (Platform.isIOS) {
      currentResolutionPreset = ResolutionPreset.veryHigh;
    } else {
      currentResolutionPreset = ResolutionPreset.high;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(cameraController.description);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isCameraPermissionGranted
            ? _isCameraInitialized
            ? Platform.isIOS
            ? Column(
          children: [
            AspectRatio(
              aspectRatio: 1 / controller!.value.aspectRatio,
              child: Stack(
                children: [
                  CameraPreview(
                    controller!,
                    child: LayoutBuilder(builder:
                        (BuildContext context,
                        BoxConstraints constraints) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) =>
                            onViewFinderTap(details, constraints),
                      );
                    }),
                  ),
                  Column(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      topBar(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          16.0,
                          8.0,
                          16.0,
                          8.0,
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.end,
                          mainAxisAlignment:
                          MainAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isCameraInitialized =
                                      false;
                                    });
                                    onNewCameraSelected(cameras[
                                    _isRearCameraSelected
                                        ? 1
                                        : 0]);
                                    setState(() {
                                      _isRearCameraSelected =
                                      !_isRearCameraSelected;
                                    });
                                  },
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      const Icon(
                                        Icons.circle,
                                        color: Colors.black38,
                                        size: 60,
                                      ),
                                      Icon(
                                        _isRearCameraSelected
                                            ? Icons.camera_front
                                            : Icons.camera_rear,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () async {
                                    XFile? rawImage =
                                    await takePicture();
                                    File imageFile =
                                    File(rawImage!.path);

                                    int currentUnix = DateTime
                                        .now()
                                        .millisecondsSinceEpoch;
                                    directory =
                                    await getCustomAppDirectory(
                                        appTemporaryPath);

                                    String fileFormat = imageFile
                                        .path
                                        .split('.')
                                        .last;

                                    _imageFile =
                                    await imageFile.copy(
                                      '${directory!
                                          .path}/$currentUnix.$fileFormat',
                                    );
                                    setState(() async {
                                      widget.controller
                                          .allFileList.value
                                          .add(_imageFile!);
                                    });
                                    //refreshAlreadyCapturedImages();
                                  },
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: const [
                                      Icon(
                                        Icons.circle,
                                        color: Colors.white,
                                        size: 80,
                                      ),
                                      Icon(
                                        Icons.circle,
                                        color: Colors.white,
                                        size: 65,
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: _imageFile != null
                                      ? () async {
                                    widget.controller
                                        .goToFileShower();
                                  }
                                      : null,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius:
                                          BorderRadius
                                              .circular(10.0),
                                          border: Border.all(
                                            color: Colors.grey,
                                            width: 2,
                                          ),
                                          image: _imageFile !=
                                              null
                                              ? DecorationImage(
                                            image: FileImage(
                                                _imageFile!),
                                            fit: BoxFit
                                                .cover,
                                          )
                                              : null,
                                        ),
                                        child: Container(),
                                      ),
                                      Positioned(
                                          child: Text(
                                              "${widget.controller.allFileList
                                                  .value.length}"))
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                // Visibility(
                                //   visible: widget
                                //       .logicController
                                //       .isVideoEnable
                                //       .value,
                                //   child: Padding(
                                //     padding:
                                //         const EdgeInsets.only(
                                //             top: 8.0),
                                //     child: Row(
                                //       children: [
                                //         Expanded(
                                //           child: Padding(
                                //             padding:
                                //                 const EdgeInsets
                                //                     .only(
                                //               left: 8.0,
                                //               right: 4.0,
                                //             ),
                                //             child: TextButton(
                                //               onPressed:
                                //                   _isRecordingInProgress
                                //                       ? null
                                //                       : () {
                                //                           if (widget.logicController.isVideoCameraSelected.value) {
                                //                             setState(() {
                                //                               widget.logicController.isVideoCameraSelected.value = false;
                                //                             });
                                //                           }
                                //                         },
                                //               style: TextButton
                                //                   .styleFrom(
                                //                 primary: widget
                                //                         .logicController
                                //                         .isVideoCameraSelected
                                //                         .value
                                //                     ? Colors
                                //                         .black54
                                //                     : Colors
                                //                         .black,
                                //                 backgroundColor: widget
                                //                         .logicController
                                //                         .isVideoCameraSelected
                                //                         .value
                                //                     ? Colors
                                //                         .white30
                                //                     : Colors
                                //                         .white,
                                //               ),
                                //               child:
                                //                   const Text(
                                //                       'IMAGE'),
                                //             ),
                                //           ),
                                //         ),
                                //         // Expanded(
                                //         //   child: Padding(
                                //         //     padding:
                                //         //         const EdgeInsets
                                //         //                 .only(
                                //         //             left: 4.0,
                                //         //             right:
                                //         //                 8.0),
                                //         //     child: TextButton(
                                //         //       onPressed: () {
                                //         //         if (!widget
                                //         //             .logicController
                                //         //             .isVideoCameraSelected
                                //         //             .value) {
                                //         //           setState(
                                //         //               () {
                                //         //             widget
                                //         //                 .logicController
                                //         //                 .isVideoCameraSelected
                                //         //                 .value = true;
                                //         //           });
                                //         //         }
                                //         //       },
                                //         //       style: TextButton
                                //         //           .styleFrom(
                                //         //         primary: widget
                                //         //                 .logicController
                                //         //                 .isVideoCameraSelected
                                //         //                 .value
                                //         //             ? Colors
                                //         //                 .black
                                //         //             : Colors
                                //         //                 .black54,
                                //         //         backgroundColor: widget
                                //         //                 .logicController
                                //         //                 .isVideoCameraSelected
                                //         //                 .value
                                //         //             ? Colors
                                //         //                 .white
                                //         //             : Colors
                                //         //                 .white30,
                                //         //       ),
                                //         //       child:
                                //         //           const Text(
                                //         //               'VIDEO'),
                                //         //     ),
                                //         //   ),
                                //         // ),
                                //       ],
                                //     ),
                                //   ),
                                // ),
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,
                                  children: [
                                    InkWell(
                                      onTap: () async {
                                        setState(() {
                                          _currentFlashMode =
                                              FlashMode.off;
                                        });
                                        await controller!
                                            .setFlashMode(
                                          FlashMode.off,
                                        );
                                      },
                                      child: Icon(
                                        Icons.flash_off,
                                        color:
                                        _currentFlashMode ==
                                            FlashMode.off
                                            ? Colors.amber
                                            : Colors.white,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () async {
                                        setState(() {
                                          _currentFlashMode =
                                              FlashMode.auto;
                                        });
                                        await controller!
                                            .setFlashMode(
                                          FlashMode.auto,
                                        );
                                      },
                                      child: Icon(
                                        Icons.flash_auto,
                                        color:
                                        _currentFlashMode ==
                                            FlashMode.auto
                                            ? Colors.amber
                                            : Colors.white,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () async {
                                        setState(() {
                                          _currentFlashMode =
                                              FlashMode.always;
                                        });
                                        await controller!
                                            .setFlashMode(
                                          FlashMode.always,
                                        );
                                      },
                                      child: Icon(
                                        Icons.flash_on,
                                        color:
                                        _currentFlashMode ==
                                            FlashMode
                                                .always
                                            ? Colors.amber
                                            : Colors.white,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () async {
                                        setState(() {
                                          _currentFlashMode =
                                              FlashMode.torch;
                                        });
                                        await controller!
                                            .setFlashMode(
                                          FlashMode.torch,
                                        );
                                      },
                                      child: Icon(
                                        Icons.highlight,
                                        color:
                                        _currentFlashMode ==
                                            FlashMode
                                                .torch
                                            ? Colors.amber
                                            : Colors.white,
                                      ),
                                    ),
                                  ],
                                ).paddingSymmetric(
                                    horizontal: 16, vertical: 8)
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        )
            : Stack(
          children: [
            CameraPreview(
              controller!,
              child: LayoutBuilder(builder: (BuildContext context,
                  BoxConstraints constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) =>
                      onViewFinderTap(details, constraints),
                );
              }),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                topBar(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isCameraInitialized = false;
                            });
                            onNewCameraSelected(cameras[
                            _isRearCameraSelected ? 1 : 0]);
                            setState(() {
                              _isRearCameraSelected =
                              !_isRearCameraSelected;
                            });
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.circle,
                                color: Colors.black38,
                                size: 60,
                              ),
                              Icon(
                                _isRearCameraSelected
                                    ? Icons.camera_front
                                    : Icons.camera_rear,
                                color: Colors.white,
                                size: 30,
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            XFile? rawImage = await takePicture();
                            File imageFile = File(rawImage!.path);

                            int currentUnix = DateTime
                                .now()
                                .millisecondsSinceEpoch;

                            directory =
                            await getCustomAppDirectory(
                                appTemporaryPath);

                            String fileFormat =
                                imageFile.path
                                    .split('.')
                                    .last;

                            _imageFile = await imageFile.copy(
                              '${directory!.path}/$currentUnix.$fileFormat',
                            );
                            setState(() {
                              widget.controller.allFileList.value
                                  .add(_imageFile!);
                            });
                            //refreshAlreadyCapturedImages();
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: const [
                              Icon(
                                Icons.circle,
                                color: Colors.white,
                                size: 80,
                              ),
                              Icon(
                                Icons.circle,
                                color: Colors.white,
                                size: 65,
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: _imageFile != null
                              ? () async {
                            widget.controller
                                .goToFileShower();
                          }
                              : null,
                          child: Obx(() {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius:
                                    BorderRadius.circular(10.0),
                                    border: Border.all(
                                      color: Colors.grey,
                                      width: 2,
                                    ),
                                    image: _imageFile != null
                                        ? DecorationImage(
                                      image: FileImage(
                                          _imageFile!),
                                      fit: BoxFit.cover,
                                    )
                                        : null,
                                  ),
                                  child: Container(),
                                ),
                                Positioned(
                                  child: Text(
                                      "${widget.controller.allFileList.value
                                          .length}"),
                                )
                              ],
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () async {
                                setState(() {
                                  _currentFlashMode =
                                      FlashMode.off;
                                });
                                await controller!.setFlashMode(
                                  FlashMode.off,
                                );
                              },
                              child: Icon(
                                Icons.flash_off,
                                color: _currentFlashMode ==
                                    FlashMode.off
                                    ? Colors.amber
                                    : Colors.white,
                              ),
                            ),
                            InkWell(
                              onTap: () async {
                                setState(() {
                                  _currentFlashMode =
                                      FlashMode.auto;
                                });
                                await controller!.setFlashMode(
                                  FlashMode.auto,
                                );
                              },
                              child: Icon(
                                Icons.flash_auto,
                                color: _currentFlashMode ==
                                    FlashMode.auto
                                    ? Colors.amber
                                    : Colors.white,
                              ),
                            ),
                            InkWell(
                              onTap: () async {
                                setState(() {
                                  _currentFlashMode =
                                      FlashMode.always;
                                });
                                await controller!.setFlashMode(
                                  FlashMode.always,
                                );
                              },
                              child: Icon(
                                Icons.flash_on,
                                color: _currentFlashMode ==
                                    FlashMode.always
                                    ? Colors.amber
                                    : Colors.white,
                              ),
                            ),
                            InkWell(
                              onTap: () async {
                                setState(() {
                                  _currentFlashMode =
                                      FlashMode.torch;
                                });
                                await controller!.setFlashMode(
                                  FlashMode.torch,
                                );
                              },
                              child: Icon(
                                Icons.highlight,
                                color: _currentFlashMode ==
                                    FlashMode.torch
                                    ? Colors.amber
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ).paddingSymmetric(
                            horizontal: 16, vertical: 8)
                      ],
                    ),
                  ],
                ).paddingSymmetric(horizontal: 16, vertical: 8),
              ],
            ),
          ],
        )
            : const Center(
          child: Text(
            'LOADING',
            style: TextStyle(color: Colors.white),
          ),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(),
            const Text(
              'Permission denied',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                getPermissionStatus();
              },
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Give permission',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget topBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 0, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              Get.back();
            },
            icon: const Icon(Icons.close),
          ),
          InkWell(
            onTap: () {
              widget.controller.goToFileShower();
            },
            child: Visibility(
              visible: _imageFile != null,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30)),
                child: const Text('Done'),
              ),
            ),
          )
        ],
      ),
    );
  }

  Align cameraQuality() {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: DropdownButton<ResolutionPreset>(
            dropdownColor: Colors.black87,
            underline: Container(),
            value: currentResolutionPreset,
            items: [
              for (ResolutionPreset preset in resolutionPresets)
                DropdownMenuItem(
                  value: preset,
                  child: Text(
                    preset.toString().split('.')[1].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                )
            ],
            onChanged: (value) {
              setState(() {
                currentResolutionPreset = value!;
                _isCameraInitialized = false;
              });
              onNewCameraSelected(controller!.description);
            },
            hint: const Text("Select item"),
          ),
        ),
      ),
    );
  }

  Widget zoomSlider() {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: _currentZoomLevel,
            min: _minAvailableZoom,
            max: _maxAvailableZoom,
            activeColor: Colors.white,
            inactiveColor: Colors.white30,
            onChanged: (value) async {
              setState(() {
                _currentZoomLevel = value;
              });
              await controller!.setZoomLevel(value);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '${_currentZoomLevel.toStringAsFixed(1)}x',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget exposureSlider() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0, top: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '${_currentExposureOffset.toStringAsFixed(1)}x',
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ),
        ),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SizedBox(
              height: 30,
              child: Slider(
                value: _currentExposureOffset,
                min: _minAvailableExposureOffset,
                max: _maxAvailableExposureOffset,
                activeColor: Colors.white,
                inactiveColor: Colors.white30,
                onChanged: (value) async {
                  setState(() {
                    _currentExposureOffset = value;
                  });
                  await controller!.setExposureOffset(value);
                },
              ),
            ),
          ),
        )
      ],
    );
  }

  Future<Directory> getCustomAppDirectory(String folderName) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory appDocDirFolder =
    Directory('${appDocDir.path}/$folderName/');

    if (await appDocDirFolder.exists()) {
      return appDocDirFolder;
    } else {
      await appDocDirFolder.create(recursive: true);
      return appDocDirFolder;
    }
  }

  clearCacheDirectory() {
    if (directory != null) {
      if (directory!.existsSync()) {
        directory!.deleteSync(recursive: true);
      }
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    widget.controller.dispose();
    clearCacheDirectory();
    super.dispose();
  }
}
