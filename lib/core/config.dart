const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api',
);

const apiDelayMs = int.fromEnvironment('API_DELAY', defaultValue: 0);
const apiFailCode = int.fromEnvironment('API_FAIL', defaultValue: 0);

/// Бездействие до выхода, секунды. По заданию — 3 минуты.
const inactivityTimeoutSeconds = int.fromEnvironment(
  'INACTIVITY_TIMEOUT',
  defaultValue: 180,
);

/// Предупреждение до выхода по бездействию, секунды.
const inactivityWarningSeconds = int.fromEnvironment(
  'INACTIVITY_WARNING',
  defaultValue: 30,
);

/// Максимальная длительность сессии независимо от активности, минуты.
const sessionMaxMinutes = int.fromEnvironment(
  'SESSION_MAX_MINUTES',
  defaultValue: 30,
);
