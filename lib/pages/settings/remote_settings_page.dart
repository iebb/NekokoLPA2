import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../settings/app_settings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/styled_header_scaffold.dart';
import '../../l10n/app_localizations.dart';
import '../../adapter/composite_adapter.dart';
import '../../adapter/remote/remocard_adapter.dart';
import '../../widgets/common/loading_spinner.dart';

class RemoteSettingsPage extends StatefulWidget {
  const RemoteSettingsPage({super.key});

  @override
  State<RemoteSettingsPage> createState() => _RemoteSettingsPageState();
}

class _RemoteSettingsPageState extends State<RemoteSettingsPage> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: "33777");
  final _passwordController = TextEditingController();
  final _globalPasswordController = TextEditingController();
  bool _useHttps = false;
  bool _isConnecting = false;
  final Set<String> _connectingServers = {};
  String? _connectionError;

  @override
  void initState() {
    super.initState();
    _globalPasswordController.text = AppSettings().remoCardPassword ?? '';
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _passwordController.dispose();
    _globalPasswordController.dispose();
    super.dispose();
  }

  Future<void> _connectAndAdd() async {
    final host = _hostController.text.trim();
    final port = _portController.text.trim();
    if (host.isEmpty || port.isEmpty) return;

    setState(() {
      _isConnecting = true;
      _connectionError = null;
    });

    try {
      // Construct URL
      String scheme = _useHttps ? "https" : "http";
      String cleanHost = host;

      // Handle if user pasted full URL
      if (host.startsWith("http://")) {
        cleanHost = host.substring(7);
        scheme = "http";
      } else if (host.startsWith("https://")) {
        cleanHost = host.substring(8);
        scheme = "https";
      }

      if (cleanHost.contains(":")) {
        cleanHost = cleanHost.split(":")[0];
      }

      var uri = Uri(scheme: scheme, host: cleanHost, port: int.tryParse(port));
      if (_passwordController.text.isNotEmpty) {
        uri = uri.replace(userInfo: ":${_passwordController.text}");
      }

      var finalUrl = uri.toString();
      if (finalUrl.endsWith("/")) {
        finalUrl = finalUrl.substring(0, finalUrl.length - 1);
      }

      // Verify the server and cache its readers for the main reader list. The
      // server remains temporary until the user explicitly taps the star.
      await CompositeAdapter().loadRemoteReadersFromUrl(finalUrl);

      _hostController.clear();
      _passwordController.clear();
      // Keep port 33777 as it's common default

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.serverAddedSuccessfully,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionError =
              "${AppLocalizations.of(context)!.connectionFailed}: ${e.toString().split('\n').first}";
          if (e.toString().contains("Invalid session") ||
              e.toString().contains("401")) {
            _connectionError = AppLocalizations.of(
              context,
            )!.authFailedCheckPassword;
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  Future<void> _connectFavorite(String url) async {
    if (_connectingServers.contains(url)) return;
    setState(() => _connectingServers.add(url));

    try {
      final readers = await CompositeAdapter().loadRemoteReadersFromUrl(url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            readers.isEmpty
                ? AppLocalizations.of(context)!.noRemoteReadersFound
                : AppLocalizations.of(
                    context,
                  )!.connectedRemoteReaders(readers.length),
          ),
          backgroundColor: readers.isEmpty ? null : Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is RemoCardInvalidPasswordException
          ? AppLocalizations.of(context)!.authFailedCheckPassword
          : AppLocalizations.of(
              context,
            )!.failedToConnectRemoteReaders(error.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _connectingServers.remove(url));
      }
    }
  }

  Future<void> _toggleFavorite(String url) async {
    final settings = AppSettings();
    if (settings.remoCardUrls.contains(url)) {
      await settings.removeRemoCardUrl(url);
    } else {
      await settings.addRemoCardUrl(url);
    }
  }

  Future<void> _deleteServer(String url) async {
    await CompositeAdapter().forgetRemoteServer(url);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = AppSettings();

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final urls = CompositeAdapter().remoteServerUrls;

        return StyledHeaderScaffold(
          title: AppLocalizations.of(context)!.remoteReaders,
          subtitle: AppLocalizations.of(context)!.remoteReadersSubtitle,
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Add New URL Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.surfaceSubtle(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.addNewServer,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Auto-load Toggle
                    SwitchListTile(
                      title: Text(
                        AppLocalizations.of(context)!.autoLoadRemotes,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        AppLocalizations.of(context)!.autoLoadRemotesSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.onSurfaceSubtle(context),
                        ),
                      ),
                      value: settings.autoLoadRemoteDevices,
                      onChanged: (val) =>
                          settings.setAutoLoadRemoteDevices(val),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HTTPS Toggle (Compact)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: InkWell(
                            onTap: () => setState(() => _useHttps = !_useHttps),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _useHttps
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : theme.colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: _useHttps
                                    ? Border.all(
                                        color: Colors.green.withValues(
                                          alpha: 0.5,
                                        ),
                                      )
                                    : null,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    _useHttps
                                        ? Icons.lock_rounded
                                        : Icons.lock_open_rounded,
                                    size: 18,
                                    color: _useHttps
                                        ? Colors.green
                                        : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "HTTPS",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _useHttps
                                          ? Colors.green
                                          : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: _hostController,
                                      enabled: !_isConnecting,
                                      decoration: InputDecoration(
                                        labelText: AppLocalizations.of(
                                          context,
                                        )!.hostIpLabel,
                                        hintText: '192.168.1.10',
                                        filled: true,
                                        fillColor: theme
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.3),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 14,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 1,
                                    child: TextField(
                                      controller: _portController,
                                      enabled: !_isConnecting,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: AppLocalizations.of(
                                          context,
                                        )!.portLabel,
                                        filled: true,
                                        fillColor: theme
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.3),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 14,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _passwordController,
                                      enabled: !_isConnecting,
                                      obscureText: true,
                                      decoration: InputDecoration(
                                        labelText: AppLocalizations.of(
                                          context,
                                        )!.passwordOptionalLabel,
                                        filled: true,
                                        fillColor: theme
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.3),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.password_rounded,
                                          size: 18,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 14,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (_isConnecting)
                                    SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: Center(child: LoadingSpinner()),
                                    )
                                  else
                                    IconButton.filled(
                                      onPressed: _connectAndAdd,
                                      icon: const Icon(Icons.add),
                                      style: IconButton.styleFrom(
                                        padding: const EdgeInsets.all(12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
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

                    if (_connectionError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 20,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _connectionError!,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Default Configuration Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.surfaceSubtle(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Default Password",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Used when no password is specified in the URL.",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurfaceSubtle(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _globalPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              )!.passwordOptionalLabel,
                              filled: true,
                              fillColor: theme
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(
                                Icons.vpn_key_rounded,
                                size: 18,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filledTonal(
                          onPressed: () {
                            final val = _globalPasswordController.text.isEmpty
                                ? null
                                : _globalPasswordController.text;
                            AppSettings().setRemoCardPassword(val);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Default password saved"),
                                backgroundColor: Colors.green,
                              ),
                            );
                            FocusScope.of(context).unfocus();
                          },
                          icon: const Icon(Icons.save_rounded),
                          tooltip: "Save",
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (urls.isNotEmpty) ...[
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.configuredServers,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurfaceSubtle(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...urls.map((url) => _buildUrlCard(context, url)),
                const SizedBox(height: 24),
              ],

              // Download RemoCard Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                      theme.colorScheme.secondary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.android_rounded,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.downloadRemoCard,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.remoCardAndroidApp,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.onSurfaceSubtle(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => launchUrl(
                          Uri.parse(
                            'https://github.com/iebb/remocard/releases',
                          ),
                        ),
                        icon: const Icon(Icons.download_rounded),
                        label: Text(
                          AppLocalizations.of(context)!.getRemoCardGitHub,
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.surfaceSubtle(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.instructions,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${AppLocalizations.of(context)!.instruction1}\n'
                      '${AppLocalizations.of(context)!.instruction2}\n'
                      '${AppLocalizations.of(context)!.instruction3}\n'
                      '${AppLocalizations.of(context)!.instruction4}',
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUrlCard(BuildContext context, String url) {
    final theme = Theme.of(context);
    final isConnecting = _connectingServers.contains(url);
    final isFavorite = AppSettings().remoCardUrls.contains(url);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceSubtle(context)),
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: isConnecting ? null : () => _connectFavorite(url),
            tooltip: AppLocalizations.of(context)!.connect,
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              foregroundColor: Colors.blue,
              disabledBackgroundColor: Colors.blue.withValues(alpha: 0.06),
            ),
            icon: isConnecting
                ? const LoadingSpinner(
                    size: 20,
                    strokeWidth: 2.5,
                    color: Colors.blue,
                  )
                : const Icon(Icons.cloud_outlined, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  url,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  url.startsWith('https')
                      ? AppLocalizations.of(context)!.secureHttps
                      : AppLocalizations.of(context)!.insecureHttp,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.onSurfaceVerySubtle(context),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.copy_rounded,
              color: AppTheme.onSurfaceSubtle(context),
              size: 18,
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.urlCopied),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            tooltip: isFavorite
                ? AppLocalizations.of(context)!.removeFromFavorites
                : AppLocalizations.of(context)!.addToFavorites,
            icon: Icon(
              isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: isFavorite
                  ? Colors.amber
                  : AppTheme.onSurfaceSubtle(context),
              size: 21,
            ),
            onPressed: isConnecting ? null : () => _toggleFavorite(url),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: isConnecting ? null : () => _deleteServer(url),
          ),
        ],
      ),
    );
  }
}
