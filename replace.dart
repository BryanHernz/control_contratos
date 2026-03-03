import 'dart:io';

void main() {
  final dir = Directory('lib');
  // Match the exact pattern split across lines as it often is
  final pattern = RegExp(
      r'maxWidth:\s*MediaQuery\.of\(context\)\s*\.size\s*\.width\s*\*\s*0\.95');
  const replacement =
      'maxWidth: MediaQuery.of(context).size.width > 800 ? 600 : MediaQuery.of(context).size.width * 0.95';

  int totalReplaced = 0;

  for (var entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      if (pattern.hasMatch(content)) {
        final newContent = content.replaceAll(pattern, replacement);
        entity.writeAsStringSync(newContent);
        print('Updated ${entity.path}');
        totalReplaced++;
      }
    }
  }
  print('Done. Replaced in $totalReplaced files.');
}
