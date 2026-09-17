import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../data/models/product.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/inventory/inventory_list_screen.dart';
import '../screens/inventory/add_inventory_item_screen.dart';
import '../screens/utang/record_utang_screen.dart';
import '../screens/utang/customer_balance_screen.dart';
import '../screens/utang/utang_list_screen.dart';
import '../screens/reports/reports_screen.dart';
import 'route_names.dart';

class AppRouter {
  static GoRouter build(AuthProvider auth) {
    return GoRouter(
      initialLocation: auth.isAuthenticated ? RouteNames.home : RouteNames.login,
      refreshListenable: auth,
      redirect: (context, state) {
        final isAuth = auth.isAuthenticated;
        final path = state.uri.path;
        final onAuthPage = path == RouteNames.login || path == RouteNames.signup;
        if (!isAuth && !onAuthPage) return RouteNames.login;
        if (isAuth && onAuthPage) return RouteNames.home;
        return null;
      },
      routes: [
        GoRoute(path: RouteNames.login, builder: (_, __) => const LoginScreen()),
        GoRoute(path: RouteNames.signup, builder: (_, __) => const SignupScreen()),
        ShellRoute(
          builder: (context, state, child) => MainShell(location: state.uri.path, child: child),
          routes: [
            GoRoute(path: RouteNames.home, builder: (_, __) => const HomeScreen()),
            GoRoute(path: RouteNames.inventory, builder: (_, __) => const InventoryListScreen()),
            GoRoute(path: RouteNames.utang, builder: (_, __) => const UtangListScreen()),
            GoRoute(path: RouteNames.reports, builder: (_, __) => const ReportsScreen()),
          ],
        ),
        GoRoute(path: RouteNames.addInventory, builder: (context, state) => AddInventoryItemScreen(product: state.extra is Product ? state.extra as Product : null)),
        GoRoute(path: RouteNames.recordUtang, builder: (_, __) => const RecordUtangScreen()),
        GoRoute(path: '${RouteNames.customer}/:id', builder: (_, state) => CustomerBalanceScreen(customerId: state.pathParameters['id']!)),
      ],
    );
  }
}

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child, required this.location});
  final Widget child;
  final String location;

  int get index {
    if (location.startsWith(RouteNames.inventory)) return 1;
    if (location.startsWith(RouteNames.utang)) return 2;
    if (location.startsWith(RouteNames.reports)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          const paths = [RouteNames.home, RouteNames.inventory, RouteNames.utang, RouteNames.reports];
          context.go(paths[value]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Inventory'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Utang'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reports'),
        ],
      ),
    );
  }
}
