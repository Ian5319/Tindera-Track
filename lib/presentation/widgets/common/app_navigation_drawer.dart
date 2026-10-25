import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';

class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({super.key, required this.location});

  final String location;

  bool _isSelected(String route) =>
      route == RouteNames.home
          ? location == RouteNames.home
          : location.startsWith(route);

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'Are you sure you want to log out of TinderaTrack?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<AuthProvider>().logout();
    } catch (_) {
      // Clear the local session and continue to login even if Firebase sign-out
      // cannot complete because of a transient network error.
    }

    if (context.mounted) context.go(RouteNames.login);
  }

  void _navigate(BuildContext context, String route) {
    Navigator.of(context).pop();
    if (context.mounted) context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final drawerWidth = math.min(
      MediaQuery.sizeOf(context).width * .82,
      360.0,
    );

    return Drawer(
      width: drawerWidth,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.accent.withValues(alpha: .35),
                    foregroundColor: AppColors.primaryDark,
                    child: const Icon(Icons.storefront_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.storeName ?? 'TinderaTrack',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.name ?? 'Store owner',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                children: [
                  _DrawerDestination(
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home,
                    label: 'Home',
                    selected: _isSelected(RouteNames.home),
                    onTap: () => _navigate(context, RouteNames.home),
                  ),
                  _DrawerDestination(
                    icon: Icons.inventory_2_outlined,
                    selectedIcon: Icons.inventory_2,
                    label: 'Product Inventory',
                    selected: _isSelected(RouteNames.inventory),
                    onTap: () => _navigate(context, RouteNames.inventory),
                  ),
                  _DrawerDestination(
                    icon: Icons.receipt_long_outlined,
                    selectedIcon: Icons.receipt_long,
                    label: 'Utang',
                    selected: _isSelected(RouteNames.utang),
                    onTap: () => _navigate(context, RouteNames.utang),
                  ),
                  _DrawerDestination(
                    icon: Icons.bar_chart_outlined,
                    selectedIcon: Icons.bar_chart,
                    label: 'Reports',
                    selected: _isSelected(RouteNames.reports),
                    onTap: () => _navigate(context, RouteNames.reports),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Log out'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onTap: () => _confirmLogout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerDestination extends StatelessWidget {
  const _DrawerDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(selected ? selectedIcon : icon),
        title: Text(label),
        selected: selected,
        selectedColor: AppColors.primaryDark,
        selectedTileColor: AppColors.accent.withValues(alpha: .22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        onTap: onTap,
      ),
    );
  }
}
