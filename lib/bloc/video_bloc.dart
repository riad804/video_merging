import 'dart:io';
import 'dart:ui';
import 'package:chewie/chewie.dart';
import 'package:compare_ai_demo/bloc/video_merger.dart';
import 'package:flutter/foundation.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:rxdart/rxdart.dart';
import 'package:video_player/video_player.dart';

class VideoBloc {
  final _video1Controller = BehaviorSubject<VideoPlayerController?>();
  final _video2Controller = BehaviorSubject<VideoPlayerController?>();

  final _chewie1Controller = BehaviorSubject<ChewieController?>();
  final _chewie2Controller = BehaviorSubject<ChewieController?>();

  final _isVertical = BehaviorSubject<bool>.seeded(true);

  late String _video1Path;
  late String _video2Path;

  Stream<VideoPlayerController?> get video1Stream => _video1Controller.stream;
  Stream<VideoPlayerController?> get video2Stream => _video2Controller.stream;

  Stream<ChewieController?> get chewie1Stream => _chewie1Controller.stream;
  Stream<ChewieController?> get chewie2Stream => _chewie2Controller.stream;

  VideoPlayerController? get controller1 => _video1Controller.valueOrNull;
  VideoPlayerController? get controller2 => _video2Controller.valueOrNull;

  ChewieController? get chewie1 => _chewie1Controller.valueOrNull;
  ChewieController? get chewie2 => _chewie2Controller.valueOrNull;

  Stream<bool> get isVerticalStream => _isVertical.stream;

  bool get isVertical => _isVertical.value;

  void toggleLayout() => _isVertical.add(!_isVertical.value);
  void setVertical() => _isVertical.add(true);
  void setPortrait() => _isVertical.add(false);

  Future<void> setVideo1(File file) async {
    _video1Path = file.path;
    final controller = VideoPlayerController.file(file,
    videoPlayerOptions: VideoPlayerOptions(
      mixWithOthers: true,
    ));
    await controller.initialize();
    _video1Controller.add(controller);

    final chewieController = ChewieController(
      videoPlayerController: controller,
      autoPlay: false,
      autoInitialize: true,
      allowMuting: true,
      allowedScreenSleep: false,
      looping: false,
    );

    _chewie1Controller.add(chewieController);
  }

  Future<void> setVideo2(File file) async {
    _video2Path = file.path;
    final controller = VideoPlayerController.file(file,
    videoPlayerOptions: VideoPlayerOptions(
      mixWithOthers: true,
    ));
    await controller.initialize();
    _video2Controller.add(controller);

    final chewieController = ChewieController(
      videoPlayerController: controller,
      autoPlay: false,
      autoInitialize: true,
      allowMuting: true,
      allowedScreenSleep: false,
      looping: false,
    );

    _chewie2Controller.add(chewieController);
  }

  Future<bool> generateVideo(Size size) async {
    try {
      final outputPath = await VideoMerger.mergeVideos(
        video1: File(_video1Path),
        video2: File(_video2Path),
        isVertical: _isVertical.value,
        width: size.width.toInt(),
        height: size.height.toInt(),
        loopShorter: false,
      );
      debugPrint('Merged file at: $outputPath');
      await GallerySaver.saveVideo(outputPath);
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  void dispose() {
    _video1Controller.valueOrNull?.dispose();
    _video2Controller.valueOrNull?.dispose();
    _chewie1Controller.valueOrNull?.dispose();
    _chewie2Controller.valueOrNull?.dispose();
    _video1Controller.close();
    _video2Controller.close();
    _chewie1Controller.close();
    _chewie2Controller.close();
    _isVertical.close();
  }
}
