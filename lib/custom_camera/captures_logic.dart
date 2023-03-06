import 'dart:io';
import 'package:get/get.dart';

class CapturesLogic extends GetxController {
  late final List<File> allFileList;
  var args = Get.arguments;
  var isLoading = true.obs;
  @override
  onReady() async {
    super.onReady();
    allFileList = args["fileList"];
    isLoading.value = false;
  }

  Future<dynamic> uploadImages() async {
    ///todo upload process
  }
}
