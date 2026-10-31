import '../../core/network/api_client.dart';

class CloudHistoryService {
  static Future<void> syncProgress({
    required String videoIdentifier,
    required String videoTitle,
    required int lastPositionSeconds,
    required int totalDurationSeconds,
  }) async {
    try {
      await ApiClient.dio.post(
        '/history/sync',
        data: {
          'video_identifier': videoIdentifier,
          'video_title': videoTitle,
          'last_position_seconds': lastPositionSeconds,
          'total_duration_seconds': totalDurationSeconds,
        },
      );
    } catch (_) {}
  }

  static Future<List<dynamic>> fetchHistory() async {
    try {
      final response = await ApiClient.dio.get('/history');
      if (response.statusCode == 200) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
