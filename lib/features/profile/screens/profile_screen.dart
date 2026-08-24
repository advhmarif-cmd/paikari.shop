import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/features/profile/providers/profile_providers.dart';
import 'package:paikari_shop/features/auth/repositories/auth_repository.dart';
import 'package:paikari_shop/core/theme/paikari_theme.dart';
import 'package:paikari_shop/features/vendors/providers/vendor_provider.dart';
import 'package:paikari_shop/features/buyer/providers/business_buyer_provider.dart';
import 'package:paikari_shop/features/quotations/models/quotation_request.dart';
import 'package:paikari_shop/features/quotations/providers/quotation_provider.dart';
import 'package:paikari_shop/features/quotations/repositories/quotation_repository.dart';
import 'package:paikari_shop/features/quotations/widgets/quote_checkout_sheet.dart';
import 'package:paikari_shop/features/checkout/providers/order_provider.dart';
import 'package:paikari_shop/features/checkout/models/order.dart';
import 'package:paikari_shop/features/cart/providers/cart_provider.dart';
import 'package:paikari_shop/features/products/repositories/product_repository.dart';
import 'package:paikari_shop/features/checkout/models/order_status_event.dart';
import 'package:paikari_shop/features/notifications/models/marketplace_notification.dart';
import 'package:paikari_shop/features/notifications/repositories/notification_repository.dart';
import 'package:paikari_shop/features/returns/repositories/return_repository.dart';
import 'package:paikari_shop/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ordersAsync = ref.watch(profileOrdersProvider);
    final userAsync = ref.watch(userProvider);
    final vendorAsync = ref.watch(myVendorProfileProvider);
    final buyerAsync = ref.watch(myBusinessBuyerProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          IconButton(
            tooltip: 'লগআউট',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            userAsync.when(
              data: (user) => _ProfileHeader(
                name: user?.displayName ?? 'ব্যবহারকারী',
                email: user?.email ?? '',
                businessName: user?.businessName,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('User error: $err')),
            ),
            const SizedBox(height: 24),
            vendorAsync.when(
              data: (vendor) => _VendorCard(
                storeName: vendor?.storeName,
                status: vendor?.verificationStatus,
                onOpen: () => Navigator.pushNamed(context, vendor == null ? '/vendor/onboarding' : '/vendor/dashboard'),
              ),
              loading: () => const SizedBox(height: 8),
              error: (_, __) => _VendorCard(
                onOpen: () => Navigator.pushNamed(context, '/vendor/onboarding'),
              ),
            ),
            const SizedBox(height: 12),
            buyerAsync.when(
              data: (buyer) => _BusinessBuyerCard(
                businessName: buyer?.businessName,
                status: buyer?.buyerStatus,
                onOpen: () => Navigator.pushNamed(context, '/buyer/business'),
              ),
              loading: () => const SizedBox(height: 8),
              error: (_, __) => _BusinessBuyerCard(onOpen: () => Navigator.pushNamed(context, '/buyer/business')),
            ),
            const SizedBox(height: 18),
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.support_agent_outlined)),
                title: const Text('নীতি ও সাহায্য', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Privacy, Terms, Return ও Support information'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/support/policies'),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Recent updates', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            ref.watch(myNotificationsProvider).when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => Row(
                children: [
                  Expanded(child: Text('Notification load করা যায়নি', style: TextStyle(color: Colors.grey.shade700))),
                  IconButton(tooltip: 'আবার চেষ্টা করুন', onPressed: () => ref.invalidate(myNotificationsProvider), icon: const Icon(Icons.refresh)),
                ],
              ),
              data: (notifications) => notifications.isEmpty
                  ? const Text('এখনও কোনো নতুন update নেই', style: TextStyle(color: Colors.grey))
                  : Column(children: notifications.take(3).map((notification) => _NotificationTile(notification: notification)).toList()),
            ),
            const SizedBox(height: 24),
            const Text('My quotations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            ref.watch(buyerQuotationsProvider).when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => Text('Quotation load করা যায়নি: $error'),
              data: (quotes) => quotes.isEmpty
                  ? const Text('এখনও কোনো quotation নেই', style: TextStyle(color: Colors.grey))
                  : Column(children: quotes.map((quote) => _BuyerQuoteTile(quote: quote, onAccept: () => _acceptQuote(context, ref, quote))).toList()),
            ),
            const SizedBox(height: 28),
            Text(l10n.myOrders, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            ordersAsync.when(
              data: (orders) => orders.isEmpty
                  ? const _EmptyOrders()
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
                          child: ListTile(
                            onTap: order.orderGroupId == null ? null : () => _showOrderTracking(context, ref, order),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            title: Text('অর্ডার #${order.id.substring(order.id.length - 6)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text('${l10n.orderDate}: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt)}\n${l10n.status}: ${_orderStatusLabel(order.status)}\nPayment: ${_paymentStatusLabel(order.paymentStatus)}'),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('৳${order.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: PaikariTheme.primaryColor)),
                                if (order.items.isNotEmpty)
                                  TextButton(onPressed: () => _reorder(context, ref, order), child: const Text('আবার কিনুন')),
                                if (order.orderGroupId != null && {OrderStatus.pending, OrderStatus.confirmed, OrderStatus.processing}.contains(order.status))
                                  TextButton(onPressed: () => _cancelOrder(context, ref, order), child: const Text('Cancel')),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: OutlinedButton.icon(
                  onPressed: () => ref.invalidate(profileOrdersProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Order আবার লোড করুন'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _reorder(BuildContext context, WidgetRef ref, Order order) async {
  var addedCount = 0;
  var skippedCount = 0;
  final productRepository = ref.read(productRepositoryProvider);
  final cartNotifier = ref.read(cartProvider.notifier);

  for (final item in order.items) {
    try {
      final currentProduct = await productRepository.getProductById(item.product.id);
      if (currentProduct == null || !currentProduct.isAvailable) {
        skippedCount++;
        continue;
      }
      cartNotifier.addItem(
        currentProduct,
        businessMode: item.businessMode,
        quantity: item.quantity,
      );
      addedCount++;
    } catch (_) {
      skippedCount++;
    }
  }

  if (!context.mounted) return;
  if (addedCount == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('এই order-এর কোনো পণ্য এখন available নেই।')),
    );
    return;
  }
  final message = skippedCount == 0
      ? '$addedCount টি পণ্য cart-এ যোগ হয়েছে।'
      : '$addedCount টি পণ্য যোগ হয়েছে; $skippedCount টি এখন available নেই।';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  Navigator.pushNamed(context, '/cart');
}

Future<void> _cancelOrder(BuildContext context, WidgetRef ref, Order order) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Order cancel করবেন?'),
      content: const Text('Reserved stock থাকলে সেটি release করা হবে।'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('না')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('হ্যাঁ, cancel করুন')),
      ],
    ),
  );
  if (confirmed != true || order.orderGroupId == null) return;
  try {
    await ref.read(orderRepositoryProvider).cancelOrderGroup(order.orderGroupId!);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order cancel হয়েছে এবং stock release করা হয়েছে'), behavior: SnackBarBehavior.floating));
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order cancel করা যায়নি: $error'), behavior: SnackBarBehavior.floating));
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? businessName;

  const _ProfileHeader({required this.name, required this.email, this.businessName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const CircleAvatar(radius: 42, child: Icon(Icons.person, size: 44)),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(email, style: TextStyle(color: Colors.grey.shade600)),
          ],
          if (businessName != null && businessName!.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(businessName!, style: const TextStyle(color: PaikariTheme.secondaryColor, fontWeight: FontWeight.w800)),
          ],
        ],
      ),
    );
  }
}

class _VendorCard extends StatelessWidget {
  final String? storeName;
  final String? status;
  final VoidCallback onOpen;

  const _VendorCard({this.storeName, this.status, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final hasProfile = storeName != null && storeName!.trim().isNotEmpty;
    final statusLabel = status == 'verified' ? 'Verified' : status == 'rejected' ? 'Rejected' : 'Approval pending';
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: PaikariTheme.primaryColor.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: PaikariTheme.primaryColor.withValues(alpha: 0.15))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.storefront_outlined, color: PaikariTheme.primaryColor, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hasProfile ? storeName! : 'আপনার supplier store তৈরি করুন', style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(hasProfile ? statusLabel : 'B2B buyer ও supplier marketplace-এ যোগ দিন', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                ],
              ),
            ),
            IconButton(tooltip: 'Vendor setup', onPressed: onOpen, icon: const Icon(Icons.arrow_forward_ios, size: 18)),
          ],
        ),
      ),
    );
  }
}

class _BusinessBuyerCard extends StatelessWidget {
  final String? businessName;
  final String? status;
  final VoidCallback onOpen;

  const _BusinessBuyerCard({this.businessName, this.status, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final hasProfile = businessName != null && businessName!.trim().isNotEmpty;
    final statusLabel = status == 'verified' ? 'Verified buyer' : 'Profile setup';
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: PaikariTheme.secondaryColor.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: PaikariTheme.secondaryColor.withValues(alpha: 0.15))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.business_center_outlined, color: PaikariTheme.secondaryColor, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hasProfile ? businessName! : 'B2B buyer profile তৈরি করুন', style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(hasProfile ? statusLabel : 'MOQ, wholesale tier ও supplier sourcing-এর জন্য', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                ],
              ),
            ),
            IconButton(tooltip: 'B2B buyer setup', onPressed: onOpen, icon: const Icon(Icons.arrow_forward_ios, size: 18)),
          ],
        ),
      ),
    );
  }
}

Future<void> _acceptQuote(BuildContext context, WidgetRef ref, QuotationRequest quote) async {
  try {
    final accepted = await ref.read(quotationRepositoryProvider).accept(quote.id);
    if (!context.mounted) return;
    if (accepted.checkoutSessionId != null) {
      await Navigator.pushNamed(context, '/quote/checkout', arguments: accepted.checkoutSessionId);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quotation accepted হয়েছে'), behavior: SnackBarBehavior.floating));
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quotation accept করা যায়নি: $error'), behavior: SnackBarBehavior.floating));
  }
}

class _BuyerQuoteTile extends StatelessWidget {
  final QuotationRequest quote;
  final VoidCallback onAccept;

  const _BuyerQuoteTile({required this.quote, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    final hasQuote = (quote.status == 'quoted' || quote.status == 'accepted') && quote.quotedUnitPrice != null && quote.checkoutSessionId != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: const CircleAvatar(child: Icon(Icons.request_quote_outlined)),
        title: Text('${quote.requestedQuantity} units · ${quote.status}', style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(hasQuote ? 'Vendor quote: ৳${quote.quotedUnitPrice!.toStringAsFixed(0)} / unit' : quote.message, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: hasQuote ? TextButton(onPressed: onAccept, child: Text(quote.status == 'accepted' ? 'Order' : 'Accept')) : null,
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 42, color: Colors.grey),
          SizedBox(height: 8),
          Text('কোনো অর্ডার পাওয়া যায়নি', style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

Future<void> _showOrderTracking(BuildContext context, WidgetRef ref, Order order) async {
  final groupId = order.orderGroupId;
  if (groupId == null) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        child: FutureBuilder<List<OrderStatusEvent>>(
          future: ref.read(orderRepositoryProvider).getOrderStatusEvents(groupId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return SizedBox(height: 160, child: Center(child: Text('Tracking load করা যায়নি: ${snapshot.error}')));
            }
            final events = snapshot.data ?? const <OrderStatusEvent>[];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #${order.id.substring(order.id.length - 6)} tracking', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                if (events.isEmpty)
                  const Text('এখনও status history তৈরি হয়নি।')
                else
                  ...events.map((event) => _OrderStatusEventTile(event: event)),
                if (order.status == OrderStatus.delivered) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showReturnRequestDialog(context, ref, order),
                      icon: const Icon(Icons.assignment_return_outlined),
                      label: const Text('Return request'),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _OrderStatusEventTile extends StatelessWidget {
  final OrderStatusEvent event;

  const _OrderStatusEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final isClosed = event.newStatus == 'delivered' || event.newStatus == 'cancelled';
    final color = isClosed ? (event.newStatus == 'delivered' ? Colors.green : Colors.red) : PaikariTheme.primaryColor;
    final label = event.newStatus[0].toUpperCase() + event.newStatus.substring(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isClosed ? (event.newStatus == 'delivered' ? Icons.check_circle : Icons.cancel) : Icons.radio_button_checked, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(DateFormat('dd MMM yyyy, hh:mm a').format(event.createdAt.toLocal()), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                if (event.note != null && event.note!.trim().isNotEmpty) Text(event.note!, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showReturnRequestDialog(BuildContext context, WidgetRef ref, Order order) async {
  final reason = TextEditingController();
  final details = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final submitted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Return request দিন'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: reason, decoration: const InputDecoration(labelText: 'Reason'), validator: (value) => (value?.trim().length ?? 0) < 3 ? 'কারণ লিখুন' : null),
              TextFormField(controller: details, maxLines: 4, decoration: const InputDecoration(labelText: 'Details (optional)')),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('বাতিল')),
        FilledButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            try {
              await ref.read(returnRepositoryProvider).create(
                    orderGroupId: order.orderGroupId!,
                    quantity: 1,
                    reason: reason.text.trim(),
                    details: details.text.trim(),
                  );
              if (dialogContext.mounted) Navigator.pop(dialogContext, true);
            } catch (error) {
              if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Return request করা যায়নি: $error')));
            }
          },
          child: const Text('Submit'),
        ),
      ],
    ),
  );
  reason.dispose();
  details.dispose();
  if (submitted == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return request জমা হয়েছে'), behavior: SnackBarBehavior.floating));
  }
}

class _NotificationTile extends ConsumerWidget {
  final MarketplaceNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnread = notification.readAt == null;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isUnread ? PaikariTheme.primaryColor.withValues(alpha: 0.08) : null,
      child: ListTile(
        dense: true,
        leading: Icon(isUnread ? Icons.notifications_active_outlined : Icons.notifications_none_outlined),
        title: Text(notification.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(notification.body, maxLines: 2, overflow: TextOverflow.ellipsis),
        onTap: isUnread
            ? () async {
                await ref.read(notificationRepositoryProvider).markRead(notification.id);
              }
            : null,
      ),
    );
  }
}

String _orderStatusLabel(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 'অপেক্ষমাণ';
    case OrderStatus.confirmed:
      return 'নিশ্চিত';
    case OrderStatus.processing:
      return 'প্রস্তুত হচ্ছে';
    case OrderStatus.shipped:
      return 'পাঠানো হয়েছে';
    case OrderStatus.delivered:
      return 'ডেলিভারড';
    case OrderStatus.cancelled:
      return 'বাতিল';
  }
}

String _paymentStatusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'paid':
      return 'পরিশোধিত';
    case 'pending':
      return 'অপেক্ষমাণ';
    case 'failed':
      return 'ব্যর্থ';
    case 'refunded':
      return 'ফেরত দেওয়া হয়েছে';
    default:
      return 'COD / পরিশোধ বাকি';
  }
}
