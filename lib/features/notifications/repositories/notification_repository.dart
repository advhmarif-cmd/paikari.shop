import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:paikari_shop/features/notifications/models/marketplace_notification.dart';

class NotificationRepository {
  NotificationRepository({SupabaseClient? client}) : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Stream<List<MarketplaceNotification>> watchMyNotifications() {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();
    return _supabase
        .from('order_notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', user.id)
        .order('created_at', ascending: false)
        .map((rows) => rows.map((row) => MarketplaceNotification.fromJson(Map<String, dynamic>.from(row))).take(20).toList());
  }

  Future<void> markRead(String notificationId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('লগইন করা প্রয়োজন');
    await _supabase.rpc('mark_order_notification_read', params: {'p_notification_id': notificationId});
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final myNotificationsProvider = StreamProvider<List<MarketplaceNotification>>((ref) {
  return ref.watch(notificationRepositoryProvider).watchMyNotifications();
});
