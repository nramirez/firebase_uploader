import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_uploader/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark(useMaterial3: true),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<void> uploadFilesDesktop() async {
    final images = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (images == null) {
      return;
    }

    for (final image in images.files) {
      final name = image.name;

      final ref = FirebaseStorage.instance
          .ref('uploads/${name + DateTime.now().toString()}');

      final data = image.bytes;
      await ref.putData(data!);
    }

    setState(() {});
  }

  Future<void> uploadFiles() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return uploadFilesDesktop();
    }

    final images = await ImagePicker().pickMultiImage();

    for (final image in images) {
      final name = image.name;

      final ref = FirebaseStorage.instance
          .ref('uploads/${name + DateTime.now().toString()}');
      final data = await image.readAsBytes();
      await ref.putData(data);
    }

    setState(() {});
  }

  Future<List<Reference>> loadImages() async {
    final ref = FirebaseStorage.instance.ref('uploads');
    final result = await ref.listAll();
    return result.items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: FutureBuilder(
              future: loadImages(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final List<Reference> images =
                      snapshot.data as List<Reference>;
                  return ListView.builder(
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return FutureBuilder(
                            future: images[index].getDownloadURL(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final url = snapshot.data as String;
                                return Image.network(url);
                              }
                              return const CircularProgressIndicator();
                            });
                      });
                }
                return const CircularProgressIndicator();
              })),
      floatingActionButton: FloatingActionButton(
        onPressed: uploadFiles,
        tooltip: 'Upload',
        child: const Icon(Icons.upload),
      ),
    );
  }
}
