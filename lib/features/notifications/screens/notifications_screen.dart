import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/core/theme/paikari_theme.dart';
import 'package:paikari_shop/features/notifications/models/marketplace_notification.dart';
import 'package:paikari_shop/features/notifications/repositories/notification_repository.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(myNotificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _MessageState(message: 'Notification load করা যায়নি: $error', onRetry: () => ref.invalidate(myNotificationsProvider)),
        data: (items) => items.isEmpty
            ? const _MessageState(message: 'এখনও কোনো notification নেই')
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(myNotificationsProvider),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _NotificationListTile(notification: items[index]),
                ),
              ),
      ),
    );
  }
}

class _NotificationListTile extends ConsumerWidget {
  final MarketplaceNotification notification;

  const _NotificationListTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = notification.readAt == null;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: unread ? PaikariTheme.primaryColor.withValues(alpha: 0.08) : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(child: Icon(_iconFor(notification.notificationType))),
        title: Text(notification.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('${notification.body}\n${notification.createdAt.toLocal()}', maxLines: 3, overflow: TextOverflow.ellipsis),
        ),
        onTap: unread
            ? () async {
                await ref.read(notificationRepositoryProvider).markRead(notification.id);
                ref.invalidate(myNotificationsProvider);
              }
            : null,
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'payment':
        return Icons.payments_outlined;
      case 'return':
        return Icons.assignment_return_outlined;
      case 'order_status':
        return Icons.local_shipping_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }
}

class _MessageState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _MessageState({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_outlined, size: 54, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('আবার চেষ্টা করুন')),
            ],
          ],
        ),
      ),
    );
  }
}
