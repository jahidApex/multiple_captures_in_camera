import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                            ),
                            itemCount: controller.allFileList.value.length,
                            itemBuilder: (BuildContext context, int index) {
                              var item = controller.allFileList.value[index];
                              return Stack(
                                children: [
                                  Container(
                                    width: 180,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 1,
                                      ),
                                    ),
                                    child: Image.file(
                                      item,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: IconButton(
                                      onPressed: () {
                                        controller.allFileList.value
                                            .removeAt(index);
                                        controller.allFileList.refresh();
                                      },
                                      icon: const Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          )),
                    ],
                  );
          }),
        ),
      ),
    );
  }
}
