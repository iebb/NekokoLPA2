import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/profile_metadata_service.dart';
import '../utils/profile_tag_utils.dart';
import '../theme/app_theme.dart';
import '../widgets/styled_header_scaffold.dart';
import '../utils/iccid_formatter.dart';
import '../l10n/app_localizations.dart';

class TagManagerPage extends StatefulWidget {
  const TagManagerPage({super.key});

  @override
  State<TagManagerPage> createState() => _TagManagerPageState();
}

class _TagManagerPageState extends State<TagManagerPage> {
  bool _isLoading = true;
  Map<String, List<ProfileMetadata>> _tagsToProfiles = {};
  List<String> _sortedTags = [];
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final service = await ProfileMetadataService.getInstance();
      final profiles = await service.getAllProfiles();

      final Map<String, List<ProfileMetadata>> map = {};
      for (final profile in profiles) {
        for (final tagStr in profile.tags) {
          try {
            // Re-parse to ensure consistency? Or trust DB string?
            // The DB stores them as raw strings (e.g. "t:Work" or "d:251231:Note").
            // We should group by the raw string itself as it represents identity.
            if (!map.containsKey(tagStr)) {
              map[tagStr] = [];
            }
            map[tagStr]!.add(profile);
          } catch (e) {
            // Ignore parse errors
          }
        }
      }

      final sortedTags = map.keys.toList()..sort();

      setState(() {
        _tagsToProfiles = map;
        _sortedTags = sortedTags;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to load tags: $e")));
      }
      setState(() => _isLoading = false);
    }
  }

  List<String> get _filteredTags {
    if (_searchQuery.isEmpty) return _sortedTags;
    final query = _searchQuery.toLowerCase();
    return _sortedTags.where((tagStr) {
      if (tagStr.toLowerCase().contains(query)) return true;
      final profiles = _tagsToProfiles[tagStr] ?? [];
      return profiles.any(
        (p) =>
            (p.displayName.toLowerCase().contains(query)) ||
            (p.iccid.toLowerCase().contains(query)),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredTags;

    return StyledHeaderScaffold(
      title: AppLocalizations.of(context)!.tagManager,
      subtitle: AppLocalizations.of(
        context,
      )!.activeTagsCount(_sortedTags.length),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(
                        context,
                      )!.searchTagsOrProfiles,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = "");
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppTheme.surfaceSubtle(context),
                        ),
                      ),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final tagStr = filtered[index];
                            final profiles = _tagsToProfiles[tagStr] ?? [];
                            final tag = ProfileTag.parse(tagStr);

                            return _buildTagExpansionTile(tag, profiles);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.label_off_outlined,
            size: 64,
            color: AppTheme.onSurfaceVerySubtle(context),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noTagsFound,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceSubtle(context),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              AppLocalizations.of(context)!.addTagsFromProfileMenu,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.onSurfaceVerySubtle(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagExpansionTile(
    ProfileTag tag,
    List<ProfileMetadata> profiles,
  ) {
    final theme = Theme.of(context);
    final isDate = tag is DateTag;
    final color = isDate
        ? (tag).countdown.isNegative
              ? Colors.red
              : theme.colorScheme.secondary
        : theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceSubtle(context)),
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isDate ? Icons.calendar_today : Icons.label_outline,
            size: 18,
            color: color,
          ),
        ),
        title: Text(
          isDate ? (tag).displayDate : (tag as TextTag).text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          AppLocalizations.of(context)!.profileCount(profiles.length),
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.onSurfaceSubtle(context),
          ),
        ),
        trailing: isDate
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatCountdown(context, (tag).countdown),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              )
            : null,
        children: [
          const Divider(height: 1),
          ...profiles.map(
            (p) => ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: p.flagUrl,
                  width: 24,
                  height: 16,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const Icon(Icons.flag, size: 16),
                ),
              ),
              title: Text(
                ProfileTagUtils.parse(
                  p.nickname,
                  regionCode: p.flag,
                ).displayName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${AppLocalizations.of(context)!.iccid}: ${IccidFormatter.forDisplay(p.iccid)}",
                    style: AppTheme.mono(
                      TextStyle(
                        fontSize: 11,
                        color: AppTheme.onSurfaceSubtle(context),
                      ),
                    ),
                  ),
                  if (p.eid != null)
                    Text(
                      "EID: ${p.eid}",
                      style: AppTheme.mono(
                        TextStyle(
                          fontSize: 10,
                          color: AppTheme.onSurfaceVerySubtle(context),
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () {
                // Future: Navigate and select this profile
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatCountdown(BuildContext context, Duration d) {
    final l10n = AppLocalizations.of(context)!;
    if (d.isNegative) return l10n.expired;
    if (d.inDays > 0) return l10n.daysLeft(d.inDays);
    if (d.inHours > 0) return l10n.hoursLeft(d.inHours);
    return l10n.expiresSoon;
  }
}
