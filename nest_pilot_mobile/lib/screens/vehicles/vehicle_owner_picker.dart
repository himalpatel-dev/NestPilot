import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/community_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/nest_loader.dart';
import '../../widgets/app_field_card.dart';

/// Result of [showVehicleOwnerPicker]. [user] null means "Myself" — the
/// vehicle is registered to the manager's own account.
class VehicleOwnerPick {
  final UserModel? user;
  const VehicleOwnerPick(this.user);
}

/// Searchable resident picker for a manager registering a vehicle on
/// someone's behalf. Resolves to null when dismissed without a choice.
Future<VehicleOwnerPick?> showVehicleOwnerPicker(
  BuildContext context, {
  String? selectedId,
}) {
  return showModalBottomSheet<VehicleOwnerPick>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _VehicleOwnerPicker(selectedId: selectedId),
  );
}

class _VehicleOwnerPicker extends StatefulWidget {
  final String? selectedId;

  const _VehicleOwnerPicker({this.selectedId});

  @override
  State<_VehicleOwnerPicker> createState() => _VehicleOwnerPickerState();
}

class _VehicleOwnerPickerState extends State<_VehicleOwnerPicker> {
  final TextEditingController _searchCtrl = TextEditingController();
  final String? _myId = SessionService().currentUser?.id;

  List<UserModel> _people = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  // The whole list is loaded once, so filtering is local — no debounce.
  void _onSearchChanged() => setState(() {});

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final people = await CommunityService().getVehicleOwnerOptions();
      if (!mounted) return;
      setState(() {
        // "Myself" is pinned separately, so drop the manager's own row.
        _people = people.where((u) => u.id != _myId).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<UserModel> get _visible {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _people;
    return _people
        .where(
          (u) =>
              u.fullName.toLowerCase().contains(q) ||
              (u.flatNumber ?? '').toLowerCase().contains(q) ||
              u.mobile.contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Fill most of the screen but stay clear of the keyboard and status bar.
    final height =
        (media.size.height - media.viewInsets.bottom - media.padding.top - 24)
            .clamp(260.0, media.size.height * 0.85);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: AppSearchField(
                controller: _searchCtrl,
                hint: 'Search name, flat or mobile',
              ),
            ),
            Expanded(child: _buildList(media.padding.bottom)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: ModuleColors.vehicles.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.person_search_rounded,
              color: Color.lerp(ModuleColors.vehicles, AppColors.black, 0.25),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vehicle Owner',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Who is this vehicle registered to?',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.accentRed,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(double bottomPad) {
    if (_isLoading) {
      return const Center(child: NestLoader(size: 48, showDots: false));
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final query = _searchCtrl.text.trim();
    final visible = _visible;
    final showMyself = query.isEmpty;
    if (visible.isEmpty && !showMyself) {
      return AppListEmpty(
        icon: Icons.person_off_outlined,
        message: 'No residents match "$query"',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 20),
      itemCount: visible.length + (showMyself ? 1 : 0),
      itemBuilder: (context, i) {
        if (showMyself && i == 0) {
          return AppListCard(
            accentColor: AppColors.primary,
            icon: Icons.person_pin_rounded,
            title: 'Myself',
            subtitleChips: const ['Register to your own account'],
            trailing: _check(widget.selectedId == null),
            onTap: () => Navigator.pop(context, const VehicleOwnerPick(null)),
          );
        }

        final user = visible[i - (showMyself ? 1 : 0)];
        return AppListCard(
          accentColor: ModuleColors.vehicles,
          icon: Icons.person_rounded,
          title: user.fullName,
          subtitleChips: [
            if ((user.flatNumber ?? '').isNotEmpty)
              'Flat ${user.flatNumber}'
            else
              'No flat linked',
            if (user.mobile.isNotEmpty) user.mobile,
          ],
          trailing: _check(widget.selectedId == user.id),
          onTap: () => Navigator.pop(context, VehicleOwnerPick(user)),
        );
      },
    );
  }

  Widget? _check(bool selected) => selected
      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
      : null;
}
