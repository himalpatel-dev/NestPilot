import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/billing_payment_service.dart';
import '../../services/permission_service.dart';
import '../../config/modules.dart';
import '../../models/billing_payment.dart';
import '../../theme/app_colors.dart';
import '../../theme/nest_loader.dart';
import '../../widgets/module_page_header.dart';
import '../../widgets/status_widgets.dart';
import 'bill_detail_screen.dart';
import 'create_bill_sheet.dart';

class BillsManageScreen extends StatefulWidget {
  const BillsManageScreen({super.key});

  @override
  State<BillsManageScreen> createState() => _BillsManageScreenState();
}

class _BillsManageScreenState extends State<BillsManageScreen> {
  final BillService _billService = BillService();
  final TextEditingController _searchController = TextEditingController();
  List<Bill> _bills = [];
  bool _isLoading = true;
  String? _error;
  String _query = '';
  String _selectedStatusFilter = 'ALL';

  /// Id of the bill currently being published — keeps its button in a
  /// spinner state and blocks a second tap on the same row.
  String? _publishingId;

  final List<String> _statusFilters = [
    'ALL',
    'DRAFT',
    'PUBLISHED',
    'CANCELLED',
  ];

  List<Bill> get _filteredBills {
    final q = _query.trim().toLowerCase();
    return _bills.where((b) {
      final matchesQuery =
          q.isEmpty ||
          b.title.toLowerCase().contains(q) ||
          b.billType.toLowerCase().contains(q) ||
          (b.description ?? '').toLowerCase().contains(q);

      final matchesStatus =
          _selectedStatusFilter == 'ALL' || b.status == _selectedStatusFilter;

      return matchesQuery && matchesStatus;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchBills();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBills() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final bills = await _billService.getBills();
      setState(() {
        _bills = bills;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _publishBill(String id) async {
    setState(() => _publishingId = id);
    try {
      final success = await _billService.publishBill(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bill published successfully'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
        _fetchBills();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _publishingId = null);
    }
  }

  void _openEditSheet(Bill bill) {
    showCreateBillSheet(context, onCreated: _fetchBills, editing: bill);
  }

  Future<void> _deleteBill(Bill bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.55),
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 36),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.15),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                decoration: const BoxDecoration(
                  color: AppColors.accentRed,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.20),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.40),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Delete Bill?',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bill.title,
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.80),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  children: [
                    const Text(
                      'The draft is cancelled and can no longer be published. '
                      'Nothing was sent to members yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx, false),
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx, true),
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.accentRed,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accentRed.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Delete',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await _billService.deleteBill(bill.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bill deleted')));
        _fetchBills();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PUBLISHED':
        return AppColors.accentGreen;
      case 'DRAFT':
        return AppColors.accentAmber;
      case 'CANCELLED':
        return AppColors.accentRed;
      default:
        return AppColors.primary;
    }
  }

  String _money(double value) => NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: value % 1 == 0 ? 0 : 2,
  ).format(value);

  @override
  Widget build(BuildContext context) {
    final canPublish = PermissionService().canManage(ModuleCodes.bills);
    final draft = _bills.where((b) => b.status == 'DRAFT').length;
    final published = _bills.where((b) => b.status == 'PUBLISHED').length;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: RefreshIndicator(
        onRefresh: _fetchBills,
        color: AppColors.white,
        backgroundColor: AppColors.primary,
        child: Column(
          children: [
            ModulePageHeader(
              title: 'Bills',
              description: 'Create & publish maintenance bills',
              icon: Icons.receipt_long_outlined,
              iconColor: ModuleColors.bills,
              stats: [
                ModuleHeaderStat('$draft', 'DRAFT'),
                ModuleHeaderStat('$published', 'PUBLISHED'),
                ModuleHeaderStat('${_bills.length}', 'TOTAL'),
              ],
              showSearch: true,
              searchHint: 'Search bill, type, notes...',
              searchController: _searchController,
              onSearchChanged: (v) => setState(() => _query = v),
            ),
            // Horizontal Filter Chips
            Container(
              height: 44,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _statusFilters.length,
                itemBuilder: (context, index) {
                  final filter = _statusFilters[index];
                  final isSelected = _selectedStatusFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                      backgroundColor: AppColors.white,
                      selectedColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      onSelected: (_) {
                        setState(() => _selectedStatusFilter = filter);
                      },
                    ),
                  );
                },
              ),
            ),
            Expanded(child: _buildBillList(canPublish: canPublish)),
          ],
        ),
      ),
      // Creating a bill is a manage-only action — the list itself is
      // shared with view-only roles.
      floatingActionButton: canPublish
          ? FloatingActionButton.extended(
              onPressed: () =>
                  showCreateBillSheet(context, onCreated: _fetchBills),
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'New Bill',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildBillList({required bool canPublish}) {
    if (_isLoading) return const Center(child: NestLoader());
    if (_error != null) {
      return ErrorWidgetView(message: _error!, onRetry: _fetchBills);
    }

    final bills = _filteredBills;
    if (bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: AppColors.border,
            ),
            SizedBox(height: 12),
            Text(
              'No bills found',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Pull down to refresh or generate a new bill',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
      itemCount: bills.length,
      itemBuilder: (context, index) =>
          _billCard(bills[index], canPublish: canPublish),
    );
  }

  Widget _billCard(Bill bill, {required bool canPublish}) {
    final statusColor = _statusColor(bill.status);
    final isDraft = bill.status == 'DRAFT';
    final isOverdue =
        bill.status == 'PUBLISHED' && bill.dueDate.isBefore(DateTime.now());
    final dueColor = isOverdue ? AppColors.accentRed : AppColors.textMuted;
    final hasNotes = bill.description != null && bill.description!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDraft ? AppColors.accentAmber : AppColors.border,
          width: isDraft ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openDetails(bill),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title row — icon chip · title + badges · amount ──────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: statusColor,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _pill(bill.status, statusColor),
                              Text(
                                '· ${bill.billType}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _money(bill.amountTotal),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'TOTAL',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (hasNotes)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Text(
                    bill.description!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const Divider(height: 1, thickness: 1, color: AppColors.border),
              // ── Footer — due date · publish action ──────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Row(
                  children: [
                    Icon(Icons.event_outlined, size: 15, color: dueColor),
                    const SizedBox(width: 6),
                    Text(
                      'Due ${DateFormat('dd MMM yyyy').format(bill.dueDate)}',
                      style: TextStyle(
                        color: dueColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isOverdue) ...[
                      const SizedBox(width: 6),
                      _pill('OVERDUE', AppColors.accentRed),
                    ],
                    const Spacer(),
                    _footerAction(bill, canPublish: canPublish),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Edit / delete / publish live on drafts only — the backend refuses all
  /// three once member bills have been generated from the bill.
  Widget _footerAction(Bill bill, {required bool canPublish}) {
    if (bill.status != 'DRAFT') {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'View details',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
        ],
      );
    }

    // View-only roles see why the bill is still sitting in draft, but get no
    // action to take on it.
    if (!canPublish) {
      return const Text(
        'Awaiting publish',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final isPublishing = _publishingId == bill.id;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _iconAction(
          icon: Icons.edit_outlined,
          color: AppColors.accentIndigo,
          onTap: () => _openEditSheet(bill),
        ),
        const SizedBox(width: 8),
        _iconAction(
          icon: Icons.delete_outline_rounded,
          color: AppColors.accentRed,
          onTap: () => _deleteBill(bill),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 34,
          child: ElevatedButton.icon(
            onPressed: isPublishing ? null : () => _publishBill(bill.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.primaryDark.withValues(
                alpha: 0.5,
              ),
              disabledForegroundColor: AppColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            // Label stays put while publishing so the row can't reflow into
            // an overflow on narrow phones — only the icon swaps.
            icon: isPublishing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.white,
                      ),
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 15),
            label: const Text(
              'Publish',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  /// Details open as their own page, matching every other module — edit and
  /// delete stay on the list card, so the page only offers Publish.
  Future<void> _openDetails(Bill bill) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => BillDetailScreen(bill: bill)),
    );
    if (changed == true) _fetchBills();
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
