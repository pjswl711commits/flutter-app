# Flutter Shop – dummyjson.com test task

Login → paginated product list → product detail, built against https://dummyjson.com.

Test user: `emilys` / `emilyspass` (prefilled on the login screen).

## Run

```bash
flutter pub get
flutter run
flutter test
```

## Structure

```
lib/
  core/            ApiException (one error type the UI understands)
  data/
    models/        Product, ProductPage
    services/      ApiClient (HTTP), TokenStorage (secure storage)
  features/
    auth/          AuthController, LoginScreen
    products/      ProductsController, list + detail screens
  app.dart         Providers, theme, auth gate
  main.dart        Wiring
```

## Decisions

- **State management: `provider` + `ChangeNotifier`.** The app has two small pieces of state
  (session, product list). Provider keeps it readable and dependency-light; Riverpod/Bloc would be
  more machinery than this scope needs.
- **Feature-first folders, thin layers.** UI → controller → `ApiClient`. A separate repository layer
  was skipped since there is a single data source; it's easy to insert later.
- **Token storage: `flutter_secure_storage`** (Keychain / encrypted prefs), never plain
  `SharedPreferences`. On launch the stored token is restored, so the user stays signed in.
- **Auth gate instead of manual navigation.** `MaterialApp.home` rebuilds from `AuthStatus`, so login
  and logout swap screens automatically. The `ProductsController` is keyed on the token, so a new
  session never sees the previous user's state.
- **Errors are mapped once** in `ApiClient` (timeout, no connection, server message, bad JSON) into
  `ApiException`, so controllers/UI only show `message`.
- **Product list states:** full-screen loading, error with Retry, empty with Refresh, pull-to-refresh,
  and infinite scroll (`limit=20&skip=N`, loads when within 300px of the end). A failed refresh keeps
  existing items; a failed "load more" shows an inline retry row instead of wiping the list.
  Duplicate requests are guarded by the `loading` / `loadingMore` flags.
- **Images** use `cached_network_image`; thumbnail → detail uses a `Hero` transition.
- The `/products` endpoint is public, but the Bearer token is still sent so the code is ready for
  protected endpoints.

## Tests

`test/widget_test.dart` uses `MockClient` to cover login → list and the error/retry state.

## What I'd add with more time

Token refresh via `refreshToken` on 401, search/category filter, offline cache, and a repository
layer with unit tests for the controllers.
