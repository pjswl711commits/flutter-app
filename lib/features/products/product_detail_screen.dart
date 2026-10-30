import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/product.dart';
import 'products_controller.dart';

const _green = Color(0xFF2FB344);
const _ink = Color(0xFF222222);
const _bg = Color(0xFFF7F7F9);

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  late int _quantity;

  Product get product => widget.product;

  late final List<String> _allImages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Combine thumbnail and images without duplicates so all photos are visible
    final imageSet = <String>{};
    if (product.images.isNotEmpty) {
      imageSet.addAll(product.images);
    }
    if (product.thumbnail.isNotEmpty && !imageSet.contains(product.thumbnail)) {
      imageSet.add(product.thumbnail);
    }
    _allImages = imageSet.isEmpty ? [product.thumbnail] : imageSet.toList();

    // Initialize quantity to minimum order quantity or at least 1
    _quantity = product.minimumOrderQuantity != null &&
            product.minimumOrderQuantity! > 0
        ? product.minimumOrderQuantity!
        : 1;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onThumbnailTap(int index) {
    setState(() => _currentPage = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _incrementQuantity() {
    if (_quantity < product.stock) {
      setState(() => _quantity++);
    }
  }

  void _decrementQuantity() {
    final min = (product.minimumOrderQuantity != null &&
            product.minimumOrderQuantity! > 0)
        ? product.minimumOrderQuantity!
        : 1;
    if (_quantity > min) {
      setState(() => _quantity--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<ProductsController?>();
    final isFavorite = controller?.favorites.contains(product.id) ?? false;

    final discounted = product.discountPercentage > 0;
    final finalPrice = discounted
        ? product.price * (1 - product.discountPercentage / 100)
        : product.price;
    final savings = product.price - finalPrice;
    final inStock = product.stock > 0;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          product.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : _ink,
            ),
            onPressed: () => controller?.toggleFavorite(product.id),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // 1. IMAGE CAROUSEL & THUMBNAILS (Images & Thumbnail)
          _buildImageSection(discounted),
          const SizedBox(height: 16),

          // 2. MAIN PRODUCT INFO CARD (Title, Category, Brand, ID, Price, Rating, Stock)
          _buildMainInfoCard(theme, discounted, finalPrice, savings, inStock),
          const SizedBox(height: 14),

          // 3. TAGS
          if (product.tags.isNotEmpty) ...[
            _buildTagsCard(theme),
            const SizedBox(height: 14),
          ],

          // 4. DESCRIPTION
          _buildDescriptionCard(theme),
          const SizedBox(height: 14),

          // 5. PRODUCT SPECIFICATIONS (ID, Brand, Category, SKU, Weight, Dimensions, MOQ, Stock, Status)
          _buildSpecCard(theme),
          const SizedBox(height: 14),

          // 6. SHIPPING & POLICIES (Shipping, Warranty, Return Policy)
          _buildShippingPolicyCard(theme),
          const SizedBox(height: 14),

          // 7. PRODUCT IDENTIFICATION & META (Barcode, QR Code, CreatedAt, UpdatedAt)
          if (product.meta != null) ...[
            _buildMetaCard(theme),
            const SizedBox(height: 14),
          ],

          // 8. CUSTOMER REVIEWS (Reviews list, rating, comments, author, email, date)
          _buildReviewsCard(theme),
          const SizedBox(height: 80), // Padding for bottom sticky bar
        ],
      ),
      bottomSheet: _buildBottomBar(theme, finalPrice, inStock),
    );
  }

  // ======================== WIDGET BUILDERS ========================

  Widget _buildImageSection(bool discounted) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 320,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _allImages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (_, i) {
                    final img = CachedNetworkImage(
                      imageUrl: _allImages[i],
                      fit: BoxFit.contain,
                      placeholder: (_, _) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (_, _, _) => const Center(
                        child: Icon(Icons.image_not_supported, size: 54, color: Colors.black26),
                      ),
                    );
                    return i == 0
                        ? Hero(tag: 'product-${product.id}', child: img)
                        : img;
                  },
                ),
              ),
            ),
            if (discounted)
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '-${product.discountPercentage.toStringAsFixed(0)}% OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            if (_allImages.length > 1)
              Positioned(
                bottom: 12,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentPage + 1} / ${_allImages.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_allImages.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _allImages.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final isSelected = i == _currentPage;
                return GestureDetector(
                  onTap: () => _onThumbnailTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? _ink : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: _allImages[i],
                        fit: BoxFit.contain,
                        placeholder: (_, _) => Container(color: Colors.grey.shade100),
                        errorWidget: (_, _, _) => const Icon(Icons.broken_image, size: 20),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMainInfoCard(
    ThemeData theme,
    bool discounted,
    double finalPrice,
    double savings,
    bool inStock,
  ) {
    return _CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand, Category & Product ID Pills
          Row(
            children: [
              if (product.brand != null && product.brand!.isNotEmpty)
                _PillBadge(
                  label: product.brand!,
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  textColor: theme.colorScheme.primary,
                  icon: Icons.verified,
                ),
              if (product.brand != null && product.brand!.isNotEmpty)
                const SizedBox(width: 8),
              _PillBadge(
                label: product.category.toUpperCase(),
                color: Colors.grey.shade100,
                textColor: Colors.grey.shade800,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ID: #${product.id}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            product.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _ink,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),

          // Rating & Stock status row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      product.rating.toStringAsFixed(2),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${product.reviews.length})',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: (inStock ? _green : Colors.red).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      inStock ? Icons.check_circle : Icons.cancel,
                      size: 15,
                      color: inStock ? _green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      product.availabilityStatus ?? (inStock ? 'In Stock' : 'Out of Stock'),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: inStock ? _green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${product.stock} left',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Price & Savings
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\$${finalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              if (discounted) ...[
                const SizedBox(width: 10),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '-${product.discountPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (discounted && savings > 0) ...[
            const SizedBox(height: 4),
            Text(
              'You save \$${savings.toStringAsFixed(2)} (${product.discountPercentage.toStringAsFixed(0)}% off)',
              style: const TextStyle(
                color: _green,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagsCard(ThemeData theme) {
    return _CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tags',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final tag in product.tags)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF1F4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '#$tag',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(ThemeData theme) {
    return _CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink),
          ),
          const SizedBox(height: 10),
          Text(
            product.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecCard(ThemeData theme) {
    final d = product.dimensions;
    final dimString = d != null
        ? '${_formatNum(d.width)} × ${_formatNum(d.height)} × ${_formatNum(d.depth)} cm'
        : null;

    final rows = <_SpecItem>[
      _SpecItem(Icons.tag, 'Product ID', '#${product.id}'),
      if (product.brand != null && product.brand!.isNotEmpty)
        _SpecItem(Icons.business_outlined, 'Brand', product.brand!),
      _SpecItem(Icons.category_outlined, 'Category', product.category),
      if (product.sku != null && product.sku!.isNotEmpty)
        _SpecItem(Icons.qr_code_2, 'SKU', product.sku!),
      if (product.weight != null)
        _SpecItem(Icons.scale_outlined, 'Weight', '${_formatNum(product.weight!)} oz'),
      if (dimString != null)
        _SpecItem(Icons.straighten, 'Dimensions', dimString),
      if (product.minimumOrderQuantity != null)
        _SpecItem(
          Icons.shopping_basket_outlined,
          'Min. Order Qty',
          '${product.minimumOrderQuantity} items',
        ),
      _SpecItem(Icons.inventory_2_outlined, 'Stock Count', '${product.stock} units'),
      if (product.availabilityStatus != null)
        _SpecItem(
          Icons.info_outline,
          'Availability',
          product.availabilityStatus!,
        ),
    ];

    return _CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Specifications',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(rows[i].icon, size: 19, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: Text(
                      rows[i].label,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rows[i].value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i < rows.length - 1)
              Divider(height: 1, color: Colors.grey.shade100),
          ],
        ],
      ),
    );
  }

  Widget _buildShippingPolicyCard(ThemeData theme) {
    final rows = <_SpecItem>[
      if (product.shippingInformation != null && product.shippingInformation!.isNotEmpty)
        _SpecItem(
          Icons.local_shipping_outlined,
          'Shipping',
          product.shippingInformation!,
        ),
      if (product.warrantyInformation != null && product.warrantyInformation!.isNotEmpty)
        _SpecItem(
          Icons.verified_user_outlined,
          'Warranty',
          product.warrantyInformation!,
        ),
      if (product.returnPolicy != null && product.returnPolicy!.isNotEmpty)
        _SpecItem(
          Icons.assignment_return_outlined,
          'Return Policy',
          product.returnPolicy!,
        ),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return _CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shipping & Policies',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(rows[i].icon, size: 20, color: _green),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: Text(
                      rows[i].label,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rows[i].value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i < rows.length - 1)
              Divider(height: 1, color: Colors.grey.shade100),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaCard(ThemeData theme) {
    final meta = product.meta!;
    final createdStr = _formatDate(meta.createdAt);
    final updatedStr = _formatDate(meta.updatedAt);
    final qrUrl = meta.qrCode;

    return _CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Identification & Meta',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink),
          ),
          const SizedBox(height: 14),
          if (meta.barcode != null && meta.barcode!.isNotEmpty) ...[
            _MetaRow(icon: Icons.pin_outlined, label: 'Barcode', value: meta.barcode!),
            Divider(height: 1, color: Colors.grey.shade100),
          ],
          if (createdStr != null) ...[
            _MetaRow(icon: Icons.calendar_today_outlined, label: 'Created At', value: createdStr),
            Divider(height: 1, color: Colors.grey.shade100),
          ],
          if (updatedStr != null) ...[
            _MetaRow(icon: Icons.update, label: 'Updated At', value: updatedStr),
            Divider(height: 1, color: Colors.grey.shade100),
          ],
          if (qrUrl != null && qrUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(4),
                      child: CachedNetworkImage(
                        imageUrl: qrUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.contain,
                        placeholder: (_, _) => const SizedBox(
                          width: 70,
                          height: 70,
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (_, _, _) => const Icon(Icons.qr_code, size: 50),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product QR Code',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _ink),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Scan this official code to verify product metadata and authenticity.',
                          style: TextStyle(fontSize: 11.5, color: Colors.black54, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewsCard(ThemeData theme) {
    return _CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Customer Reviews (${product.reviews.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink),
              ),
              Row(
                children: [
                  const Icon(Icons.star, size: 18, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    product.rating.toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  Text(
                    ' / 5',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (product.reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No reviews yet for this product.',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            for (var i = 0; i < product.reviews.length; i++) ...[
              _ReviewItem(review: product.reviews[i]),
              if (i < product.reviews.length - 1)
                Divider(height: 16, color: Colors.grey.shade100),
            ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme, double finalPrice, bool inStock) {
    final totalPrice = finalPrice * _quantity;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Quantity Selector
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 18),
                    onPressed: inStock ? _decrementQuantity : null,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '$_quantity',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: _ink,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: inStock && _quantity < product.stock
                        ? _incrementQuantity
                        : null,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Add to Cart Button
            Expanded(
              child: FilledButton(
                onPressed: inStock
                    ? () {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                '$_quantity × ${product.title} added to cart (\$${totalPrice.toStringAsFixed(2)})',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _ink,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      inStock
                          ? 'Add to Cart • \$${totalPrice.toStringAsFixed(2)}'
                          : 'Out of Stock',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================== HELPER METHODS ========================

  static String _formatNum(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  static String? _formatDate(DateTime? d) => d == null
      ? null
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}


class _CardWrapper extends StatelessWidget {
  final Widget child;
  const _CardWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PillBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final IconData? icon;

  const _PillBadge({
    required this.label,
    required this.color,
    required this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecItem {
  final IconData icon;
  final String label;
  final String value;
  const _SpecItem(this.icon, this.label, this.value);
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 19, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final Review review;
  const _ReviewItem({required this.review});

  @override
  Widget build(BuildContext context) {
    final d = review.date;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFFEFF1F4),
                child: Text(
                  review.reviewerName.isEmpty
                      ? '?'
                      : review.reviewerName[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: _ink,
                      ),
                    ),
                    if (review.reviewerEmail.isNotEmpty)
                      Text(
                        review.reviewerEmail,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
              if (d != null)
                Text(
                  '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= review.rating ? Icons.star : Icons.star_border,
                  size: 15,
                  color: Colors.amber,
                ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.comment,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
