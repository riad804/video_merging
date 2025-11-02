import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/log.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await requestStoragePermissionIfNeeded();
  } catch (e) {
    print(e);
  }
  FFmpegKitConfig.enableLogCallback((Log log) {
    print("FFmpegLog: ${log.getMessage()}");
  });

  FFmpegKitConfig.enableStatisticsCallback((stats) {
    print("FFmpegStats: time=${stats.getTime()}");
  });

  runApp(const MyApp());
}

Future<void> requestStoragePermissionIfNeeded() async {
  if (Platform.isAndroid) {
    if (await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
    }
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Compare AI Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      home: const HomePage(),
    );
  }
}