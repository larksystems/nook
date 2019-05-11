LogLevel logLevel = LogLevel.DEBUG;

enum LogLevel {
  ERROR,
  WARNING,
  DEBUG,
  VERBOSE
}

class Logger {
  String name;

  Logger(this.name);

  void error(String s) {
    _log(s);
  }

  void warning(String s) {
    switch (logLevel) {
      case LogLevel.ERROR:
        return;
      default:
        _log(s);
    }
  }

  void debug(String s) {
    switch (logLevel) {
      case LogLevel.WARNING:
      case LogLevel.ERROR:
        return;
      default:
        _log(s);
    }
  }

  void verbose(String s) {
    switch (logLevel) {
      case LogLevel.DEBUG:
      case LogLevel.WARNING:
      case LogLevel.ERROR:
        return;
      default:
        _log(s);
    }
  }

  void _log(String s) {
    print ("${DateTime.now().toIso8601String()} $name: $s");
  }

}
