import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../settings/app_settings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/styled_header_scaffold.dart';
import '../../l10n/app_localizations.dart';

class AidSettingsPage extends StatefulWidget {
  const AidSettingsPage({super.key});

  @override
  State<AidSettingsPage> createState() => _AidSettingsPageState();
}

class _AidSettingsPageState extends State<AidSettingsPage> {
  final _addController = TextEditingController();

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  Future<void> _addAid() async {
    final text = _addController.text.trim();
    if (text.isEmpty) return;

    // Basic validation
    final clean = text.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    if (clean.isEmpty || clean.length % 2 != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.invalidHexString)),
      );
      return;
    }

    final settings = AppSettings();
    final newAids = List<String>.from(settings.aids);

    // Check dupe
    if (newAids.contains(clean.toUpperCase())) {
      // Normalize case
      // Already exists
    } else {
      newAids.add(clean.toUpperCase());
      await settings.setAids(newAids);
    }

    _addController.clear();
    setState(() {}); // refresh UI
  }

  Future<void> _removeAid(int index) async {
    final settings = AppSettings();
    final newAids = List<String>.from(settings.aids);
    newAids.removeAt(index);
    await settings.setAids(newAids);
    setState(() {});
  }

  Future<void> _resetDefaults() async {
    final settings = AppSettings();
    final defaults = [
      "A06573746B6D65FFFF4953442D522031",
      "A06573746B6D65FFFF4953442D522030",
      "A0000005591010FFFFFFFF8900000100",
      "A0000005591010FFFFFFFF8900050500",
      "A0000005591010000000008900000300",
      "A0000005591010FFFFFFFF8900000177",
    ];
    await settings.setAids(defaults);
    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.resetToDefaultsSuccess),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings();
    final aids = settings.aids;
    final theme = Theme.of(context);

    return StyledHeaderScaffold(
      title: AppLocalizations.of(context)!.isdrAids,
      subtitle: AppLocalizations.of(context)!.configureDefaultAids,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.addAidHexHint,
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      isDense: true,
                    ),
                    style: AppTheme.mono(const TextStyle()),
                    onSubmitted: (_) => _addAid(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addAid,
                  icon: const Icon(Icons.add_circle, size: 28),
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: aids.length,
              separatorBuilder: (c, i) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final aid = aids[index];
                return Dismissible(
                  key: ValueKey(aid),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _removeAid(index),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.surfaceSubtle(context),
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        aid,
                        style: AppTheme.mono(const TextStyle(fontSize: 12)),
                      ),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: aid));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)!.aidCopied,
                            ),
                            duration: const Duration(milliseconds: 800),
                          ),
                        );
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _removeAid(index),
                        color: AppTheme.onSurfaceSubtle(context),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextButton.icon(
              onPressed: _resetDefaults,
              icon: const Icon(Icons.restore),
              label: Text(AppLocalizations.of(context)!.resetToDefaults),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
