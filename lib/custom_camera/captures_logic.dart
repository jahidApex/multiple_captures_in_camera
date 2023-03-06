import 'dart:io';
import 'package:get/get.dart';

class CapturesLogic extends GetxController {
  final Rx<List<File>> allFileList = Rx([]);
  var args = Get.arguments;
  var isLoading = true.obs;
  @override
  onReady() async {
    super.onReady();
    allFileList.value.addAll(args["fileList"]);
    isLoading.value = false;
  }

  Future<dynamic> uploadImages() async {
    ///todo upload process
  }
}
