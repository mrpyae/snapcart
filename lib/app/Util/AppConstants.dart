class AppConstants {
  // Base URLs
  static String domain = "http://localhost/snapcartapi/WebAPI/";
  
  static String get apiBaseUrl => "${domain}api/";
  static String get authUrl => "${apiBaseUrl}authapi.php";
  static String get syncUrl => "${apiBaseUrl}syncapi.php";
  static String get productUrl => "${apiBaseUrl}productapi.php";
  static String get categoryUrl => "${apiBaseUrl}categoryapi.php";
  static String get customerUrl => "${apiBaseUrl}customerapi.php";
  static String get saleOrderUrl => "${apiBaseUrl}saleorderapi.php";
  static String get expenseUrl => "${apiBaseUrl}expenseapi.php";

  // App Metadata
  static const String appName = "SnapCart POS";
  static const String defaultBusinessId = "default_biz";
  static const String currency = "Ks";
}