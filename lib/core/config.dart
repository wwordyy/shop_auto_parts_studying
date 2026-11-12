const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api',
);

const apiDelayMs = int.fromEnvironment('API_DELAY', defaultValue: 0);
const apiFailCode = int.fromEnvironment('API_FAIL', defaultValue: 0);

const apiLogin = String.fromEnvironment('API_LOGIN', defaultValue: 'admin');
const apiPassword = String.fromEnvironment('API_PASSWORD', defaultValue: 'admin123');
