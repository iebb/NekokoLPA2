import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nlpa2/vowifi_sms/vowifi_sms_plugin.dart';

import '../l10n/app_localizations.dart';
import '../services/vowifi_sms_service.dart';
import '../settings/app_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/styled_header_scaffold.dart';

class VowifiSmsPage extends StatefulWidget {
  const VowifiSmsPage({super.key, this.initialSessionId});

  final String? initialSessionId;

  @override
  State<VowifiSmsPage> createState() => _VowifiSmsPageState();
}

class _VowifiSmsPageState extends State<VowifiSmsPage> {
  final VowifiSmsService _service = VowifiSmsService();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  Timer? _ticker;
  String? _selectedSessionId;
  bool _formattingRecipient = false;

  @override
  void initState() {
    super.initState();
    _selectedSessionId = widget.initialSessionId;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
    _toController.addListener(_formatRecipientController);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _toController.removeListener(_formatRecipientController);
    _toController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_service, AppSettings()]),
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        final sessions = _service.sessions;
        if (sessions.isNotEmpty &&
            !sessions.any((session) => session.id == _selectedSessionId)) {
          _selectedSessionId = sessions.first.id;
        }
        final selected = sessions
            .where((s) => s.id == _selectedSessionId)
            .firstOrNull;
        return StyledHeaderScaffold(
          showBackButton: false,
          compact: true,
          title: 'VoWiFi',
          subtitle: '${sessions.length} active session(s)',
          actions: [
            IconButton(
              tooltip: l10n.vowifiAutoRenewSubtitle,
              isSelected: AppSettings().vowifiAutoRenew,
              onPressed: () => AppSettings().setVowifiAutoRenew(
                !AppSettings().vowifiAutoRenew,
              ),
              icon: Icon(
                Icons.autorenew,
                color: AppSettings().vowifiAutoRenew
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
            IconButton(
              tooltip: 'Disconnect all',
              onPressed: _service.busy || sessions.isEmpty
                  ? null
                  : _service.disconnectAll,
              icon: const Icon(Icons.link_off),
            ),
          ],
          body: LayoutBuilder(
            builder: (context, constraints) {
              if (sessions.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [_buildEmptyState(context)],
                );
              }
              final wide = constraints.maxWidth >= 980;
              final leftPane = _buildSessionListPane(context, sessions);
              final rightPane = _buildDetailPane(
                context,
                selected,
                wide: wide,
                conversationHeight: wide ? 420 : 320,
              );
              if (!wide) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [leftPane, const SizedBox(height: 16), rightPane],
                );
              }
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 340, child: leftPane),
                    const SizedBox(width: 16),
                    Expanded(child: rightPane),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.wifi_calling_3_outlined,
            size: 42,
            color: AppTheme.onSurfaceSubtle(context),
          ),
          const SizedBox(height: 12),
          Text(
            'No active VoWiFi sessions.',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Load a SIM into VoWiFi from the device page.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.onSurfaceSubtle(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionListPane(
    BuildContext context,
    List<VowifiSessionInfo> sessions,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Sessions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final session in sessions) _buildSessionCard(context, session),
        ],
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, VowifiSessionInfo session) {
    final theme = Theme.of(context);
    final selected = session.id == _selectedSessionId;
    return InkWell(
      onTap: () => setState(() => _selectedSessionId = session.id),
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.28)
                : Colors.transparent,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileAvatarWithBadge(
              context,
              session,
              badgeCount: _messageCount(session),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.profileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _associatedLabel(session),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceSubtle(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    session.readerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceSubtle(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatRemaining(session.remaining),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.55,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _stateLabel(session.state),
                    style: theme.textTheme.labelSmall,
                  ),
                ),
                if (AppSettings().vowifiAutoRenew) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.autorenew,
                        size: 11,
                        color: session.needsAutoRenew
                            ? theme.colorScheme.primary
                            : AppTheme.onSurfaceSubtle(context),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        AppLocalizations.of(context)!.vowifiAutoRenewTitle,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: session.needsAutoRenew
                              ? theme.colorScheme.primary
                              : AppTheme.onSurfaceSubtle(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatarWithBadge(
    BuildContext context,
    VowifiSessionInfo session, {
    required int badgeCount,
  }) {
    final resolvedIcon = session.profileResolvedIcon.trim();
    final customIcon = session.profileCustomIcon.trim();
    final imageBytes = session.profileIcon;
    ImageProvider? imageProvider;
    if (resolvedIcon.isNotEmpty) {
      try {
        imageProvider = MemoryImage(base64Decode(resolvedIcon));
      } catch (_) {}
    }
    if (customIcon.isNotEmpty) {
      try {
        imageProvider ??= MemoryImage(base64Decode(customIcon));
      } catch (_) {}
    }
    if (imageProvider == null && imageBytes != null && imageBytes.isNotEmpty) {
      imageProvider = MemoryImage(imageBytes);
    }
    final avatar = imageProvider != null
        ? CircleAvatar(radius: 24, backgroundImage: imageProvider)
        : CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.12),
            child: Text(
              session.profileName.trim().isEmpty
                  ? '?'
                  : session.profileName.trim().characters.first.toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
    if (badgeCount <= 0) {
      return avatar;
    }
    final theme = Theme.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.surface, width: 2),
            ),
            child: Text(
              badgeCount > 99 ? '99+' : '$badgeCount',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
                fontSize: badgeCount > 99 ? 8 : 10,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailPane(
    BuildContext context,
    VowifiSessionInfo? session, {
    required bool wide,
    required double conversationHeight,
  }) {
    return _buildConversationPane(
      context,
      session,
      wide: wide,
      conversationHeight: conversationHeight,
    );
  }

  Widget _buildConversationPane(
    BuildContext context,
    VowifiSessionInfo? session, {
    required bool wide,
    required double conversationHeight,
  }) {
    final theme = Theme.of(context);
    if (session == null) {
      return _buildEmptyState(context);
    }
    final messages = _messagesForSession(session);
    final deliveryStatuses = _deliveryStatusByMessage(session);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailHero(context, session, wide: wide),
            if ((session.lastError ?? '').isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildErrorBanner(context, session.lastError!),
            ],
            const SizedBox(height: 18),
            Text(
              'Messages',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Conversation timeline with network delivery updates.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceSubtle(context),
              ),
            ),
            const SizedBox(height: 14),
            if (messages.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.18,
                    ),
                  ),
                ),
                child: Text(
                  'No messages for ${_associatedLabel(session)}.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceSubtle(context),
                  ),
                ),
              )
            else
              ...messages.map(
                (message) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment: message.direction == VowifiSmsDirection.outbound
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: _buildMessageCard(
                      context,
                      session,
                      message,
                      deliveryStatus: deliveryStatuses[message],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            _buildComposerCard(context, session),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailHero(
    BuildContext context,
    VowifiSessionInfo session, {
    required bool wide,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileAvatarWithBadge(
            context,
            session,
            badgeCount: _messageCount(session),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.profileName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                _associatedIdentityRow(context, session),
                const SizedBox(height: 8),
                Text(
                  _heroMetadataLine(session),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceSubtle(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  if (wide) ...[
                    OutlinedButton.icon(
                      onPressed: _service.busy
                          ? null
                          : () => _service.refreshSession(session.id),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Refresh'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _service.busy
                          ? null
                          : () => _service.disconnectSession(session.id),
                      icon: const Icon(Icons.link_off_rounded),
                      label: const Text('Disconnect'),
                    ),
                  ] else ...[
                    IconButton.outlined(
                      onPressed: _service.busy
                          ? null
                          : () => _service.refreshSession(session.id),
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Refresh',
                    ),
                    IconButton.outlined(
                      onPressed: _service.busy
                          ? null
                          : () => _service.disconnectSession(session.id),
                      icon: const Icon(Icons.link_off_rounded),
                      tooltip: 'Disconnect',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _formatRemaining(session.remaining),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (AppSettings().vowifiAutoRenew)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.autorenew,
                        size: 13,
                        color: session.needsAutoRenew
                            ? theme.colorScheme.primary
                            : AppTheme.onSurfaceSubtle(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        session.needsAutoRenew
                            ? AppLocalizations.of(context)!.vowifiAutoRenewDue
                            : AppLocalizations.of(
                                context,
                              )!.vowifiAutoRenewEnabled,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: session.needsAutoRenew
                              ? theme.colorScheme.primary
                              : AppTheme.onSurfaceSubtle(context),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _associatedIdentityRow(
    BuildContext context,
    VowifiSessionInfo session,
  ) {
    final theme = Theme.of(context);
    final identities = _sortedIdentities(session);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: identities.isEmpty
          ? null
          : () => _showIdentityPicker(context, session),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                _associatedLabel(session),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (identities.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                '${identities.length} identities',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.swap_horiz_rounded,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(
    BuildContext context,
    VowifiSessionInfo session,
    VowifiSmsMessage message, {
    String? deliveryStatus,
  }) {
    final theme = Theme.of(context);
    final outgoing = message.direction == VowifiSmsDirection.outbound;
    final status = _isStatusMessage(message);
    final fill = status
        ? theme.colorScheme.tertiary.withValues(alpha: 0.12)
        : outgoing
        ? theme.colorScheme.primary.withValues(alpha: 0.08)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.24);
    return Container(
      constraints: BoxConstraints(
        maxWidth: status ? 760 : 680,
        minWidth: status ? 360 : 260,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(outgoing ? 20 : 6),
          bottomRight: Radius.circular(outgoing ? 6 : 20),
        ),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: status
                      ? theme.colorScheme.tertiary.withValues(alpha: 0.16)
                      : outgoing
                      ? theme.colorScheme.primary.withValues(alpha: 0.16)
                      : theme.colorScheme.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _messageDirectionIcon(message),
                      size: 14,
                      color: _messageDirectionColor(context, message),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _messageDirectionLabel(message),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _messageDirectionColor(context, message),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _isStatusMessage(message)
                      ? null
                      : () => _populateRecipientFromMessage(message, session),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      _messageTitle(message, session),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: _isStatusMessage(message)
                            ? null
                            : TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                _formatTimestamp(message.timestamp),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.onSurfaceSubtle(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_isBinaryMessage(message)) ...[
            Text(
              'Carrier service SMS',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Binary payload hidden',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceSubtle(context),
              ),
            ),
          ] else
            SelectableText(
              _displayMessageText(message),
              style: theme.textTheme.bodyMedium,
            ),
          if (((deliveryStatus ?? '').isNotEmpty ||
                  (message.status).isNotEmpty) &&
              !_isStatusMessage(message)) ...[
            const SizedBox(height: 6),
            Text(
              (deliveryStatus ?? '').isNotEmpty
                  ? deliveryStatus!
                  : message.status,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.onSurfaceSubtle(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComposerCard(BuildContext context, VowifiSessionInfo? session) {
    final theme = Theme.of(context);
    final associated = session == null ? '' : _associatedLabel(session);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Compose SMS',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'Tap a sender to reuse it',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.onSurfaceSubtle(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _messageController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Message',
              isDense: true,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _toController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()-]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Recipient',
                    isDense: true,
                    prefixIcon: const Icon(
                      Icons.alternate_email_rounded,
                      size: 18,
                    ),
                    // helperText removed here to fix height/alignment
                    hintText: _formatE164Display(associated).isEmpty
                        ? '+12025550123'
                        : _formatE164Display(associated),
                    // Make it look attached to the button on the right
                    border: OutlineInputBorder(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12),
                        right: Radius.zero,
                      ),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12),
                        right: Radius.zero,
                      ),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12),
                        right: Radius.zero,
                      ),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 54, // Match TextField height with label + isDense
                child: FilledButton(
                  onPressed: session == null || _service.busy
                      ? null
                      : _sendMessage,
                  style: FilledButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.zero,
                        right: Radius.circular(12),
                      ),
                    ),
                  ),
                  child: const Icon(Icons.send_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Sent over the selected session with E.164 (+12025550123).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.onSurfaceSubtle(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showIdentityPicker(
    BuildContext context,
    VowifiSessionInfo session,
  ) async {
    final theme = Theme.of(context);
    final identities = _sortedIdentities(session);
    if (identities.isEmpty) {
      return;
    }
    final selected = identities.contains(session.selectedIdentity.trim())
        ? session.selectedIdentity.trim()
        : (identities.contains(session.associatedIdentity.trim())
              ? session.associatedIdentity.trim()
              : identities.first);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select sending identity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'P-Associated-URI values starting with + are listed first.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceSubtle(context),
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: identities.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final identity = identities[index];
                      final active = identity == selected;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            _service.selectSessionIdentity(
                              session.id,
                              identity,
                            );
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: active
                                  ? theme.colorScheme.primaryContainer
                                        .withValues(alpha: 0.68)
                                  : theme.colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.38),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: active
                                    ? theme.colorScheme.primary.withValues(
                                        alpha: 0.28,
                                      )
                                    : theme.colorScheme.outlineVariant
                                          .withValues(alpha: 0.18),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  active
                                      ? Icons.check_circle_rounded
                                      : Icons.alternate_email_rounded,
                                  color: active
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatIdentityChoice(identity),
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        identity,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: AppTheme.onSurfaceSubtle(
                                                context,
                                              ),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    final sessionId = _selectedSessionId;
    if (sessionId == null) {
      return;
    }
    final recipient = _normalizeE164(_toController.text);
    if (recipient == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recipient must be an E.164 number like +12025550123'),
        ),
      );
      return;
    }
    await _service.sendTextSms(
      sessionId,
      to: recipient,
      text: _messageController.text.trim(),
    );
    _messageController.clear();
  }

  String _stateLabel(VowifiSmsConnectionState state) {
    return switch (state) {
      VowifiSmsConnectionState.disconnected => 'Disconnected',
      VowifiSmsConnectionState.connecting => 'Connecting',
      VowifiSmsConnectionState.connected => 'Connected',
      VowifiSmsConnectionState.registered => 'Registered',
      VowifiSmsConnectionState.error => 'Error',
    };
  }

  String _formatRemaining(Duration remaining) {
    final total = remaining.inSeconds;
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _associatedLabel(VowifiSessionInfo session) {
    final associated =
        (session.selectedIdentity.trim().isNotEmpty
                ? session.selectedIdentity
                : session.associatedIdentity)
            .trim();
    if (associated.isEmpty) {
      return session.iccid;
    }
    final lower = associated.toLowerCase();
    if (lower.startsWith('sip:')) {
      final body = associated.substring(4);
      final at = body.indexOf('@');
      return _formatE164Display(at > 0 ? body.substring(0, at) : body);
    }
    if (lower.startsWith('tel:')) {
      return _formatE164Display(associated.substring(4));
    }
    return _formatE164Display(associated);
  }

  String _heroMetadataLine(VowifiSessionInfo session) {
    return 'Registered over ${session.readerName}, ICCID ${session.iccid}, ready for SMS traffic.';
  }

  List<String> _sortedIdentities(VowifiSessionInfo session) {
    final seen = <String>{};
    final identities = session.associatedIdentities
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty && seen.add(value))
        .toList(growable: false);
    identities.sort((a, b) {
      final aRank = _identityPriority(a);
      final bRank = _identityPriority(b);
      if (aRank != bRank) {
        return aRank.compareTo(bRank);
      }
      return a.compareTo(b);
    });
    return identities;
  }

  int _identityPriority(String identity) {
    final normalized = identity.trim().toLowerCase();
    if (normalized.startsWith('sip:+') || normalized.startsWith('tel:+')) {
      return 0;
    }
    if (normalized.contains('@')) {
      final local = normalized
          .replaceFirst(RegExp(r'^(sip:|tel:)'), '')
          .split('@')
          .first;
      if (local.startsWith('+')) {
        return 0;
      }
    }
    if (normalized.startsWith('sip:') || normalized.startsWith('tel:')) {
      return 1;
    }
    return 2;
  }

  String _formatIdentityChoice(String identity) {
    final lower = identity.toLowerCase();
    if (lower.startsWith('sip:')) {
      final body = identity.substring(4);
      final at = body.indexOf('@');
      return _formatE164Display(at > 0 ? body.substring(0, at) : body);
    }
    if (lower.startsWith('tel:')) {
      return _formatE164Display(identity.substring(4));
    }
    return _formatE164Display(identity);
  }

  int _messageCount(VowifiSessionInfo session) =>
      _messagesForSession(session).length;

  List<VowifiSmsMessage> _messagesForSession(VowifiSessionInfo session) {
    return List<VowifiSmsMessage>.from(
      session.messages.where((message) {
        return message.direction != VowifiSmsDirection.system;
      }).toList(),
    );
  }

  Map<VowifiSmsMessage, String> _deliveryStatusByMessage(
    VowifiSessionInfo session,
  ) {
    final result = <VowifiSmsMessage, String>{};
    final outbound = <VowifiSmsMessage>[];
    for (final message in session.messages) {
      if (message.direction == VowifiSmsDirection.outbound) {
        outbound.add(message);
        continue;
      }
      if (!_isStatusMessage(message)) {
        continue;
      }
      if (outbound.isEmpty) {
        continue;
      }
      final target = _findOutboundForStatus(outbound, message) ?? outbound.last;
      result[target] = _displayMessageText(message);
    }
    return result;
  }

  VowifiSmsMessage? _findOutboundForStatus(
    List<VowifiSmsMessage> outbound,
    VowifiSmsMessage status,
  ) {
    final text = status.text;
    final match = RegExp(
      r'\bto=([+0-9]+)\b',
      caseSensitive: false,
    ).firstMatch(text);
    final to = match?.group(1);
    if (to == null || to.isEmpty) {
      return null;
    }
    for (final message in outbound.reversed) {
      if (_normalizeE164(message.peer) == _normalizeE164(to)) {
        return message;
      }
    }
    return null;
  }

  String _displayMessageText(VowifiSmsMessage message) {
    final text = message.text.trim();
    final upper = text.toUpperCase();
    if (upper.startsWith('SMS-SUBMIT-REPORT ACCEPTED')) {
      return 'Message accepted by the network.';
    }
    if (upper.startsWith('SMS-SUBMIT-REPORT FAILURE')) {
      return 'Message submission failed.\n$text';
    }
    if (upper.startsWith('SMS-STATUS-REPORT')) {
      return text.replaceFirst('SMS-STATUS-REPORT ', '');
    }
    if (upper.startsWith('SMS-RPDU HEX:')) {
      return 'Carrier submit report received.';
    }
    if (text.startsWith('hex:')) {
      return 'Carrier service SMS';
    }
    return text;
  }

  bool _isStatusMessage(VowifiSmsMessage message) {
    final upper = message.text.toUpperCase();
    return message.direction == VowifiSmsDirection.system &&
        (upper.contains('SMS-SUBMIT-REPORT') ||
            upper.contains('SMS-STATUS-REPORT') ||
            upper.contains('SMS-RPDU'));
  }

  String _messageDirectionLabel(VowifiSmsMessage message) {
    if (_isStatusMessage(message)) {
      return 'Update';
    }
    return message.direction == VowifiSmsDirection.outbound
        ? 'Sent'
        : 'Received';
  }

  IconData _messageDirectionIcon(VowifiSmsMessage message) {
    if (_isStatusMessage(message)) {
      return Icons.mark_email_read_outlined;
    }
    return message.direction == VowifiSmsDirection.outbound
        ? Icons.north_east_rounded
        : Icons.south_west_rounded;
  }

  Color _messageDirectionColor(BuildContext context, VowifiSmsMessage message) {
    final theme = Theme.of(context);
    if (_isStatusMessage(message)) {
      return theme.colorScheme.tertiary;
    }
    return message.direction == VowifiSmsDirection.outbound
        ? theme.colorScheme.primary
        : AppTheme.onSurfaceSubtle(context);
  }

  String _messageTitle(VowifiSmsMessage message, VowifiSessionInfo session) {
    if (_isStatusMessage(message)) {
      return 'Delivery Update';
    }
    if (message.direction == VowifiSmsDirection.outbound) {
      return 'To ${_messagePeerLabel(message, session)}';
    }
    return _messagePeerLabel(message, session);
  }

  bool _isBinaryMessage(VowifiSmsMessage message) {
    return message.text.trim().startsWith('hex:');
  }

  String _messagePeerLabel(
    VowifiSmsMessage message,
    VowifiSessionInfo session,
  ) {
    final peer = message.peer.trim();
    if (peer.isEmpty) {
      return _associatedLabel(session);
    }
    final lower = peer.toLowerCase();
    if (lower.startsWith('sip:')) {
      final body = peer.substring(4);
      final at = body.indexOf('@');
      return _formatE164Display(at > 0 ? body.substring(0, at) : body);
    }
    if (lower.startsWith('tel:')) {
      return _formatE164Display(peer.substring(4));
    }
    return _formatE164Display(peer);
  }

  String _formatTimestamp(DateTime time) {
    final local = time.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $hh:$mm';
  }

  String _formatE164Display(String value) {
    final normalized = _normalizeE164(value);
    return normalized ?? value.trim();
  }

  void _populateRecipientFromMessage(
    VowifiSmsMessage message,
    VowifiSessionInfo session,
  ) {
    final peer = _messagePeerLabel(message, session);
    final normalized = _normalizeE164(peer);
    if (normalized == null) {
      return;
    }
    _toController.value = TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
  }

  void _formatRecipientController() {
    if (_formattingRecipient) {
      return;
    }
    final current = _toController.text;
    final formatted = _formatRecipientInput(current);
    if (formatted == current) {
      return;
    }
    _formattingRecipient = true;
    _toController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _formattingRecipient = false;
  }

  String _formatRecipientInput(String value) {
    var working = value.trim();
    if (working.isEmpty) {
      return '';
    }
    final hasPlus = working.startsWith('+');
    working = working.replaceAll(RegExp(r'[^0-9+]'), '');
    if (hasPlus) {
      working = '+${working.replaceAll('+', '')}';
    } else {
      working = working.replaceAll('+', '');
    }
    return working;
  }

  String? _normalizeE164(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    var working = trimmed;
    if (working.toLowerCase().startsWith('sip:')) {
      working = working.substring(4);
      final at = working.indexOf('@');
      if (at > 0) {
        working = working.substring(0, at);
      }
    } else if (working.toLowerCase().startsWith('tel:')) {
      working = working.substring(4);
    }
    working = working.replaceAll(RegExp(r'[\s()-]'), '');
    if (!working.startsWith('+')) {
      return null;
    }
    final digits = working.substring(1);
    if (!RegExp(r'^[0-9]{8,15}$').hasMatch(digits)) {
      return null;
    }
    return '+$digits';
  }
}
