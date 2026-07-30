class GameLogger {
  final List<String> _logs = [];

  void log(String message) {
    final timestamp = DateTime.now();
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    _logs.add('[$timeStr] $message');
  }

  void clear() {
    _logs.clear();
  }

  String get fullLog => _logs.join('\n');

  bool get isEmpty => _logs.isEmpty;
}
