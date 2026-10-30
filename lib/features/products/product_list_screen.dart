import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import 'product_detail_screen.dart';
import 'products_controller.dart';
import 'widgets/product_card.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ProductsController>().refresh(),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 300) {
      context.read<ProductsController>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ProductsController>();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F9),
        scrolledUnderElevation: 0,
        title: const Text('Products'),
        actions: [
          IconButton(
            tooltip: 'List view',
            isSelected: !c.isGrid,
            icon: const Icon(Icons.view_list_outlined),
            selectedIcon: const Icon(Icons.view_list),
            onPressed: () => c.setGrid(false),
          ),
          IconButton(
            tooltip: 'Grid view',
            isSelected: c.isGrid,
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view_rounded),
            onPressed: () => c.setGrid(true),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthController>().logout(),
          ),
        ],
      ),
      body: _body(c),
    );
  }

  Widget _body(ProductsController c) {
    if (c.loading && c.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (c.error != null && c.items.isEmpty) {
      return _Message(
        icon: Icons.error_outline,
        text: c.error!,
        actionLabel: 'Retry',
        onAction: c.refresh,
      );
    }
    if (c.items.isEmpty) {
      return _Message(
        icon: Icons.inventory_2_outlined,
        text: 'No products found.',
        actionLabel: 'Refresh',
        onAction: c.refresh,
      );
    }
    final footer = SliverToBoxAdapter(child: _Footer(controller: c));
    return RefreshIndicator(
      onRefresh: c.refresh,
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: c.isGrid
                ? SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 240,
                          mainAxisExtent: 300,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                    itemCount: c.items.length,
                    itemBuilder: (_, i) => _card(c, i, compact: true),
                  )
                : SliverList.separated(
                    itemCount: c.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 18),
                    itemBuilder: (_, i) => _card(c, i, compact: false),
                  ),
          ),
          footer,
        ],
      ),
    );
  }

  Widget _card(ProductsController c, int i, {required bool compact}) {
    final p = c.items[i];
    return ProductCard(
      product: p,
      compact: compact,
      isFavorite: c.favorites.contains(p.id),
      onFavorite: () => c.toggleFavorite(p.id),
      onAddToCart: () => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${p.title} added to cart'),
            duration: const Duration(seconds: 1),
          ),
        ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: c,
            child: ProductDetailScreen(product: p),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final ProductsController controller;
  const _Footer({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (controller.moreError != null) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: TextButton.icon(
            onPressed: controller.loadMore,
            icon: const Icon(Icons.refresh),
            label: Text('${controller.moreError} Tap to retry'),
          ),
        ),
      );
    }
    if (!controller.hasMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text("You've reached the end")),
      );
    }
    return const SizedBox(height: 56);
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  const _Message({
    required this.icon,
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
