import 'dart:developer';
import 'dart:io';
import 'package:compare_ai_demo/views/dual_video_view.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:chewie/chewie.dart';

import 'bloc/video_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final VideoBloc bloc = VideoBloc();

  // Sliders
  final _sliderAllSubject = BehaviorSubject.seeded(0.0);
  final _sliderV1Subject = BehaviorSubject.seeded(0.0);
  final _sliderV2Subject = BehaviorSubject.seeded(0.0);

  @override
  void initState() {
    super.initState();

    // Listen to VideoPlayerControllers to update individual sliders
    bloc.chewie1Stream.listen((chewieCtrl) {
      chewieCtrl?.videoPlayerController.addListener(() {
        if (chewieCtrl.videoPlayerController.value.isPlaying) {
          _sliderV1Subject.add(
              chewieCtrl.videoPlayerController.value.position.inMilliseconds.toDouble());
        }
      });
    });

    bloc.chewie2Stream.listen((chewieCtrl) {
      chewieCtrl?.videoPlayerController.addListener(() {
        if (chewieCtrl.videoPlayerController.value.isPlaying) {
          _sliderV2Subject.add(
              chewieCtrl.videoPlayerController.value.position.inMilliseconds.toDouble());
        }
      });
    });

    // Listen to all-slider to sync both videos
    _sliderAllSubject.stream.listen(_seekBothVideos);
  }

  @override
  void dispose() {
    bloc.dispose();
    _sliderAllSubject.close();
    _sliderV1Subject.close();
    _sliderV2Subject.close();
    super.dispose();
  }

  // Seek both videos simultaneously
  void _seekBothVideos(double value) {
    final ctrl1 = bloc.chewie1?.videoPlayerController;
    final ctrl2 = bloc.chewie2?.videoPlayerController;

    if (ctrl1 == null || ctrl2 == null) return;
    if (!ctrl1.value.isInitialized || !ctrl2.value.isInitialized) return;

    final wasPlaying1 = ctrl1.value.isPlaying;
    final wasPlaying2 = ctrl2.value.isPlaying;

    if (wasPlaying1) ctrl1.pause();
    if (wasPlaying2) ctrl2.pause();

    final pos1 = Duration(
      milliseconds: value.clamp(0, ctrl1.value.duration.inMilliseconds).toInt(),
    );
    final pos2 = Duration(
      milliseconds: value.clamp(0, ctrl2.value.duration.inMilliseconds).toInt(),
    );
    print("======");
    print(pos1);
    print("++++");
    print(pos2);
    print("======");

    ctrl1.seekTo(pos1);
    ctrl2.seekTo(pos2);

    _sliderV1Subject.add(pos1.inMilliseconds.toDouble());
    _sliderV2Subject.add(pos2.inMilliseconds.toDouble());

    if (wasPlaying1) ctrl1.play();
    if (wasPlaying2) ctrl2.play();
  }

  // Seek individual video 1
  void _seekToVideo1(double value) {
    final ctrl = bloc.chewie1?.videoPlayerController;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    final wasPlaying = ctrl.value.isPlaying;
    if (wasPlaying) ctrl.pause();

    final pos = Duration(
        milliseconds: value.clamp(0, ctrl.value.duration.inMilliseconds).toInt());
    ctrl.seekTo(pos);
    _sliderV1Subject.add(pos.inMilliseconds.toDouble());

    if (wasPlaying) ctrl.play();
  }

  // Seek individual video 2
  void _seekToVideo2(double value) {
    final ctrl = bloc.chewie2?.videoPlayerController;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    final wasPlaying = ctrl.value.isPlaying;
    if (wasPlaying) ctrl.pause();

    final pos = Duration(
        milliseconds: value.clamp(0, ctrl.value.duration.inMilliseconds).toInt());
    ctrl.seekTo(pos);
    _sliderV2Subject.add(pos.inMilliseconds.toDouble());

    if (wasPlaying) ctrl.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Compare AI Demo"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            DualVideoView(bloc: bloc), // Your DualVideoView should use ChewieControllers
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // All-slider (sync both videos)
                  StreamBuilder<double>(
                    stream: _sliderAllSubject.stream,
                    builder: (context, snap) {
                      final value = snap.data ?? 0.0;
                      final max1 = bloc.controller1?.value.duration.inMilliseconds.toDouble() ?? 1.0;
                      final max2 = bloc.controller2?.value.duration.inMilliseconds.toDouble() ?? 1.0;
                      final max = max1 < max2 ? max1 : max2;

                      return Slider(
                        value: value.clamp(0.0, max),
                        min: 0.0,
                        max: max,
                        onChanged: (val) => _sliderAllSubject.add(val),
                      );
                    },
                  ),

                  // 🎥 Video 1 slider
                  StreamBuilder<double>(
                    stream: _sliderV1Subject.stream,
                    builder: (context, snap) {
                      final value = snap.data ?? 0.0;
                      final max = bloc.controller1?.value.duration.inMilliseconds.toDouble() ?? 1.0;
                      return Slider(
                        min: 0.0,
                        max: max,
                        value: value.clamp(0.0, max),
                        onChanged: (val) => _seekToVideo1(val),
                      );
                    },
                  ),

                  // 🎥 Video 2 slider
                  StreamBuilder<double>(
                    stream: _sliderV2Subject.stream,
                    builder: (context, snap) {
                      final value = snap.data ?? 0.0;
                      final max = bloc.controller2?.value.duration.inMilliseconds.toDouble() ?? 1.0;
                      return Slider(
                        min: 0.0,
                        max: max,
                        value: value.clamp(0.0, max),
                        onChanged: (val) => _seekToVideo2(val),
                      );
                    },
                  ),
                  SizedBox(height: 20),

                  ElevatedButton(
                      onPressed: () async {
                        bool result = await bloc.generateVideo();
                        if (result) {
                          log("success");
                        } else {
                          log("failed");
                        }
                      },
                      child: Text("Save to Gallery"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: bloc.setPortrait,
              icon: Icon(Icons.phone_android),
            ),
            SizedBox(width: 40),
            IconButton(
              onPressed: bloc.setVertical,
              icon: Icon(Icons.stay_current_landscape),
            ),
          ],
        ),
      ),
    );
  }
}
