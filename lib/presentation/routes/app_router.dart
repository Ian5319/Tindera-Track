import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../data/models/customer.dart';
import '../../data/models/product.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/inventory/inventory_list_screen.dart';
import '../screens/inventory/add_inventory_item_screen.dart';
import '../screens/inventory/product_management_screen.dart';
import '../screens/utang/record_utang_screen.dart';
import '../screens/utang/customer_balance_screen.dart';
import '../screens/utang/record_payment_screen.dart';
import '../screens/utang/utang_list_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../widgets/common/app_navigation_drawer.dart';
import 'route_names.dart';

class AppRouter {
  static GoRouter build(AuthProvider auth) {
    return GoRouter(
      initialLocation:
          auth.isAuthenticated ? RouteNames.home : RouteNames.login,
      refreshListenable: auth,
      redirect: (context, state) {
        final isAuth = auth.isAuthenticated;
        final path = state.uri.path;
        final onAuthPage =
            path == RouteNames.login || path == RouteNames.signup;
        if (!isAuth && !onAuthPage) return RouteNames.login;
        if (isAuth && onAuthPage) return RouteNames.home;
        return null;
      },
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Page not found')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.route_outlined, size: 56),
                const SizedBox(height: 12),
                const Text(
                  'This page is unavailable.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.go(RouteNames.home),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Return home'),
                ),
              ],
            ),
          ),
        ),
      ),
      routes: [
        GoRoute(
            path: RouteNames.login, builder: (_, __) => const LoginScreen()),
        GoRoute(
            path: RouteNames.signup, builder: (_, __) => const SignupScreen()),
        ShellRoute(
          builder: (context, state, child) =>
              MainShell(location: state.uri.path, child: child),
          routes: [
            GoRoute(
                path: RouteNames.home, builder: (_, __) => const HomeScreen()),
            GoRoute(
              path: RouteNames.inventory,
              builder: (_, __) => const InventoryListScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (_, __) => const AddInventoryItemScreen(),
                ),
                GoRoute(
                  path: 'product/:id',
                  builder: (_, state) => ProductManagementScreen(
                    productId: state.pathParameters['id']!,
                    product:
                        state.extra is Product ? state.extra as Product : null,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: RouteNames.utang,
              builder: (_, __) => const UtangListScreen(),
              routes: [
                GoRoute(
                  path: 'record',
                  builder: (_, __) => const RecordUtangScreen(),
                ),
                GoRoute(
                  path: 'customer/:id',
                  builder: (_, state) => CustomerBalanceScreen(
                    customerId: state.pathParameters['id']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'payment',
                      builder: (_, state) => RecordPaymentScreen(
                        customerId: state.pathParameters['id']!,
                        customer: state.extra is Customer
                            ? state.extra as Customer
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
                path: RouteNames.reports,
                builder: (_, __) => const ReportsScreen()),
          ],
        ),
      ],
    );
  }
}

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child, required this.location});
  final Widget child;
  final String location;

  String get title {
    if (location.startsWith(RouteNames.inventory)) return 'Inventory';
    if (location.startsWith(RouteNames.utang)) return 'Utang';
    if (location.startsWith(RouteNames.reports)) return 'Reports';
    return 'Dashboard';
  }

  bool get isTopLevelDestination =>
      location == RouteNames.home ||
      location == RouteNames.inventory ||
      location == RouteNames.utang ||
      location == RouteNames.reports;

  int get index {
    if (location.startsWith(RouteNames.inventory)) return 1;
    if (location.startsWith(RouteNames.utang)) return 2;
    if (location.startsWith(RouteNames.reports)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isTopLevelDestination
          ? AppBar(
              leading: Builder(
                builder: (context) => IconButton(
                  tooltip: 'Open navigation menu',
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: Text(title),
            )
          : null,
      drawer: AppNavigationDrawer(location: location),
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          const paths = [
            RouteNames.home,
            RouteNames.inventory,
            RouteNames.utang,
            RouteNames.reports
          ];
          context.go(paths[value]);
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Inventory'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Utang'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Reports'),
        ],
      ),
    );
  }
}
