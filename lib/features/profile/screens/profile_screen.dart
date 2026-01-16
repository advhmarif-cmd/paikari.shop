import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/features/profile/providers/profile_providers.dart';
import 'package:paikari_shop/features/auth/repositories/auth_repository.dart';
import 'package:paikari_shop/core/theme/paikari_theme.dart';
import 'package:paikari_shop/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ordersAsync = ref.watch(profileOrdersProvider);
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            userAsync.when(
              data: (user) => Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      child: Icon(Icons.person, size: 50),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.displayName ?? 'ব্যবহারকারী',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(user?.email ?? '',
                        style: const TextStyle(color: Colors.grey)),
                    if (user?.businessName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user!.businessName!,
                        style: const TextStyle(
                            color: PaikariTheme.secondaryColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('User error: $err')),
            ),
            const SizedBox(height: 40),
            Text(l10n.myOrders,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ordersAsync.when(
              data: (orders) => orders.isEmpty
                  ? const Center(child: Text('কোনো অর্ডার পাওয়া যায়নি'))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text(
                                'অর্ডার #${order.id.substring(order.id.length - 6)}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${l10n.orderDate}: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt)}'),
                                Text(
                                    '${l10n.status}: ${order.status.name.toUpperCase()}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            trailing: Text(
                              '৳${order.totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: PaikariTheme.primaryColor),
                            ),
                          ),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('ত্রুটি: $err')),
            ),
          ],
        ),
      ),
    );
  }
}
