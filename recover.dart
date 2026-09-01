
import 'dart:io';

void main() {
  final historyDir = Directory(Platform.environment['APPDATA']! + r'\Code\User\History');
  if (!historyDir.existsSync()) {
    print('No history');
    return;
  }
  File? foundFile;
  final files = historyDir.listSync(recursive: true).whereType<File>();
  for (final file in files) {
    try {
      final content = file.readAsStringSync();
      if (content.contains('void startQaydha(QaydhaActionType action)') && content.contains('class GameProvider')) {
        print('Found it');
        foundFile = file;
        break;
      }
    } catch (e) {}
  }
  if (foundFile != null) {
    foundFile.copySync('game_provider_backup.dart');
    print('Copied to game_provider_backup.dart');
  } else {
    print('Not found');
  }
}

