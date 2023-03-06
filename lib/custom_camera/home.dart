import 'package:customcamera/custom_camera/view_camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          Get.to(CameraScreen());
        },
        child: const Text('Go to Camera'),
      ),
    );
  }
}
