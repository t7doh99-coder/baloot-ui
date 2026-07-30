import 'dart:convert';
import 'dart:io';

void main() async {
  final transcriptPath = r'C:\Users\Abdul Sami\.gemini\antigravity-ide\brain\922581bc-7a82-4a33-8214-02c901a3e14d\.system_generated\logs\transcript.jsonl';
  final file = File(transcriptPath);
  final lines = await file.readAsLines();

  for (final line in lines) {
    if (line.contains('Blue Clash-Royale-style')) {
      final data = jsonDecode(line);
      if (data['type'] == 'TOOL_CALL' && data.containsKey('tool_calls')) {
        for (final tc in data['tool_calls']) {
          if (tc['name'] == 'write_to_file' && tc['args'] != null) {
            final args = tc['args'];
            final fileStr = args.toString();
            if (fileStr.contains('test_screen_3')) {
              // Note: the args string from the json might be stringified, so let's check it.
              // We need the CodeContent.
              print('Found tool call for test_screen_3.dart!');
              // Wait, the args might be a Map if it's already decoded.
              if (args is Map) {
                final content = args['CodeContent'];
                if (content != null) {
                  final outFile = File(r'e:\my projects\baloot-ui\lib\features\dashboard\presentation\test_screen_3.dart');
                  await outFile.writeAsString(content);
                  print('Restored successfully from parsed args.');
                  return;
                }
              }
              // If it's a string, we might need to parse it or just fall back to regex
              print('args is not a Map, or CodeContent is missing. It is: ${args.runtimeType}');
            }
          }
        }
      }
    }
  }
  print('Could not find the restore point.');
}
