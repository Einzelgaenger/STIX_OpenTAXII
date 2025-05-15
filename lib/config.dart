class AppConfig {
  static const String baseUrl = 'http://172.16.11.159:8000';

  static const String addDeviceUrl = '$baseUrl/add_device';
  static const String listSourcesUrl = '$baseUrl/list_sources';
  static const String syncSourcesUrl = '$baseUrl/sync_sources'; // << Tambahan
  static const String pushStixUrl = '$baseUrl/push';
  static const String listStixUrl = '$baseUrl/list_stix';
  static const String deleteStixUrl = '$baseUrl/delete_stix';
  static const String deleteCollectionUrl = '$baseUrl/delete_collection';
  static const String pollAuthenticateUrl = '$baseUrl/poll_stix_authenticate';
  static const String getDevicesUrl = '$baseUrl/get_devices';
  static const String deleteDeviceUrl = '$baseUrl/delete_device';
  static const String deviceDetailUrl = '$baseUrl/device_detail';
  static const String updateSourceConfigUrl = '$baseUrl/update_source_config';
}
