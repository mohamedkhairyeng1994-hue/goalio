import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';

final unreadNotificationsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  return await ApiService.getUnreadNotificationsCount();
});

class NotificationsNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    return await ApiService.getNotifications(page: 1);
  }

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || _isLoadingMore) return;

    final data = currentState['data'] as List?;
    final currentPage = currentState['current_page'] ?? 1;
    final lastPage = currentState['last_page'] ?? 1;

    if (currentPage >= lastPage) return;

    _isLoadingMore = true;
    try {
      final nextPage = currentPage + 1;
      final response = await ApiService.getNotifications(page: nextPage);
      
      final List<dynamic> newData = response['data'] ?? [];
      
      state = AsyncValue.data({
        ...response,
        'data': [...?data, ...newData],
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> markAsRead(int id) async {
    final success = await ApiService.markNotificationAsRead(id);
    if (success) {
      ref.invalidate(unreadNotificationsCountProvider);
      // Update local state if needed, or just refresh
      ref.invalidateSelf();
    }
  }

  Future<void> markAllAsRead() async {
    final success = await ApiService.markAllNotificationsAsRead();
    if (success) {
      ref.invalidate(unreadNotificationsCountProvider);
      ref.invalidateSelf();
    }
  }
}

final notificationsProvider = AsyncNotifierProvider<NotificationsNotifier, Map<String, dynamic>>(() {
  return NotificationsNotifier();
});
