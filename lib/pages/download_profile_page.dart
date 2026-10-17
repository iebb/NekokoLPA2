import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../logic/profile_manager.dart';
import '../adapter/euicc_adapter.dart';
import '../adapter/se_hal_adapter.dart';
import '../adapter/se_hal_host.dart';
import '../models/activation_code.dart';
import '../models/asn1/rsp_definitions.g.dart';
import '../services/es9plus_service.dart';
import '../utils/hex_utils.dart';
import '../utils/iccid_formatter.dart';
import '../widgets/common/simple_dialog_container.dart';
import '../widgets/common/loading_spinner.dart';
import '../widgets/styled_header_scaffold.dart';
import '../theme/app_theme.dart';
import '../logic/profile_download_session.dart';
import 'package:logging/logging.dart';
import '../utils/mcc_mapper.dart';
import '../utils/crypto_utils.dart';
import '../services/notification_service.dart';
import '../settings/app_settings.dart';
import '../widgets/euicc_info_dialog.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io if (dart.library.html) '../utils/io_stub.dart';
import '../utils/platform_adapter_io.dart' if (dart.library.js_interop) '../utils/platform_adapter_web.dart';
import 'package:file_picker/file_picker.dart';
import '../services/database_service.dart';
import '../utils/size_formatter.dart';
import 'qr_scanner_page.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as ms;
import '../utils/zxing_decoder.dart' if (dart.library.js_interop) '../utils/zxing_decoder_web.dart';
import '../widgets/lpa_text_editing_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/profile_size_prediction_service.dart';
import '../utils/error_codes.dart';
import '../plugins/plugin_base.dart';
import '../plugins/plugin_manager.dart';


class DownloadProfilePage extends StatefulWidget {
  final ProfileManager profileManager;
  final Adapter adapter;
  final Reader reader;

  final String? initialCode;
  final bool autoStart;

  const DownloadProfilePage({
    super.key,
    required this.profileManager,
    required this.adapter,
    required this.reader,
    this.initialCode,
    this.autoStart = false,
  });

  @override
  State<DownloadProfilePage> createState() => _DownloadProfilePageState();
}

class _DownloadProfilePageState extends State<DownloadProfilePage> {
  static final Logger _log = Logger('DownloadProfilePage');
  final LpaTextEditingController _controller = LpaTextEditingController();
  final TextEditingController _smdpController = TextEditingController();
  final TextEditingController _matchingIdController = TextEditingController();
  final TextEditingController _ccController = TextEditingController();
  final TextEditingController _smdpOidController = TextEditingController();
  bool _isInternalUpdating = false;
  bool _isLoading = false;
  bool _isFinished = false;
  String? _statusMessage;
  String? _error;
  StoreMetadataRequest? _metadata;
  ProfileDownloadSession? _session;
  String? _installedIccid;
  String? _actualConfirmationCode;
  bool _showCcInput = false;
  bool _showValidationErrors = false;
  final Set<String> _touchedFields = {};
  
  final FocusNode _fullFocusNode = FocusNode();
  final FocusNode _smdpFocusNode = FocusNode();
  final FocusNode _matchingIdFocusNode = FocusNode();
  final FocusNode _ccFocusNode = FocusNode();

  int? _predictedSize;

  double? _progress;

  bool _isConfirmationCodeRequired = false;
  final TextEditingController _confirmationCodeController = TextEditingController();
  AuthenticateResponseOk? _authServerResponse; // Store for euiccInfo2 access
  AuthenticateResponseOk? _authServer2Response;
  EUICCInfo2? _finalEuiccInfo2;
  Channel? _sessionChannel;
  
  // Stored auth parameters for re-verification
  Uint8List? _serverSigned1;
  Uint8List? _serverSignature1;
  Uint8List? _euiccCiPKId;
  Uint8List? _serverCert;
  Uint8List? _euiccInfo1Bytes;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null) {
      _controller.text = widget.initialCode!;
    }
    _updateSplitFromFull();
    
    _controller.addListener(_onFullCodeChanged);
    _smdpController.addListener(_onAddressOrMatchingIdChanged);
    _matchingIdController.addListener(_onAddressOrMatchingIdChanged);
    _ccController.addListener(_onSplitCodeChanged);

    // Track touches via focus nodes
    _fullFocusNode.addListener(() { if (!_fullFocusNode.hasFocus) setState(() => _touchedFields.add('full')); });
    _smdpFocusNode.addListener(() { if (!_smdpFocusNode.hasFocus) setState(() => _touchedFields.add('smdp')); });
    _matchingIdFocusNode.addListener(() { if (!_matchingIdFocusNode.hasFocus) setState(() => _touchedFields.add('matchingId')); });
    _ccFocusNode.addListener(() { if (!_ccFocusNode.hasFocus) setState(() => _touchedFields.add('cc')); });

    if (widget.initialCode != null && widget.autoStart && !_isHalDownload) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startPreview();
      });
    }
  }

  void _onFullCodeChanged() {
    if (_isInternalUpdating) return;
    _touchedFields.add('full');
    _updateSplitFromFull();
  }

  void _onAddressOrMatchingIdChanged() {
    if (_isInternalUpdating) return;
    _touchedFields.add('smdp');
    _touchedFields.add('matchingId');
    _updateFullFromSplit();
  }

  void _onSplitCodeChanged() {
    if (_isInternalUpdating) return;
    _touchedFields.add('cc');
    _updateFullFromSplit();
  }

  void _updateSplitFromFull() {
    setState(() {
      _isInternalUpdating = true;
      final ac = ActivationCode.parse(_controller.text);
      if (ac != null) {
        _smdpController.text = ac.smdpAddress;
        _matchingIdController.text = ac.matchingId;
        _smdpOidController.text = ac.smdpOid ?? "";
        
        // Only show CC box if the LPA code has '1' in that bit
        if (ac.confirmationCode == '1') {
          _showCcInput = true;
          _ccController.text = _actualConfirmationCode ?? "";
        } else {
          _showCcInput = false;
          // If it's not '1', we don't show the box, but if it's something else, 
          // we might want to store it anyway (though user said "otherwise don't give the box")
          _actualConfirmationCode = ac.confirmationCode;
        }
        
        // When we successfully populate fields from a pasted/scanned LPA string, 
        // we should show any validation errors (like invalid FQDN) immediately.
        _touchedFields.addAll(['smdp', 'matchingId', 'cc', 'oid']);
      }
      _isInternalUpdating = false;
    });
  }

  void _updateFullFromSplit() {
    _isInternalUpdating = true;
    final smdp = _smdpController.text.trim();
    final matchingId = _matchingIdController.text.trim();
    final ccInput = _ccController.text.trim();
    _actualConfirmationCode = ccInput.isNotEmpty ? ccInput : (_showCcInput ? null : _actualConfirmationCode);
    final oid = _smdpOidController.text.trim();
    
    // Strict FQDN check
    final fqdnRegex = RegExp(r'^(?=^.{4,253}\.?$)(^((?!-)[a-zA-Z0-9-]{1,63}(?<!-)\.)+[a-zA-Z]{2,63}\.?$)$');
    final isValidSmdp = fqdnRegex.hasMatch(smdp);

    // OID check (optional but must be valid if present)
    final oidRegex = RegExp(r'^\d+(\.\d+)+$');
    final isValidOid = oid.isEmpty || oidRegex.hasMatch(oid);

    // Matching ID check
    final matchingIdRegex = RegExp(r'^[0-9A-Z\-]*$');
    final isValidMatchingId = matchingIdRegex.hasMatch(matchingId);

    if (isValidSmdp && isValidOid && isValidMatchingId) {
      // Parse current state to know what the '1' bit currently is
      final currentAc = ActivationCode.parse(_controller.text);
      
      // If user is typing in CC box, it should be '1' if not empty.
      // Otherwise, if the box is hidden but the original LPA had '1', keep the '1'.
      final canonicalCc = ccInput.isNotEmpty ? "1" : (currentAc?.confirmationCode == '1' ? "1" : null);
      
      final finalAc = ActivationCode(
        format: "LPA:1",
        smdpAddress: smdp,
        matchingId: matchingId,
        confirmationCode: canonicalCc,
        smdpOid: oid.isNotEmpty ? oid : null,
      );

      _controller.text = finalAc.toString();
    }
    
    _isInternalUpdating = false;
    // Trigger rebuild to update error states if they are being shown
    setState(() {});
  }

  Uint8List _decodeEs9Base64(dynamic value, String fieldName) {
    if (value is! String || value.isEmpty) {
      throw Exception("Missing $fieldName in SM-DP+ response");
    }
    return base64Decode(value.replaceAll(RegExp(r'\s+'), ''));
  }

  String? get _smdpErrorText {
    if (!_showValidationErrors && !_touchedFields.contains('smdp')) return null;
    final l10n = AppLocalizations.of(context)!;
    final val = _smdpController.text.trim();
    if (val.isEmpty) return l10n.smdpAddressRequired;
    final fqdnRegex = RegExp(r'^(?=^.{4,253}\.?$)(^((?!-)[a-zA-Z0-9-]{1,63}(?<!-)\.)+[a-zA-Z]{2,63}\.?$)$');
    if (!fqdnRegex.hasMatch(val)) return l10n.invalidFqdnFormat;
    return null;
  }

  String? get _matchingIdErrorText {
    if (!_showValidationErrors && !_touchedFields.contains('matchingId')) return null;
    final val = _matchingIdController.text.trim();
    final matchingIdRegex = RegExp(r'^[0-9A-Z\-]*$');
    if (!matchingIdRegex.hasMatch(val)) return AppLocalizations.of(context)!.invalidMatchingIdChars;
    return null;
  }

  String? get _oidErrorText {
    if (!_showValidationErrors && !_touchedFields.contains('oid')) return null;
    final val = _smdpOidController.text.trim();
    if (val.isEmpty) return null; // OID is optional
    final oidRegex = RegExp(r'^\d+(\.\d+)+$');
    if (!oidRegex.hasMatch(val)) return AppLocalizations.of(context)!.invalidOidFormat;
    return null;
  }

  String? get _fullErrorText {
    if (!_showValidationErrors && !_touchedFields.contains('full')) return null;
    final l10n = AppLocalizations.of(context)!;
    final code = _controller.text.trim();
    if (code.isEmpty) return l10n.activationCodeRequired;
    if (ActivationCode.parse(code) == null) return l10n.invalidLpaFormatGeneric;
    return null;
  }

  @override
  void dispose() {
    _controller.removeListener(_onFullCodeChanged);
    _smdpController.removeListener(_onAddressOrMatchingIdChanged);
    _matchingIdController.removeListener(_onAddressOrMatchingIdChanged);
    _ccController.removeListener(_onSplitCodeChanged);
    _fullFocusNode.dispose();
    _smdpFocusNode.dispose();
    _matchingIdFocusNode.dispose();
    _ccFocusNode.dispose();
    _controller.dispose();
    _smdpController.dispose();
    _matchingIdController.dispose();
    _ccController.dispose();
    _smdpOidController.dispose();
    _confirmationCodeController.dispose();
    _sessionChannel?.close();
    if (_isHalDownload) {
      SeHalHost.halEndDownload(_halSlot).catchError((Object e) {
        _log.warning('Could not clear HAL download approval: $e');
      });
    }
    super.dispose();
  }

  int get _halSlot => SeHalAdapter.slotFor(widget.reader);

  bool get _isHalDownload => widget.reader.source is SeHalAdapter;

  Future<bool> _confirmHalDownload({required bool write}) async {
    if (!_isHalDownload) return true;
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.seHalDownloadTitle),
        content: Text(write ? l10n.seHalInstallWarning : l10n.seHalPreviewWarning),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(write ? l10n.seHalAcceptInstall : l10n.seHalContinuePreview)),
        ],
      ),
    ) ?? false;
  }

  void _startPreview() async {
     _log.info("Download preview requested");
     setState(() {
       _showValidationErrors = true;
       _touchedFields.addAll(['full', 'smdp', 'matchingId', 'cc', 'oid']);
     });
     
     if (_smdpErrorText != null || _matchingIdErrorText != null || _oidErrorText != null || _fullErrorText != null) {
       return;
     }

     final code = _controller.text.trim();
     final ac = ActivationCode.parse(code);
     _log.info(
       "Download preview activation code parsed: "
       "hasAc=${ac != null}, inputLength=${code.length}",
     );
     
     if (ac == null) {
       setState(() => _error = AppLocalizations.of(context)!.invalidAcFormatDetailed);
       return;
     }


     if (!await _confirmHalDownload(write: false) || !mounted) return;
     setState(() {
       _isLoading = true;
       _error = null;
       _statusMessage = AppLocalizations.of(context)!.connectingToEuicc;
       _metadata = null;
       _session = null;
     });

     try {
       await widget.adapter.connect(widget.reader);
       if (_isHalDownload) {
         await SeHalHost.halBeginDownload(_halSlot);
       }
       _sessionChannel?.close();
       _sessionChannel = null;
       
       final channel = await widget.profileManager.openSession();
       try {
          // Step 1 & 2: Get eUICC Info and Challenge
          setState(() => _statusMessage = AppLocalizations.of(context)!.gettingChallenge);
          final challengeBytes = await widget.profileManager.getEuiccChallenge(useChannel: channel);
          final info1Bytes = await widget.profileManager.getEuiccInfo1(useChannel: channel);
          _euiccInfo1Bytes = info1Bytes;
          
          String? currentEid;
          try {
            currentEid = await widget.profileManager.getEid(useChannel: channel);
          } catch (e) {
            _log.warning("Failed to get EID for size prediction: $e");
          }

          // Predict size
          try {
            await ProfileSizePredictionService().ensureLoaded();
            final predicted = ProfileSizePredictionService().predictSize(
              eid: currentEid, 
              smdpAddress: ac.smdpAddress,
            );
            if (mounted) setState(() => _predictedSize = predicted);
          } catch (e) {
            _log.warning("Size prediction failed: $e");
          }
          
          // Use the actual confirmation code if we have one, otherwise fallback to parsed
          final effectiveCc = (_actualConfirmationCode != null && _actualConfirmationCode!.isNotEmpty) 
             ? _actualConfirmationCode 
             : (ac.confirmationCode != '1' ? ac.confirmationCode : null);

          // Create download session
          final session = ProfileDownloadSession(
            smdpAddress: ac.smdpAddress,
            matchingId: ac.matchingId,
            confirmationCode: effectiveCc,
          );
          
          session.processEuiccInfo1(info1Bytes);
          session.processEuiccChallenge(challengeBytes);
          
          _log.fine("eUICC Info1: ${HexUtils.bytesToHex(info1Bytes)}");
          _log.fine("eUICC Challenge: ${HexUtils.bytesToHex(challengeBytes)}");
          
          // Step 3: InitiateAuthentication with SM-DP+
          setState(() => _statusMessage = AppLocalizations.of(context)!.authenticatingWithSmdp);
          final initAuthReq = session.getInitiateAuthenticationRequest();
          final initAuthResp = await Es9PlusService().initiateAuthentication(
             smdpAddress: ac.smdpAddress, 
             euiccChallenge: base64Encode(initAuthReq.euiccChallenge!), 
             euiccInfo1: base64Encode(initAuthReq.euiccInfo1!.encode()),
             clientTransactionId: "0"
          );
          
          // Process response - store raw data in session
          _log.fine("InitiateAuthentication RESPONSE: $initAuthResp");
          
          if (initAuthResp['serverSigned1'] == null) {
            throw Exception("Missing serverSigned1 in InitiateAuthentication response");
          }
          if (initAuthResp['serverSignature1'] == null) {
            throw Exception("Missing serverSignature1 in InitiateAuthentication response");
          }
          if (initAuthResp['euiccCiPKIdToBeUsed'] == null) {
            throw Exception("Missing euiccCiPKIdToBeUsed in InitiateAuthentication response");
          }
          if (initAuthResp['serverCertificate'] == null) {
            throw Exception("Missing serverCertificate in InitiateAuthentication response");
          }
          if (initAuthResp['transactionId'] == null) {
            throw Exception("Missing transactionId in InitiateAuthentication response");
          }
          
          final serverSigned1 = _decodeEs9Base64(initAuthResp['serverSigned1'], 'serverSigned1');
          final serverSignature1 = _decodeEs9Base64(initAuthResp['serverSignature1'], 'serverSignature1');
          final euiccCiPKId = _decodeEs9Base64(initAuthResp['euiccCiPKIdToBeUsed'], 'euiccCiPKIdToBeUsed');
          final serverCert = _decodeEs9Base64(initAuthResp['serverCertificate'], 'serverCertificate');
          final txnId = initAuthResp['transactionId'] as String;

          _serverSigned1 = serverSigned1;
          _serverSignature1 = serverSignature1;
          _euiccCiPKId = euiccCiPKId;
          _serverCert = serverCert;
          
          // Store transaction ID and server certificate in session
          session.processInitiateAuthenticationResponse(
            'Executed-Success', 
            Uint8List.fromList(utf8.encode(txnId)),
            serverCert
          );
          
          // Step 4: AuthenticateServer with eUICC
          setState(() => _statusMessage = AppLocalizations.of(context)!.verifyingSignatures);
          final authServerResp = await widget.profileManager.authenticateServer(
             serverSigned1: serverSigned1, 
             serverSignature1: serverSignature1, 
             euiccCiPKIdToBeUsed: euiccCiPKId, 
             serverCertificate: serverCert, 
             matchingId: ac.matchingId,
             useChannel: channel
          );
          
          session.processAuthenticateServerResponse(authServerResp);
          
          // Step 5: AuthenticateClient with SM-DP+
          setState(() => _statusMessage = AppLocalizations.of(context)!.retrievingMetadata);
          final authClientReq = session.getAuthenticateClientRequest();
          final clientResp = await Es9PlusService().authenticateClient(
             smdpAddress: ac.smdpAddress, 
             transactionId: utf8.decode(authClientReq.transactionId!), 
             authenticateServerResponse: base64Encode(authClientReq.authenticateServerResponse!.encode()),
          );
          
          _log.fine("AuthenticateClient RESPONSE: $clientResp");
          
          // Process and check success
          if (clientResp['profileMetadata'] != null) {
              final metadataBytes = _decodeEs9Base64(clientResp['profileMetadata'], 'profileMetadata');
              _log.fine("Profile Metadata (Hex): ${HexUtils.bytesToHex(metadataBytes)}");
              final metadata = StoreMetadataRequest.decode(metadataBytes);
              _log.info("Decoded Metadata: ICCID=${metadata.iccid != null ? HexUtils.bytesToHex(metadata.iccid!) : 'null'}, Provider=${metadata.serviceProviderName}");
              
              final authClientResponse = AuthenticateClientResponseEs9(
                authenticateClientOk: AuthenticateClientOk(
                  transactionId: Uint8List.fromList(utf8.encode(txnId)),
                  profileMetadata: metadata,
                  smdpSigned2: clientResp['smdpSigned2'] != null ? SmdpSigned2.decode(_decodeEs9Base64(clientResp['smdpSigned2'], 'smdpSigned2')) : null,
                  smdpSignature2: clientResp['smdpSignature2'] != null ? _decodeEs9Base64(clientResp['smdpSignature2'], 'smdpSignature2') : null,
                  smdpCertificate: clientResp['smdpCertificate'] != null ? Certificate.decode(_decodeEs9Base64(clientResp['smdpCertificate'], 'smdpCertificate')) : null,
                ),
              );
              
              session.processAuthenticateClientResponse('Executed-Success', authClientResponse);
              
              if (session.isClientAuthenticatedSuccessfully()) {
                final signed2 = session.getSmdpSigned2();
                // Check if confirmation code is required
                final ccRequired = signed2?.ccRequiredFlag ?? false;
                
                setState(() {
                  _metadata = session.getProfileMetadata();
                  if (_metadata?.estimatedProfileSize != null && _metadata!.estimatedProfileSize! > 0) {
                    _predictedSize = _metadata!.estimatedProfileSize;
                  } else {
                    // Refine prediction with metadata (Provider Name, PLMN)
                    String? plmn; 
                    if (_metadata?.profileOwner != null) {
                      final parsed = MccMapper.parseOperatorId(_metadata!.profileOwner!.mccMnc);
                      if (parsed != null) plmn = "${parsed['mcc']}${parsed['mnc']}";
                    }
                    
                    final improvedPrediction = ProfileSizePredictionService().predictSize(
                       eid: currentEid, 
                       smdpAddress: ac.smdpAddress,
                       plmn: plmn,
                       serviceProviderName: _metadata?.serviceProviderName,
                    );
                    
                    if (improvedPrediction != null) {
                      _predictedSize = improvedPrediction;
                    }
                  }
                  _session = session;
                  _isConfirmationCodeRequired = ccRequired;
                  _authServerResponse = authServerResp; // Store for preview
                  _isLoading = false;
                  _sessionChannel = channel;
                });
              } else {
                throw Exception("Client authentication failed");
              }
          } else {
              throw Exception("No profile metadata returned.");
          }
       } catch (e) {
          await channel.close();
          rethrow;
       }
     } catch (e, stackTrace) {
       _log.severe("Error during profile download: $e", e, stackTrace);
       if (mounted) {
         setState(() {
           _isLoading = false;
           _error = (e is AppException) ? e.toString() : e.toString();
           if (e is AppException) {
              final local = AppLocalizations.of(context)!;
              switch (e.code) {
                 case AppErrorCode.ERROR_BLUETOOTH_TIMEOUT:
                   _error = local.errorBluetoothTimeout;
                   break;
                 case AppErrorCode.ERROR_OMAPI_SECURITYEXCEPTION:
                 case AppErrorCode.ERROR_OMAPI_PERMISSION_DENIED:
                   _error = local.errorOmapiSecurity;
                   break;
                 case AppErrorCode.ERROR_APPLICATION_NOT_FOUND:
                   _error = local.errorApplicationNotFound;
                   break;
                 default:
                   if (e.message != null) _error = e.message;
              }
           }
         });
       }
     } finally {
       // Keep connection alive between transactions
     }
  }

  void _downloadProfile() async {
    if (_session == null || _metadata == null) return;
    if (!await _confirmHalDownload(write: true) || !mounted) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = true;
      _error = null;
      _statusMessage = AppLocalizations.of(context)!.preparingDownload;
    });

     int? bppSize;
     Channel? channel;
     try {
      _log.info("Profile download requested");
      await widget.adapter.connect(widget.reader);
      
      final ac = ActivationCode.parse(_controller.text)!;
      _log.info(
        "Profile download context: reader=${widget.reader.id}, "
        "smdp=${ac.smdpAddress}, matchingIdLength=${ac.matchingId.length}, "
        "hasConfirmationCode=${_session!.confirmationCode != null}",
      );
      // Use existing session channel if available, or start a new one
      if (_sessionChannel != null) {
        _log.info("Reusing existing authenticated session channel");
        channel = _sessionChannel;
      } else {
        _log.info("Session channel lost, opening new channel and re-authenticating...");
        channel = await widget.profileManager.openSession();
        // Since we opened a new channel, we MUST re-run the mutual authentication
        // to set up the ES10b session context on the eUICC.
        await widget.profileManager.authenticateServer(
          serverSigned1: _serverSigned1!,
          serverSignature1: _serverSignature1!,
          euiccCiPKIdToBeUsed: _euiccCiPKId!,
          serverCertificate: _serverCert!,
          matchingId: ac.matchingId,
          useChannel: channel,
        );
      }

      try {
        final smdpSigned2 = _session!.getSmdpSigned2()!;
        final smdpSignature2 = _session!.getSmdpSignature2()!;
        final serverCert = _session!.getServerCertificate()!;
        final txnId = utf8.decode(_session!.getTransactionId()!);

        // Step 1: Prepare Download on eUICC
        setState(() => _statusMessage = AppLocalizations.of(context)!.preparingEuicc);
        
        Uint8List? hashCc;
        if (_session!.confirmationCode != null) {
          hashCc = CryptoUtils.computeHashCc(_session!.confirmationCode!, _session!.getTransactionId()!);
          _log.info("Using Hashed Confirmation Code: ${HexUtils.bytesToHex(hashCc)}");
        }

        final settings = AppSettings();
        if (!_isHalDownload && settings.notifProcessBeforeDownload &&
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
          useChannel: channel
        );

        // Step 2: Get Bound Profile Package from SM-DP+
        setState(() => _statusMessage = AppLocalizations.of(context)!.fetchingProfilePackage);
        final bppResp = await Es9PlusService().getBoundProfilePackage(
          smdpAddress: ac.smdpAddress,
          transactionId: txnId,
          prepareDownloadResponse: base64Encode(prepareDownloadResp.encode())
        );
        _log.info(
          "getBoundProfilePackage response hasBpp="
          "${bppResp['boundProfilePackage'] != null}",
        );

        if (bppResp['boundProfilePackage'] == null) {
          throw Exception("No boundProfilePackage returned from SM-DP+");
        }

        final bppBytes = _decodeEs9Base64(bppResp['boundProfilePackage'], 'boundProfilePackage');
        bppSize = bppBytes.length;
        _log.info("Decoded bound profile package: $bppSize bytes");

        // Step 3: Load Bound Profile Package to eUICC
        setState(() => _statusMessage = AppLocalizations.of(context)!.installing(0, bppBytes.length));
        await widget.profileManager.loadBoundProfilePackage(
          bppBytes, 
          useChannel: channel,
          onProgress: (sent, total) {
            if (mounted) {
              setState(() {
                _progress = sent / total;
                _statusMessage = AppLocalizations.of(context)!.installing(sent, total);
              });
            }
          },
          onStatusMessage: (msg) {
             if (mounted) {
               setState(() {
                 _statusMessage = msg;
               });
             }
          }
        );

        // Success!
        _installedIccid = _metadata?.iccid != null
            ? IccidFormatter.forDisplay(HexUtils.swapNibbles(HexUtils.bytesToHex(_metadata!.iccid!)))
            : null;

        if (_isHalDownload) {
          final installed = await widget.profileManager.listProfiles(useChannel: channel);
          if (_installedIccid == null || !installed.any((p) => IccidFormatter.forDisplay(p.iccid) == _installedIccid)) {
            throw InstallationException(l10n.seHalInstallNotVerified);
          }
        }

        // Post-installation: Get updated free space
        if (_euiccInfo1Bytes != null && !_isHalDownload) {
          try {
             setState(() => _statusMessage = AppLocalizations.of(context)!.finalizing);
             // Start a new logical sequence to get fresh eUICCInfo2
             
             // 1. Get new challenge
             final newChallenge = await widget.profileManager.getEuiccChallenge(useChannel: channel);
             
             // 2. Initiate Authentication (using stored EuiccInfo1 + new Challenge)
             // We can reuse the original download session object logic or create a temp one 
             // but we just need the request parameters.
             final tempSession = ProfileDownloadSession(
                smdpAddress: ac.smdpAddress,
                matchingId: ac.matchingId,
             );
             tempSession.processEuiccInfo1(_euiccInfo1Bytes!);
             tempSession.processEuiccChallenge(newChallenge);
             
             final initAuthReq = tempSession.getInitiateAuthenticationRequest();
             
             final initAuthResp = await Es9PlusService().initiateAuthentication(
                smdpAddress: ac.smdpAddress, 
                euiccChallenge: base64Encode(initAuthReq.euiccChallenge!), 
                euiccInfo1: base64Encode(initAuthReq.euiccInfo1!.encode()),
                clientTransactionId: "1" // Use different transaction ID
             );
             
             if (initAuthResp['serverSigned1'] != null && 
                 initAuthResp['serverSignature1'] != null && 
                 initAuthResp['euiccCiPKIdToBeUsed'] != null && 
                 initAuthResp['serverCertificate'] != null) {
                   
                 final serverSigned1 = _decodeEs9Base64(initAuthResp['serverSigned1'], 'serverSigned1');
                 final serverSignature1 = _decodeEs9Base64(initAuthResp['serverSignature1'], 'serverSignature1');
                 final euiccCiPKId = _decodeEs9Base64(initAuthResp['euiccCiPKIdToBeUsed'], 'euiccCiPKIdToBeUsed');
                 final serverCert = _decodeEs9Base64(initAuthResp['serverCertificate'], 'serverCertificate');
                 
                 // 3. AuthenticateServer to get fresh eUICCInfo2
                 final finalAuthResp = await widget.profileManager.authenticateServer(
                    serverSigned1: serverSigned1,
                    serverSignature1: serverSignature1,
                    euiccCiPKIdToBeUsed: euiccCiPKId,
                    serverCertificate: serverCert,
                    matchingId: ac.matchingId,
                    useChannel: channel
                 );
                 _finalEuiccInfo2 = finalAuthResp.euiccSigned1?.euiccInfo2;
                 _authServer2Response = finalAuthResp;
             } else {
                 _log.warning("Final InitiateAuthentication failed: missing fields");
                 _finalEuiccInfo2 = await widget.profileManager.getEuiccInfo2(useChannel: channel);
             }
          } catch (e) {
             _log.warning("Failed to fetch final eUICC Info 2 via ES9+: $e");
             // Fallback
             try {
                _finalEuiccInfo2 = await widget.profileManager.getEuiccInfo2(useChannel: channel);
             } catch (e2) {
                _log.warning("Fallback getEuiccInfo2 failed: $e2");
             }
          }
        } else {
           // Fallback to simple getEuiccInfo2 if we don't have info1 stored
           try {
             _finalEuiccInfo2 = await widget.profileManager.getEuiccInfo2(useChannel: channel);
           } catch (e) {
             _log.warning("Failed to fetch final eUICC Info 2: $e");
           }
         }

          // Calculate and save consumed space
         if (_installedIccid != null && _authServerResponse?.euiccSigned1?.euiccInfo2?.extCardResource != null && _finalEuiccInfo2?.extCardResource != null) {
             final initialFree = _authServerResponse!.euiccSigned1!.euiccInfo2!.extCardResource?.freeNonVolatileMemory ?? 0;
             final finalFree = _finalEuiccInfo2!.extCardResource?.freeNonVolatileMemory ?? 0;
             final consumed = initialFree - finalFree;
             if (consumed > 0) {
                try {
                   // Retrieve EID if needed
                   String? eid;
                   try {
                     eid = await widget.profileManager.getEid(useChannel: channel);
                   } catch (_) {}
                   
                   if (eid != null) {
                     final e1Before = _authServerResponse!;
                     final e1After = _authServer2Response;
                     
                     await DatabaseService().saveProfileSize(
                        eid, 
                        _installedIccid!, 
                        consumed,
                        info2Before: base64Encode(e1Before.encode()),
                        info2After: e1After != null
                            ? base64Encode(e1After.encode())
                            : null,
                        bppLength: bppBytes.length,
                     );
                  }
               } catch (e) {
                  _log.warning("Failed to save profile size: $e");
               }
            }
         }

        if (_isHalDownload) {
          try {
            await NotificationService().processPendingNotifications(widget.profileManager, channel,
              autoSendInstall: true, autoRemoveInstall: false,
              autoSendEnable: true, autoRemoveEnable: false, deleteWithoutSendingEnable: false,
              autoSendDisable: true, autoRemoveDisable: false, deleteWithoutSendingDisable: false,
              autoSendDelete: false, autoRemoveDelete: false);
          } catch (e) { _log.warning('HAL installation notification reporting failed; send manually: $e'); }
        }

        if (!_isHalDownload && settings.notifProcessAfterInstall &&
            settings.isAnyNotificationProcessingEnabled) {
          try {
            await NotificationService().processPendingNotifications(
              widget.profileManager, 
              channel,
              autoSendInstall: settings.notifAutoSendInstall, autoRemoveInstall: settings.notifAutoRemoveInstall,
              autoSendEnable: settings.notifAutoSendEnable, autoRemoveEnable: settings.notifAutoRemoveEnable, deleteWithoutSendingEnable: settings.notifDeleteWithoutSendingEnable,
              autoSendDisable: settings.notifAutoSendDisable, autoRemoveDisable: settings.notifAutoRemoveDisable, deleteWithoutSendingDisable: settings.notifDeleteWithoutSendingDisable,
              autoSendDelete: settings.notifAutoSendDelete, autoRemoveDelete: settings.notifAutoRemoveDelete,
            );
          } catch (e) {
            _log.warning("Notification processing failed (non-critical): $e");
          }
        }

        if (mounted) {
          setState(() {
             _isLoading = false;
             _isFinished = true;
             _statusMessage = AppLocalizations.of(context)!.profileInstalledSuccessfully;
          });
        }

        _notifyInstallationReported(
          authBefore: _authServerResponse,
          authAfter: _authServer2Response,
          bppSize: bppSize,
        );
      } finally {
        if (channel != null) {
          try {
            await channel.close();
            if (channel == _sessionChannel) _sessionChannel = null;
          } catch (_) {}
        }
      }
    } catch (e, stackTrace) {
      _handleInstallationFailure(
        e,
        _authServerResponse,
        bppSize: bppSize,
        stackTrace: stackTrace,
      );
    } finally {
      // Keep connection alive between transactions
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = NotificationService();
    return ListenableBuilder(
      listenable: Listenable.merge([
        notifications.isProcessing,
        notifications.isFetching,
      ]),
      builder: (context, _) => PopScope(
        canPop: !_isLoading &&
            !_isInternalUpdating &&
            !notifications.isProcessing.value &&
            !notifications.isFetching.value,
        child: StyledHeaderScaffold(
          title: AppLocalizations.of(context)!.downloadProfileTitle,
          body: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: _buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
     if (_error != null) return _buildErrorScreen(context);
     return ValueListenableBuilder<bool>(
       valueListenable: NotificationService().isFetching,
       builder: (context, isFetching, _) {
         if (_isLoading || isFetching) return _buildLoading(context, isFetching: isFetching);
         if (_isFinished) return _buildSuccessView(context);
         if (_metadata != null) return _buildPreview(context);
         return _buildInput(context);
       },
     );
  }

  Widget _buildLoading(BuildContext context, {bool isFetching = false}) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_progress == null || isFetching)
            const LoadingSpinner()
          else
            Container(
              width: 400,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                   LayoutBuilder(
                     builder: (context, constraints) {
                       final maxWidth = constraints.maxWidth;
                       return SizedBox(
                         height: 50, // Reserve height for turtle
                         child: Stack(
                           clipBehavior: Clip.none,
                           alignment: Alignment.bottomCenter, // Align bar to bottom
                           children: [
                              // Progress Bar at bottom
                              Container(
                                 margin: const EdgeInsets.only(top: 40), // Push bar down
                                 child: LinearProgressIndicator(
                                   value: _progress,
                                   minHeight: 8,
                                   borderRadius: BorderRadius.circular(4),
                                 ),
                              ),
                              // Turtle moving on top
                              if (_progress != null)
                                 AnimatedPositioned(
                                     duration: const Duration(milliseconds: 30),
                                     curve: Curves.easeInOut,
                                     left: (maxWidth * _progress!) - 24, 
                                     top: -5, // Slightly moved up to sit on top
                                     child: Transform.flip(
                                       flipX: true, // Face direction of progress (Right)
                                       child: Image.asset(
                                         'assets/turtle.webp',
                                         width: 48,
                                         height: 48,
                                       ),
                                     ),
                                 ),
                           ],
                         ),
                       );
                     }
                   ),
                   const SizedBox(height: 12),
                   Text("${(_progress! * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                ],
               ),
             ),
           const SizedBox(height: 24),
           Text(isFetching ? AppLocalizations.of(context)!.loadingNotifications : (_statusMessage ?? AppLocalizations.of(context)!.processing), style: TextStyle(fontSize: 16, color: AppTheme.onSurface(context).withValues(alpha: 0.6))),
         ],
       ),
    );
  }

    Widget _buildInput(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return DropTarget(
      onDragDone: (detail) async {
        if (detail.files.isNotEmpty) {
           await _handleImageFile(detail.files.first.path);
        }
      },
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            child: Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: [
                  Text(l10n.activationCodeTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.5, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 12),
                  Text(l10n.activationCodeSubtitle, style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), height: 1.4)),
                  const SizedBox(height: 32),
                  _buildErrorDisplay(context),
                    TextField(
                     controller: _controller,
                     focusNode: _fullFocusNode,
                     autofocus: true,
                     maxLines: null,
                     keyboardType: TextInputType.multiline,
                     style: AppTheme.mono(TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w400)),
                    decoration: InputDecoration(
                      labelText: l10n.fullActivationCodeLabel,
                      hintText: l10n.fullActivationCodeHint,
                      errorText: _fullErrorText,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: l10n.pasteFromClipboardTooltip,
                            icon: const Icon(Icons.content_paste_outlined),
                            onPressed: () async {
                              final data = await Clipboard.getData(Clipboard.kTextPlain);
                              final text = data?.text;
                              if (text != null && mounted) {
                                // Paste only if it begins with LPA:1$
                                if (text.startsWith('LPA:1\$')) {
                                  _controller.text = text;
                                } else {
                                  setState(() => _error = l10n.invalidLpaClipboard);
                                }
                              }
                            },
                          ),
                          IconButton(
                            tooltip: l10n.selectFromGalleryTooltip,
                            icon: const Icon(Icons.image_outlined),
                            onPressed: () async {
                                final result = await FilePicker.platform.pickFiles(type: FileType.image);
                                if (result != null && result.files.single.path != null) {
                                   await _handleImageFile(result.files.single.path!);
                                }
                            },
                          ),
                          if (!PlatformX.isWindows && !PlatformX.isLinux)
                          IconButton(
                            tooltip: l10n.scanQrCodeTooltip,
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: () async {
                              final code = await Navigator.push<String>(
                                context,
                                MaterialPageRoute(builder: (context) => const QrScannerPage()),
                              );
                              if (code != null && mounted) {
                                _controller.text = code;
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _smdpController,
                        focusNode: _smdpFocusNode,
                        style: AppTheme.mono(TextStyle(
                          fontSize: 14, 
                          color: _smdpErrorText != null ? theme.colorScheme.error : AppTheme.smdpAddress(context)
                        )),
                        decoration: InputDecoration(
                          labelText: l10n.smdpAddressLabel,
                          hintText: l10n.smdpAddressHint,
                          errorText: _smdpErrorText,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _matchingIdController,
                        focusNode: _matchingIdFocusNode,
                        style: AppTheme.mono(TextStyle(
                          fontSize: 14, 
                          color: _matchingIdErrorText != null ? theme.colorScheme.error : AppTheme.matchingId(context)
                        )),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            return newValue.copyWith(text: newValue.text.toUpperCase());
                          }),
                        ],
                        decoration: InputDecoration(
                          labelText: l10n.matchingIdLabel,
                          hintText: l10n.matchingIdHint,
                          errorText: _matchingIdErrorText,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      if (_smdpOidController.text.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _smdpOidController,
                          readOnly: true,
                          style: AppTheme.mono(TextStyle(
                            fontSize: 14, 
                            color: _oidErrorText != null ? theme.colorScheme.error : AppTheme.smdpOid(context)
                          )),
                          decoration: InputDecoration(
                            labelText: l10n.smdpOidLabel,
                            errorText: _oidErrorText,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                setState(() {
                                  _touchedFields.add('oid');
                                  _smdpOidController.clear();
                                  _updateFullFromSplit();
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                      if (_showCcInput) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _ccController,
                          focusNode: _ccFocusNode,
                          style: AppTheme.mono(TextStyle(fontSize: 14, color: AppTheme.confirmationCode(context))),
                          decoration: InputDecoration(
                            labelText: l10n.confirmationCodeLabel,
                            hintText: l10n.confirmationCodeHint,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _startPreview,
                    child: Text(_isHalDownload
                      ? l10n.seHalDownloadUnusedQr
                      : l10n.continueButton),
                  ),
               ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleImageFile(String path) async {
     final l10n = AppLocalizations.of(context)!;
     setState(() {
        _isLoading = true;
        _statusMessage = l10n.analyzingImage;
        _error = null;
     });
     
     try {
        String? code;
        
        // Use zxing_lib pure dart fallback for Windows and Linux 
        // as mobile_scanner analyzeImage is not implemented there.
        // On Android/iOS, we rely on mobile_scanner and avoid linking zxing_lib via ENABLE_ZXING flag.
        const bool useZxing = bool.fromEnvironment("ENABLE_ZXING", defaultValue: true);

        if ((PlatformX.isWindows || PlatformX.isLinux) && useZxing) {
           code = await decodeQrWithZxing(path);
        } else {
           // For mobile platforms and macOS, try mobile_scanner first
           try {
              final controller = ms.MobileScannerController();
              final capture = await controller.analyzeImage(path);
              await controller.dispose();
              if (capture != null && capture.barcodes.isNotEmpty) {
                 code = capture.barcodes.first.rawValue;
              }
           } catch (e) {
              _log.warning("mobile_scanner analyzeImage failed: $e");
              if (useZxing) {
                  _log.info("Falling back to zxing_lib.");
                  code = await decodeQrWithZxing(path);
              }
           }
        }
        
        if (code != null && mounted) {
           setState(() {
              _controller.text = code!;
              _isLoading = false;
           });
           return;
        }
        
        if (mounted) {
           setState(() {
              _isLoading = false;
              _error = l10n.noQrFoundInImage;
           });
        }
     } catch (e) {
        if (mounted) {
           setState(() {
              _isLoading = false;
              _error = "${l10n.invalidAcInImage}: $e";
           });
        }
     }
  }

  Widget _buildPreview(BuildContext context) {
    // Debug logging
    _log.info("=== METADATA PREVIEW DEBUG ===");
    _log.info("ICCID (raw bytes): ${_metadata?.iccid != null ? HexUtils.bytesToHex(_metadata!.iccid!) : 'null'}");
    _log.info("Profile Name: ${_metadata?.profileName}");
    _log.info("Service Provider Name: ${_metadata?.serviceProviderName}");
    _log.info("Profile Class: ${_metadata?.profileClass}");
    _log.info("Icon Type: ${_metadata?.iconType}");
    _log.info("Icon (bytes): ${_metadata?.icon != null ? '${_metadata!.icon!.length} bytes' : 'null'}");
    _log.info("Profile Policy Rules: ${_metadata?.profilePolicyRules}");
    _log.info("Profile Owner: ${_metadata?.profileOwner}");
    _log.info("Profile Metadata: $_metadata");
    _log.info("==============================");
    
    // Show metadata
    final l10n = AppLocalizations.of(context)!;
    final iccidHex = _metadata?.iccid != null ? HexUtils.swapNibbles(HexUtils.bytesToHex(_metadata!.iccid!)) : l10n.unavailable;
    final iccidDisplay = IccidFormatter.forDisplay(iccidHex);
    final name = _metadata?.profileName ?? l10n.unknownProfile;
    final provider = _metadata?.serviceProviderName ?? l10n.unknownProvider;
    
    String? flagUrl;
    final opId = _metadata?.profileOwner;
    String mcc = "";
    String mnc = "";
    if (opId != null) {
      final parsed = MccMapper.parseOperatorId(opId.mccMnc);
      if (parsed != null) {
        mcc = parsed['mcc']!;
        mnc = parsed['mnc']!;
        flagUrl = MccMapper.getFlagUrl(parsed['mcc'], mnc: parsed['mnc'], iccid: iccidHex);
      }
    }

    final theme = Theme.of(context);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildErrorDisplay(context),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (flagUrl != null) ...[
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: flagUrl, 
                      width: 44, 
                      height: 30, 
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const Icon(Icons.flag_outlined, size: 30),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Flexible(
                child: Text(
                  name, 
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.8, color: theme.colorScheme.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Elegant Info Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                _buildElegantInfoRow(Icons.business_rounded, AppLocalizations.of(context)!.provider, provider, context),
                _buildElegantInfoRow(Icons.sim_card_rounded, AppLocalizations.of(context)!.iccid, iccidDisplay, context),
                _buildElegantInfoRow(Icons.public_rounded, AppLocalizations.of(context)!.plmn, "$mcc $mnc", context),
                
                if (_authServerResponse?.euiccSigned1?.euiccInfo2?.extCardResource != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.storage_rounded, size: 14, color: theme.colorScheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              AppLocalizations.of(context)!.storage,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              onPressed: () => EuiccInfoDialog.show(context, _authServerResponse!.euiccSigned1!.euiccInfo2!),
                              icon: Icon(Icons.info_outline_rounded, size: 18, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                    Text(
                                      SizeFormatter.format(_authServerResponse!.euiccSigned1!.euiccInfo2!.extCardResource?.freeNonVolatileMemory ?? 0),
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                                    ),
                                  Text(" ${AppLocalizations.of(context)!.free.toUpperCase()} ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withValues(alpha: 0.4), letterSpacing: 0.5)),
                                  
                                  if (MediaQuery.of(context).size.width > 400) ...[
                                    const SizedBox(width: 10),
                                    Text(
                                      SizeFormatter.format(_authServerResponse!.euiccSigned1!.euiccInfo2!.extCardResource?.freeVolatileMemory ?? 0),
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                                    ),
                                      Text(" RAM ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withValues(alpha: 0.4), letterSpacing: 0.5)),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_predictedSize != null) ...[
                          const SizedBox(height: 8),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.analytics_outlined, size: 14, color: theme.colorScheme.onTertiaryContainer),
                                    const SizedBox(width: 6),
                                    Text(
                                      "${AppLocalizations.of(context)!.estimatedDownloadSize}: ",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onTertiaryContainer.withValues(alpha: 0.8),
                                      ),
                                    ),
                                    Text(
                                      SizeFormatter.format(_predictedSize!),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.onTertiaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if ((_authServerResponse!.euiccSigned1!.euiccInfo2!.extCardResource?.freeNonVolatileMemory ?? 0) < (_predictedSize! * 1.25))
                            Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 16, color: theme.colorScheme.error),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(context)!.insufficientStorageWarning,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: theme.colorScheme.error,
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
                ],
              ],
            ),
          ),
          
          // Certificate Export Section (Developer Mode Only, Non-web)
          if (!kIsWeb && AppSettings().developerModeEnabled && _authServerResponse != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.terminal_rounded, size: 12, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizations.of(context)!.exportCertificates,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInlineFilledButton(
                          context,
                          onPressed: _authServerResponse?.euiccCertificate != null 
                            ? () => _exportCert(_authServerResponse!.euiccCertificate!, 'euiccCertificate') 
                            : null,
                          icon: Icons.download_rounded,
                          label: AppLocalizations.of(context)!.euiccCert,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInlineFilledButton(
                          context,
                          onPressed: _authServerResponse?.nextCertInChain != null 
                            ? () => _exportCert(_authServerResponse!.nextCertInChain!, 'eumCertificate') 
                            : null,
                          icon: Icons.download_rounded,
                          label: AppLocalizations.of(context)!.eumCert,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          
          if (_isConfirmationCodeRequired) ...[
            const SizedBox(height: 32),
            Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: TextField(
                controller: _confirmationCodeController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.confirmationCodeLabel,
                  hintText: AppLocalizations.of(context)!.enterConfirmationCode,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildInlineFilledButton(
                  context,
                  onPressed: () => Navigator.pop(context),
                  label: AppLocalizations.of(context)!.cancel,
                  isGrey: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInlineFilledButton(
                  context,
                  onPressed: () {
                     if (_isConfirmationCodeRequired) {
                        final code = _confirmationCodeController.text.trim();
                        if (code.isEmpty) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.confirmationCodeRequired)));
                           return;
                        }
                        _session?.setConfirmationCode(code);
                     }
                     _downloadProfile();
                  }, 
                  label: AppLocalizations.of(context)!.download,
                  isPrimary: true,
                ),
              ),
            ],
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElegantInfoRow(IconData icon, String label, String value, BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineFilledButton(
    BuildContext context, {
    required VoidCallback? onPressed,
    required String label,
    IconData? icon,
    bool isPrimary = false,
    bool isGrey = false,
  }) {
    final theme = Theme.of(context);
    Color bgColor = theme.colorScheme.primary.withValues(alpha: 0.08);
    Color fgColor = theme.colorScheme.primary;
    
    if (isPrimary) {
      bgColor = theme.colorScheme.primary;
      fgColor = Colors.white;
    } else if (isGrey) {
      bgColor = theme.colorScheme.onSurface.withValues(alpha: 0.05);
      fgColor = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    }
    
    return TextButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 16) : const SizedBox.shrink(),
      label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        disabledBackgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.02),
        disabledForegroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    final theme = Theme.of(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;
        final iconSize = isSmall ? 60.0 : 80.0;
        final titleSize = isSmall ? 22.0 : 28.0;
        final horizontalPadding = isSmall ? 24.0 : 0.0;
        
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: isSmall ? 24 : 0),
                Container(
                  padding: EdgeInsets.all(isSmall ? 16 : 24),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_outline, color: Colors.green, size: iconSize),
                ),
                SizedBox(height: isSmall ? 16 : 32),
                Text(
                  AppLocalizations.of(context)!.installationSuccessful, 
                  style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w600, letterSpacing: -0.8, color: theme.colorScheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmall ? 8 : 12),
                Text(
                  AppLocalizations.of(context)!.installationSuccessMessage,
                  style: TextStyle(fontSize: isSmall ? 14 : 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  textAlign: TextAlign.center,
                ),
                if (_authServerResponse?.euiccSigned1?.euiccInfo2?.extCardResource != null && _finalEuiccInfo2?.extCardResource != null) ...[
                   SizedBox(height: isSmall ? 16 : 24),
                   Builder(
                     builder: (context) {
                       final initialFree = _authServerResponse!.euiccSigned1!.euiccInfo2!.extCardResource?.freeNonVolatileMemory ?? 0;
                       final finalFree = _finalEuiccInfo2!.extCardResource?.freeNonVolatileMemory ?? 0;
                       final consumed = initialFree - finalFree;
                       
                       final consumedStr = consumed > 0 ? SizeFormatter.format(consumed) : AppLocalizations.of(context)!.lessThan1Kb;
                       
                       return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.storage_rounded, size: 20, color: theme.colorScheme.primary),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(AppLocalizations.of(context)!.consumed, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                                  Text(consumedStr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                                ],
                              ),
                              const SizedBox(width: 20),
                              Container(width: 1, height: 30, color: theme.colorScheme.outlineVariant),
                              const SizedBox(width: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                   Text(AppLocalizations.of(context)!.free, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                                   Text(SizeFormatter.format(finalFree), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                                ],
                              )
                            ],
                          ),
                       );
                     },
                   ),
                ],
                SizedBox(height: isSmall ? 32 : 48),
                Container(
                  width: isSmall ? double.infinity : 400,
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: _isHalDownload ? () => Navigator.pop(context, true) : _handleEnable,
                        icon: const Icon(Icons.flash_on),
                        label: Text(_isHalDownload ? AppLocalizations.of(context)!.seHalReturnToEnable : AppLocalizations.of(context)!.enableProfileNow),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _handleRename,
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(AppLocalizations.of(context)!.renameProfile),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: theme.colorScheme.onSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => Navigator.pop(context, true),
                        icon: const Icon(Icons.check_rounded),
                        label: Text(AppLocalizations.of(context)!.done),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          foregroundColor: theme.colorScheme.onSurface,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleEnable() async {
    if (_installedIccid == null) return;
    setState(() {
      _isLoading = true;
      _statusMessage = AppLocalizations.of(context)!.enablingProfile;
    });
    try {
      await widget.adapter.connect(widget.reader);
      await widget.profileManager.enableProfile(_installedIccid!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.profileEnabledSuccessfully)));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleRename() async {
    if (_installedIccid == null) return;
    final controller = TextEditingController(text: _metadata?.profileName);
    
    final newName = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return SimpleDialogContainer(
          title: AppLocalizations.of(context)!.renameProfile,
          secondaryActionLabel: AppLocalizations.of(context)!.cancel,
          primaryActionLabel: AppLocalizations.of(context)!.rename,
          onPrimaryAction: () => Navigator.pop(context, controller.text),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppLocalizations.of(context)!.enterNewProfileName,
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.profileName,
                    hintText: AppLocalizations.of(context)!.profileNameHint,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() {
        _isLoading = true;
        _statusMessage = AppLocalizations.of(context)!.updatingProfile; // Using existing updatingProfile key
      });
      try {
        await widget.adapter.connect(widget.reader);
        await widget.profileManager.renameProfile(_installedIccid!, newName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.profileRenamedSuccessfully)));
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() => _error = e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildErrorScreen(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;
        final iconSize = isSmall ? 60.0 : 80.0;
        
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: isSmall ? 32 : 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmall ? 16 : 24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: iconSize),
                  ),
                  SizedBox(height: isSmall ? 24 : 32),
                  Text(
                    AppLocalizations.of(context)!.downloadFailed, 
                    style: TextStyle(fontSize: isSmall ? 24 : 28, fontWeight: FontWeight.w600, letterSpacing: -0.8, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withValues(alpha: 0.8), height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: isSmall ? 32 : 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _buildInlineFilledButton(
                          context,
                          onPressed: () {
                            setState(() {
                              _error = null;
                              _metadata = null;
                              _session = null;
                              _progress = null;
                            });
                          },
                          label: AppLocalizations.of(context)!.tryAgain,
                          isGrey: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInlineFilledButton(
                          context,
                          onPressed: () => Navigator.pop(context),
                          label: AppLocalizations.of(context)!.close,
                          isPrimary: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildErrorDisplay(BuildContext context) {
    if (_error == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.error.withValues(alpha: 0.15),
            theme.colorScheme.error.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.downloadFailed,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: theme.colorScheme.error.withValues(alpha: 0.8),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _error = null),
              icon: Icon(Icons.close_rounded, color: theme.colorScheme.error, size: 20),
              hoverColor: theme.colorScheme.error.withValues(alpha: 0.1),
            ),
          ],
        ),
      ),
    );
  }



  Future<void> _exportCert(Certificate cert, String prefix) async {
    if (kIsWeb) return;
    
    try {
      final eid = await widget.profileManager.getEid().catchError((_) => 'unknown');
      if (!mounted) return;
      final filename = '$prefix.$eid.der';
      
      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: AppLocalizations.of(context)!.saveCertificate,
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['der'],
      );
      
      if (outputFile != null) {
        await io.File(outputFile).writeAsBytes(cert.encode());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.savedSuccessfully)));
        }
      }
    } catch (e) {
      _log.severe('Export error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export error: $e')));
      }
    }
  }

  Future<void> _notifyInstallationReported({
    required AuthenticateResponseOk? authBefore,
    AuthenticateResponseOk? authAfter,
    String? installResult,
    int? bppSize,
    PendingNotification? notification,
  }) async {
    return PluginManager().notifyInstallationReported(
      InstallationReportContext(
        session: _session,
        authBefore: authBefore,
        authAfter: authAfter,
        installResult: installResult,
        bppSize: bppSize,
        notification: notification,
      ),
    );
  }

  void _handleInstallationFailure(
    dynamic e,
    AuthenticateResponseOk? authBefore, {
    int? bppSize,
    StackTrace? stackTrace,
  }) {
    _log.severe("Download failed: $e", e, stackTrace);
    if (mounted) {
      setState(() {
        _isLoading = false;
        String errMsg = e.toString();
        if (e is AppException) {
          final local = AppLocalizations.of(context)!;
          switch (e.code) {
            case AppErrorCode.ERROR_BLUETOOTH_TIMEOUT:
              errMsg = local.errorBluetoothTimeout;
              break;
            case AppErrorCode.ERROR_OMAPI_SECURITYEXCEPTION:
            case AppErrorCode.ERROR_OMAPI_PERMISSION_DENIED:
              errMsg = local.errorOmapiSecurity;
              break;
            case AppErrorCode.ERROR_APPLICATION_NOT_FOUND:
              errMsg = local.errorApplicationNotFound;
              break;
            default:
              if (e.message != null) errMsg = e.message!;
          }
        }
        _error = errMsg;
      });
    }

    PendingNotification? notification;
    if (e is InstallationException) {
      notification = e.notification;
    }
    
    if (authBefore != null) {
      _notifyInstallationReported(
        authBefore: authBefore,
        installResult: e.toString(),
        bppSize: bppSize,
        notification: notification,
      );
    }
  }

}
