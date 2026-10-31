class SubtitleItem {
  final Duration start;
  final Duration end;
  final String text;

  SubtitleItem({required this.start, required this.end, required this.text});
}

class SubtitleParser {
  static List<SubtitleItem> parseSrt(String srtContent) {
    final List<SubtitleItem> items = [];
    final lines = srtContent
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');

    int index = 0;
    while (index < lines.length) {
      if (lines[index].trim().isEmpty) {
        index++;
        continue;
      }

      index++;
      if (index >= lines.length) break;

      final timeLine = lines[index].trim();
      if (!timeLine.contains('-->')) {
        index++;
        continue;
      }

      final times = timeLine.split('-->');
      final start = _parseDuration(times[0].trim());
      final end = _parseDuration(times[1].trim());

      index++;
      final StringBuffer textBuffer = StringBuffer();
      while (index < lines.length && lines[index].trim().isNotEmpty) {
        textBuffer.writeln(lines[index].trim());
        index++;
      }

      items.add(
        SubtitleItem(
          start: start,
          end: end,
          text: textBuffer.toString().trim(),
        ),
      );
    }
    return items;
  }

  static Duration _parseDuration(String timeString) {
    final parts = timeString.replaceAll(',', '.').split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final secondsParts = parts[2].split('.');
    final seconds = int.parse(secondsParts[0]);
    final milliseconds = int.parse(
      secondsParts[1].padRight(3, '0').substring(0, 3),
    );

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );
  }
}
