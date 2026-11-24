import 'package:flutter/material.dart';
import '../../services/profile_metadata_service.dart';
import '../../utils/iccid_formatter.dart';
import '../../utils/profile_redaction.dart';
import '../../theme/app_theme.dart';
import '../../widgets/styled_header_scaffold.dart';

import '../l10n/app_localizations.dart';

class ReminderDetailsPage extends StatefulWidget {
  final String iccid;
  final String eid;

  const ReminderDetailsPage({
    super.key,
    required this.iccid,
    required this.eid,
  });

  @override
  State<ReminderDetailsPage> createState() => _ReminderDetailsPageState();
}

class _ReminderDetailsPageState extends State<ReminderDetailsPage> {
  ProfileMetadata? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final s = await ProfileMetadataService.getInstance();
    final p = await s.getProfile(widget.iccid);

    // Fallback if not found by strict ICCID, maybe search logic?
    // User requested "eid it was on".

    if (mounted) {
      setState(() {
        _profile = p;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_profile == null) {
      return StyledHeaderScaffold(
        title: l10n.reminderDetails,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.onSurfaceSubtle(context),
              ),
              const SizedBox(height: 16),
              Text(l10n.profileNotFound),
              const SizedBox(height: 8),
              Text(
                "${l10n.iccid}: ${IccidFormatter.forDisplay(ProfileRedaction.redactIccid(widget.iccid))}",
              ),
            ],
          ),
        ),
      );
    }

    final p = _profile!;
    final theme = Theme.of(context);

    return StyledHeaderScaffold(
      title: l10n.reminderDetails,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.3 : 0.05,
                    ),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Icon placeholder if no widget
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            p.displayName.isNotEmpty
                                ? p.displayName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.displayName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.providerName ?? l10n.unknownProvider,
                              style: TextStyle(
                                color: AppTheme.onSurfaceSubtle(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(
                    context,
                    l10n.iccid,
                    IccidFormatter.forDisplay(
                      ProfileRedaction.redactIccid(p.iccid),
                    ),
                  ),
                  _buildDetailRow(
                    context,
                    "EID",
                    IccidFormatter.forDisplay(
                      widget.eid.isNotEmpty
                          ? ProfileRedaction.redactEid(widget.eid)
                          : (p.eid == null
                              ? l10n.unavailable
                              : ProfileRedaction.redactEid(p.eid!)),
                    ),
                  ), // Use notification EID if valid
                  _buildDetailRow(
                    context,
                    l10n.lastSeen,
                    p.lastSeen.toString(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text(
              l10n.tags.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            if (p.tags.isEmpty)
              Text(
                l10n.noTags,
                style: TextStyle(color: AppTheme.onSurfaceSubtle(context)),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: p.tags
                    .map(
                      (t) => Chip(
                        label: Text(t),
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.onSurfaceSubtle(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.mono(
                const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
