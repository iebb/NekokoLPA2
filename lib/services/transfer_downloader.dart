import 'dart:convert';
import 'dart:typed_data';

import 'package:logging/logging.dart';

import '../adapter/euicc_adapter.dart';
import '../logic/profile_download_session.dart';
import '../logic/profile_manager.dart';
import '../models/activation_code.dart';
import '../models/asn1/rsp_definitions.g.dart';
import '../settings/app_settings.dart';
import '../utils/crypto_utils.dart';
import '../utils/hex_utils.dart';
import '../utils/iccid_formatter.dart';
import 'es9plus_service.dart';
import 'notification_service.dart';

/// Result of a TS.43 target-profile download.
class TransferDownloadResult {
  /// ICCID of the installed profile, when known.
  final String? iccid;
  TransferDownloadResult(this.iccid);
}

/// Performs an SGP.22 ES9+/ES10 profile download + install + enable, reusing
/// the same [ProfileManager] / [Es9PlusService] / [ProfileDownloadSession]
/// primitives as the interactive download page. Used by the TS.43 transfer
/// wizard for the `DownloadReady` step (the download is auto-confirmed because
/// the carrier already authorized it via TS.43).
class TransferDownloader {
  static final Logger _log = Logger('TransferDownloader');

  final ProfileManager manager;
  final Adapter adapter;
  final Reader reader;

  TransferDownloader({
    required this.manager,
    required this.adapter,
    required this.reader,
  });

  /// Downloads the profile described by [activationCode] (an `LPA:1$...`
  /// string), installs it, enables it, and processes notifications. Returns the
  /// installed ICCID. [onStatus]/[onProgress] surface progress to the UI.
  Future<TransferDownloadResult> downloadInstallEnable({
    required String activationCode,
    String? confirmationCode,
    void Function(String message)? onStatus,
    void Function(double progress)? onProgress,
  }) async {
    final ac = ActivationCode.parse(activationCode);
    if (ac == null) {
      throw Exception('Invalid TS.43 activation code: $activationCode');
    }
    final effectiveCc =
        (confirmationCode != null && confirmationCode.isNotEmpty)
        ? confirmationCode
        : (ac.confirmationCode != null && ac.confirmationCode != '1'
              ? ac.confirmationCode
              : null);

    await adapter.connect(reader);
    onStatus?.call('Connecting to eUICC');
    final channel = await manager.openSession();
    try {
      // --- Mutual authentication (ES9+ / ES10b) ---
      onStatus?.call('Getting challenge');
      final challengeBytes = await manager.getEuiccChallenge(
        useChannel: channel,
      );
      final info1Bytes = await manager.getEuiccInfo1(useChannel: channel);

      final session = ProfileDownloadSession(
        smdpAddress: ac.smdpAddress,
        matchingId: ac.matchingId,
        confirmationCode: effectiveCc,
      );
      session.processEuiccInfo1(info1Bytes);
      session.processEuiccChallenge(challengeBytes);

      onStatus?.call('Authenticating with SM-DP+');
      final initAuthReq = session.getInitiateAuthenticationRequest();
      final initAuthResp = await Es9PlusService().initiateAuthentication(
        smdpAddress: ac.smdpAddress,
        euiccChallenge: base64Encode(initAuthReq.euiccChallenge!),
        euiccInfo1: base64Encode(initAuthReq.euiccInfo1!.encode()),
        clientTransactionId: '0',
      );
      for (final key in [
        'serverSigned1',
        'serverSignature1',
        'euiccCiPKIdToBeUsed',
        'serverCertificate',
        'transactionId',
      ]) {
        if (initAuthResp[key] == null) {
          throw Exception('Missing $key in InitiateAuthentication response');
        }
      }
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

      onStatus?.call('Verifying signatures');
      final authServerResp = await manager.authenticateServer(
        serverSigned1: serverSigned1,
        serverSignature1: serverSignature1,
        euiccCiPKIdToBeUsed: euiccCiPKId,
        serverCertificate: serverCert,
        matchingId: ac.matchingId,
        useChannel: channel,
      );
      session.processAuthenticateServerResponse(authServerResp);

      onStatus?.call('Retrieving metadata');
      final authClientReq = session.getAuthenticateClientRequest();
      final clientResp = await Es9PlusService().authenticateClient(
        smdpAddress: ac.smdpAddress,
        transactionId: txnId,
        authenticateServerResponse: base64Encode(
          authClientReq.authenticateServerResponse!.encode(),
        ),
      );
      if (clientResp['profileMetadata'] == null) {
        throw Exception('No profile metadata returned.');
      }
      final metadata = StoreMetadataRequest.decode(
        base64Decode(clientResp['profileMetadata']),
      );
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
              ? Certificate.decode(base64Decode(clientResp['smdpCertificate']))
              : null,
        ),
      );
      session.processAuthenticateClientResponse(
        'Executed-Success',
        authClientResponse,
      );
      if (!session.isClientAuthenticatedSuccessfully()) {
        throw Exception('Client authentication failed');
      }

      // --- Prepare download + fetch BPP + install ---
      final settings = AppSettings();
      Uint8List? hashCc;
      if (session.confirmationCode != null) {
        hashCc = CryptoUtils.computeHashCc(
          session.confirmationCode!,
          session.getTransactionId()!,
        );
      }

      if (settings.notifProcessBeforeDownload &&
          settings.isAnyNotificationProcessingEnabled) {
        await _processNotifications(channel, settings);
      }

      onStatus?.call('Preparing eUICC');
      final prepareDownloadResp = await manager.prepareDownload(
        smdpSigned2: session.getSmdpSigned2()!.encode(),
        smdpSignature2: session.getSmdpSignature2()!,
        smdpCertificate: session.getServerCertificate()!,
        hashCc: hashCc,
        useChannel: channel,
      );

      onStatus?.call('Fetching profile package');
      final bppResp = await Es9PlusService().getBoundProfilePackage(
        smdpAddress: ac.smdpAddress,
        transactionId: txnId,
        prepareDownloadResponse: base64Encode(prepareDownloadResp.encode()),
      );
      if (bppResp['boundProfilePackage'] == null) {
        throw Exception('No boundProfilePackage returned from SM-DP+');
      }
      final bppBytes = base64Decode(bppResp['boundProfilePackage']);

      await manager.loadBoundProfilePackage(
        bppBytes,
        useChannel: channel,
        onProgress: (sent, total) {
          if (total > 0) onProgress?.call(sent / total);
        },
        onStatusMessage: (msg) => onStatus?.call(msg),
      );

      final installedIccid = metadata.iccid != null
          ? IccidFormatter.forDisplay(
              HexUtils.swapNibbles(HexUtils.bytesToHex(metadata.iccid!)),
            )
          : null;

      if (settings.notifProcessAfterInstall &&
          settings.isAnyNotificationProcessingEnabled) {
        await _processNotifications(channel, settings);
      }

      // --- Enable the freshly installed profile so the carrier can activate it ---
      if (installedIccid != null) {
        onStatus?.call('Enabling profile');
        try {
          await manager.enableProfile(installedIccid, useChannel: channel);
          if (settings.isAnyNotificationProcessingEnabled) {
            await _processNotifications(channel, settings);
          }
        } catch (e) {
          _log.warning('Enable after transfer download failed: $e');
        }
      }

      return TransferDownloadResult(installedIccid);
    } finally {
      try {
        await channel.close();
      } catch (_) {}
    }
  }

  Future<void> _processNotifications(
    Channel channel,
    AppSettings settings,
  ) async {
    try {
      await NotificationService().processPendingNotifications(
        manager,
        channel,
        autoSendInstall: settings.notifAutoSendInstall,
        autoRemoveInstall: settings.notifAutoRemoveInstall,
        autoSendEnable: settings.notifAutoSendEnable,
        autoRemoveEnable: settings.notifAutoRemoveEnable,
        deleteWithoutSendingEnable: settings.notifDeleteWithoutSendingEnable,
        autoSendDisable: settings.notifAutoSendDisable,
        autoRemoveDisable: settings.notifAutoRemoveDisable,
        deleteWithoutSendingDisable: settings.notifDeleteWithoutSendingDisable,
        autoSendDelete: settings.notifAutoSendDelete,
        autoRemoveDelete: settings.notifAutoRemoveDelete,
      );
    } catch (e) {
      _log.warning('Notification processing failed (non-critical): $e');
    }
  }
}
