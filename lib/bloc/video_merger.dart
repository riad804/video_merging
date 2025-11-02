import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';

import '../main.dart';

class VideoMerger {
  // static Future<String> mergeVideos({
  //   required File video1,
  //   required File video2,
  //   bool isVertical = true,
  //   int width = 1080,
  //   int height = 1920,
  //   bool loopShorter = true,
  // }) async {
  //   if (!await video1.exists()) throw Exception('video1 not found');
  //   if (!await video2.exists()) throw Exception('video2 not found');
  //
  //   final tempDir = await getTemporaryDirectory();
  //   final outDir = await getApplicationDocumentsDirectory();
  //   final outputPath =
  //       '${outDir.path}/merged_${DateTime.now().millisecondsSinceEpoch}.mp4';
  //
  //   // --- get durations ---
  //   final d1 = await _getDuration(video1.path);
  //   final d2 = await _getDuration(video2.path);
  //   if (d1 <= 0 || d2 <= 0) throw Exception('Could not read video durations');
  //
  //   final maxDuration = d1 > d2 ? d1 : d2;
  //   final shorterIsFirst = d1 < d2;
  //
  //   File? loopedTemp;
  //   String input1 = video1.path;
  //   String input2 = video2.path;
  //
  //   // --- loop shorter video if requested ---
  //   if (loopShorter) {
  //     final shorter = shorterIsFirst ? video1 : video2;
  //     final loopedPath =
  //         '${tempDir.path}/looped_${DateTime.now().millisecondsSinceEpoch}.mp4';
  //
  //     final loopCmd =
  //         '-y -stream_loop -1 -i "${shorter.path}" -t $maxDuration -c copy "$loopedPath"';
  //     final loopSession = await FFmpegKit.execute(loopCmd);
  //     final rc = await loopSession.getReturnCode();
  //     if (!ReturnCode.isSuccess(rc)) {
  //       final logs = await loopSession.getAllLogsAsString();
  //       throw Exception('Failed looping shorter video: $logs');
  //     }
  //
  //     loopedTemp = File(loopedPath);
  //     if (shorterIsFirst) input1 = loopedPath;
  //     else input2 = loopedPath;
  //   }
  //
  //   // Compute half sizes
  //   final halfWidth = isVertical ? width : (width ~/ 2);
  //   final halfHeight = isVertical ? (height ~/ 2) : height;
  //
  //   // Filter for each video: scale up if smaller, else leave size; then center crop
  //   final filter1 =
  //       '[0:v]scale=w=if(gt(iw, $halfWidth),$halfWidth,iw):h=$halfHeight:force_original_aspect_ratio=decrease,'
  //       'crop=$halfWidth:$halfHeight,setsar=1[v1]';
  //   final filter2 =
  //       '[1:v]scale=w=if(gt(iw, $halfWidth),$halfWidth,iw):h=$halfHeight:force_original_aspect_ratio=decrease,'
  //       'crop=$halfWidth:$halfHeight,setsar=1[v2]';
  //
  //   final layoutFilter =
  //   isVertical ? '[v1][v2]vstack=inputs=2[v]' : '[v1][v2]hstack=inputs=2[v]';
  //   final filterComplex = '$filter1;$filter2;$layoutFilter';
  //
  //   final ffmpegCmd =
  //       '-y -i "$input1" -i "$input2" -filter_complex "$filterComplex" '
  //       '-map "[v]" -map 0:a? -c:v libx264 -preset medium -crf 23 '
  //       '-c:a aac -b:a 128k -t $maxDuration "$outputPath"';
  //
  //   print('🧩 FFmpeg command:\n$ffmpegCmd\n');
  //
  //   final session = await FFmpegKit.execute(ffmpegCmd);
  //   final rc = await session.getReturnCode();
  //   final logs = await session.getAllLogsAsString();
  //
  //   // cleanup temporary looped file
  //   if (loopedTemp != null && await loopedTemp.exists()) {
  //     try {
  //       await loopedTemp.delete();
  //     } catch (_) {}
  //   }
  //
  //   if (ReturnCode.isSuccess(rc)) {
  //     print('✅ Merge successful: $outputPath');
  //     return outputPath;
  //   } else {
  //     throw Exception('❌ Merge failed:\n$logs');
  //   }
  // }
  //
  // /// --- get video duration in seconds ---
  // static Future<double> _getDuration(String path) async {
  //   final session =
  //   await FFmpegKit.execute('-i "$path" -hide_banner -f null -');
  //   final logs = await session.getAllLogsAsString();
  //   final match = RegExp(r'Duration:\s*(\d{2}):(\d{2}):(\d{2}\.\d+)')
  //       .firstMatch(logs ?? '');
  //   if (match == null) return 0;
  //   final h = double.parse(match.group(1)!);
  //   final m = double.parse(match.group(2)!);
  //   final s = double.parse(match.group(3)!);
  //   return h * 3600 + m * 60 + s;
  // }

  static Future<String> mergeVideos({
    required File video1,
    required File video2,
    bool isVertical = true,
    int width = 1080,
    int height = 1920,
    bool loopShorter = true,
  }) async {
    if (!await video1.exists()) throw Exception('video1 not found');
    if (!await video2.exists()) throw Exception('video2 not found');

    final tempDir = await getTemporaryDirectory();
    final outDir = await getApplicationDocumentsDirectory();
    final outputPath =
        '${outDir.path}/merged_${DateTime.now().millisecondsSinceEpoch}.mp4';

    // --- get durations ---
    final d1 = await _getDuration(video1.path);
    final d2 = await _getDuration(video2.path);
    if (d1 <= 0 || d2 <= 0) throw Exception('Could not read video durations');

    final maxDuration = d1 > d2 ? d1 : d2;
    final shorterIsFirst = d1 < d2;

    File? loopedTemp;
    String input1 = video1.path;
    String input2 = video2.path;

    // --- loop shorter video if requested ---
    if (loopShorter) {
      final shorter = shorterIsFirst ? video1 : video2;
      final loopedPath =
          '${tempDir.path}/looped_${DateTime.now().millisecondsSinceEpoch}.mp4';

      final loopCmd =
          '-y -stream_loop -1 -i "${shorter.path}" -t $maxDuration -c copy "$loopedPath"';
      final loopSession = await FFmpegKit.execute(loopCmd);
      final rc = await loopSession.getReturnCode();
      if (!ReturnCode.isSuccess(rc)) {
        final logs = await loopSession.getAllLogsAsString();
        throw Exception('Failed looping shorter video: $logs');
      }

      loopedTemp = File(loopedPath);
      if (shorterIsFirst) {
        input1 = loopedPath;
      } else {
        input2 = loopedPath;
      }
    }

    // --- calculate box dimensions ---
    final boxW = width;
    final boxH = isVertical ? (height ~/ 2) : height;

    // Safe filter using min() and center crop
    String buildFilter(int index) {
      return '''
[${index}:v]scale='min(iw*${boxH}/ih,$boxW)':'$boxH':force_original_aspect_ratio=decrease,
crop=${boxW}:${boxH}:((iw-${boxW})/2):0,setsar=1[v$index]
''';
    }

    final filter1 = buildFilter(0);
    final filter2 = buildFilter(1);
    final layoutFilter =
    isVertical ? '[v0][v1]vstack=inputs=2[v]' : '[v0][v1]hstack=inputs=2[v]';

    final filterComplex = '$filter1;$filter2;$layoutFilter';

    final ffmpegCmd =
        '-y -i "$input1" -i "$input2" -filter_complex "$filterComplex" '
        '-map "[v]" -map 0:a? -c:v libx264 -preset medium -crf 23 '
        '-c:a aac -b:a 128k -t $maxDuration "$outputPath"';

    print('🧩 FFmpeg command:\n$ffmpegCmd\n');

    final session = await FFmpegKit.execute(ffmpegCmd);
    final rc = await session.getReturnCode();
    final logs = await session.getAllLogsAsString();

    // cleanup temporary looped file
    if (loopedTemp != null && await loopedTemp.exists()) {
      try {
        await loopedTemp.delete();
      } catch (_) {}
    }

    if (ReturnCode.isSuccess(rc)) {
      print('✅ Merge successful: $outputPath');
      return outputPath;
    } else {
      throw Exception('❌ Merge failed:\n$logs');
    }
  }

  /// Extracts video duration in seconds using FFmpeg
  static Future<double> _getDuration(String path) async {
    final session = await FFmpegKit.execute('-i "$path"');
    final logs = await session.getAllLogsAsString();
    final match = RegExp(r'Duration:\s*(\d+):(\d+):([\d.]+)')
        .firstMatch(logs ?? '');
    if (match == null) return 0;
    final h = double.parse(match.group(1)!);
    final m = double.parse(match.group(2)!);
    final s = double.parse(match.group(3)!);
    return h * 3600 + m * 60 + s;
  }
}