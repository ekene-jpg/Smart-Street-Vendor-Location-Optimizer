// Point this at your deployed backend.
// - Android emulator talking to a backend on your dev machine: http://10.0.2.2:4000/api
// - iOS simulator talking to a backend on your dev machine:    http://localhost:4000/api
// - Physical device / production:                              https://your-domain.com/api
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000/api',
  );
}
