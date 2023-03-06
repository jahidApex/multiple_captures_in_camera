import 'dart:io';
import 'package:get/get.dart';
import 'captures_screen.dart';

class CameraLogic extends GetxController {
  Rx<List<File>> allFileList = Rx([]);
  var arguments = Get.arguments;
  File? imageFile;

  @override
  onReady() {}

  void goToFileShower() async {
    var agr = {};
    agr["fileList"] = allFileList.value;
    final result = await Get.to(() => CapturesScreen(), arguments: agr);
    if (result == 'success') {
      ///todo
    }
  }

  @override
  void onClose() {
    allFileList.value.clear();
    super.onClose();
  }
}
