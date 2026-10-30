import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/services/api_client.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/products/product_list_screen.dart';
import 'features/products/products_controller.dart';

class App extends StatelessWidget {
  final ApiClient api;
  final AuthController auth;

  const App({super.key, required this.api, required this.auth});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider<AuthController>.value(value: auth),
      ],
      child: MaterialApp(
        title: 'Shop',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const _AuthGate(),
      ),
    );
  }
}

/// Switches between splash, login and the product list based on auth state.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.signedOut:
        return const LoginScreen();
      case AuthStatus.signedIn:
        // Keyed on the token so a new session gets a fresh controller.
        return ChangeNotifierProvider(
          key: ValueKey(auth.token),
          create: (_) =>
              ProductsController(context.read<ApiClient>(), auth.token),
          child: const ProductListScreen(),
        );
    }
  }
}
