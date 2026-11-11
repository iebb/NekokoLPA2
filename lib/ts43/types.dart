import 'sim/aka.dart';
import 'sim/identity.dart';
import 'enums.dart';
import 'response.dart';

/// A source SIM channel: reads identity and performs EAP-AKA, the analog of
/// the Go `ts43.Channel` interface.
abstract class SourceChannel {
  Future<Identity> identity();
  Future<AkaResponse> authenticateAka(AkaRequest request);
}

/// Device terminal identity fields. Ported from `ts43-go/ts43/types.go` Device.
class Device {
  String imei;
  List<String> imeis;
  String iccid;
  String eid;
  String vendor;
  String model;
  String softwareVersion;
  String serialNumber;
  String friendlyName;
  String service;
  int entitlementProtocol;

  Device({
    this.imei = '',
    this.imeis = const [],
    this.iccid = '',
    this.eid = '',
    this.vendor = '',
    this.model = '',
    this.softwareVersion = '',
    this.serialNumber = '',
    this.friendlyName = '',
    this.service = '',
    this.entitlementProtocol = 0,
  });

  Device clone() => Device(
    imei: imei,
    imeis: List<String>.from(imeis),
    iccid: iccid,
    eid: eid,
    vendor: vendor,
    model: model,
    softwareVersion: softwareVersion,
    serialNumber: serialNumber,
    friendlyName: friendlyName,
    service: service,
    entitlementProtocol: entitlementProtocol,
  );
}

/// Carrier TS.43 entitlement configuration. Ported from `Entitlement`.
class Entitlement {
  String server;
  EntitlementChannel channel;
  bool usePost;
  Duration timeout;
  SimType sourceSimType;
  int transferType;
  bool useTempTokenConversion;
  bool setTargetTerminalFields;
  bool restrictOldTerminalFields;
  bool useSmdsDelayedDownload;
  Duration pollInterval;
  Duration pollTimeout;
  int autoRetry511Limit;
  String app;
  String appName;
  String provisioningVersion;
  String requestVersion;
  String version;

  Entitlement({
    this.server = '',
    this.channel = EntitlementChannel.none,
    this.usePost = false,
    this.timeout = Duration.zero,
    this.sourceSimType = SimType.esim,
    this.transferType = TransferType.disabled,
    this.useTempTokenConversion = false,
    this.setTargetTerminalFields = false,
    this.restrictOldTerminalFields = false,
    this.useSmdsDelayedDownload = false,
    this.pollInterval = Duration.zero,
    this.pollTimeout = Duration.zero,
    this.autoRetry511Limit = 0,
    this.app = '',
    this.appName = '',
    this.provisioningVersion = '',
    this.requestVersion = '',
    this.version = '',
  });
}

class Endpoint {
  final SourceChannel? channel;
  final Device device;
  Endpoint({this.channel, required this.device});
}

/// TS.43 transfer flow states.
enum Ts43State {
  unknown,
  pendingUserInput,
  pendingWebsheet,
  pendingSourceProfileDeletion,
  pendingDownload,
  pendingActivation,
  done,
  pendingSmdsDiscovery,
  dismissed,
  pendingDelayedDownload,
}

/// Auth token sent as IMSI + token.
class AuthToken {
  String value;
  DateTime? expiresAt;
  List<String> cookies;
  AuthToken({this.value = '', this.expiresAt, this.cookies = const []});
}

/// Temporary token from AcquireTemporaryToken.
class TemporaryToken {
  String value;
  DateTime? expiresAt;
  List<String> cookies;
  List<Operation> targets;
  TemporaryToken({
    this.value = '',
    this.expiresAt,
    this.cookies = const [],
    this.targets = const [],
  });
}

class Message {
  final String title;
  final String text;
  final bool acceptButton;
  final String acceptButtonLabel;
  final bool rejectButton;
  final String rejectButtonLabel;
  final bool acceptFreeText;
  final String acceptFreeTextHint;
  final String acceptFreeTextValidation;
  final String acceptFreeTextValidationFailedErrorText;

  const Message({
    this.title = '',
    this.text = '',
    this.acceptButton = false,
    this.acceptButtonLabel = '',
    this.rejectButton = false,
    this.rejectButtonLabel = '',
    this.acceptFreeText = false,
    this.acceptFreeTextHint = '',
    this.acceptFreeTextValidation = '',
    this.acceptFreeTextValidationFailedErrorText = '',
  });
}

class Websheet {
  final String url;
  final String userData;
  final String contentsType;
  const Websheet({this.url = '', this.userData = '', this.contentsType = ''});
}

class DownloadConfig {
  String activationCode;
  String smdpFqdn;
  String matchingId;
  String profileIccid;
  String imei;
  DownloadConfig({
    this.activationCode = '',
    this.smdpFqdn = '',
    this.matchingId = '',
    this.profileIccid = '',
    this.imei = '',
  });
}

enum WebsheetCallbackEvent {
  unknown,
  profileReadyWithActivationCode,
  profileReadyWithDefaultSmdp,
  selectionCompleted,
  dismissFlow,
  finishFlow,
  deleteToken,
  checkProfileServiceStatus,
  deleteProfileInUse,
  voWiFiEntitlementChanged,
  voWiFiDismissFlow,
}

class WebsheetResult {
  final WebsheetCallbackEvent event;
  final String activationCode;
  final String smdpFqdn;
  final String iccid;
  final String imei;
  final Operation nextAction;
  const WebsheetResult({
    this.event = WebsheetCallbackEvent.unknown,
    this.activationCode = '',
    this.smdpFqdn = '',
    this.iccid = '',
    this.imei = '',
    this.nextAction = Operation.none,
  });
}

class UserInputResult {
  final String response;
  final int button; // MessageButton
  const UserInputResult({
    this.response = '',
    this.button = MessageButton.unknown,
  });
}

class ContinueRequest {
  final UserInputResult? userInput;
  final WebsheetResult? websheet;
  final bool sourceProfileDeleted;
  const ContinueRequest({
    this.userInput,
    this.websheet,
    this.sourceProfileDeleted = false,
  });
}

class ActivationResult {
  final String iccid;
  const ActivationResult({this.iccid = ''});
}

// --- Events ---

abstract class Ts43Event {
  const Ts43Event();
}

class UserInputEvent extends Ts43Event {
  final Message message;
  const UserInputEvent(this.message);
}

class WebsheetEvent extends Ts43Event {
  final Websheet websheet;
  const WebsheetEvent(this.websheet);
}

class SourceProfileDeletionEvent extends Ts43Event {
  final String iccid;
  const SourceProfileDeletionEvent(this.iccid);
}

class DownloadReadyEvent extends Ts43Event {
  final DownloadConfig config;
  const DownloadReadyEvent(this.config);
}

class SmdsDiscoveryEvent extends Ts43Event {
  final String sourceIccid;
  final String targetEid;
  final String targetImei;
  final int subscriptionResult;
  const SmdsDiscoveryEvent({
    required this.sourceIccid,
    required this.targetEid,
    required this.targetImei,
    required this.subscriptionResult,
  });
}

class DelayedDownloadEvent extends Ts43Event {
  final String sourceIccid;
  final String targetEid;
  final String targetImei;
  final int subscriptionResult;
  const DelayedDownloadEvent({
    required this.sourceIccid,
    required this.targetEid,
    required this.targetImei,
    required this.subscriptionResult,
  });
}

class ActivationPendingEvent extends Ts43Event {
  final String iccid;
  final int subscriptionResult;
  const ActivationPendingEvent({
    required this.iccid,
    required this.subscriptionResult,
  });
}

class DismissEvent extends Ts43Event {
  final int subscriptionResult;
  const DismissEvent(this.subscriptionResult);
}

class DoneEvent extends Ts43Event {
  const DoneEvent();
}

/// Internal transfer offer/session carried inside [Ts43Result].
class TransferOffer {
  Identity sourceIdentity;
  Device sourceDevice;
  Device targetDevice;
  AuthToken authToken;
  TemporaryToken temporaryToken;
  TransferOffer({
    required this.sourceIdentity,
    required this.sourceDevice,
    required this.targetDevice,
    required this.authToken,
    required this.temporaryToken,
  });
}

class TransferSession {
  TransferOffer offer;
  String sourceProfileIccid;
  TransferSession({required this.offer, this.sourceProfileIccid = ''});
}

class Ts43Result {
  Ts43State state;
  Ts43Event? event;
  OdsaResponse? manageSubscription;
  OdsaResponse? updateSubscription;
  OdsaResponse? configuration;
  OdsaResponse? updateConfiguration;
  DownloadConfig downloadConfig;
  TransferSession? session;

  Ts43Result({
    this.state = Ts43State.unknown,
    this.event,
    this.manageSubscription,
    this.updateSubscription,
    this.configuration,
    this.updateConfiguration,
    DownloadConfig? downloadConfig,
    this.session,
  }) : downloadConfig = downloadConfig ?? DownloadConfig();
}

class TransferTokenResult {
  final AuthToken auth;
  final TemporaryToken temporary;
  TransferTokenResult({AuthToken? auth, TemporaryToken? temporary})
    : auth = auth ?? AuthToken(),
      temporary = temporary ?? TemporaryToken();
}

String firstNonEmpty(List<String> values) {
  for (final v in values) {
    if (v.isNotEmpty) return v;
  }
  return '';
}
