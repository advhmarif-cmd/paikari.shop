import 'package:flutter/material.dart';
import 'package:paikari_shop/core/theme/paikari_theme.dart';

class LegalSupportScreen extends StatelessWidget {
  const LegalSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('নীতি ও সাহায্য')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PaikariTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_outlined, color: PaikariTheme.primaryColor),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Paikari-তে price, stock, order status ও payment state server দ্বারা নির্ধারিত হয়। কোনো payment secret বা service key app-এর ভিতরে রাখা হয় না।',
                    style: TextStyle(height: 1.45, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _PolicySection(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy policy',
            children: [
              'Account, business profile, phone, shipping address, quotation এবং order information service চালানোর জন্য ব্যবহার করা হয়।',
              'Order ও payment information buyer, সংশ্লিষ্ট vendor এবং অনুমোদিত admin-এর প্রয়োজনীয় সীমার মধ্যে দৃশ্যমান থাকে।',
              'Payment provider বা courier integration চালু হলে প্রয়োজনীয় transaction/tracking data সংশ্লিষ্ট provider-এর সঙ্গে share হতে পারে।',
              'Account deletion বা data request-এর জন্য production support contact প্রকাশের আগে app owner-এর নির্ধারিত support channel ব্যবহার করতে হবে।',
            ],
          ),
          const _PolicySection(
            icon: Icons.gavel_outlined,
            title: 'Terms of use',
            children: [
              'Buyer সঠিক phone, address এবং business information দেওয়ার জন্য দায়ী।',
              'Vendor product description, price, MOQ, stock এবং shipment information সঠিক রাখবে।',
              'Shared Origen catalog product Paikari vendor দ্বারা edit করা যায় না; local product moderation-এর অধীন।',
              'Platform server-side validation, moderation, cancellation এবং status rules অনুসরণ করে।',
            ],
          ),
          const _PolicySection(
            icon: Icons.assignment_return_outlined,
            title: 'Return ও refund policy',
            children: [
              'Return request delivered order-এর জন্য করা যায় এবং reason/details দিতে হয়।',
              'Vendor প্রথমে request review করতে পারে; final resolution ও refund-state admin workflow-এর অধীন।',
              'COD return/refund manual review-এর মাধ্যমে হবে। Online gateway চালু হলে refund method provider-এর verified transaction state অনুযায়ী নির্ধারিত হবে।',
              'এই policy production launch-এর আগে business owner-এর final approval ও applicable legal review প্রয়োজন।',
            ],
          ),
          const _PolicySection(
            icon: Icons.support_agent_outlined,
            title: 'Support ও order help',
            children: [
              'Order সমস্যা হলে Profile → My Orders থেকে order timeline খুলে status ও payment state দেখুন।',
              'Delivered order-এর ক্ষেত্রে tracking sheet থেকেই Return request করা যায়।',
              'Support-এ যোগাযোগের সময় order ID, vendor name, সমস্যার সংক্ষিপ্ত বিবরণ এবং প্রয়োজনীয় screenshot প্রস্তুত রাখুন।',
              'Production release-এর আগে app owner-এর verified phone, email বা helpdesk link এখানে configure করতে হবে।',
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'শেষ আপডেট: ${DateTime.now().year}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> children;

  const _PolicySection({required this.icon, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
      child: ExpansionTile(
        leading: Icon(icon, color: PaikariTheme.primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: children
            .map((text) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Align(alignment: Alignment.centerLeft, child: Text('• $text', style: const TextStyle(height: 1.45))),
                ))
            .toList(),
      ),
    );
  }
}
