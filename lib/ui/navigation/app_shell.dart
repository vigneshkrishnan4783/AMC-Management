import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/breakpoints.dart';
import '../../providers/contract_provider.dart';
import '../../providers/service_visit_provider.dart';
import '../../providers/settings_provider.dart';
import '../contracts/contracts_screen.dart';
import '../customers/customers_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../documents/documents_history_screen.dart';
import '../reminders/reminders_screen.dart';
import '../service_visits/service_visits_screen.dart';
import '../settings/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.isDesktop(context);
    final isTablet = Breakpoints.isTablet(context);
    final settingsProv = context.watch<SettingsProvider>();
    final contractProv = context.watch<ContractProvider>();
    final visitProv = context.watch<ServiceVisitProvider>();

    final expiringCount = contractProv.expiringSoonCount + contractProv.expiredCount;
    final todayVisitsCount = visitProv.visitsScheduledToday.length;

    final screens = [
      DashboardScreen(onTabSelected: (idx) => setState(() => _currentIndex = idx)),
      const CustomersScreen(),
      const ContractsScreen(),
      const ServiceVisitsScreen(),
      const RemindersScreen(),
      const DocumentsHistoryScreen(),
      const SettingsScreen(),
    ];

    if (isDesktop) {
      // Desktop Layout: Full Sidebar Navigation + Content
      return Scaffold(
        body: Row(
          children: [
            _buildDesktopSidebar(context, settingsProv, expiringCount, todayVisitsCount),
            const VerticalDivider(width: 1, thickness: 1, color: AppColors.lightBorder),
            Expanded(
              child: screens[_currentIndex],
            ),
          ],
        ),
      );
    }

    if (isTablet) {
      // Tablet Layout: Navigation Rail + Content
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.handyman_rounded, color: Colors.white, size: 20),
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IconButton(
                      icon: Icon(settingsProv.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
                      onPressed: () => settingsProv.toggleTheme(),
                    ),
                  ),
                ),
              ),
              destinations: [
                const NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Home'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: Text('Clients'),
                ),
                NavigationRailDestination(
                  icon: Badge(
                    isLabelVisible: expiringCount > 0,
                    label: Text('$expiringCount'),
                    child: const Icon(Icons.description_outlined),
                  ),
                  selectedIcon: const Icon(Icons.description),
                  label: const Text('Contracts'),
                ),
                NavigationRailDestination(
                  icon: Badge(
                    isLabelVisible: todayVisitsCount > 0,
                    label: Text('$todayVisitsCount'),
                    child: const Icon(Icons.build_circle_outlined),
                  ),
                  selectedIcon: const Icon(Icons.build_circle),
                  label: const Text('Visits'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.notifications_none),
                  selectedIcon: Icon(Icons.notifications),
                  label: Text('Alerts'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.folder_outlined),
                  selectedIcon: Icon(Icons.folder),
                  label: Text('Docs'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1, color: AppColors.lightBorder),
            Expanded(
              child: screens[_currentIndex],
            ),
          ],
        ),
      );
    }

    // Mobile Layout: Bottom NavigationBar + AppBar
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.handyman_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Text(
              _currentIndex == 0
                  ? 'AMC Manager'
                  : (_currentIndex == 1
                      ? 'Customers'
                      : (_currentIndex == 2
                          ? 'Contracts'
                          : (_currentIndex == 3
                              ? 'Service Visits'
                              : (_currentIndex == 4
                                  ? 'Reminders'
                                  : (_currentIndex == 5 ? 'Documents' : 'Settings'))))),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(settingsProv.themeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => settingsProv.toggleTheme(),
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Clients',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: expiringCount > 0,
              label: Text('$expiringCount'),
              child: const Icon(Icons.description_outlined),
            ),
            selectedIcon: const Icon(Icons.description),
            label: 'Contracts',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: todayVisitsCount > 0,
              label: Text('$todayVisitsCount'),
              child: const Icon(Icons.build_circle_outlined),
            ),
            selectedIcon: const Icon(Icons.build_circle),
            label: 'Visits',
          ),
          const NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(
    BuildContext context,
    SettingsProvider settingsProv,
    int expiringCount,
    int todayVisitsCount,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 260,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & App Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.handyman_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AMC Manager',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Service Suite v1.0',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.lightBorder),
          const SizedBox(height: 12),

          // Nav Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSidebarItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
                _buildSidebarItem(1, Icons.people_outline, Icons.people, 'Customers'),
                _buildSidebarItem(
                  2,
                  Icons.description_outlined,
                  Icons.description,
                  'Contracts',
                  badgeCount: expiringCount,
                  badgeColor: AppColors.statusExpiring,
                ),
                _buildSidebarItem(
                  3,
                  Icons.build_circle_outlined,
                  Icons.build_circle,
                  'Service Visits',
                  badgeCount: todayVisitsCount,
                  badgeColor: AppColors.primary,
                ),
                _buildSidebarItem(4, Icons.notifications_none, Icons.notifications, 'Renewal Reminders'),
                _buildSidebarItem(5, Icons.folder_outlined, Icons.folder, 'Document History'),
                _buildSidebarItem(6, Icons.settings_outlined, Icons.settings, 'Settings & Backup'),
              ],
            ),
          ),

          // User / Theme Switcher Footer
          const Divider(height: 1, thickness: 1, color: AppColors.lightBorder),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settingsProv.settings.businessName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Offline Mode Active',
                        style: TextStyle(fontSize: 10, color: AppColors.statusActive, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(settingsProv.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode, size: 20),
                  onPressed: () => settingsProv.toggleTheme(),
                  tooltip: 'Toggle Theme',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String title, {
    int? badgeCount,
    Color? badgeColor,
  }) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? AppColors.primary : theme.colorScheme.onSurface.withOpacity(0.7),
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primary : theme.colorScheme.onSurface.withOpacity(0.85),
          ),
        ),
        trailing: (badgeCount != null && badgeCount > 0)
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: (badgeColor ?? AppColors.primary).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor ?? AppColors.primary,
                  ),
                ),
              )
            : null,
        onTap: () => setState(() => _currentIndex = index),
      ),
    );
  }
}
