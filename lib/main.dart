import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:paikari_shop/core/config/supabase_config.dart';
import 'package:paikari_shop/firebase_options.dart';
import 'package:paikari_shop/core/theme/paikari_theme.dart';
import 'package:paikari_shop/features/auth/screens/login_screen.dart';
import 'package:paikari_shop/features/auth/screens/signup_screen.dart';
import 'package:paikari_shop/features/auth/repositories/auth_repository.dart';
import 'package:paikari_shop/features/products/models/product.dart';
import 'package:paikari_shop/features/products/screens/product_detail_screen.dart';
import 'package:paikari_shop/features/products/screens/product_slug_screen.dart';
import 'package:paikari_shop/features/products/widgets/product_card.dart';
import 'package:paikari_shop/features/products/providers/product_provider.dart';
import 'package:paikari_shop/features/checkout/screens/checkout_screen.dart';
import 'package:paikari_shop/features/quotations/widgets/quote_checkout_sheet.dart';
import 'package:paikari_shop/features/admin/screens/admin_moderation_screen.dart';
import 'package:paikari_shop/features/profile/screens/profile_screen.dart';
import 'package:paikari_shop/features/notifications/screens/notifications_screen.dart';
import 'package:paikari_shop/features/notifications/repositories/notification_repository.dart';
import 'package:paikari_shop/features/support/screens/legal_support_screen.dart';
import 'package:paikari_shop/features/chat/screens/chat_screen.dart';
import 'package:paikari_shop/features/chat/repositories/chat_repository.dart';
import 'package:paikari_shop/features/vendors/screens/vendor_onboarding_screen.dart';
import 'package:paikari_shop/features/vendors/screens/vendor_dashboard_screen.dart';
import 'package:paikari_shop/features/buyer/screens/business_buyer_screen.dart';
import 'package:paikari_shop/l10n/generated/app_localizations.dart';
import 'package:paikari_shop/features/cart/screens/cart_screen.dart';
import 'package:paikari_shop/features/cart/providers/cart_provider.dart';
import 'package:paikari_shop/core/widgets/shimmer_loading.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    authFlowType: AuthFlowType.pkce,
  );

  // Firebase remains only for legacy storage/trade-license uploads; auth and orders use Supabase.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: PaikariApp()));
}

class PaikariApp extends StatelessWidget {
  const PaikariApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paikari.shop',
      debugShowCheckedModeBanner: false,
      theme: PaikariTheme.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('bn'),
      ],
      locale: const Locale('bn'),
      home: const AuthWrapper(),
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        if (name.startsWith('/p/')) {
          final slug = Uri.decodeComponent(name.substring(3));
          return MaterialPageRoute(builder: (_) => ProductSlugScreen(slug: slug));
        }
        return null;
      },
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/cart': (context) => const CartScreen(),
        '/checkout': (context) => const CheckoutScreen(),
        '/quote/checkout': (context) {
          final sessionId = ModalRoute.of(context)?.settings.arguments;
          if (sessionId is! String || sessionId.isEmpty) return const ProfileScreen();
          return QuoteCheckoutScreen(sessionId: sessionId);
        },
        '/profile': (context) => const ProfileScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/chats': (context) => const ChatInboxScreen(isVendor: false),
        '/vendor/chats': (context) => const ChatInboxScreen(isVendor: true),
        '/support/policies': (context) => const LegalSupportScreen(),
        '/vendor/onboarding': (context) => const VendorOnboardingScreen(),
        '/vendor/dashboard': (context) => const VendorDashboardScreen(),
        '/vendor/products/new': (context) => const VendorProductFormScreen(),
        '/buyer/business': (context) => const BusinessBuyerScreen(),
        '/admin/moderation': (context) => const AdminModerationScreen(),
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userModel = ref.watch(userProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return userModel.when(
            data: (model) {
              if (model == null) return const SignupScreen();
              return const HomeScreen();
            },
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => _ProfileBootstrapError(
              onRetry: () => ref.invalidate(userProvider),
            ),
          );
        }
        return const LoginScreen();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Auth Error: $error')),
      ),
    );
  }
}

class _ProfileBootstrapError extends StatelessWidget {
  final VoidCallback onRetry;

  const _ProfileBootstrapError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off_outlined, size: 52),
              const SizedBox(height: 12),
              const Text('Profile load করা যায়নি', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('ইন্টারনেট সংযোগ যাচাই করে আবার চেষ্টা করুন।', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('আবার চেষ্টা করুন')),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _selectedCategory = 'সব';
  bool _businessMode = false;
  bool _onlyAvailable = false;
  bool _onlyWholesale = false;
  String _sortMode = 'latest';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final productsAsync = ref.watch(productListProvider(_businessMode));
    final cartCount = ref.watch(cartProvider).itemCount;
    final unreadNotifications = ref.watch(myNotificationsProvider).valueOrNull?.where((item) => item.readAt == null).length ?? 0;
    final userId = ref.watch(authRepositoryProvider).currentUser?.id ?? '';
    final unreadChats = ref.watch(buyerChatConversationsProvider).valueOrNull?.where((chat) => chat.isUnreadFor(userId)).length ?? 0;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset(
              'assets/logo.jpg',
              height: 40,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.store, size: 30),
            ),
            const SizedBox(width: 10),
            Text(l10n.appTitle),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_none_outlined),
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
              ),
              if (unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('$unreadNotifications', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
          Stack(
            children: [
              IconButton(
                tooltip: 'Seller chats',
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () => Navigator.pushNamed(context, '/chats'),
              ),
              if (unreadChats > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('$unreadChats', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
          Stack(
            children: [
              IconButton(
                tooltip: l10n.cart,
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => Navigator.pushNamed(context, '/cart'),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: 'প্রোফাইল',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) => _buildCatalog(context, products),
        loading: () => _buildLoadingGrid(context),
        error: (err, stack) => _CatalogError(onRetry: () => ref.invalidate(productListProvider(_businessMode))),
      ),
    );
  }

  Widget _buildCatalog(BuildContext context, List<Product> products) {
    final categories = <String>{
      'সব',
      ...products.map((product) => product.category.trim()).where((category) => category.isNotEmpty),
    }.toList();
    final normalizedQuery = _query.trim().toLowerCase();
    final filteredProducts = products.where((product) {
      final matchesQuery = normalizedQuery.isEmpty ||
          product.name.toLowerCase().contains(normalizedQuery) ||
          product.description.toLowerCase().contains(normalizedQuery) ||
          product.category.toLowerCase().contains(normalizedQuery) ||
          (product.sku?.toLowerCase().contains(normalizedQuery) ?? false) ||
          (product.vendorName?.toLowerCase().contains(normalizedQuery) ?? false);
      final matchesCategory = _selectedCategory == 'সব' || product.category == _selectedCategory;
      final matchesAvailability = !_onlyAvailable || product.isAvailable;
      final matchesWholesale = !_onlyWholesale || product.wholesaleTiers.isNotEmpty;
      return matchesQuery && matchesCategory && matchesAvailability && matchesWholesale;
    }).toList();

    filteredProducts.sort((a, b) {
      switch (_sortMode) {
        case 'price_low':
          return a.retailPrice.compareTo(b.retailPrice);
        case 'price_high':
          return b.retailPrice.compareTo(a.retailPrice);
        case 'moq_low':
          return a.moq.compareTo(b.moq);
        default:
          return 0;
      }
    });

    if (products.isEmpty) return const _EmptyCatalog();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'পণ্য, category বা supplier খুঁজুন',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'সার্চ মুছুন',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              const Text('কেনাকাটার ধরন', style: TextStyle(fontWeight: FontWeight.w900)),
              const Spacer(),
              ChoiceChip(
                label: const Text('B2C'),
                selected: !_businessMode,
                onSelected: (_) => setState(() => _businessMode = false),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('B2B'),
                selected: _businessMode,
                onSelected: (_) => setState(() => _businessMode = true),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              return ChoiceChip(
                label: Text(category),
                selected: _selectedCategory == category,
                onSelected: (_) => setState(() => _selectedCategory = category),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              FilterChip(
                avatar: const Icon(Icons.inventory_2_outlined, size: 17),
                label: const Text('শুধু available'),
                selected: _onlyAvailable,
                onSelected: (value) => setState(() => _onlyAvailable = value),
              ),
              const SizedBox(width: 8),
              FilterChip(
                avatar: const Icon(Icons.sell_outlined, size: 17),
                label: const Text('Wholesale'),
                selected: _onlyWholesale,
                onSelected: (value) => setState(() => _onlyWholesale = value),
              ),
              const SizedBox(width: 8),
              _SortChip(
                value: _sortMode,
                onChanged: (value) => setState(() => _sortMode = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filteredProducts.isEmpty
              ? const _EmptySearch()
              : RefreshIndicator(
                  onRefresh: () async {
                    await ref.refresh(productListProvider(_businessMode).future);
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 700 ? 4 : 2;
                      return GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisExtent: 320,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return ProductCard(
                            product: product,
                            businessMode: _businessMode,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product, businessMode: _businessMode),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLoadingGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 4 : 2;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 320,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: columns * 2,
          itemBuilder: (context, index) => const ProductCardShimmer(),
        );
      },
    );
  }
}

class _SortChip extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _SortChip({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InputChip(
      avatar: const Icon(Icons.sort, size: 17),
      label: Text(_sortLabel(value)),
      onPressed: () async {
        final selected = await showModalBottomSheet<String>(
          context: context,
          showDragHandle: true,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(title: Text('পণ্য সাজান', style: TextStyle(fontWeight: FontWeight.w900))),
                for (final option in const ['latest', 'price_low', 'price_high', 'moq_low'])
                  RadioListTile<String>(
                    value: option,
                    groupValue: value,
                    title: Text(_sortLabel(option)),
                    onChanged: (next) => Navigator.pop(context, next),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
        if (selected != null) onChanged(selected);
      },
    );
  }
}

String _sortLabel(String value) {
  switch (value) {
    case 'price_low':
      return 'দাম: কম থেকে বেশি';
    case 'price_high':
      return 'দাম: বেশি থেকে কম';
    case 'moq_low':
      return 'MOQ: কম থেকে বেশি';
    default:
      return 'সর্বশেষ যোগ করা';
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined, size: 68, color: PaikariTheme.primaryColor.withValues(alpha: 0.7)),
            const SizedBox(height: 18),
            const Text('এখনও কোনো পণ্য নেই', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('নতুন পণ্য যোগ হলে এখানে দেখা যাবে।', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.search_off, size: 58, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        const Center(child: Text('এই filter-এ কোনো পণ্য নেই', style: TextStyle(fontWeight: FontWeight.w800))),
        const SizedBox(height: 8),
        Center(child: Text('অন্য keyword বা category দিয়ে চেষ্টা করুন।', style: TextStyle(color: Colors.grey))),
      ],
    );
  }
}

class _CatalogError extends StatelessWidget {
  final VoidCallback onRetry;

  const _CatalogError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 64, color: Colors.grey.shade500),
            const SizedBox(height: 16),
            const Text('পণ্য লোড করা যায়নি', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('ইন্টারনেট connection যাচাই করে আবার চেষ্টা করুন।', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 18),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('আবার চেষ্টা করুন')),
          ],
        ),
      ),
    );
  }
}
