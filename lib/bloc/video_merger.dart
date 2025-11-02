import 'dart:io';
import 'dart:math';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';

class VideoMerger {
  static Future<String> mergeVideos({
    required File video1,
    required File video2,
    bool isVertical = true,
    int width = 1080,
    int height = 1920,
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

    File? loopedTemp;
    String input1 = video1.path;
    String input2 = video2.path;

    // --- ensure even dimensions ---
    int even(int v) => v.isEven ? v : v - 1;
    final boxW = even(isVertical ? width : (width ~/ 2));
    final boxH = even(isVertical ? (height ~/ 2) : height);

    String buildFilter(int idx) {
      int safeBoxW = boxW.isEven ? boxW : boxW - 1;
      int safeBoxH = boxH.isEven ? boxH : boxH - 1;

      // Scale so video covers the box entirely, crop the overflow
      return "[${idx}:v]"
          "scale='if(gt(iw/ih,${safeBoxW}/${safeBoxH}),-2,${safeBoxW})':'if(gt(iw/ih,${safeBoxW}/${safeBoxH}),${safeBoxH},-2)',"
          "crop=${safeBoxW}:${safeBoxH}:(iw-${safeBoxW})/2:(ih-${safeBoxH})/2,"
          "setsar=1[v${idx}]";
    }

    final f1 = buildFilter(0);
    final f2 = buildFilter(1);
    final layoutFilter =
    isVertical ? '[v0][v1]vstack=inputs=2[v]' : '[v0][v1]hstack=inputs=2[v]';
    final filterComplex = '$f1;$f2;$layoutFilter';

    // --- FFmpeg command ---
    final ffmpegCmd =
        '-y -i "$input1" -i "$input2" -filter_complex "$filterComplex" '
        '-map "[v]" -map 0:a? -c:v libx264 -preset medium -crf 23 '
        '-c:a aac -b:a 128k -shortest -t $maxDuration -movflags +faststart "$outputPath"';

    print('🧩 FFmpeg command:\n$ffmpegCmd\n');

    try {
      final session = await FFmpegKit.execute(ffmpegCmd);
      final rc = await session.getReturnCode();
      final logs = await session.getAllLogsAsString();

      if (ReturnCode.isSuccess(rc)) {
        print('✅ Merge successful: $outputPath');
        return outputPath;
      } else {
        throw Exception('❌ Merge failed:\n$logs');
      }
    } finally {
      if (loopedTemp != null && await loopedTemp.exists()) await loopedTemp.delete();
    }
  }

  static Future<double> _getDuration(String path) async {
    final session = await FFprobeKit.getMediaInformation(path);
    final info = session.getMediaInformation();
    final durationStr = info?.getDuration();
    return double.tryParse(durationStr ?? '0') ?? 0;
  }

}