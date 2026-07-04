import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dashboard_header.dart';
import '../theme/app_bottom_nav.dart';
import '../theme/tab_route.dart';

import 'login_screen.dart';
import 'notification_list_screen.dart';
import 'module_catalog.dart';

class ServicesHubScreen extends StatefulWidget {
  final UserModel user;
  final bool embedded;
  const ServicesHubScreen({
    super.key,
    required this.user,
    this.embedded = true,
  });

  @override
  State<ServicesHubScreen> createState() => _ServicesHubScreenState();
}

class _ServicesHubScreenState extends State<ServicesHubScreen> {
  int _selectedTab = 2;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sections = filterModuleSections(_masterSections());
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cardBackground,
        bottomNavigationBar: widget.embedded
            ? null
            : AppBottomNav(
                selectedIndex: _selectedTab,
                bottomPadding: bottomPad,
                onTap: _onNavTap,
                items: _navItems(),
              ),
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: AppDashboardHeader(
                leftAction: Navigator.canPop(context)
                    ? appHeaderBackButton(context)
                    : null,
                title: 'Services',
                subtitle: 'All your tools in one place',
                onNotificationTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationListScreen(),
                  ),
                ),
                bottomSection: _buildSearchBar(),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPad + 24),
              sliver: _searchQuery.isEmpty
                  ? SliverList(
                      delegate: SliverChildBuilderDelegate((ctx, i) {
                        final s = sections[i];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: i == sections.length - 1 ? 0 : 24,
                          ),
                          child: ModuleSectionView(title: s.title, tiles: s.tiles),
                        );
                      }, childCount: sections.length),
                    )
                  : SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSearchResults(sections),
                      ]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Search bar ──────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      height: 37,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 13),
          const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.2,
              ),
              cursorColor: AppColors.primary,
              cursorHeight: 16,
              decoration: InputDecoration(
                hintText: 'Search services...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.65),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            GestureDetector(
              onTap: () => _searchController.clear(),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                  size: 13,
                ),
              ),
            ),
          ],
          const SizedBox(width: 13),
        ],
      ),
    );
  }

  // ─── Search results ──────────────────────────────────────────────────────────

  Widget _buildSearchResults(List<ModuleSection> sections) {
    final tiles = _filterTiles(sections);
    if (tiles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            Text(
              'No services found',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try different keywords',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.40),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    return ModuleGrid(tiles: tiles);
  }

  List<ModuleTile> _filterTiles(List<ModuleSection> sections) {
    final words = _searchQuery
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return [];

    final scores = <ModuleTile, int>{};
    for (final section in sections) {
      for (final tile in section.tiles) {
        final s = _scoreTile(tile, words);
        if (s > 0) scores[tile] = s;
      }
    }
    final result = scores.keys.toList();
    result.sort((a, b) => scores[b]!.compareTo(scores[a]!));
    return result;
  }

  int _scoreTile(ModuleTile tile, List<String> words) {
    final label = tile.label.toLowerCase();
    final terms = [label, ...tile.tags];
    int total = 0;
    for (final word in words) {
      int best = 0;
      for (final term in terms) {
        if (term == word) {
          best = best > 100 ? best : 100;
        } else if (term.startsWith(word)) {
          best = best > 70 ? best : 70;
        } else if (term.contains(word)) {
          best = best > 50 ? best : 50;
        } else if (word.length >= 3 && _fuzzyMatch(term, word)) {
          best = best > 20 ? best : 20;
        }
      }
      total += best;
    }
    return total;
  }

  bool _fuzzyMatch(String text, String pattern) {
    int pi = 0;
    for (int i = 0; i < text.length && pi < pattern.length; i++) {
      if (text[i] == pattern[pi]) pi++;
    }
    return pi == pattern.length;
  }

  // ─── Bottom nav ───────────────────────────────────────────────────────────────

  List<AppNavItem> _navItems() {
    return const [
      AppNavItem(Icons.home_rounded, 'Home'),
      AppNavItem(Icons.people_rounded, 'Community'),
      AppNavItem(Icons.apps_rounded, 'Services'),
      AppNavItem(Icons.account_balance_wallet_rounded, 'Payments'),
      AppNavItem(Icons.person_rounded, 'Profile'),
    ];
  }

  void _onNavTap(int index) {
    if (index == 2) return;
    if (index == 0 || index == 4) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _selectedTab = index);
    Widget? screen;
    switch (index) {
      case 1:
        screen = noticesDest();
        break;
      case 3:
        screen = billsDest();
        break;
    }
    if (screen != null) {
      Navigator.push(context, tabRoute(screen)).then((_) {
        if (mounted) setState(() => _selectedTab = 2);
      });
    }
  }

  // ─── Sections: shared catalogue + hub-only settings ──────────────────────────

  List<ModuleSection> _masterSections() => [
    ...masterModuleSections(),
    ModuleSection('Settings', [
      ModuleTile(
        Icons.notifications_outlined, 'Notifications', AppColors.accentOrange,
        (c) => Navigator.push(
          c,
          MaterialPageRoute(builder: (_) => const NotificationListScreen()),
        ),
        ['alert', 'notify', 'push', 'message', 'reminder', 'bell'],
      ),
      ModuleTile(
        Icons.logout_rounded, 'Logout', AppColors.accentRed,
        (c) => _logout(c),
        ['sign out', 'exit', 'signout', 'quit', 'leave'],
      ),
    ]),
  ];

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
