import 'package:flutter/foundation.dart';

import '../../core/api_exception.dart';
import '../../data/models/product.dart';
import '../../data/services/api_client.dart';

class ProductsController extends ChangeNotifier {
  static const pageSize = 20;

  final ApiClient _api;
  final String? _token;

  ProductsController(this._api, this._token);

  final List<Product> items = [];
  int _total = 0;
  bool loading = false; // first page / refresh
  bool loadingMore = false;
  String? error; // full-screen error (no items yet)
  String? moreError; // inline error while paginating

  bool isGrid = false;
  final Set<int> favorites = {};
  int _requestId = 0;

  void setGrid(bool value) {
    if (isGrid == value) return;
    isGrid = value;
    notifyListeners();
  }

  void toggleFavorite(int id) {
    favorites.contains(id) ? favorites.remove(id) : favorites.add(id);
    notifyListeners();
  }

  bool get hasMore => items.length < _total;

  /// Loads the first page. Keeps existing items visible if a refresh fails.
  Future<void> refresh() async {
    if (loading) return;
    final requestId = ++_requestId;
    loading = true;
    loadingMore = false;
    error = null;
    moreError = null;
    notifyListeners();
    try {
      final page = await _api.getProducts(
        skip: 0,
        limit: pageSize,
        token: _token,
      );
      if (_requestId != requestId) return;
      items
        ..clear()
        ..addAll(page.products);
      _total = page.total;
    } on ApiException catch (e) {
      if (_requestId != requestId) return;
      error = e.message;
    } finally {
      if (_requestId == requestId) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (loading || loadingMore || !hasMore) return;
    final requestId = _requestId;
    loadingMore = true;
    moreError = null;
    notifyListeners();
    try {
      final page = await _api.getProducts(
        skip: items.length,
        limit: pageSize,
        token: _token,
      );
      if (_requestId != requestId) return;
      final existingIds = items.map((p) => p.id).toSet();
      final newProducts = page.products.where(
        (p) => !existingIds.contains(p.id),
      );
      items.addAll(newProducts);
      _total = page.total;
    } on ApiException catch (e) {
      if (_requestId != requestId) return;
      moreError = e.message;
    } finally {
      if (_requestId == requestId) {
        loadingMore = false;
        notifyListeners();
      }
    }
  }
}
