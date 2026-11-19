import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/breakpoints.dart';
import '../../providers/contract_provider.dart';
import '../../providers/service_visit_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/subscription_provider.dart';
import '../chatbot/amc_assistant_sheet.dart';
import '../contracts/contracts_screen.dart';
import '../customers/customers_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../documents/documents_history_screen.dart';
import '../reminders/reminders_screen.dart';
import '../service_visits/service_visits_screen.dart';
import '../settings/settings_screen.dart';
import '../subscription/subscription_screen.dart';

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
    final subProv = context.watch<SubscriptionProvider>();

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
            _buildDesktopSidebar(context, settingsProv, subProv, expiringCount, todayVisitsCount),
            const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
            Expanded(
              child: screens[_currentIndex],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => AmcAssistantSheet.show(context),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.smart_toy_outlined),
          label: const Text('AMC Assistant'),
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
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                  ),
                  child: CircleAvatar(
                    backgroundColor: subProv.isSubscribed ? AppColors.success : AppColors.primary,
                    child: Icon(
                      subProv.isSubscribed ? Icons.verified : Icons.handyman_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IconButton(
                      icon: const Icon(Icons.support_agent_rounded, color: AppColors.primary),
                      tooltip: 'Help Assistant',
                      onPressed: () => AmcAssistantSheet.show(context),
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
            const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
            Expanded(
              child: screens[_currentIndex],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => AmcAssistantSheet.show(context),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          tooltip: 'AMC Assistant',
          child: const Icon(Icons.smart_toy_outlined),
        ),
      );
    }

    // Mobile Layout: Bottom NavigationBar + AppBar
    final isSub = subProv.isSubscribed;
    final days = subProv.daysRemaining;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.handyman_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        actions: [
          // Trial / Subscription Badge
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSub
                    ? const Color(0xFFD1FAE5)
                    : (days <= 5 ? const Color(0xFFFEF3C7) : AppColors.primary.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSub ? AppColors.success : (days <= 5 ? AppColors.warning : AppColors.primary),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSub ? Icons.verified : Icons.timer_outlined,
                    size: 13,
                    color: isSub ? AppColors.success : (days <= 5 ? AppColors.warning : AppColors.primary),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isSub ? 'Pro' : '${days}d Trial',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSub ? AppColors.success : (days <= 5 ? AppColors.warning : AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.support_agent_rounded, color: AppColors.primary),
            tooltip: 'AMC Help Assistant',
            onPressed: () => AmcAssistantSheet.show(context),
          ),
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
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Docs',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AmcAssistantSheet.show(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'AMC Smart Assistant',
        child: const Icon(Icons.smart_toy_outlined),
      ),
    );
  }

  Widget _buildDesktopSidebar(
    BuildContext context,
    SettingsProvider settingsProv,
    SubscriptionProvider subProv,
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AMC Manager',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Service Suite v1.0',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Trial / Subscription Card in Sidebar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: subProv.isSubscribed
                      ? const Color(0xFFD1FAE5)
                      : AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: subProv.isSubscribed
                        ? AppColors.success.withOpacity(0.4)
                        : AppColors.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      subProv.isSubscribed ? Icons.verified : Icons.timer_outlined,
                      size: 20,
                      color: subProv.isSubscribed ? AppColors.success : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subProv.isSubscribed ? 'Active License' : '30-Day Free Trial',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: subProv.isSubscribed ? AppColors.success : AppColors.primary,
                            ),
                          ),
                          Text(
                            subProv.isSubscribed ? 'Unlimited Pro Access' : '${subProv.daysRemaining} days remaining',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: AppColors.border),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              children: [
                _buildSidebarItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
                _buildSidebarItem(1, Icons.people_outline, Icons.people, 'Customers'),
                _buildSidebarItem(
                  2,
                  Icons.description_outlined,
                  Icons.description,
                  'Contracts & AMC',
                  badgeCount: expiringCount,
                  badgeColor: AppColors.warning,
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
                const Divider(height: 20),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 20),
                  title: const Text('AMC Assistant', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  onTap: () => AmcAssistantSheet.show(context),
                ),
              ],
            ),
          ),

          // User / Theme Switcher Footer & Branding
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settingsProv.settings.businessName.isNotEmpty
                                ? settingsProv.settings.businessName
                                : 'AMC Management',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Offline SQLite Storage',
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
                const SizedBox(height: 6),
                Text(
                  'Powered by ${settingsProv.settings.poweredBy}',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
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
