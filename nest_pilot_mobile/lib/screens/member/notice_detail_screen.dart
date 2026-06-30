import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/notice_complaint.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_page_header.dart';

class NoticeDetailScreen extends StatelessWidget {
  final Notice notice;
  const NoticeDetailScreen({super.key, required this.notice});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final date = DateFormat('dd MMM yyyy').format(notice.createdAt);
    final time = DateFormat('hh:mm a').format(notice.createdAt);
    final hasAttachment = notice.attachmentUrl != null && notice.attachmentUrl!.isNotEmpty;
    final authorName = (notice.createdBy != null && notice.createdBy!.isNotEmpty)
        ? notice.createdBy!
        : null;
    final authorInitial = authorName != null ? authorName[0].toUpperCase() : 'N';

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppPageHeader(
              icon: const Icon(Icons.campaign_outlined, color: AppColors.white, size: 28),
              title: 'Notice',
              subtitle: 'Posted $date',
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 22, 16, bottomPad + 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Title + meta card ──────────────────────────────────
                  _card(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Notice title
                        Text(
                          notice.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.3,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Date — 1 line
                        _infoRow(
                          icon: Icons.calendar_month_rounded,
                          color: AppColors.accentIndigo,
                          label: 'Date',
                          value: date,
                        ),
                        const SizedBox(height: 12),

                        // Time — 1 line
                        _infoRow(
                          icon: Icons.access_time_rounded,
                          color: const Color(0xFF00897B),
                          label: 'Time',
                          value: time,
                        ),

                        // Author
                        if (authorName != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.accentIndigo.withValues(alpha: 0.12),
                                  child: Text(
                                    authorInitial,
                                    style: const TextStyle(
                                      color: AppColors.accentIndigo,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 13),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Posted by',
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      authorName,
                                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Message card ────────────────────────────────────────
                  _card(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppColors.accentIndigo,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Message',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          notice.description,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15.5,
                            height: 1.85,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Attachment ──────────────────────────────────────────
                  if (hasAttachment) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri.tryParse(notice.attachmentUrl!);
                        if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      child: _card(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        borderColor: AppColors.accentBlue.withValues(alpha: 0.30),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.accentBlue.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.attach_file_rounded, color: AppColors.accentBlue, size: 24),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Attachment', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
                                  SizedBox(height: 4),
                                  Text('Tap to open or download', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                                ],
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.accentBlue.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.download_rounded, color: AppColors.accentBlue, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 13),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color.withValues(alpha: 0.75), fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
          ],
        ),
      ],
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding, Color? borderColor}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
