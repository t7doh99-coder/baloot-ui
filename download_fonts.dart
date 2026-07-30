import 'dart:io';

void main() async {
  final dir = Directory('assets/fonts');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  final urls = {
    'ReadexPro-Regular.ttf': 'https://github.com/ThomasJockin/readexpro/raw/master/fonts/ttf/ReadexPro-Regular.ttf',
    'ReadexPro-Bold.ttf': 'https://github.com/ThomasJockin/readexpro/raw/master/fonts/ttf/ReadexPro-Bold.ttf',
    'ReadexPro-Light.ttf': 'https://github.com/ThomasJockin/readexpro/raw/master/fonts/ttf/ReadexPro-Light.ttf',
    'ReadexPro-SemiBold.ttf': 'https://github.com/ThomasJockin/readexpro/raw/master/fonts/ttf/ReadexPro-SemiBold.ttf',
  };

  for (final entry in urls.entries) {
    final fileName = entry.key;
    final url = entry.value;
    print('Downloading $fileName...');
    try {
      final request = await HttpClient().getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == 200) {
        final file = File('assets/fonts/$fileName');
        await response.pipe(file.openWrite());
        print('Saved $fileName successfully.');
      } else {
        print('Failed to download $fileName: ${response.statusCode}');
      }
    } catch (e) {
      print('Error downloading $fileName: $e');
    }
  }
}
