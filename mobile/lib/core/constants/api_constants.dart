class ApiConstants {
  // OTruyen API Endpoints
  static const String otruyenBaseUrl = 'https://otruyenapi.com/v1/api';
  static const String otruyenChapterBaseUrl = 'https://sv1.otruyencdn.com/v1/api/chapter';
  static const String otruyenImageBaseCdn = 'https://img.otruyenapi.com/uploads/comics';

  // RockyDex Backend API Endpoints (Local development)
  // For android emulator, use 10.0.2.2 instead of localhost
  static const String rockydexBaseUrl = 'http://localhost:8080/api';
  static const String rockydexEmulatorBaseUrl = 'http://10.0.2.2:8080/api';

  // OTruyen Paths
  static const String pathHome = '/home';
  static const String pathSearch = '/tim-kiem';
  static const String pathComicDetail = '/truyen-tranh';
  static const String pathCategories = '/the-loai';
  static const String pathList = '/danh-sach';

  // List types
  static const String listNew = 'truyen-moi';
  static const String listFeatured = 'truyen-noi-bat';
  static const String listCompleted = 'hoan-thanh';
  static const String listOngoing = 'dang-phat-hanh';
  static const String listComingSoon = 'sap-ra-mat';
}
