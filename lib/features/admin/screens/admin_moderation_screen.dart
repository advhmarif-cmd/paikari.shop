import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paikari_shop/features/admin/repositories/admin_moderation_repository.dart';

class AdminModerationScreen extends ConsumerStatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  ConsumerState<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends ConsumerState<AdminModerationScreen> {
  bool _loading = true;
  bool _isAdmin = false;
  String? _error;
  List<Map<String, dynamic>> _vendors = const [];
  List<Map<String, dynamic>> _products = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin moderation'),
        actions: [IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh), tooltip: 'Refresh')],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_isAdmin
              ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Admin access required.')))
              : _error != null
                  ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
                  : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [_sectionTitle('Vendor verification'), ..._vendors.map(_vendorCard), const SizedBox(height: 24), _sectionTitle('Local product approval'), ..._products.map(_productCard)])),
    );
  }

  Widget _sectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)));

  Widget _vendorCard(Map<String, dynamic> vendor) {
    final status = vendor['verification_status'] as String? ?? 'pending';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(vendor['store_name'] as String? ?? 'Vendor store', style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('${vendor['city'] as String? ?? 'বাংলাদেশ'} · $status'),
        trailing: _statusMenu(status, const ['pending', 'verified', 'rejected', 'suspended'], (next) => _updateVendor(vendor['user_id'] as String, next)),
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> product) {
    final status = product['approval_status'] as String? ?? 'pending';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(product['name'] as String? ?? 'Local product', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('${product['sku'] as String? ?? 'No SKU'} · $status'),
        trailing: _statusMenu(status, const ['pending', 'approved', 'rejected', 'suspended'], (next) => _updateProduct(product['id'] as String, next)),
      ),
    );
  }

  Widget _statusMenu(String current, List<String> statuses, Future<void> Function(String) onChanged) {
    return DropdownButton<String>(
      value: statuses.contains(current) ? current : statuses.first,
      underline: const SizedBox.shrink(),
      items: statuses.map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
      onChanged: (value) {
        if (value != null && value != current) onChanged(value);
      },
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repository = ref.read(adminModerationRepositoryProvider);
      final isAdmin = await repository.isAdmin();
      if (!isAdmin) {
        if (mounted) setState(() { _isAdmin = false; _loading = false; });
        return;
      }
      final results = await Future.wait([repository.listVendors(), repository.listProducts()]);
      if (!mounted) return;
      setState(() {
        _isAdmin = true;
        _vendors = results[0];
        _products = results[1];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Moderation data load করা যায়নি: $error';
      });
    }
  }

  Future<void> _updateVendor(String vendorId, String status) async {
    try {
      await ref.read(adminModerationRepositoryProvider).updateVendorStatus(vendorId: vendorId, status: status);
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vendor status update করা যায়নি: $error')));
    }
  }

  Future<void> _updateProduct(String productId, String status) async {
    try {
      await ref.read(adminModerationRepositoryProvider).updateProductStatus(productId: productId, status: status);
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product status update করা যায়নি: $error')));
    }
  }
}
