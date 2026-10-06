class AppConfig {
  static const String apiBase = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://84.16.235.111:2193/api',
  );
  static const int locationEverySeconds = 10;
  static const int maxBufferedPoints = 5000;
  static const int maxPointsPerSend = 300;
  static const Duration requestTimeout = Duration(seconds: 20);
  static const Duration profilePoll = Duration(seconds: 60);
  static const Duration liveDebounce = Duration(milliseconds: 300);
}
