import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/themes/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/inventory_repository.dart';
import 'data/repositories/sales_repository.dart';
import 'data/repositories/utang_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/inventory_provider.dart';
import 'presentation/providers/payment_provider.dart';
import 'presentation/providers/utang_provider.dart';
import 'presentation/routes/app_router.dart';
import 'services/payment_service.dart';

class TinderaTrackApp extends StatefulWidget {
  const TinderaTrackApp({super.key});

  @override
  State<TinderaTrackApp> createState() => _TinderaTrackAppState();
}

class _TinderaTrackAppState extends State<TinderaTrackApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.build(context.read<AuthProvider>());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'TinderaTrack',
      theme: buildAppTheme(),
      routerConfig: _router,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }
}

MultiProvider buildAppProviders(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider(AuthRepository())),
      ChangeNotifierProvider(
        create: (_) => InventoryProvider(
          InventoryRepository(),
          SalesRepository(),
        ),
      ),
      ChangeNotifierProvider(create: (_) => UtangProvider(UtangRepository())),
      ChangeNotifierProxyProvider<AuthProvider, PaymentProvider>(
        create: (_) => PaymentProvider(
          PaymentService.forCurrentFirebaseApp(),
        ),
        update: (_, auth, payments) {
          payments!.setAuthenticated(auth.isAuthenticated);
          return payments;
        },
      ),
    ],
    child: child,
  );
}
