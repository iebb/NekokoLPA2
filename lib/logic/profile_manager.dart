import 'dart:typed_data';
import 'dart:convert';
import '../plugins/session_plugin.dart';

import 'package:flutter/foundation.dart';
import '../utils/profile_tag_utils.dart';
import '../adapter/euicc_adapter.dart';
import '../adapter/omapi/omapi_safety.dart';
import '../models/euicc_profile.dart';
import '../models/asn1/rsp_definitions.g.dart';
import '../models/asn1/simple_reader.dart';
import '../utils/hex_utils.dart';
import '../utils/imei_codec.dart';
import '../utils/apdu_exception.dart';
import '../utils/error_codes.dart';

import '../settings/app_settings.dart';
import 'package:logging/logging.dart';

class InstallationException implements Exception {
  final String message;
  final PendingNotification? notification;
  InstallationException(this.message, {this.notification});
  @override
  String toString() => message;
}

class NxpMemoryInfo {
  final int availableBytes;
  final int totalOrUnknownBytes;
  final int volatileBytes;
  final int reservedBlocks;
  final String firmwareVersion;
  final String? osInformation;

  NxpMemoryInfo({
    required this.availableBytes,
    required this.totalOrUnknownBytes,
    required this.volatileBytes,
    required this.reservedBlocks,
    required this.firmwareVersion,
    this.osInformation,
  });

  String get modelName {
    if (firmwareVersion.startsWith('84.')) return 'SN110U';
    if (firmwareVersion.startsWith('98.86.')) return 'SN220E';
    if (firmwareVersion.startsWith('98.')) return 'SN220U';
    if (firmwareVersion.startsWith('5.')) return 'NXP v1 (Hubble)';
    if (firmwareVersion.startsWith('82.')) return 'NXP v2';
    if (firmwareVersion.startsWith('83.')) return 'NXP v3';
    return 'Unknown NXP Chip';
  }
}

class ProfileManager {
  static final Logger _log = Logger('ProfileManager');
  final Adapter adapter;
  final List<SessionPlugin> _sessionPlugins = [];

  final Map<String, NxpMemoryInfo> nxpInfos = {};

  ProfileManager(this.adapter);

  void addSessionPlugin(SessionPlugin plugin) {
    if (!_sessionPlugins.any((p) => p.id == plugin.id)) {
      _sessionPlugins.add(plugin);
    }
  }

  void removeSessionPlugin(String id) {
    _sessionPlugins.removeWhere((p) => p.id == id);
  }

  // Cache working AID per reader ID: ReaderID -> {aid, atr}
  final Map<String, Map<String, String>> _workingAidCache = {};

  String? getWorkingAid(String readerId) {
    final cached = _workingAidCache[readerId];
    // Return if exists. Validation happens on connect mainly, but we can return raw pending value too.
    // If user wants to toggle, they just toggle what's there.
    return cached?['aid'];
  }

  void setWorkingAid(String readerId, String aid) {
    // Force update. Binds to whatever current ATR is or empty if not yet connected (will be validated/discarded on connect if mismatch)
    // Actually, if we are switching, we are likely connected.
    _workingAidCache[readerId] = {'aid': aid, 'atr': adapter.lastAtr ?? ''};
  }

  void _logAsn1Request(dynamic request) {
    if (AppSettings().decodeAsn1) {
      _log.info("ASN.1 >>\n$request");
    }
  }

  void _logAsn1Response(dynamic response) {
    if (AppSettings().decodeAsn1) {
      _log.info("ASN.1 <<\n$response");
    }
  }

  Future<Channel> openSession() async {
    // User configured AIDs from settings
    final aidStrings = AppSettings().aids;
    final aids = <List<int>>[];

    final currentAtr = adapter.lastAtr?.toUpperCase() ?? "";
    final allAidStrings = List<String>.from(aidStrings);

    // Get extra AIDs from plugins (e.g. EstkPlugin)
    for (final plugin in _sessionPlugins) {
      allAidStrings.addAll(plugin.getExtraAids(currentAtr));
    }

    for (final s in allAidStrings) {
      try {
        final clean = s.replaceAll(RegExp(r'[^0-9a-fA-F]'), '').toUpperCase();
        if (clean.length % 2 == 0 && clean.isNotEmpty) {
          // eSTKme-specific AID check: skip if ATR doesn't match
          final isEstkAid = clean.startsWith("A06573746B");
          final isEstkAtr = RegExp(
            r'6573746B',
            caseSensitive: false,
          ).hasMatch(currentAtr);
          if (isEstkAid && !isEstkAtr) {
            continue;
          }
          aids.add(HexUtils.hexToBytes(clean).toList());
        }
      } catch (e) {
        _log.warning("Skipping invalid AID: $s");
      }
    }

    // Fallback if empty
    if (aids.isEmpty) {
      _log.warning("No valid AIDs in settings, using minimal fallback.");
      aids.add([
        0xA0,
        0x00,
        0x00,
        0x05,
        0x59,
        0x10,
        0x10,
        0xFF,
        0xFF,
        0xFF,
        0xFF,
        0x89,
        0x00,
        0x00,
        0x01,
        0x00,
      ]);
    }

    // Prioritize working AID for this reader (Ephemeral, tied to ATR)
    final readerName = adapter.connectedReader;
    if (readerName != null) {
      final cached = _workingAidCache[readerName.id];
      final currentAtr = adapter.lastAtr;

      final cachedAtr = cached?['atr'] ?? '';
      final atrMatches = currentAtr != null
          ? cachedAtr == currentAtr
          : cachedAtr.isEmpty;
      if (cached != null && atrMatches) {
        final workingAidHex = cached['aid'];
        if (workingAidHex != null) {
          try {
            final workingBytes = HexUtils.hexToBytes(workingAidHex);
            // Move to front if exists, or add to front
            int index = -1;
            for (int i = 0; i < aids.length; i++) {
              if (listEquals(aids[i], workingBytes)) {
                index = i;
                break;
              }
            }
            if (index != -1) {
              aids.removeAt(index);
            }
            _log.info(
              "Prioritizing cached working AID for $readerName: $workingAidHex",
            );
            aids.insert(0, workingBytes.toList());
          } catch (e) {
            _log.warning("Invalid cached working AID ignored: $workingAidHex");
          }
        }
      } else {
        // Discard if ATR changed or disconnected (cached ATR mismatch)
        if (cached != null) {
          _log.info(
            "Discarding cached working AID for $readerName (ATR mismatch or reset)",
          );
          _workingAidCache.remove(readerName.id);
        }
      }
    }

    return _retrySafeCommand(() async {
      Channel ch;
      try {
        final aidHexList = aids
            .map((a) => HexUtils.bytesToHex(Uint8List.fromList(a)))
            .toList();
        ch = await adapter.openChannel(aids: aidHexList);
        if (ch.aid != null) {
          final aid = ch.aid!;
          _log.info("Channel opened with AID: $aid");
          if (readerName != null) {
            readerName.aid = aid;
            adapter.updateConnectedReader(readerName);

            _workingAidCache[readerName.id] = {
              "aid": aid,
              "atr": adapter.lastAtr ?? "",
            };
          }
          return ch;
        }

        if (aids.isNotEmpty) {
          _log.warning("Adapter returned channel without AID despite request.");
          await ch.close();
          throw Exception("AID not selected");
        }
        return ch;
      } catch (e) {
        _log.severe("Failed to open logical channel: $e");
        rethrow;
      }
    }, desc: "openSession");
  }

  Future<List<EuiccProfile>> listProfiles({Channel? useChannel}) async {
    // Conditionally include icon tags based on setting
    final loadIcons = AppSettings().loadProfileIcons;
    final tagList = loadIcons
        ? Uint8List.fromList([
            0x5A,
            0x4F,
            0x9F,
            0x70,
            0x90,
            0x91,
            0x92,
            0x93,
            0x94,
            0x95,
            0xB6,
            0xB7,
          ])
        : Uint8List.fromList([
            0x5A,
            0x4F,
            0x9F,
            0x70,
            0x90,
            0x91,
            0x92,
            0x95,
            0xB6,
            0xB7, // Omit 0x93, 0x94
          ]);

    return _retrySafeCommand(
      () async {
        return await _runOnChannel(useChannel, (channel) async {
          final request = ProfileInfoListRequest(tagList: tagList);
          _logAsn1Request(request);
          final requestData = request.encode();

          final responseData = await transmitLogicalApdu(channel, requestData);

          final responseObj = await compute((data) {
            final resp = ProfileInfoListResponse.decode(data);
            return resp;
          }, responseData);
          _logAsn1Response(responseObj);

          if (responseObj.profileInfoListError != null) {
            final err = responseObj.profileInfoListError!;
            throw Exception(
              'GetProfilesInfo failed with error code: ${err.name} (${err.value})',
            );
          }

          final profilesRaw = responseObj.profileInfoListOk ?? [];
          return await compute(_mapProfiles, profilesRaw);
        });
      },
      desc: "listProfiles",
      retryAidErrors: useChannel == null,
    );
  }

  Future<bool> enableProfile(String iccid, {Channel? useChannel}) async {
    const int maxAttempts = 10;
    int attempt = 0;
    bool commandSubmitted = false;
    final managesSwitchMarker = useChannel == null;

    if (managesSwitchMarker) {
      await adapter.setProfileSwitchInProgress(true);
    }
    try {
      while (true) {
        try {
          return await _runOnChannel(useChannel, (channel) async {
            bool isRefresh = false;
            String iccidHex = iccid;
            if (iccidHex.length % 2 != 0) iccidHex += 'F';
            final iccidBytes = HexUtils.hexToBytes(
              HexUtils.swapNibbles(iccidHex),
            );

            final request = EnableProfileRequest(
              profileIdentifier: EnableProfileRequest_profileIdentifier(
                iccid: iccidBytes,
              ),
              refreshFlag: AppSettings().disableRefreshFlags
                  ? false
                  : adapter.requiresRefresh,
            );
            _logAsn1Request(request);
            var requestData = request.encode();

            try {
              commandSubmitted = true;
              final responseData = await transmitLogicalApdu(
                channel,
                requestData,
              );
              final resp = EnableProfileResponse.decode(responseData);
              _logAsn1Response(resp);
              if (resp.enableResult != null &&
                  resp.enableResult != EnableProfileResponse_enableResult.ok &&
                  resp.enableResult !=
                      EnableProfileResponse_enableResult
                          .profileNotInDisabledState) {
                throw Exception('ENABLE_FAILED:${resp.enableResult?.name}');
              }
              if (request.refreshFlag == true) {
                await _handleRefresh(channel);
                isRefresh = true;
              } else {
                await _handleSoftRefresh(channel);
              }
              return isRefresh;
            } catch (e) {
              if (e is ProactiveRefreshException) {
                _markRefreshing();
                _log.info(
                  "Got 91xx status; deferring recovery to the next fresh session.",
                );
                return true;
              }
              rethrow;
            }
          });
        } catch (e) {
          if (e is CardBusyException &&
              attempt < maxAttempts &&
              canAutomaticallyRetryProfileSwitch(
                e,
                commandSubmitted: commandSubmitted,
              )) {
            attempt++;
            _log.info(
              "enableProfile: Card busy (6881), retry attempt $attempt/$maxAttempts...",
            );
            await Future.delayed(const Duration(milliseconds: 500));
            continue;
          }
          rethrow;
        }
      }
    } finally {
      if (managesSwitchMarker) {
        await adapter.setProfileSwitchInProgress(false);
      }
    }
  }

  Future<bool> disableProfile(String iccid, {Channel? useChannel}) async {
    const int maxAttempts = 10;
    int attempt = 0;
    bool commandSubmitted = false;
    final managesSwitchMarker = useChannel == null;

    if (managesSwitchMarker) {
      await adapter.setProfileSwitchInProgress(true);
    }
    try {
      while (true) {
        try {
          return await _runOnChannel(useChannel, (channel) async {
            bool isRefresh = false;
            String iccidHex = iccid;
            if (iccidHex.length % 2 != 0) iccidHex += 'F';
            final iccidBytes = HexUtils.hexToBytes(
              HexUtils.swapNibbles(iccidHex),
            );

            final request = DisableProfileRequest(
              profileIdentifier: DisableProfileRequest_profileIdentifier(
                iccid: iccidBytes,
              ),
              refreshFlag: AppSettings().disableRefreshFlags
                  ? false
                  : adapter.requiresRefresh,
            );
            _logAsn1Request(request);
            final requestData = request.encode();

            try {
              commandSubmitted = true;
              final responseData = await transmitLogicalApdu(
                channel,
                requestData,
              );
              final resp = DisableProfileResponse.decode(responseData);
              _logAsn1Response(resp);
              if (resp.disableResult != null &&
                  resp.disableResult !=
                      DisableProfileResponse_disableResult.ok &&
                  resp.disableResult !=
                      DisableProfileResponse_disableResult
                          .profileNotInEnabledState) {
                throw Exception('DISABLE_FAILED:${resp.disableResult?.name}');
              }
              if (request.refreshFlag == true) {
                await _handleRefresh(channel);
                isRefresh = true;
              } else {
                await _handleSoftRefresh(channel);
              }
              return isRefresh;
            } catch (e) {
              if (e is ProactiveRefreshException) {
                _markRefreshing();
                _log.info(
                  "Got 91xx status; deferring recovery to the next fresh session.",
                );
                return true;
              }
              rethrow;
            }
          });
        } catch (e) {
          if (e is CardBusyException &&
              attempt < maxAttempts &&
              canAutomaticallyRetryProfileSwitch(
                e,
                commandSubmitted: commandSubmitted,
              )) {
            attempt++;
            _log.info(
              "disableProfile: Card busy (6881), retry attempt $attempt/$maxAttempts...",
            );
            await Future.delayed(const Duration(milliseconds: 500));
            continue;
          }
          rethrow;
        }
      }
    } finally {
      if (managesSwitchMarker) {
        await adapter.setProfileSwitchInProgress(false);
      }
    }
  }

  Future<void> renameProfile(
    String iccid,
    String nickname, {
    Channel? useChannel,
  }) async {
    return _runOnChannel(useChannel, (channel) async {
      String iccidHex = iccid;
      if (iccidHex.length % 2 != 0) iccidHex += 'F';
      final iccidBytes = HexUtils.hexToBytes(HexUtils.swapNibbles(iccidHex));

      final requestData = _encodeNicknameRequestUtf8(iccidBytes, nickname);

      if (AppSettings().decodeAsn1) {
        try {
          final node = SimpleAsn1Reader(requestData).readNext();
          if (node != null) _logAsn1Request(node);
        } catch (_) {}
      }

      try {
        await transmitLogicalApdu(channel, requestData);
      } catch (e) {
        if (e is ProactiveRefreshException) {
          await _handleSoftRefresh(channel);
          return;
        }
        rethrow;
      }
    });
  }

  Future<void> deleteProfile(String iccid, {Channel? useChannel}) async {
    return _runOnChannel(useChannel, (channel) async {
      String iccidHex = iccid;
      final iccidBytes = HexUtils.hexToBytes(HexUtils.swapNibbles(iccidHex));

      final request = DeleteProfileRequest(iccid: iccidBytes);
      _logAsn1Request(request);
      final requestData = request.encode();

      try {
        final responseData = await transmitLogicalApdu(channel, requestData);
        final resp = DeleteProfileResponse.decode(responseData);
        _logAsn1Response(resp);
        if (resp.deleteResult != null &&
            resp.deleteResult != DeleteProfileResponse_deleteResult.ok) {
          throw Exception('DELETE_FAILED:${resp.deleteResult?.name}');
        }
      } catch (e) {
        if (e is ProactiveRefreshException) {
          await _handleSoftRefresh(channel);
          return;
        }
        rethrow;
      }
    });
  }

  Future<String> getEid({Channel? useChannel}) async {
    return _retrySafeCommand(
      () async {
        return await _runOnChannel(useChannel, (channel) async {
          final request = GetEuiccDataRequest(
            tagList: Uint8List.fromList([0x5A]),
          );
          _logAsn1Request(request);
          final requestData = request.encode();

          try {
            final responseData = await transmitLogicalApdu(
              channel,
              requestData,
            );

            final responseObj = GetEuiccDataResponse.decode(responseData);
            _logAsn1Response(responseObj);
            if (responseObj.eidValue == null) {
              throw Exception("EID not returned by eUICC");
            }
            final eid = HexUtils.bytesToHex(responseObj.eidValue!);
            for (final p in _sessionPlugins) {
              await p.afterCommand('getEid', {}, eid, channel);
            }
            return eid;
          } catch (e) {
            for (final p in _sessionPlugins) {
              await p.afterCommand('getEid', {}, e, channel);
            }
            rethrow;
          }
        });
      },
      desc: "getEid",
      retryAidErrors: useChannel == null,
    );
  }

  Future<EUICCInfo2> getEuiccInfo2({Channel? useChannel}) async {
    return _retrySafeCommand(
      () async {
        return await _runOnChannel(useChannel, (channel) async {
          final request = GetEuiccInfo2Request();
          _logAsn1Request(request);
          final requestData = request.encode();

          final responseData = await transmitLogicalApdu(channel, requestData);
          final resp = EUICCInfo2.decode(responseData);

          _log.info(
            "Standard eUICCInfo2 extCardResource: ${resp.extCardResource}",
          );

          try {
            final currentEid = channel.adapter.currentEid;
            if (currentEid != null && currentEid.startsWith("89043051")) {
              // Attempt to fetch NXP proprietary memory info
              // GET DATA (NXP_PROPRIETARY = 0xFE), Data = 0xDF25 (MEMORY_INFORMATION)
              final nxpRawResp = await _transmitApdu(
                channel,
                0x80,
                0xCA,
                0x00,
                0xFE,
                Uint8List.fromList([0xDF, 0x25]),
              );
              final nxpResp = _checkSwAndGetData(nxpRawResp);

              if (nxpResp.length >= 5) {
                int nxpAvailable = 0;
                int nxpTotal = 0;
                int nxpVolatile = 0;
                int b3Value = 0;
                int b14Value = 0;
                // The data consists of 6-byte chunks starting at index 5.
                for (int i = 5; i + 5 < nxpResp.length; i += 6) {
                  int b = nxpResp[i];
                  // 4-byte integer (big-endian) at i+2 to i+5
                  int val =
                      (nxpResp[i + 2] << 24) |
                      (nxpResp[i + 3] << 16) |
                      (nxpResp[i + 4] << 8) |
                      nxpResp[i + 5];
                  if (b == 0) {
                    nxpAvailable += val;
                  } else if (b == 1) {
                    nxpVolatile = val;
                  } else if (b == 2) {
                    nxpTotal = val;
                  } else if (b == 3) {
                    b3Value = val;
                  } else if (b == 14) {
                    b14Value = val;
                  }
                }

                String fwVersion =
                    resp.euiccFirmwareVersion
                        ?.map((b) => b.toString())
                        .join('.') ??
                    "";

                int overheadBytes = b14Value;
                if (fwVersion != "98.0.22" && fwVersion != "98.16.25") {
                  overheadBytes = b3Value * 16;
                }

                String? osInfoParsed;
                try {
                  Uint8List? lastOsInfoResp;
                  for (int attempt = 1; attempt <= 3; attempt++) {
                    final osInfoRawResp = await _transmitApdu(
                      channel,
                      0x80,
                      0xCA,
                      0x00,
                      0xFE,
                      Uint8List.fromList([0xDF, 0x31]),
                    );
                    lastOsInfoResp = _checkSwAndGetData(osInfoRawResp);
                    _log.info(
                      "OS_INFORMATION fetch attempt $attempt: ${HexUtils.bytesToHex(lastOsInfoResp)}",
                    );
                  }
                  final osInfoResp = lastOsInfoResp!;

                  // Parse the DF31 TLV
                  int idx = 0;
                  if (idx < osInfoResp.length && osInfoResp[idx] == 0xFE) {
                    idx += 2; // Skip FE and length
                  }
                  if (idx < osInfoResp.length - 1 &&
                      osInfoResp[idx] == 0xDF &&
                      osInfoResp[idx + 1] == 0x31) {
                    idx += 3; // Skip DF 31 and length
                  }

                  List<String> parts = [];
                  while (idx < osInfoResp.length) {
                    int tag = osInfoResp[idx++];
                    if (idx >= osInfoResp.length) break;
                    int len = osInfoResp[idx++];
                    if (idx + len > osInfoResp.length) break;

                    List<int> valBytes = osInfoResp.sublist(idx, idx + len);
                    String strVal = valBytes
                        .where((b) => b > 0 && b >= 32 && b <= 126)
                        .map((b) => String.fromCharCode(b))
                        .join('');
                    bool isPrintable = valBytes.every(
                      (b) => b == 0 || (b >= 32 && b <= 126),
                    );

                    String displayVal = (isPrintable && strVal.isNotEmpty)
                        ? strVal
                        : "0x${HexUtils.bytesToHex(Uint8List.fromList(valBytes)).toUpperCase()}";

                    String tagLabel;
                    switch (tag) {
                      case 0x81:
                        tagLabel = "ROM Version";
                        break;
                      case 0x82:
                        tagLabel = "Platform Build";
                        break;
                      case 0x83:
                        tagLabel = "OS Version";
                        break;
                      case 0x84:
                        tagLabel = "OS Build";
                        break;
                      case 0x85:
                        tagLabel = "Patch Version";
                        break;
                      case 0x86:
                        tagLabel = "Patch Build";
                        break;
                      default:
                        tagLabel = "Tag ${tag.toRadixString(16).toUpperCase()}";
                    }
                    parts.add("$tagLabel: $displayVal");
                    idx += len;
                  }

                  if (parts.isNotEmpty) {
                    osInfoParsed = parts.join('\n');
                  } else {
                    osInfoParsed =
                        "Raw Data: ${HexUtils.bytesToHex(osInfoResp).toUpperCase()}";
                  }
                } catch (e) {
                  _log.warning("Could not fetch OS_INFORMATION: $e");
                }

                nxpInfos[currentEid] = NxpMemoryInfo(
                  availableBytes: nxpAvailable,
                  totalOrUnknownBytes: nxpTotal,
                  volatileBytes: nxpVolatile,
                  reservedBlocks: overheadBytes ~/ 16,
                  firmwareVersion: fwVersion,
                  osInformation: osInfoParsed,
                );

                // Deduplicate overhead
                nxpAvailable -= overheadBytes;
                if (nxpAvailable < 0) nxpAvailable = 0;

                final newExt = ExtendedCardResource(
                  installedApplication:
                      resp.extCardResource?.installedApplication,
                  freeNonVolatileMemory: nxpAvailable,
                  freeVolatileMemory: resp.extCardResource?.freeVolatileMemory,
                );

                final modifiedResp = EUICCInfo2(
                  baseProfilePackageVersion: resp.baseProfilePackageVersion,
                  lowestSvn: resp.lowestSvn,
                  euiccFirmwareVersion: resp.euiccFirmwareVersion,
                  extCardResource: newExt,
                  uiccCapability: resp.uiccCapability,
                  ts102241Version: resp.ts102241Version,
                  globalplatformVersion: resp.globalplatformVersion,
                  euiccRspCapability: resp.euiccRspCapability,
                  euiccCiPKIdListForVerification:
                      resp.euiccCiPKIdListForVerification,
                  euiccCiPKIdListForSigning: resp.euiccCiPKIdListForSigning,
                  euiccCategory: resp.euiccCategory,
                  forbiddenProfilePolicyRules: resp.forbiddenProfilePolicyRules,
                  ppVersion: resp.ppVersion,
                  sasAcreditationNumber: resp.sasAcreditationNumber,
                  certificationDataObject: resp.certificationDataObject,
                  treProperties: resp.treProperties,
                  treProductReference: resp.treProductReference,
                  additionalProfilePackageVersions:
                      resp.additionalProfilePackageVersions,
                  lpaMode: resp.lpaMode,
                  euiccCiPKIdListForSigningV3: resp.euiccCiPKIdListForSigningV3,
                  additionalEuiccInfo: resp.additionalEuiccInfo,
                  highestSvn: resp.highestSvn,
                  iotSpecificInfo: resp.iotSpecificInfo,
                );

                _log.info("NXP memory info applied: $nxpAvailable bytes free.");
                _logAsn1Response(modifiedResp);
                return modifiedResp;
              }
            }
          } catch (e) {
            _log.info("NXP memory info not available or failed: $e");
          }

          _logAsn1Response(resp);
          return resp;
        });
      },
      desc: "getEuiccInfo2",
      retryAidErrors: useChannel == null,
    );
  }

  Future<List<PendingNotification>> retrieveNotifications({
    Channel? useChannel,
  }) async {
    return _retrySafeCommand(
      () async {
        return await _runOnChannel(useChannel, (channel) async {
          _log.info("Notification strategy: ${adapter.notificationStrategy}");
          if (adapter.notificationStrategy == NotificationStrategy.twoStep) {
            _log.info("Using two-step notification listing (skeletons)...");
            final metadatas = await listNotifications(useChannel: channel);
            return metadatas.map((m) => createSkeleton(m)).toList();
          }

          // Combined strategy (default)
          final request = RetrieveNotificationsListRequest(
            searchCriteria: null,
          );
          _logAsn1Request(request);
          final requestData = request.encode();

          final responseData = await transmitLogicalApdu(channel, requestData);
          final resp = RetrieveNotificationsListResponse.decode(responseData);
          _logAsn1Response(resp);
          if (resp.notificationsListResultError != null) {
            final err = resp.notificationsListResultError!;
            throw Exception(
              "RetrieveNotificationsList failed: ${err.name} (${err.value})",
            );
          }
          return resp.notificationList ?? [];
        });
      },
      desc: "retrieveNotifications",
      retryAidErrors: useChannel == null,
    );
  }

  static PendingNotification createSkeleton(NotificationMetadata meta) {
    if ((meta.profileManagementOperation?.value ?? 0) &
            NotificationEvent.notificationInstall !=
        0) {
      return PendingNotification(
        profileInstallationResult: ProfileInstallationResult(
          profileInstallationResultData: ProfileInstallationResultData(
            notificationMetadata: meta,
          ),
        ),
      );
    } else {
      return PendingNotification(
        otherSignedNotification: OtherSignedNotification(
          tbsOtherNotification: meta,
        ),
      );
    }
  }

  static NotificationMetadata? extractMetadata(PendingNotification n) {
    if (n.profileInstallationResult != null) {
      return n
          .profileInstallationResult
          ?.profileInstallationResultData
          ?.notificationMetadata;
    }
    if (n.otherSignedNotification != null) {
      return n.otherSignedNotification?.tbsOtherNotification;
    }
    return null;
  }

  Future<PendingNotification> resolveNotification(
    PendingNotification n, {
    Channel? useChannel,
  }) async {
    if (n.asn1 != null) return n; // Already resolved

    final meta = extractMetadata(n);
    if (meta == null || meta.seqNumber == null) return n;

    _log.info("Resolving skeleton notification ${meta.seqNumber}...");
    return await retrieveNotification(meta.seqNumber!, useChannel: useChannel);
  }

  Future<List<NotificationMetadata>> listNotifications({
    Channel? useChannel,
  }) async {
    return _retrySafeCommand(() async {
      return await _runOnChannel(useChannel, (channel) async {
        final request = ListNotificationRequest();
        _logAsn1Request(request);
        final requestData = request.encode();

        final responseData = await transmitLogicalApdu(channel, requestData);
        final resp = ListNotificationResponse.decode(responseData);
        _logAsn1Response(resp);
        if (resp.listNotificationsResultError != null) {
          final err = resp.listNotificationsResultError!;
          throw Exception(
            "ListNotification failed: ${err.name} (${err.value})",
          );
        }
        return resp.notificationMetadataList ?? [];
      });
    }, desc: "listNotifications");
  }

  Future<PendingNotification> retrieveNotification(
    int seqNumber, {
    Channel? useChannel,
  }) async {
    return _retrySafeCommand(() async {
      return await _runOnChannel(useChannel, (channel) async {
        final request = RetrieveNotificationsListRequest(
          searchCriteria: RetrieveNotificationsListRequest_searchCriteria(
            seqNumber: seqNumber,
          ),
        );
        _logAsn1Request(request);
        final requestData = request.encode();

        final responseData = await transmitLogicalApdu(channel, requestData);
        final resp = RetrieveNotificationsListResponse.decode(responseData);
        _logAsn1Response(resp);
        if (resp.notificationsListResultError != null) {
          final err = resp.notificationsListResultError!;
          throw Exception(
            "RetrieveNotification failed for $seqNumber: ${err.name} (${err.value})",
          );
        }
        if (resp.notificationList == null || resp.notificationList!.isEmpty) {
          throw Exception("Notification $seqNumber not found");
        }
        return resp.notificationList!.first;
      });
    }, desc: "retrieveNotification");
  }

  Future<NotificationSentResponse_deleteNotificationStatus?> removeNotification(
    int seqNumber, {
    Channel? useChannel,
  }) async {
    final results = await removeNotifications([
      seqNumber,
    ], useChannel: useChannel);
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<NotificationSentResponse_deleteNotificationStatus?>>
  removeNotifications(List<int> seqNumbers, {Channel? useChannel}) async {
    return _runOnChannel(useChannel, (channel) async {
      final results = <NotificationSentResponse_deleteNotificationStatus?>[];
      for (final seq in seqNumbers) {
        final request = NotificationSentRequest(seqNumber: seq);
        _logAsn1Request(request);
        final requestData = request.encode();

        final responseData = await transmitLogicalApdu(channel, requestData);
        final resp = NotificationSentResponse.decode(responseData);
        _logAsn1Response(resp);

        results.add(resp.deleteNotificationStatus);
        _log.info(
          "Notification removed (Seq: $seq) Status: ${resp.deleteNotificationStatus?.name}",
        );
      }
      return results;
    });
  }

  Future<Uint8List> getEuiccChallenge({Channel? useChannel}) async {
    return _runOnChannel(useChannel, (channel) async {
      final eid = await getEid(useChannel: channel);
      _log.info(
        "getEuiccChallenge: evaluate plugins (total: ${_sessionPlugins.length})",
      );
      final activePlugins = <SessionPlugin>[];
      for (final p in _sessionPlugins) {
        final interested = await p.isInterested(adapter, eid);
        _log.info(
          "Plugin ${p.id} interested in getEuiccChallenge: $interested",
        );
        if (interested) {
          activePlugins.add(p);
        }
      }

      final params = <String, dynamic>{};
      for (final p in activePlugins) {
        await p.beforeCommand('getEuiccChallenge', params, channel);
      }

      final request = GetEuiccChallengeRequest();
      _logAsn1Request(request);
      final requestData = request.encode();

      final responseData = await transmitLogicalApdu(channel, requestData);
      final resp = GetEuiccChallengeResponse.decode(responseData);
      _logAsn1Response(resp);
      if (resp.euiccChallenge == null) throw Exception("No challenge returned");

      final result = resp.euiccChallenge!;
      for (final p in activePlugins) {
        await p.afterCommand('getEuiccChallenge', params, result, channel);
      }
      return result;
    });
  }

  Future<Uint8List> getEuiccInfo1({Channel? useChannel}) async {
    return _runOnChannel(useChannel, (channel) async {
      final request = GetEuiccInfo1Request();
      _logAsn1Request(request);
      final requestData = request.encode();

      final responseData = await transmitLogicalApdu(channel, requestData);
      final resp = EUICCInfo1.decode(responseData); // Validate structure
      _logAsn1Response(resp);
      return responseData;
    });
  }

  /// Reads MSISDN from the active profile on the basic channel.
  /// Tricky function: selects MF, USIM ADF, and reads EF_MSISDN.
  Future<String?> readActiveMsisdn() async {
    // try {
    //   _log.info("Attempting to read active MSISDN from basic channel...");

    //   // 1. Select MF (3F00)
    //   await adapter.sendApdu(Uint8List.fromList([0x00, 0xA4, 0x00, 0x04, 0x02, 0x3F, 0x00]));

    //   // 2. Select DF_TELECOM (7F10)
    //   // Check if successful, if not try USIM ADF
    //   bool parentSelected = false;
    //   Uint8List resp = await adapter.sendApdu(Uint8List.fromList([0x00, 0xA4, 0x00, 0x04, 0x02, 0x7F, 0x10]));
    //   if (_isSuccessSw(resp)) {
    //      parentSelected = true;
    //   } else {
    //      _log.info("DF_TELECOM select failed (${HexUtils.bytesToHex(resp)}), trying USIM ADF...");
    //      // Fallback to USIM ADF
    //      final selectUsim = Uint8List.fromList([0x00, 0xA4, 0x04, 0x00, 0x07, 0xA0, 0x00, 0x00, 0x00, 0x87, 0x10, 0x02]);
    //      resp = await adapter.sendApdu(selectUsim);
    //      if (_isSuccessSw(resp)) {
    //        parentSelected = true;
    //      } else {
    //        _log.warning("USIM ADF select also failed: ${HexUtils.bytesToHex(resp)}");
    //      }
    //   }

    //   if (!parentSelected) {
    //      _log.warning("Could not select DF_TELECOM or USIM ADF. Aborting MSISDN read.");
    //      return null;
    //   }

    //   // 3. Select EF_MSISDN (6F40)
    //   final selectResp = await adapter.sendApdu(Uint8List.fromList([0x00, 0xA4, 0x00, 0x04, 0x02, 0x6F, 0x40]));
    //   if (!_isSuccessSw(selectResp)) {
    //      _log.info("EF.MSISDN not found or select failed: ${HexUtils.bytesToHex(selectResp)}");
    //      return null;
    //   }

    //   int recordLength = 0;
    //   // Parse FCP/Header for record length
    //   // ... same parsing logic ...
    //   final fcp = selectResp.sublist(0, selectResp.length - 2);

    //   // Try to find record length in FCP (Tag 82)
    //   for (int i = 0; i < fcp.length - 2; i++) {
    //     if (fcp[i] == 0x82) {
    //       int len = fcp[i+1];
    //       // 82 02 41 21 (Transparent) or 82 05 42 21 00 1C 01 (Linear Fixed)
    //       // Byte 1: File descriptor byte (42 = Linear Fixed, 41 = Transparent)
    //       // Byte 2: Data coding byte (21 generally)
    //       // Byte 3,4: Record length (2 bytes for Linear Fixed)
    //       // Byte 5: Number of records

    //       // Looking at provided hex: 82 05 42 21 00 1C 01
    //       // i+0: 82 (Tag)
    //       // i+1: 05 (Length)
    //       // i+2: 42 (File Type: Linear Fixed)
    //       // i+3: 21 (Data coding)
    //       // i+4: 00 (Rec Len High)
    //       // i+5: 1C (Rec Len Low) -> This is what we want!
    //       // i+6: 01 (Num Recs)

    //       if (len >= 5 && i + 1 + len <= fcp.length) {
    //           // Check if Linear Fixed (0x42) or Cyclic (0x46)
    //           // Actually ISO/IEC 7816-4 says:
    //           // Tag 82 (File Descriptor)
    //           // 1st byte: File descriptor byte.
    //           //    - Bit 7=0: Working EF
    //           //         Bits 3-1: Structure (001=Transp, 010=Linear Fixed, 110=Cyclic)
    //           //         0x42 (0100 0010) => Linear Fixed.
    //           //         0x46 (0100 0110) => Cyclic.
    //           // 2nd byte: Data coding byte.
    //           // 3rd & 4th byte: Record length (16 bit big endian)
    //           // 5th byte: Number of records

    //          if (len >= 5) {
    //              int rLenHigh = fcp[i+4];
    //              int rLenLow = fcp[i+5];
    //              recordLength = (rLenHigh << 8) | rLenLow;
    //          }
    //          break;
    //       }
    //     }
    //   }
    //   // Old SIM fallback
    //   if (recordLength == 0 && fcp.length >= 14) {
    //     // In old GSM response, byte 13 (index 13?) is file length?
    //     // byte 14 is record length in some specs?
    //     // Let's stick to Safe default if FCP parse fails, effectively 0x1C or user standard.
    //   }

    //   if (recordLength == 0) {
    //     _log.warning("Could not determine record length, falling back to 0x1C");
    //     recordLength = 0x1C;
    //   } else {
    //     _log.info("Detected record length: $recordLength");
    //   }

    //   // 4. Read Record 1
    //   final readResp = await adapter.sendApdu(Uint8List.fromList([0x00, 0xB2, 0x01, 0x04, recordLength]));

    //   if (readResp.length < 2) return null;
    //   final sw1 = readResp[readResp.length - 2];
    //   final sw2 = readResp[readResp.length - 1];

    //   if (sw1 == 0x90 && sw2 == 0x00) {
    //     final data = readResp.sublist(0, readResp.length - 2);
    //     return _decodeMsisdn(data);
    //   } else {
    //     _log.info("Read EF.MSISDN failed: ${HexUtils.bytesToHex(readResp)}");
    //   }
    // } catch (e) {
    //   _log.warning("Failed to read MSISDN: $e");
    // }
    return null;
  }

  Future<Uint8List> authenticateServerRaw({
    required Uint8List serverSigned1,
    required Uint8List serverSignature1,
    required Uint8List euiccCiPKIdToBeUsed,
    required Uint8List serverCertificate,
    required String matchingId,
    Uint8List? tac,
    Uint8List? imei,
    Channel? useChannel,
  }) async {
    return _runOnChannel(useChannel, (channel) async {
      // TAC-only remains the default. A full IMEI is sent when explicitly
      // supplied by the caller or when the user entered 15 digits in settings.
      final settings = AppSettings();
      final actualTac = tac ?? await settings.getTac();
      final actualImei = imei == null
          ? await settings.getDeviceInfoImei()
          : encodeDeviceInfoImei(imei);

      // Construct DeviceInfo
      final deviceInfo = DeviceInfo(
        tac: actualTac,
        deviceCapabilities: DeviceCapabilities(),
        imei: actualImei,
      );

      // Build AuthenticateServerRequest using generated model

      final request = AuthenticateServerRequest(
        serverSigned1: ServerSigned1.decode(serverSigned1),
        // Strip tag from serverSignature1 as generated code adds it
        serverSignature1: SimpleAsn1Reader(serverSignature1).readNext()?.value,
        // euiccCiPKIdToBeUsed and serverCertificate are now properly typed
        euiccCiPKIdToBeUsed: SimpleAsn1Reader(
          euiccCiPKIdToBeUsed,
        ).readNext()?.value,
        serverCertificate: Certificate.decode(serverCertificate),
        ctxParams1: CtxParams1(
          ctxParamsForCommonAuthentication: CtxParamsForCommonAuthentication(
            matchingId: matchingId,
            deviceInfo: deviceInfo,
          ),
        ),
      );
      _logAsn1Request(request);
      final requestData = request.encode();
      _log.info(
        "Sending AuthenticateServerRequest (${requestData.length} bytes)",
      );

      return await transmitLogicalApdu(channel, requestData);
    });
  }

  Future<AuthenticateResponseOk> authenticateServer({
    required Uint8List serverSigned1,
    required Uint8List serverSignature1,
    required Uint8List euiccCiPKIdToBeUsed,
    required Uint8List serverCertificate,
    required String matchingId,
    Uint8List? tac,
    Uint8List? imei,
    Channel? useChannel,
  }) async {
    return _runOnChannel(useChannel, (channel) async {
      final eid = await getEid(useChannel: channel);
      _log.info(
        "authenticateServer: evaluate plugins (total: ${_sessionPlugins.length})",
      );
      final activePlugins = <SessionPlugin>[];
      for (final p in _sessionPlugins) {
        final interested = await p.isInterested(adapter, eid);
        _log.info(
          "Plugin ${p.id} interested in authenticateServer: $interested",
        );
        if (interested) {
          activePlugins.add(p);
        }
      }

      final params = {
        'serverSigned1': serverSigned1,
        'serverSignature1': serverSignature1,
        'euiccCiPKIdToBeUsed': euiccCiPKIdToBeUsed,
        'serverCertificate': serverCertificate,
        'matchingId': matchingId,
        'tac': tac,
        'imei': imei,
      };

      for (final p in activePlugins) {
        await p.beforeCommand('authenticateServer', params, channel);
      }

      try {
        final responseData = await authenticateServerRaw(
          serverSigned1: serverSigned1,
          serverSignature1: serverSignature1,
          euiccCiPKIdToBeUsed: euiccCiPKIdToBeUsed,
          serverCertificate: serverCertificate,
          matchingId: matchingId,
          tac: tac,
          imei: imei,
          useChannel: channel,
        );

        final resp = AuthenticateServerResponse.decode(responseData);
        _logAsn1Response(resp);

        if (resp.authenticateResponseError != null) {
          final err = resp.authenticateResponseError!;
          final errorCode = err.authenticateErrorCode;
          final errorMsg = errorCode != null
              ? "${errorCode.name} (${errorCode.value})"
              : "Unknown";
          _log.severe("AuthenticateServer error: $errorMsg");
          throw Exception("AuthenticateServer failed: $errorMsg");
        }
        if (resp.authenticateResponseOk == null) {
          _log.severe("AuthenticateServer returned no OK response");
          throw Exception("AuthenticateServer returned no OK response");
        }

        _log.info("AuthenticateServer succeeded");
        final authOk = resp.authenticateResponseOk!;
        for (final p in activePlugins) {
          await p.afterCommand('authenticateServer', params, authOk, channel);
        }
        return authOk;
      } catch (e, stackTrace) {
        if (e is ApduException && e.sw1 == 0x6F && e.sw2 == 0x00) {
          _log.warning(
            "eUICC returned 6F00 for authenticateServer. This might be normal for some cards but usually indicates a parameter error.",
          );
        }
        _log.severe("AuthenticateServer exception: $e", e, stackTrace);
        for (final p in activePlugins) {
          await p.afterCommand('authenticateServer', params, e, channel);
        }
        rethrow;
      }
    });
  }

  Future<PrepareDownloadResponse> prepareDownload({
    required Uint8List smdpSigned2,
    required Uint8List smdpSignature2,
    required Uint8List smdpCertificate,
    Uint8List? hashCc,
    Channel? useChannel,
  }) async {
    return _runOnChannel(useChannel, (channel) async {
      final request = PrepareDownloadRequest(
        smdpSigned2: SmdpSigned2.decode(smdpSigned2),
        smdpSignature2: SimpleAsn1Reader(smdpSignature2).readNext()?.value,
        smdpCertificate: Certificate.decode(smdpCertificate),
        hashCc: hashCc,
      );
      _logAsn1Request(request);
      final requestData = request.encode();
      _log.info("Sending PrepareDownloadRequest (${requestData.length} bytes)");

      final responseData = await transmitLogicalApdu(channel, requestData);
      final resp = PrepareDownloadResponse.decode(responseData);
      _logAsn1Response(resp);

      if (resp.downloadResponseError != null) {
        final err = resp.downloadResponseError!;
        final errorCode = err.downloadErrorCode;
        final errorMsg = errorCode != null
            ? "${errorCode.name} (${errorCode.value})"
            : "Unknown";
        _log.severe("PrepareDownload error: $errorMsg");
        throw Exception("PrepareDownload failed: $errorMsg");
      }
      if (resp.downloadResponseOk == null) {
        throw Exception("PrepareDownload returned no OK response");
      }

      _log.info("PrepareDownload succeeded");
      return resp;
    });
  }

  Future<void> loadBoundProfilePackage(
    Uint8List bpp, {
    Channel? useChannel,
    void Function(int sent, int total)? onProgress,
    void Function(String message)? onStatusMessage,
  }) async {
    return _runOnChannel(useChannel, (channel) async {
      final segments = _decomposeBpp(bpp);
      final totalSize = bpp.length;
      int totalSentBytes = 0;

      final mss = AppSettings().mss;
      _log.info(
        "Loading BoundProfilePackage: totalBytes=$totalSize, "
        "segments=${segments.length}, mss=$mss",
      );

      try {
        for (int i = 0; i < segments.length; i++) {
          final segment = segments[i];
          _log.fine(
            "BPP segment ${i + 1}/${segments.length}: "
            "${segment.length} bytes",
          );

          int offset = 0;
          int blockNumber = 0; // Reset for each segment, 0-based as in lpac

          while (offset < segment.length) {
            int chunkSize = mss;
            if (offset + chunkSize > segment.length) {
              chunkSize = segment.length - offset;
            }

            final chunk = segment.sublist(offset, offset + chunkSize);
            final isLastBlockOfSegment = (offset + chunkSize == segment.length);

            // Following lpac/SGP.22 STORE DATA: P1=0x11 for more, 0x91 for last. P2=sequence.
            final p1 = isLastBlockOfSegment ? 0x91 : 0x11;
            final p2 = blockNumber & 0xFF;

            // Send chunk RAW without any extra wrapping.
            // The segments from _decomposeBpp already have the necessary tags (BF36, 87, 88, etc.)
            final response = await _transmitApdu(
              channel,
              0x80,
              0xE2,
              p1,
              p2,
              chunk,
            );

            _checkSwAndGetData(response);

            offset += chunkSize;
            totalSentBytes += chunkSize;
            blockNumber++;

            if (onProgress != null) {
              onProgress(totalSentBytes, totalSize);
            }
          }
        }
      } catch (e) {
        if (e is ApduException) {
          _log.warning(
            "BPP Load failed with APDU error: ${e.message} (SW=${e.sw1.toRadixString(16)}${e.sw2.toRadixString(16)}). searching for detailed error...",
          );
          _log.warning(
            "BPP progress at failure: sentBytes=$totalSentBytes, "
            "totalBytes=$totalSize",
          );
          onStatusMessage?.call("Analyzing installation failure...");
          await _handleInstallationFailure(channel);
        }
        rethrow;
      }
    });
  }

  Future<PendingNotification?> getLatestInstallNotification({
    Channel? useChannel,
  }) async {
    return _runOnChannel(useChannel, (channel) async {
      final request = RetrieveNotificationsListRequest(
        searchCriteria: RetrieveNotificationsListRequest_searchCriteria(
          profileManagementOperation: const NotificationEvent(
            NotificationEvent.notificationInstall,
          ),
        ),
      );
      _logAsn1Request(request);
      final requestData = request.encode();
      final responseData = await transmitLogicalApdu(channel, requestData);
      final resp = RetrieveNotificationsListResponse.decode(responseData);
      _logAsn1Response(resp);

      if (resp.notificationList != null && resp.notificationList!.isNotEmpty) {
        return resp.notificationList!.last;
      }
      return null;
    });
  }

  Future<void> _handleInstallationFailure(Channel channel) async {
    try {
      final notification = await getLatestInstallNotification(
        useChannel: channel,
      );
      if (notification != null) {
        final result = notification
            .profileInstallationResult
            ?.profileInstallationResultData
            ?.finalResult;
        if (result?.errorResult != null) {
          final err = result!.errorResult!;
          final cmdId = err.bppCommandId;
          final reason = err.errorReason;

          final cmdStr = cmdId != null ? cmdId.name : "Unknown Cmd";
          final reasonStr = reason != null ? reason.name : "Unknown Reason";

          _log.info("Found detailed failure: $reasonStr (Cmd: $cmdStr)");
          throw InstallationException(
            "Installation Failed: $reasonStr\n(Cmd: $cmdStr)",
            notification: notification,
          );
        }
      }
    } catch (e) {
      if (e is InstallationException) rethrow;
      _log.warning("Failed to retrieve installation failure details: $e");
    }
  }

  List<Uint8List> _decomposeBpp(Uint8List bpp) {
    final reader = SimpleAsn1Reader(bpp);
    final root = reader.readNext();
    if (root == null || root.tag != 0xBF36) {
      _log.warning("BPP does not start with BF36, sending as single segment");
      return [bpp];
    }

    final segments = <Uint8List>[];

    // root.encodedBytes contains T+L+V. root.value is V.
    final rootTl = root.encodedBytes.sublist(
      0,
      root.encodedBytes.length - root.value.length,
    );
    final children = root.children;

    // Segment 1: Tag and length fields of the BoundProfilePackage TLV plus the initialiseSecureChannelRequest TLV
    if (children.isNotEmpty && children[0].tag == 0xBF23) {
      final b = BytesBuilder();
      b.add(rootTl);
      b.add(children[0].encodedBytes);
      segments.add(b.toBytes());
    } else {
      segments.add(rootTl);
    }

    // Remaining segments based on sequences
    for (int i = 1; i < children.length; i++) {
      final seq = children[i];
      final seqTl = seq.encodedBytes.sublist(
        0,
        seq.encodedBytes.length - seq.value.length,
      );
      final elements = seq.children;

      if (elements.isEmpty) {
        segments.add(seq.encodedBytes);
        continue;
      }

      if (seq.tag == 0xA0 || seq.tag == 0xA2) {
        // sequences of 87
        // Tag and length fields of the sequence TLV plus the first element
        final b = BytesBuilder();
        b.add(seqTl);
        b.add(elements[0].encodedBytes);
        segments.add(b.toBytes());
        // Each of the remaining elements
        for (int j = 1; j < elements.length; j++) {
          segments.add(elements[j].encodedBytes);
        }
      } else if (seq.tag == 0xA1 || seq.tag == 0xA3) {
        // sequenceOf88 or sequenceOf86
        // Tag and length fields of the sequence TLV
        segments.add(seqTl);
        // Each of the contained TLVs
        for (final e in elements) {
          segments.add(e.encodedBytes);
        }
      } else {
        segments.add(seq.encodedBytes);
      }
    }

    return segments;
  }

  Future<Uint8List> transmitLogicalApdu(
    Channel channel,
    Uint8List requestData,
  ) async {
    // Rely on BaseChannel's internal logging and CLA mapping
    final response = await channel.transmit(
      0x80,
      0xE2,
      0x91,
      0x00,
      requestData,
    );
    return _checkSwAndGetData(response);
  }

  Future<T> _runOnChannel<T>(
    Channel? channel,
    Future<T> Function(Channel channel) action,
  ) async {
    if (channel != null) {
      return await action(channel);
    }
    return _withChannel(action);
  }

  Future<T> _withChannel<T>(Future<T> Function(Channel channel) action) async {
    final channel = await openSession();
    try {
      return await action(channel);
    } finally {
      await channel.close();
    }
  }

  Future<Uint8List> _transmitApdu(
    Channel channel,
    int cla,
    int ins,
    int p1,
    int p2,
    Uint8List? data,
  ) async {
    // BaseChannel now handles logging if enableApduLogging is on
    return await channel.transmit(cla, ins, p1, p2, data);
  }

  Future<void> _handleSoftRefresh(Channel channel) async {
    _log.info("Performing soft recovery sequence (no reconnect)...");
    try {
      // Lightly sync state to clear proactive status and update UI caches
      await listProfiles(useChannel: channel);
      await retrieveNotifications(useChannel: channel);
    } catch (e) {
      _log.warning("Soft recovery command failed: $e");
    }
  }

  Future<void> _handleRefresh(Channel channel) async {
    _log.info("Performing recovery sequence...");
    _markRefreshing();

    // 1. Wait 2 seconds before closing
    await Future.delayed(const Duration(seconds: 2));

    try {
      await channel.close();
    } catch (e) {
      if (isOmapiSessionCorruptedError(e)) rethrow;
      /* ignore */
    }

    await adapter.proactiveRefresh();

    int backoff = 2; // Initial backoff for retry

    for (int attempt = 0; attempt < 6; attempt++) {
      try {
        _log.info("Attempting to reopen session (attempt ${attempt + 1})...");
        final ch = await openSession();
        await ch.close();
        _log.info("Reopen success.");
        return; // Success!
      } catch (e) {
        if (e is ProactiveRefreshException) {
          _log.info("Reopen got 91xx, waiting ${backoff}s and retrying...");
          await Future.delayed(Duration(seconds: backoff));
          backoff *= 2;
          continue; // Retry
        }

        _log.warning("Reopen failed with non-refresh error: $e");
        rethrow;
      }
    }

    _log.warning("Reopen sequence failed, reconnecting device...");
    if (adapter.connectedReader != null) {
      final reader = adapter.connectedReader!;
      try {
        await adapter.disconnect();
      } catch (_) {}

      try {
        await adapter.connect(reader);
        _log.info("Reconnect success.");
      } catch (e2) {
        _log.severe("Reconnect failed: $e2");
      }
    }
  }

  void _markRefreshing() {
    final until = DateTime.now().add(const Duration(seconds: 90));
    if (adapter.refreshingUntil == null ||
        adapter.refreshingUntil!.isBefore(until)) {
      adapter.refreshingUntil = until;
    }
  }

  Uint8List _checkSwAndGetData(Uint8List response) {
    if (response.length < 2) {
      throw Exception(
        "Invalid response length: ${response.length}, data: ${HexUtils.bytesToHex(response)}",
      );
    }
    final sw1 = response[response.length - 2];
    final sw2 = response[response.length - 1];

    if (sw1 == 0x91) {
      throw ProactiveRefreshException(sw1, sw2);
    }

    // Use centralized validator
    try {
      ApduValidator.validate(sw1, sw2);
    } catch (e) {
      if (sw1 == 0x61 || sw1 == 0x6C) {
        // Should be handled by adapter, if we see it here, it's an error in adapter logic or unhandled residue
      }
      rethrow;
    }

    return response.sublist(0, response.length - 2);
  }

  Future<T> _retrySafeCommand<T>(
    Future<T> Function() action, {
    String desc = "command",
    bool retryAidErrors = true,
  }) async {
    const int maxAttempts = 10;
    int attempt = 0;
    while (true) {
      try {
        return await action();
      } catch (e) {
        if (isOmapiSessionCorruptedError(e)) rethrow;
        attempt++;
        if (attempt >= maxAttempts) {
          _log.severe("$desc failed after $maxAttempts attempts: $e");
          rethrow;
        }

        bool isRefresh = (e is ProactiveRefreshException);
        bool isConditionsNotSatisfied =
            (e is ConditionOfUseNotSatisfiedException);
        bool isAidNotSelected =
            (e is AppException &&
            (e.code == AppErrorCode.ERROR_APPLICATION_NOT_FOUND ||
                e.code == AppErrorCode.ERROR_CHANNEL_OPEN_FAILED));

        final isRefreshing =
            adapter.refreshingUntil != null &&
            DateTime.now().isBefore(adapter.refreshingUntil!);

        if (!retryAidErrors && e is CardBusyException) {
          _log.info(
            "$desc got card-busy on caller-owned channel: $e. Letting caller reopen a fresh session.",
          );
          rethrow;
        }

        if (isConditionsNotSatisfied) {
          _log.info(
            "$desc: Got 6985, triggering proactive refresh and rethrowing.",
          );
          try {
            await adapter.proactiveRefresh();
          } catch (e2) {
            _log.warning("Proactive refresh failed: $e2");
          }
          rethrow;
        }

        if (isRefresh || isAidNotSelected) {
          if (!retryAidErrors) {
            _log.info(
              "$desc failed on caller-owned channel: $e. Letting caller reopen a fresh session.",
            );
            rethrow;
          }
          if (!isRefreshing && isAidNotSelected) {
            _log.info("$desc failed: $e. No retry (not in refreshing state).");
            rethrow;
          }

          if (isRefresh) {
            _log.info(
              "$desc: Got 91xx, skipping hard proactive refresh (recovery sequence).",
            );
          }

          final sleepSecs = 1 + attempt;
          _log.info(
            "$desc: Got ${isRefresh ? '91xx' : 'AID not selected'}, retry $attempt/$maxAttempts after ${sleepSecs}s...",
          );
          await Future.delayed(Duration(seconds: sleepSecs));
        } else {
          final bool isNotConnected =
              e is AppException &&
              e.code == AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED;

          if (!isRefreshing && !isNotConnected) {
            _log.info(
              "$desc: Unexpected error $e. No retry (not in refreshing state).",
            );
            rethrow;
          }

          _log.warning(
            "$desc: ${isNotConnected ? 'Disconnected' : 'Unexpected error'} $e, attempt $attempt/$maxAttempts. Reconnecting reader...",
          );
          try {
            await adapter.reconnect();
          } catch (re2) {
            _log.warning("$desc: Reconnect failed: $re2");
          }
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }
    }
  }
}

// Top-level functions for compute
List<EuiccProfile> _mapProfiles(List<ProfileInfo> profilesRaw) {
  return profilesRaw.map((p) {
    String? iccid;
    if (p.iccid != null) {
      iccid = HexUtils.swapNibbles(HexUtils.bytesToHex(p.iccid!));
      if (iccid.endsWith('F')) iccid = iccid.substring(0, iccid.length - 1);
    }

    String? mcc;
    String? mnc;
    if (p.profileOwner?.mccMnc != null) {
      final b = p.profileOwner!.mccMnc!;
      if (b.length >= 3) {
        final digits = b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
        if (digits.length >= 5) {
          mcc = "${digits[1]}${digits[0]}${digits[3]}";
          if (digits[2].toUpperCase() == 'F') {
            mnc = "${digits[5]}${digits[4]}";
          } else {
            mnc = "${digits[5]}${digits[4]}${digits[2]}";
          }
        }
      }
    }

    String? gid1;
    String? gid2;
    if (p.profileOwner?.gid1 != null) {
      gid1 = HexUtils.bytesToHex(p.profileOwner!.gid1!).toUpperCase();
    }
    if (p.profileOwner?.gid2 != null) {
      gid2 = HexUtils.bytesToHex(p.profileOwner!.gid2!).toUpperCase();
    }

    final decodedName = _decodeUtf8Safe(p.profileName);
    final decodedNickname = _decodeUtf8Safe(p.profileNickname);
    final decodedServiceProviderName = _decodeUtf8Safe(p.serviceProviderName);

    final parsedNickname = ProfileTagUtils.parse(decodedNickname);

    String? smdpAddress;
    if (p.notificationConfigurationInfo != null &&
        p.notificationConfigurationInfo!.isNotEmpty) {
      smdpAddress = p.notificationConfigurationInfo![0].notificationAddress;
    }

    return EuiccProfile(
      iccid: iccid ?? "Unknown",
      name: decodedName,
      nickname: decodedNickname,
      serviceProviderName: decodedServiceProviderName,
      enabled: p.profileState?.value == 1,
      profileClass: p.profileClass?.value ?? 2,
      isdpAid: p.isdpAid != null ? HexUtils.bytesToHex(p.isdpAid!) : null,
      icon: p.icon,
      mcc: mcc,
      mnc: mnc,
      gid1: gid1,
      gid2: gid2,
      smdpAddress: smdpAddress,
      tags: parsedNickname.tags.map((t) => t.raw).toList(),
    );
  }).toList();
}

String? _decodeUtf8Safe(String? input) {
  if (input == null) return null;
  try {
    return utf8.decode(input.codeUnits);
  } catch (_) {
    return input;
  }
}

Uint8List _encodeNicknameRequestUtf8(Uint8List iccid, String nickname) {
  // Construct SetNicknameRequest manually with UTF-8 nickname to support non-ASCII characters.
  final children = <Uint8List>[
    _asn1EncodeRaw(0x5A, iccid),
    _asn1EncodeRaw(0x90, Uint8List.fromList(utf8.encode(nickname))),
  ];
  // Context-specific constructed tag BF29
  return _asn1EncodeConstructed(0xBF29, children);
}

// ASN.1 Helpers
Uint8List _asn1EncodeRaw(int tag, Uint8List value) {
  final tagBytes = _encodeTag(tag);
  final lenBytes = _encodeLength(value.length);
  final b = BytesBuilder();
  b.add(tagBytes);
  b.add(lenBytes);
  b.add(value);
  return b.toBytes();
}

Uint8List _asn1EncodeConstructed(int tag, List<Uint8List> children) {
  final b = BytesBuilder();
  for (var c in children) {
    b.add(c);
  }
  final value = b.toBytes();
  return _asn1EncodeRaw(tag, value);
}

Uint8List _encodeTag(int tag) {
  if (tag <= 30) return Uint8List.fromList([tag]);
  if (tag > 0xFF) {
    return Uint8List.fromList([(tag >> 8) & 0xFF, tag & 0xFF]);
  }
  return Uint8List.fromList([tag]);
}

Uint8List _encodeLength(int length) {
  if (length < 128) {
    return Uint8List.fromList([length]);
  }
  final bytes = <int>[];
  var l = length;
  while (l > 0) {
    bytes.insert(0, l & 0xFF);
    l = l >> 8;
  }
  bytes.insert(0, 0x80 | bytes.length);
  return Uint8List.fromList(bytes);
}
