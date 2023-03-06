import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mime/mime.dart';
import 'captures_logic.dart';

class CapturesScreen extends StatelessWidget {
  CapturesScreen({Key? key}) : super(key: key);

  final controller = Get.put(CapturesLogic());
  AppBar customAppbar(BuildContext context) {
    return AppBar(
      actions: [
        Center(
          child: InkWell(
            onTap: () async {
              controller.uploadImages();
            },
            child: const Text(
              'Upload',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(
          width: 12,
        )
      ],
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        color: Colors.black,
        onPressed: () {
          Get.back();
        },
      ),
      title: const Text(
        'Captures',
        style: TextStyle(
          fontSize: 24,
          color: Colors.black,
        ),
      ),
      leadingWidth: 40,
      backgroundColor: Colors.white,
      elevation: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppbar(context),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Obx(() {
            return controller.isLoading.value
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GridView.count(
                            crossAxisSpacing: 8,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            children: getFileListWithImageThumbnail(context)),
                      ),
                    ],
                  );
          }),
        ),
      ),
    );
  }

  List<Widget> getFileListWithImageThumbnail(BuildContext context) {
    List<Widget> widgets = [];
    for (File file in controller.allFileList) {
      widgets.add(
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black,
              width: 1,
            ),
          ),
          child: Image.file(
            file,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return widgets;
  }

  List<Widget> getImage() {
    List<Widget> widgets = [];
    for (File aFile in controller.allFileList) {
      String? fileDetails = lookupMimeType(aFile.path);
      var fileType = fileDetails?.split('/');
      if (fileType![0].contains("image")) {
        widgets.add(
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
            ),
            child: InkWell(
              onTap: () {},
              child: Image.file(
                aFile,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }
}
