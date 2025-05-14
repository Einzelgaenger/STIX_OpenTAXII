class AppConfig {
  static const String backendBaseUrl = 'http://172.16.11.159:8000';

  static const String addDeviceUrl = '$backendBaseUrl/add_device';
  static const String listSourcesUrl = '$backendBaseUrl/list_sources';
  static const String pushStixUrl = '$backendBaseUrl/push';
  static const String listStixUrl = '$backendBaseUrl/list_stix';
  static const String deleteStixUrl = '$backendBaseUrl/delete_stix';
  static const String deleteCollectionUrl = '$backendBaseUrl/delete_collection';
  static const String pollAuthenticateUrl =
      '$backendBaseUrl/poll_stix_authenticate';
}
