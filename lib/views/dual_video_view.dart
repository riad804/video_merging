import 'dart:async';
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:compare_ai_demo/bloc/video_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:video_player/video_player.dart';

class DualVideoView extends StatefulWidget {
  const DualVideoView({super.key, required this.bloc});

  final VideoBloc bloc;

  @override
  State<DualVideoView> createState() => _DualVideoViewState();
}

class _DualVideoViewState extends State<DualVideoView> {
  Timer? _overlayTimer1;
  final _overlayVisible1 = ValueNotifier<bool>(true);

  Timer? _overlayTimer2;
  final _overlayVisible2 = ValueNotifier<bool>(true);

  final _isPlayingSubject1 = BehaviorSubject.seeded(false);
  final _isPlayingSubject2 = BehaviorSubject.seeded(false);

  void _restartOverlayTimer1() {
    _overlayTimer1?.cancel();
    _overlayVisible1.value = true;
    _overlayTimer1 = Timer(const Duration(seconds: 1), () {
      _overlayVisible1.value = false;
    });
  }


  void _restartOverlayTimer2() {
    _overlayTimer2?.cancel();
    _overlayVisible2.value = true;
    _overlayTimer2 = Timer(const Duration(seconds: 1), () {
      _overlayVisible2.value = false;
    });
  }

  Future<void> _pickVideo(int index) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.first.path != null) {
      final file = File(result.files.first.path!);
      if (index == 1) {
        await widget.bloc.setVideo1(file);
      } else {
        await widget.bloc.setVideo2(file);
      }
    }
  }

  Widget _buildPlayer(ChewieController? controller, int index) {
    if (controller == null) {
      print("controller null");
      return GestureDetector(
        onTap: () async {
          if (index == 1) {
            _pickVideo(index);
          } else {
            _pickVideo(index);
          }
        },
        child: Container(
          color: Colors.white70,
          width: double.maxFinite,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Add Video'),
              Icon(Icons.add, size: 24),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final width = constraints.maxWidth;

        return GestureDetector(
          onTap: index == 1 ? _restartOverlayTimer1 : _restartOverlayTimer2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                width: width,
                height: height,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FittedBox(
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: controller.videoPlayerController.value.size.width,
                    height: controller.videoPlayerController.value.size.height,
                    child: VideoPlayer(controller.videoPlayerController),
                  ),
                ),
              ),

              /// Overlay play/pause button
              ValueListenableBuilder<bool>(
                valueListenable: index == 1 ? _overlayVisible1 : _overlayVisible2,
                builder: (context, visible, _) {
                  return AnimatedOpacity(
                    opacity: visible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    child: GestureDetector(
                      onTap: () {
                        if (controller.isPlaying) {
                          controller.pause();
                        } else {
                          controller.play();
                        }
                        if (index == 1) {
                          _restartOverlayTimer1();
                        } else {
                          _restartOverlayTimer2();
                        }
                      },
                      child: Container(
                        height: height,
                        width: width,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.black45,
                        ),
                        padding: const EdgeInsets.all(12),
                        child: StreamBuilder(
                          stream: index == 1 ? _isPlayingSubject1.stream : _isPlayingSubject2.stream,
                          builder: (context, snap) {
                            final isPlaying = snap.data ?? false;
                            return Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 48,
                            );
                          }
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    widget.bloc.video1Stream.listen((controller) {
      if (controller != null) {
        controller.addListener(() {
          _isPlayingSubject1.add(controller.value.isPlaying);
        });
      }
    });

    widget.bloc.video2Stream.listen((controller) {
      if (controller != null) {
        controller.addListener(() {
          _isPlayingSubject2.add(controller.value.isPlaying);
        });
      }
    });
  }

  @override
  void dispose() {
    _overlayTimer1?.cancel();
    _overlayVisible1.dispose();

    _overlayTimer2?.cancel();
    _overlayVisible2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.width,
      width: double.maxFinite,
      decoration: BoxDecoration(
        color: Color(0xFF121212),
      ),
      child: StreamBuilder(
        stream: widget.bloc.isVerticalStream,
        initialData: true,
        builder: (ctx, snap) {
          final isVertical = snap.data ?? true;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) => RotationTransition(turns: animation, child: child),
            child: StreamBuilder(
              stream: Rx.combineLatest2(
                widget.bloc.chewie1Stream.startWith(null),
                widget.bloc.chewie2Stream.startWith(null),
                  (v1, v2) => [v1, v2],
              ),
              builder: (ctx, snap) {
                final controllers = snap.data ?? [null, null];
                final v1 = controllers[0];
                final v2 = controllers[1];

                final player1 = _buildPlayer(v1, 1);
                final player2 = _buildPlayer(v2, 2);

                return isVertical
                    ? Column(
                  key: const ValueKey('vertical'),
                  children: [
                    Expanded(child: player1),
                    const SizedBox(height: 4),
                    Expanded(child: player2),
                  ],
                )
                    : Row(
                  key: const ValueKey('horizontal'),
                  children: [
                    Expanded(child: player1),
                    const SizedBox(width: 4),
                    Expanded(child: player2),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
