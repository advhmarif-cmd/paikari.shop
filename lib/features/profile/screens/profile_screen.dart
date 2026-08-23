import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/features/profile/providers/profile_providers.dart';
import 'package:paikari_shop/features/auth/repositories/auth_repository.dart';
import 'package:paikari_shop/core/theme/paikari_theme.dart';
import 'package:paikari_shop/features/vendors/providers/vendor_provider.dart';
import 'package:paikari_shop/features/buyer/providers/business_buyer_provider.dart';
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            title: Text('অর্ডার #${order.id.substring(order.id.length - 6)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text('${l10n.orderDate}: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt)}\n${l10n.status}: ${order.status.name.toUpperCase()}'),
                            ),
                            trailing: Text('৳${order.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: PaikariTheme.primaryColor)),
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
