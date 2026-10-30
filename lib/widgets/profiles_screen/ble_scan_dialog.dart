import 'package:flutter/material.dart';
import '../../adapter/ble/ble_accessory_setup.dart';
import '../../adapter/ble/ble_manager.dart';
import '../../l10n/app_localizations.dart';
import '../common/simple_dialog_container.dart';
import '../common/loading_spinner.dart';
import '../../theme/app_theme.dart';
import 'reader_helper.dart';

/// Uses the system picker where available. Cancelling it never starts a scan.
Future<String?> showBluetoothReaderPicker(BuildContext context) async {
  final setup = BleAccessorySetup.instance;
  try {
    final supported = await setup.isSupported;
    if (!context.mounted) return null;
    if (!supported) {
      return await showDialog<String>(
        context: context,
        builder: (_) => const BleScanDialog(),
      );
    }
    final authorized = await setup.authorizedReaders();
    if (!context.mounted) return null;
    BleReaderInfo? reader;
    if (authorized.isEmpty) {
      reader = await setup.pickReader();
    } else {
      final l10n = AppLocalizations.of(context)!;
      final choice = await showDialog<Object>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: Text(l10n.scanBluetooth),
          children: [
            for (final accessory in authorized)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, accessory),
                child: ListTile(
                  leading: Icon(
                    ReaderHelper.getBleAdapterIconData(accessory.type),
                  ),
                  title: Text(accessory.name),
                  subtitle: Text(accessory.type.label),
                ),
              ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, 'add'),
              child: ListTile(
                leading: const Icon(Icons.add),
                title: Text(l10n.addBluetoothReader),
              ),
            ),
          ],
        ),
      );
      if (choice is BleReaderInfo) reader = choice;
      if (choice == 'add' && context.mounted) reader = await setup.pickReader();
    }
    if (reader == null || !context.mounted) return null;
    return BleManager().addReaderInfo(reader);
  } catch (error, stack) {
    debugPrint('Bluetooth accessory setup failed: $error\n$stack');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.bluetoothSetupFailed),
        ),
      );
    }
    return null;
  }
}

class BleScanDialog extends StatefulWidget {
  const BleScanDialog({super.key});

  @override
  State<BleScanDialog> createState() => _BleScanDialogState();
}

class _BleScanDialogState extends State<BleScanDialog> {
  @override
  void initState() {
    super.initState();
    BleManager().startScan();
  }

  @override
  void dispose() {
    BleManager().stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: BleManager(),
      builder: (context, _) {
        final results = BleManager().scanResults;
        final isScanning = BleManager().isScanning;

        return SimpleDialogContainer(
          title: "Bluetooth Scan",
          headerAction: isScanning
              ? Container(
                  width: 20,
                  height: 20,
                  padding: const EdgeInsets.all(2),
                  child: LoadingSpinner(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                )
              : IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: AppTheme.onSurfaceSubtle(context),
                  ),
                  onPressed: () => BleManager().startScan(),
                  tooltip: "Scan again",
                  iconSize: 20,
                ),
          secondaryActionLabel: "Cancel",
          child: SizedBox(
            height: 320,
            child: Column(
              children: [
                if (isScanning)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                  ),
                Expanded(
                  child: results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isScanning)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: Column(
                                    children: [
                                      LoadingSpinner(
                                        color: theme.colorScheme.primary,
                                        strokeWidth: 3,
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        "Searching for devices...",
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Column(
                                  children: [
                                    Icon(
                                      Icons.bluetooth_searching,
                                      size: 48,
                                      color: AppTheme.onSurfaceVerySubtle(
                                        context,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "No devices found",
                                      style: TextStyle(
                                        color: AppTheme.onSurfaceVerySubtle(
                                          context,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: results.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final result = results[index];
                            final info = BleReaderInfo.fromScanResult(result);

                            return Material(
                              color: AppTheme.surfaceSubtle(context),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: theme.dividerColor),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: theme.dividerColor,
                                    ),
                                  ),
                                  child: Center(
                                    child: Tooltip(
                                      message: info.type.label,
                                      child: Icon(
                                        ReaderHelper.getBleAdapterIconData(
                                          info.type,
                                        ),
                                        color: theme.colorScheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  info.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  result.device.remoteId.toString(),
                                  style: AppTheme.mono(
                                    TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.onSurfaceSubtle(context),
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  final readerName = BleManager().addReader(
                                    result,
                                  );
                                  Navigator.pop(context, readerName);
                                },
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
}
