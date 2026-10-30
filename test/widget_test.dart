import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/data/services/api_client.dart';
import 'package:flutter_app/data/services/token_storage.dart';
import 'package:flutter_app/features/auth/auth_controller.dart';
import 'package:flutter_app/features/products/widgets/product_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _MemoryStorage extends TokenStorage {
  String? value;
  _MemoryStorage([this.value]);
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String token) async => value = token;
  @override
  Future<void> clear() async => value = null;
}

Map<String, dynamic> _product(int id) => {
  'id': id,
  'title': 'Product $id',
  'description': 'Desc $id',
  'category': 'beauty',
  'price': 9.99,
  'thumbnail': '',
  'images': <String>[],
  'tags': ['beauty'],
  'sku': 'SKU-$id',
  'dimensions': {'width': 1.5, 'height': 2, 'depth': 3},
  'reviews': [
    {
      'rating': 4,
      'comment': 'Great',
      'date': '2025-04-30T09:41:02.053Z',
      'reviewerName': 'Eve',
      'reviewerEmail': 'e@x.com',
    },
  ],
  'meta': {'createdAt': '2025-10-09T14:47:01.588Z', 'barcode': '123'},
};

final _detailScrollable =
    find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;

void main() {
  testWidgets('login then shows product list', (tester) async {
    final client = MockClient((req) async {
      if (req.url.path == '/auth/login') {
        return http.Response(jsonEncode({'accessToken': 'tok'}), 200);
      }
      return http.Response(
        jsonEncode({
          'products': [_product(1), _product(2)],
          'total': 2,
        }),
        200,
      );
    });
    final api = ApiClient(client);
    final auth = AuthController(api, _MemoryStorage())..restore();

    await tester.pumpWidget(App(api: api, auth: auth));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Add To Cart'), findsWidgets);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(find.text("You've reached the end"), findsOneWidget);

    // Switch to grid: compact cards drop the "Add To Cart" label.
    await tester.tap(find.byTooltip('Grid view'));
    await tester.pumpAndSettle();
    expect(find.text('Add To Cart'), findsNothing);
    expect(find.byIcon(Icons.shopping_cart_outlined), findsWidgets);
  });

  testWidgets('detail page shows extra fields', (tester) async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'products': [_product(1)],
          'total': 1,
        }),
        200,
      ),
    );
    final api = ApiClient(client);
    final auth = AuthController(api, _MemoryStorage('tok'))..restore();

    await tester.pumpWidget(App(api: api, auth: auth));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ProductCard).first, warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('SKU-1'), 200, scrollable: _detailScrollable);
    expect(find.text('SKU-1'), findsOneWidget);
    expect(find.text('1.5 × 2 × 3 cm'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Eve'), 200, scrollable: _detailScrollable);
    expect(find.text('Eve'), findsOneWidget);
    expect(find.text('Great'), findsOneWidget);
  });

  testWidgets('shows error state with retry', (tester) async {
    final client = MockClient(
      (_) async => http.Response('{"message":"boom"}', 500),
    );
    final api = ApiClient(client);
    final auth = AuthController(api, _MemoryStorage('tok'))..restore();

    await tester.pumpWidget(App(api: api, auth: auth));
    await tester.pumpAndSettle();
    expect(find.text('boom'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
