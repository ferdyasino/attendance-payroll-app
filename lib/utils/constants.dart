class Constants {
  // API Configuration
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000/api', // Android Emulator
  );
  
  // Platform-specific API URLs
  static const String localApiUrl = 'http://localhost:3000/api';
  static const String emulatorApiUrl = 'http://10.0.2.2:3000/api';
  static const String productionApiUrl = 'https://api.example.com/api';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  
  // API Endpoints
  static const String loginEndpoint = '/login';
  static const String registerEndpoint = '/register';
  static const String profileEndpoint = '/profile';
  static const String healthEndpoint = '/health';
  
  // Attendance Endpoints
  static const String attendanceBaseEndpoint = '/attendance';
  static const String timeInEndpoint = '/attendance/time-in';
  static const String timeOutEndpoint = '/attendance/time-out';
  static const String userAttendanceEndpoint = '/attendance/user';
  static const String todayAttendanceEndpoint = '/attendance/today';
  
  // User Roles
  static const String roleEmployee = 'employee';
  static const String roleAdmin = 'admin';
  static const String roleSuperadmin = 'superadmin';
  
  // Payroll Endpoints
  static const String payrollBaseEndpoint = '/payroll';
  static const String userPayrollEndpoint = '/payroll/user';
  static const String payrollSummaryEndpoint = '/payroll/summary';
  static const String computePayrollEndpoint = '/payroll/compute';
  
  // App Configuration
  static const String appName = 'Attendance Payroll System';
  static const String appVersion = '1.0.0';
  // Timeout Configuration
  static const int requestTimeoutSeconds = 30;
  static const int connectionTimeoutSeconds = 10;
}

