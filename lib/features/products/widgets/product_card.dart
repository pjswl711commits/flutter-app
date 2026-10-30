import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../data/models/product.dart';

const _green = Color(0xFF2FB344);
const _ink = Color(0xFF222222);

class ProductCard extends StatelessWidget {
  final Product product;
  final bool compact; // true = grid cell, false = full-width list card
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.compact,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
    required this.onAddToCart,
  });

  String? get _badge {
    if (product.rating >= 4.5) return 'Trending';
    if (product.discountPercentage >= 10) {
      return '-${product.discountPercentage.toStringAsFixed(0)}%';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final image = _Image(
      product: product,
      badge: _badge,
      isFavorite: isFavorite,
      onFavorite: onFavorite,
    );

    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(compact ? 22 : 28),
      child: InkWell(
        borderRadius: BorderRadius.circular(compact ? 22 : 28),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(compact ? 8 : 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact)
                Expanded(child: image)
              else
                AspectRatio(aspectRatio: 1.15, child: image),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 6 : 14,
                  12,
                  compact ? 6 : 14,
                  compact ? 4 : 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 15 : 22,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 12 : 14,
                        height: 1.4,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: compact ? 16 : 20,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                        ),
                        if (compact)
                          _CartIconButton(onPressed: onAddToCart)
                        else
                          FilledButton(
                            onPressed: onAddToCart,
                            style: FilledButton.styleFrom(
                              backgroundColor: _ink,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Add To Cart'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Image extends StatelessWidget {
  final Product product;
  final String? badge;
  final bool isFavorite;
  final VoidCallback onFavorite;

  const _Image({
    required this.product,
    required this.badge,
    required this.isFavorite,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: const Color(0xFFEFF1F4),
            child: Hero(
              tag: 'product-${product.id}',
              child: CachedNetworkImage(
                imageUrl: product.thumbnail,
                fit: BoxFit.contain,
                placeholder: (_, _) => const SizedBox.shrink(),
                errorWidget: (_, _, _) => const Icon(
                  Icons.image_not_supported,
                  color: Colors.black38,
                ),
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onFavorite,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: isFavorite ? Colors.red : Colors.black45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CartIconButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _ink,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(
            Icons.shopping_cart_outlined,
            size: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
