import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/themes/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/inventory_repository.dart';
import 'data/repositories/utang_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/inventory_provider.dart';
import 'presentation/providers/utang_provider.dart';
import 'presentation/routes/app_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TinderaTrackApp extends StatelessWidget {
  const TinderaTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'TinderaTrack',
      theme: buildAppTheme(),
      routerConfig: AppRouter.build(auth),
    );
  }
}

MultiProvider buildAppProviders(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider(AuthRepository())),
      ChangeNotifierProvider(create: (_) => InventoryProvider(InventoryRepository())),
      ChangeNotifierProvider(create: (_) => UtangProvider(UtangRepository())),
    ],
    child: child,
  );
}
