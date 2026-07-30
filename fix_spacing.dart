import 'dart:io';

void main() {
  final file = File('lib/features/game/presentation/widgets/scoring_overlays.dart');
  final lines = file.readAsLinesSync();
  
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('letterSpacing:')) {
      // Find what the variable for Arabic is by looking back up to 20 lines
      String arVar = 'isAr';
      bool foundAr = false;
      for(int j = i; j >= (i-30 > 0 ? i-30 : 0); j--) {
         if (lines[j].contains('isArabic')) {
           arVar = 'isArabic';
           foundAr = true;
           break;
         } else if (lines[j].contains('isAr')) {
           arVar = 'isAr';
           foundAr = true;
           break;
         } else if (lines[j].contains('ar ?')) {
           arVar = 'ar';
           foundAr = true;
           break;
         }
      }
      if (!foundAr) {
        arVar = 'context.read<LocaleProvider>().isArabic';
      }

      // Replace letterSpacing: X, with letterSpacing: arVar ? 0 : X,
      if (!lines[i].contains('? 0 :')) {
        final match = RegExp(r'letterSpacing:\s*([0-9.]+),?').firstMatch(lines[i]);
        if (match != null) {
          final val = match.group(1);
          lines[i] = lines[i].replaceFirst(
            match.group(0)!, 
            'letterSpacing: $arVar ? 0 : $val,'
          );
          print('Replaced line ${i+1}: ${lines[i].trim()}');
        }
      }
    }
  }
  
  file.writeAsStringSync(lines.join('\n'));
  print('Done!');
}
