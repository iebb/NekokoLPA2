import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../logic/profile_manager.dart';
import '../adapter/euicc_adapter.dart';
import '../models/activation_code.dart';
import '../models/asn1/rsp_definitions.g.dart';
import '../services/es9plus_service.dart';
import '../utils/hex_utils.dart';
import '../utils/crypto_utils.dart';
import '../utils/iccid_formatter.dart';
import '../utils/size_formatter.dart';
import '../widgets/styled_header_scaffold.dart';
import '../theme/app_theme.dart';
import '../logic/profile_download_session.dart';
import '../widgets/lpa_text_editing_controller.dart';
import 'package:logging/logging.dart';
import '../services/notification_service.dart';
import '../settings/app_settings.dart';
import '../services/database_service.dart';
import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';
import '../services/profile_size_prediction_service.dart';
import '../plugins/plugin_base.dart';
import '../plugins/plugin_manager.dart';

class BatchDownloadItem {
  final String lpa;
  String status = 'Pending';
  String? iccid;
  int? size;
  bool isSuccess = false;
  bool isError = false;
  String? message;

  BatchDownloadItem({required this.lpa});
}

class _AuthResult {
  final ProfileDownloadSession session;
  final int? initialFreeMemory;
  final AuthenticateResponseOk? authBefore;
  final Uint8List? euiccInfo1; // Needed for re-auth
  _AuthResult(
    this.session,
    this.initialFreeMemory,
    this.authBefore,
    this.euiccInfo1,
  );
}

class _InstallResult {
  final int? freeMemory;
  final AuthenticateResponseOk? authAfter;
  final int bppSize;
  _InstallResult(this.freeMemory, this.authAfter, this.bppSize);
}

class BatchDownloadPage extends StatefulWidget {
  final ProfileManager profileManager;
  final Adapter adapter;
  final Reader reader;

  const BatchDownloadPage({
    super.key,
    required this.profileManager,
    required this.adapter,
    required this.reader,
  });

  @override
  State<BatchDownloadPage> createState() => _BatchDownloadPageState();
}

class _BatchDownloadPageState extends State<BatchDownloadPage> {
  static final Logger _log = Logger('BatchDownloadPage');
  final LpaTextEditingController _inputController = LpaTextEditingController();
  List<BatchDownloadItem> _items = [];
  bool _isProcessing = false;
  bool _isFinished = false;
  int _currentIndex = -1;
  bool _stopRequested = false;
  int? _remainingSpace;
  int _totalPredictedSize = 0;
  String? _eid;

  @override
  void initState() {
    super.initState();
    _updateRemainingSpace();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _updateRemainingSpace() async {
    try {
      await widget.adapter.connect(widget.reader);
      final channel = await widget.profileManager.openSession();
      try {
        final info2 = await widget.profileManager.getEuiccInfo2(
          useChannel: channel,
        );
        final eid = await widget.profileManager.getEid(useChannel: channel);
        if (mounted) {
          setState(() {
            _remainingSpace = info2.extCardResource?.freeNonVolatileMemory;
            _eid = eid;
          });
          _parseInput(); // Re-parse to update predictions with EID
        }
      } finally {
        await channel.close();
      }
    } catch (e) {
      _log.warning("Failed to update remaining space: $e");
    }
  }

  Future<void> _parseInput() async {
    final text = _inputController.text;
    final lines = text.split('\n');
    final List<BatchDownloadItem> newItems = [];
    final lpaRegex = RegExp(r'LPA:1\$[^\$]+\$[^\$]+');

    int totalPredicted = 0;
    await ProfileSizePredictionService().ensureLoaded();

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      if (lpaRegex.hasMatch(line)) {
        final item = BatchDownloadItem(lpa: line);
        final ac = ActivationCode.parse(line);
        if (ac != null) {
          final predicted = ProfileSizePredictionService().predictSize(
            eid: _eid,
            smdpAddress: ac.smdpAddress,
          );
          if (predicted != null) {
            item.size = predicted;
            totalPredicted += predicted;
          }
        }
        newItems.add(item);
      }
      if (newItems.length >= 20) break;
    }

    if (mounted) {
      setState(() {
        _items = newItems;
        _totalPredictedSize = totalPredicted;
        _isFinished = false;
      });
    }
  }

  Future<void> _startBatch() async {
    // Awaited: the parse replaces _items after an async gap, and the batch
    // must run over that list, not the one it replaces.
    await _parseInput();
    if (!mounted || _items.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _isFinished = false;
      _currentIndex = 0;
      _stopRequested = false;
    });

    for (int i = 0; i < _items.length; i++) {
      if (_stopRequested) break;

      setState(() {
        _currentIndex = i;
        _items[i].status = 'Running';
      });

      try {
        await _downloadSingle(i);
        setState(() {
          _items[i].status = 'Success';
          _items[i].message = null; // Clear any transient status
          _items[i].isSuccess = true;
        });
        await _updateRemainingSpace();
      } catch (e) {
        _log.severe("Batch item $i failed: $e");
        setState(() {
          _items[i].status = 'Error';
          _items[i].isError = true;
          _items[i].message = e.toString();
        });

        // Reporting failure happens inside _downloadSingle or via specialized handler soon

        // Check for insufficient space error
        final errMsg = e.toString().toLowerCase();
        if (errMsg.contains('mem') ||
            errMsg.contains('space') ||
            errMsg.contains('6a84') ||
            errMsg.contains('6985')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.insufficientSpaceStoppingBatch,
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          break;
        }
      }
    }

    if (mounted) {
      // Items that are NOT success are put back into the input field
      final uncompleted = _items
          .where((item) => !item.isSuccess)
          .map((e) => e.lpa)
          .toList();

      if (uncompleted.isNotEmpty) {
        _inputController.text = uncompleted.join('\n');
      } else {
        _inputController.clear();
      }

      setState(() {
        _isProcessing = false;
        _isFinished = true;
        _currentIndex = -1;
      });
    }
  }

  Future<void> _downloadSingle(int index) async {
    final item = _items[index];
    final l10n = AppLocalizations.of(context)!;
    final ac = ActivationCode.parse(item.lpa);
    if (ac == null) throw Exception("Invalid LPA format");

    _AuthResult? authResult;
    int? finalFree;
    AuthenticateResponseOk? authAfter;

    try {
      // Step 1: Authentication & Metadata
      authResult = await _authenticate(ac, index);
      final session = authResult.session;
      final initialFreeMemory = authResult.initialFreeMemory;

      final metadata = session.getProfileMetadata();
      if (metadata == null) throw Exception("Failed to retrieve metadata");

      final String? rawIccid = metadata.iccid != null
          ? IccidFormatter.forDisplay(
              HexUtils.swapNibbles(HexUtils.bytesToHex(metadata.iccid!)),
            )
          : null;
      item.iccid = rawIccid;

      // Step 2: Confirmation Code Handling
      final signed2 = session.getSmdpSigned2();
      if (signed2?.ccRequiredFlag == true) {
        setState(() => item.status = l10n.confirmationCodeRequired);
        final code = await _promptConfirmationCode(index, ac.smdpAddress);
        if (code == null) throw Exception("Confirmation code required");
        session.setConfirmationCode(code);
      } else if (ac.confirmationCode != null && ac.confirmationCode != '1') {
        session.setConfirmationCode(ac.confirmationCode!);
      }

      // Step 3: Download & Install
      final installResult = await _install(
        session,
        ac,
        index,
        authResult.euiccInfo1,
      );
      finalFree = installResult.freeMemory;
      authAfter = installResult.authAfter;
      final bppSize = installResult.bppSize;

      // Step 4: Calculate Consumed Storage (for UI)
      if (initialFreeMemory != null && finalFree != null) {
        final consumed = initialFreeMemory - finalFree;
        if (consumed > 0) {
          setState(() => item.size = consumed);

          // Save to Database for recognition in profile list
          try {
            final channel = await widget.profileManager.openSession();
            try {
              final eid = await widget.profileManager.getEid(
                useChannel: channel,
              );
              if (rawIccid != null) {
                await DatabaseService().saveProfileSize(
                  eid,
                  rawIccid,
                  consumed,
                  info2Before: authResult.authBefore != null
                      ? base64Encode(authResult.authBefore!.encode())
                      : null,
                  info2After: authAfter != null
                      ? base64Encode(authAfter.encode())
                      : null,
                  bppLength: bppSize,
                );
              }
            } finally {
              await channel.close();
            }
          } catch (e) {
            _log.warning("Failed to save profile size to DB: $e");
          }
        }
      }

      if (authResult.authBefore != null) {
        await _notifyInstallationReported(
          session: session,
          authBefore: authResult.authBefore,
          authAfter: authAfter,
          bppSize: bppSize,
        );
      }
    } catch (e) {
      if (authResult?.authBefore != null) {
        _notifyInstallationReported(
          session: authResult?.session,
          authBefore: authResult?.authBefore,
          installResult: e.toString(),
          bppSize: null,
        );
      }
      rethrow;
    }
  }

  Future<_AuthResult> _authenticate(ActivationCode ac, int index) async {
    final item = _items[index];
    final l10n = AppLocalizations.of(context)!;

    setState(() => item.status = l10n.connectingToEuicc);
    await widget.adapter.connect(widget.reader);
    final channel = await widget.profileManager.openSession();
    try {
      setState(() => item.status = l10n.gettingChallenge);
      final challengeBytes = await widget.profileManager.getEuiccChallenge(
        useChannel: channel,
      );
      final info1Bytes = await widget.profileManager.getEuiccInfo1(
        useChannel: channel,
      );

      // Try to get initial free memory for size calculation
      int? initialFree;
      AuthenticateResponseOk? authBefore;
      try {
        final info2 = await widget.profileManager.getEuiccInfo2(
          useChannel: channel,
        );
        initialFree = info2.extCardResource?.freeNonVolatileMemory;
      } catch (_) {}

      final session = ProfileDownloadSession(
        smdpAddress: ac.smdpAddress,
        matchingId: ac.matchingId,
      );
      session.processEuiccInfo1(info1Bytes);
      session.processEuiccChallenge(challengeBytes);

      setState(() => item.status = l10n.authenticatingWithSmdp);
      final initAuthReq = session.getInitiateAuthenticationRequest();
      final initAuthResp = await Es9PlusService().initiateAuthentication(
        smdpAddress: ac.smdpAddress,
        euiccChallenge: base64Encode(initAuthReq.euiccChallenge!),
        euiccInfo1: base64Encode(initAuthReq.euiccInfo1!.encode()),
        clientTransactionId: "batch_$index",
      );

      final serverSigned1 = base64Decode(initAuthResp['serverSigned1']);
      final serverSignature1 = base64Decode(initAuthResp['serverSignature1']);
      final euiccCiPKId = base64Decode(initAuthResp['euiccCiPKIdToBeUsed']);
      final serverCert = base64Decode(initAuthResp['serverCertificate']);
      final txnId = initAuthResp['transactionId'] as String;

      session.processInitiateAuthenticationResponse(
        'Executed-Success',
        txnId,
        serverCert,
      );

      setState(() => item.status = l10n.verifyingSignatures);
      final authServerResp = await widget.profileManager.authenticateServer(
        serverSigned1: serverSigned1,
        serverSignature1: serverSignature1,
        euiccCiPKIdToBeUsed: euiccCiPKId,
        serverCertificate: serverCert,
        matchingId: ac.matchingId,
        useChannel: channel,
      );
      authBefore = authServerResp;
      session.processAuthenticateServerResponse(authServerResp);

      setState(() => item.status = l10n.retrievingMetadata);
      final authClientReq = session.getAuthenticateClientRequest();
      final clientResp = await Es9PlusService().authenticateClient(
        smdpAddress: ac.smdpAddress,
        transactionId: txnId,
        authenticateServerResponse: base64Encode(
          authClientReq.authenticateServerResponse!.encode(),
        ),
      );

      if (clientResp['profileMetadata'] != null) {
        final metadataBytes = base64Decode(clientResp['profileMetadata']);
        final metadata = StoreMetadataRequest.decode(metadataBytes);

        final authClientResponse = AuthenticateClientResponseEs9(
          authenticateClientOk: AuthenticateClientOk(
            transactionId: session.getTransactionId(),
            profileMetadata: metadata,
            smdpSigned2: clientResp['smdpSigned2'] != null
                ? SmdpSigned2.decode(base64Decode(clientResp['smdpSigned2']))
                : null,
            smdpSignature2: clientResp['smdpSignature2'] != null
                ? base64Decode(clientResp['smdpSignature2'])
                : null,
            smdpCertificate: clientResp['smdpCertificate'] != null
                ? Certificate.decode(
                    base64Decode(clientResp['smdpCertificate']),
                  )
                : null,
          ),
        );

        session.processAuthenticateClientResponse(
          'Executed-Success',
          authClientResponse,
        );
        return _AuthResult(session, initialFree, authBefore, info1Bytes);
      } else {
        throw Exception("No profile metadata returned.");
      }
    } finally {
      await channel.close();
    }
  }

  Future<_InstallResult> _install(
    ProfileDownloadSession session,
    ActivationCode ac,
    int index,
    Uint8List? euiccInfo1,
  ) async {
    final item = _items[index];
    final l10n = AppLocalizations.of(context)!;
    final channel = await widget.profileManager.openSession();
    try {
      final smdpSigned2 = session.getSmdpSigned2()!;
      final smdpSignature2 = session.getSmdpSignature2()!;
      final serverCert = session.getServerCertificate()!;
      final txnId = session.getTransactionIdHex()!;

      Uint8List? hashCc;
      if (session.confirmationCode != null) {
        hashCc = CryptoUtils.computeHashCc(
          session.confirmationCode!,
          session.getTransactionId()!,
        );
      }

      setState(() => item.status = l10n.preparingEuicc);
      final settings = AppSettings();
      if (settings.notifProcessBeforeDownload &&
          settings.isAnyNotificationProcessingEnabled) {
        try {
          await NotificationService().processPendingNotifications(
            widget.profileManager,
            channel,
            autoSendInstall: settings.notifAutoSendInstall,
            autoRemoveInstall: settings.notifAutoRemoveInstall,
            autoSendEnable: settings.notifAutoSendEnable,
            autoRemoveEnable: settings.notifAutoRemoveEnable,
            deleteWithoutSendingEnable:
                settings.notifDeleteWithoutSendingEnable,
            autoSendDisable: settings.notifAutoSendDisable,
            autoRemoveDisable: settings.notifAutoRemoveDisable,
            deleteWithoutSendingDisable:
                settings.notifDeleteWithoutSendingDisable,
            autoSendDelete: settings.notifAutoSendDelete,
            autoRemoveDelete: settings.notifAutoRemoveDelete,
          );
        } catch (e) {
          _log.warning("Pre-download notification processing failed: $e");
        }
      }

      final prepareDownloadResp = await widget.profileManager.prepareDownload(
        smdpSigned2: smdpSigned2.encode(),
        smdpSignature2: smdpSignature2,
        smdpCertificate: serverCert,
        hashCc: hashCc,
        useChannel: channel,
      );

      setState(() => item.status = l10n.fetchingProfilePackage);
      final bppResp = await Es9PlusService().getBoundProfilePackage(
        smdpAddress: ac.smdpAddress,
        transactionId: txnId,
        prepareDownloadResponse: base64Encode(prepareDownloadResp.encode()),
      );

      if (bppResp['boundProfilePackage'] == null) {
        throw Exception("No boundProfilePackage returned from SM-DP+");
      }

      final bppBytes = base64Decode(bppResp['boundProfilePackage']);
      setState(() {
        item.status = l10n.installing(0, bppBytes.length);
      });

      await widget.profileManager.loadBoundProfilePackage(
        bppBytes,
        useChannel: channel,
        onProgress: (sent, total) {
          setState(() {
            item.status = l10n.installing(sent, total);
          });
        },
      );

      setState(() => item.status = l10n.finalizing);
      if (settings.notifProcessAfterInstall &&
          settings.isAnyNotificationProcessingEnabled) {
        try {
          await NotificationService().processPendingNotifications(
            widget.profileManager,
            channel,
            autoSendInstall: settings.notifAutoSendInstall,
            autoRemoveInstall: settings.notifAutoRemoveInstall,
            autoSendEnable: settings.notifAutoSendEnable,
            autoRemoveEnable: settings.notifAutoRemoveEnable,
            deleteWithoutSendingEnable:
                settings.notifDeleteWithoutSendingEnable,
            autoSendDisable: settings.notifAutoSendDisable,
            autoRemoveDisable: settings.notifAutoRemoveDisable,
            deleteWithoutSendingDisable:
                settings.notifDeleteWithoutSendingDisable,
            autoSendDelete: settings.notifAutoSendDelete,
            autoRemoveDelete: settings.notifAutoRemoveDelete,
          );
        } catch (_) {}
      }

      // Post-installation: Get updated free space via re-auth (normal behavior)
      int? finalFree;
      AuthenticateResponseOk? authAfter;
      try {
        if (euiccInfo1 != null) {
          final newChallenge = await widget.profileManager.getEuiccChallenge(
            useChannel: channel,
          );
          final tempSession = ProfileDownloadSession(
            smdpAddress: ac.smdpAddress,
            matchingId: ac.matchingId,
          );
          tempSession.processEuiccInfo1(euiccInfo1);
          tempSession.processEuiccChallenge(newChallenge);

          final initAuthReq = tempSession.getInitiateAuthenticationRequest();
          final initAuthResp = await Es9PlusService().initiateAuthentication(
            smdpAddress: ac.smdpAddress,
            euiccChallenge: base64Encode(initAuthReq.euiccChallenge!),
            euiccInfo1: base64Encode(initAuthReq.euiccInfo1!.encode()),
            clientTransactionId: "batch_final_$index",
          );

          if (initAuthResp['serverSigned1'] != null) {
            final serverSigned1 = base64Decode(initAuthResp['serverSigned1']);
            final serverSignature1 = base64Decode(
              initAuthResp['serverSignature1'],
            );
            final euiccCiPKId = base64Decode(
              initAuthResp['euiccCiPKIdToBeUsed'],
            );
            final serverCert = base64Decode(initAuthResp['serverCertificate']);

            authAfter = await widget.profileManager.authenticateServer(
              serverSigned1: serverSigned1,
              serverSignature1: serverSignature1,
              euiccCiPKIdToBeUsed: euiccCiPKId,
              serverCertificate: serverCert,
              matchingId: ac.matchingId,
              useChannel: channel,
            );
            finalFree = authAfter
                .euiccSigned1
                ?.euiccInfo2
                ?.extCardResource
                ?.freeNonVolatileMemory;
          }
        }

        if (finalFree == null) {
          final info2 = await widget.profileManager.getEuiccInfo2(
            useChannel: channel,
          );
          finalFree = info2.extCardResource?.freeNonVolatileMemory;
        }
      } catch (e) {
        _log.warning("Failed to fetch fresh info after install: $e");
      }

      return _InstallResult(finalFree, authAfter, bppBytes.length);
    } finally {
      await channel.close();
    }
  }

  Future<void> _notifyInstallationReported({
    required ProfileDownloadSession? session,
    required AuthenticateResponseOk? authBefore,
    AuthenticateResponseOk? authAfter,
    String? installResult,
    int? bppSize,
    PendingNotification? notification,
  }) async {
    return PluginManager().notifyInstallationReported(
      InstallationReportContext(
        session: session,
        authBefore: authBefore,
        authAfter: authAfter,
        installResult: installResult,
        bppSize: bppSize,
        notification: notification,
      ),
    );
  }

  Future<String?> _promptConfirmationCode(int index, String smdp) async {
    final item = _items[index];
    final TextEditingController ccController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.confirmationCodeRequired),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${AppLocalizations.of(context)!.lpa}: ${item.lpa}",
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                "${AppLocalizations.of(context)!.smdp}: $smdp",
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ccController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.confirmationCode,
                  hintText: AppLocalizations.of(context)!.enterConfirmationCode,
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, ccController.text.trim()),
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        );
      },
    );
  }

  void _exportCsv() async {
    if (_items.isEmpty) return;

    final StringBuffer csv = StringBuffer();
    csv.writeln("#,LPA,Status,ICCID,Size,Message");
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      csv.writeln(
        "${i + 1},\"${item.lpa}\",\"${item.status}${item.message != null ? ': ${item.message}' : ''}\",\"${item.iccid ?? ''}\",${item.size ?? ''}",
      );
    }

    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filename = "batch_download_$timestamp.csv";

      final String? path = await FilePicker.platform.saveFile(
        dialogTitle: AppLocalizations.of(context)!.exportResults,
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (path != null) {
        final io.File file = io.File(path);
        await file.writeAsString(csv.toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.exportedSuccessfully),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${AppLocalizations.of(context)!.exportFailed}: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeItem(int index) {
    if (_isProcessing && index <= _currentIndex) return;
    setState(() {
      _items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return StyledHeaderScaffold(
      title: l10n.batchDownloadTitle,
      actions: [
        if (_items.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: l10n.exportCsv,
            onPressed: _exportCsv,
          ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_remainingSpace != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      "${l10n.remainingSpace}: ${SizeFormatter.format(_remainingSpace!)}",
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                if (_totalPredictedSize > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "${l10n.estimatedDownloadSize}: ${SizeFormatter.format(_totalPredictedSize)}",
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                                fontSize: 13,
                              ),
                            ),
                            if (_remainingSpace != null &&
                                _totalPredictedSize > _remainingSpace!) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: theme.colorScheme.error,
                              ),
                            ],
                          ],
                        ),
                        if (_remainingSpace != null &&
                            _totalPredictedSize > _remainingSpace!)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              l10n.insufficientStorageWarning,
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                TextField(
                  controller: _inputController,
                  maxLines: 5,
                  enabled: !_isProcessing,
                  decoration: InputDecoration(
                    hintText: l10n.batchDownloadHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceSubtle(context),
                  ),
                  onChanged: (_) {
                    if (!_isFinished) {
                      _parseInput();
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.foundLpaCodes(_items.length),
                        style: TextStyle(
                          color: AppTheme.onSurfaceSubtle(context),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (_isProcessing)
                      ElevatedButton.icon(
                        onPressed: _stopRequested
                            ? null
                            : () => setState(() => _stopRequested = true),
                        icon: const Icon(Icons.stop),
                        label: Text(
                          _stopRequested ? l10n.stopping : l10n.stopBatch,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: (_items.isEmpty) ? null : _startBatch,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(l10n.startBatch),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.list_alt_rounded,
                          size: 64,
                          color: AppTheme.onSurfaceVerySubtle(context),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noLpaCodesFound,
                          style: TextStyle(
                            color: AppTheme.onSurfaceSubtle(context),
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(
                      bottom: 32,
                      left: 16,
                      right: 16,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: SingleChildScrollView(
                              child: DataTable(
                                columnSpacing: 24,
                                horizontalMargin: 24,
                                columns: [
                                  DataColumn(
                                    label: Text(
                                      "#",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      l10n.lpa,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      l10n.status,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      l10n.iccid,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      l10n.size,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const DataColumn(
                                    label: Text(""),
                                  ), // For actions
                                ],
                                rows: List.generate(_items.length, (index) {
                                  final item = _items[index];
                                  final isCurrent = index == _currentIndex;
                                  final isPending =
                                      !_isProcessing || index > _currentIndex;

                                  return DataRow(
                                    selected: isCurrent,
                                    cells: [
                                      DataCell(Text("${index + 1}")),
                                      DataCell(
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 200,
                                          ),
                                          child: Text(
                                            item.lpa,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 300,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (item.isSuccess)
                                                const Icon(
                                                  Icons.check_circle,
                                                  color: Colors.green,
                                                  size: 18,
                                                )
                                              else if (item.isError)
                                                const Icon(
                                                  Icons.cancel,
                                                  color: Colors.red,
                                                  size: 18,
                                                )
                                              else if (isCurrent)
                                                const SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              else
                                                const Icon(
                                                  Icons.help_outline,
                                                  color: Colors.grey,
                                                  size: 18,
                                                ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  item.message != null
                                                      ? "${item.status}: ${item.message}"
                                                      : item.status,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(item.iccid ?? '-')),
                                      DataCell(
                                        Text(
                                          item.size != null
                                              ? SizeFormatter.format(item.size!)
                                              : '-',
                                        ),
                                      ),
                                      DataCell(
                                        isPending
                                            ? IconButton(
                                                icon: const Icon(
                                                  Icons.remove_circle_outline,
                                                  color: Colors.red,
                                                  size: 20,
                                                ),
                                                onPressed: () =>
                                                    _removeItem(index),
                                                tooltip: l10n.remove,
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
