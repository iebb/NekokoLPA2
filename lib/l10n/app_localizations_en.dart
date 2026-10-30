// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get addBluetoothReader => 'Add Bluetooth reader';

  @override
  String get bluetoothSetupFailed =>
      'Unable to set up the Bluetooth reader. Check that Bluetooth is on and the reader is nearby, then try again.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get displaySettings => 'Display Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get appearanceSubtitle =>
      'Customize theme, layout, and display preferences';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get themeStyle => 'Theme Style';

  @override
  String get themeStyleSubtitle => 'Choose between Custom and MD3 style';

  @override
  String get customDesign => 'Nekoko Style';

  @override
  String get stockMD3 => 'Stock MD3';

  @override
  String get waterfallLayout => 'Waterfall Layout';

  @override
  String get waterfallLayoutSubtitle =>
      'Use Masonry style layout on wide screens';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'System Language';

  @override
  String get general => 'General';

  @override
  String get ui => 'UI';

  @override
  String get autoLoadProfiles => 'Auto-load Profiles';

  @override
  String get autoLoadProfilesSubtitle =>
      'Load profiles when reader is selected';

  @override
  String get loadProfileIcons => 'Load Profile Icons';

  @override
  String get loadProfileIconsSubtitle =>
      'Fetch profile icons from eUICC (slower)';

  @override
  String get useNekokoIcons => 'Use Operator Icons';

  @override
  String get useNekokoIconsSubtitle =>
      'Fetch carrier icons from operator-icons';

  @override
  String get forceDeviceDropdown => 'Force Device Dropdown';

  @override
  String get forceDeviceDropdownSubtitle =>
      'Always use dropdown for device selection';

  @override
  String get sizeDisplayUnit => 'Size Display Unit';

  @override
  String get sizeDisplayUnitSubtitle => 'Unit format for storage size display';

  @override
  String get phoneFormat => 'Phone Number Format';

  @override
  String get phoneFormatSubtitle => 'Format for displaying phone numbers';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get notificationSettingsSubtitle =>
      'Configure automatic processing and removal';

  @override
  String get notificationHistory => 'Notification History';

  @override
  String get notificationHistorySubtitle =>
      'Find, manage and resend sent notifications';

  @override
  String get tagsAndReminders => 'Tags & Reminders';

  @override
  String get tagManager => 'Tag Manager';

  @override
  String get tagManagerSubtitle => 'Create and edit profile tags';

  @override
  String get tagReminders => 'Tag Reminders';

  @override
  String get tagRemindersSubtitle =>
      'Scheduled notifications based on date tags';

  @override
  String get manageTagsAndReminders => 'Manage Tags & Reminders';

  @override
  String get manageTagsAndRemindersSubtitle =>
      'Configure tags, permissions, and test alerts';

  @override
  String get viewScheduledReminders => 'View Scheduled Reminders';

  @override
  String get viewScheduledRemindersSubtitle =>
      'Manage your upcoming tag-based notifications';

  @override
  String get connectivity => 'Connectivity';

  @override
  String get remoteReaders => 'Remote Readers';

  @override
  String get remoteReadersSubtitle => 'Configure RemoCard companion apps';

  @override
  String get enableBle => 'Bluetooth Connector';

  @override
  String get enableBleSubtitle =>
      'Enable scanning and connecting to Bluetooth readers';

  @override
  String get enableCcid => 'USB CCID Connector';

  @override
  String get enableCcidSubtitle => 'Enable USB smart card readers (CCID)';

  @override
  String get enableOmapi => 'OMAPI Connector';

  @override
  String get enableOmapiSubtitle =>
      'Enable Open Mobile API functionality for OMAPI-based eUICC management.';

  @override
  String get enableTmapi => 'Telephony API Connector';

  @override
  String get enableTmapiSubtitle =>
      'Enable Telephony API functionality for SIM-based eUICC management.';

  @override
  String get readerTypes => 'Reader Types';

  @override
  String get readerTypesSubtitle =>
      'Manage enabled reader types (CCID, Bluetooth, Remote, etc.)';

  @override
  String get enabledReaderTypes => 'Enabled Reader Types';

  @override
  String get enabledReaderTypesSubtitle =>
      'Control which types of readers are available in the app';

  @override
  String get remoteReaderSettings => 'Remote Reader Settings';

  @override
  String get remoteReaderSettingsSubtitle =>
      'Configure remote reader servers and connections';

  @override
  String get ccidReaderTitle => 'CCID (USB/PC/SC)';

  @override
  String get ccidReaderSubtitle => 'USB smart card readers and PC/SC devices';

  @override
  String get bluetoothReaderTitle => 'Bluetooth';

  @override
  String get bluetoothReaderSubtitle =>
      'Bluetooth LE smart card readers and writers';

  @override
  String get remoteReadersTitle => 'Remote Readers';

  @override
  String get remoteReadersConnectorSubtitle =>
      'Network-connected remote smart card readers';

  @override
  String get omapiReaderTitle => 'OMAPI';

  @override
  String get omapiReaderSubtitle =>
      'Built-in SIM card slots via Open Mobile API';

  @override
  String get tmapiReaderTitle => 'Telephony API';

  @override
  String get tmapiReaderSubtitle => 'Built-in SIM card slots via Telephony API';

  @override
  String get remoteServerConfiguration => 'Remote Server Configuration';

  @override
  String get remoteServerConfigurationSubtitle =>
      'Manage remote reader servers and connection settings';

  @override
  String get enableBrowser => 'Enable Browser';

  @override
  String get enableBrowserSubtitle =>
      'Show additional browser tabs like Store, Buy, or Help';

  @override
  String get transport => 'Transport';

  @override
  String get disableRefreshFlags => 'Disable Refresh Flags';

  @override
  String get disableRefreshFlagsSubtitle =>
      'This will not apply to external readers';

  @override
  String get apduMaxSegmentSize => 'APDU Max Segment Size';

  @override
  String get apduMaxSegmentSizeSubtitle => 'Maximum data size per APDU chunk';

  @override
  String get ensureSingleChannel => 'Ensure Single Channel';

  @override
  String get ensureSingleChannelSubtitle =>
      'Close other logical channels before opening a new one';

  @override
  String get analytics => 'Analytics & Cloud Services';

  @override
  String get nekokoCloud => 'Nekoko Cloud';

  @override
  String get nekokoCloudSubtitle =>
      'Analyze installation data for better prediction';

  @override
  String get developer => 'Developer';

  @override
  String get developerMode => 'Developer Mode';

  @override
  String get developerModeSubtitle => 'Enable advanced debugging features';

  @override
  String get exportDatabase => 'Export Database';

  @override
  String get exportDatabaseSubtitle =>
      'Save a copy of your application database to external storage.';

  @override
  String get openDatabaseFolder => 'Open Database Folder';

  @override
  String get openDatabaseFolderSubtitle =>
      'Reveal local storage folder in explorer';

  @override
  String get decodeAsn1 => 'Decode ASN.1 Logs (Slow)';

  @override
  String get decodeAsn1Subtitle => 'Heavily impacts performance';

  @override
  String get viewAppLogs => 'View App Logs';

  @override
  String get viewAppLogsSubtitle => 'View collected application logs';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get build => 'Build';

  @override
  String get checkUpdates => 'Check for Updates';

  @override
  String get checkUpdatesSubtitle =>
      'Automatically check for new versions on startup';

  @override
  String get licenses => 'Open Source Licenses';

  @override
  String get licensesSubtitle =>
      'License information for open source libraries used';

  @override
  String get noUpdatesFound => 'No updates found';

  @override
  String get profilesTitle => 'Profiles';

  @override
  String get switchEstkSlot => 'Switch eSTK Slot';

  @override
  String get notificationsButton => 'Notifications';

  @override
  String get downloadProfile => 'Download Profile';

  @override
  String get reconnect => 'Reconnect';

  @override
  String get bluetoothNotConnected => 'Bluetooth Not Connected';

  @override
  String get bluetoothNotConnectedSubtitle =>
      'Ensure Bluetooth is enabled and the device is nearby. Tap Connect to start using this device.';

  @override
  String get bluetoothConnectionFailed => 'Bluetooth Connection Failed';

  @override
  String bluetoothConnectionFailedSubtitle(Object error) {
    return 'Failed to connect to Bluetooth device.\n\n$error';
  }

  @override
  String get removeDevice => 'Remove Device';

  @override
  String get retryConnection => 'Connect';

  @override
  String get remoteConnectionFailed => 'Remote Reader Connection Failed';

  @override
  String remoteConnectionFailedMessage(Object error) {
    return 'Ensure the remote server is running and accessible.\n\n$error';
  }

  @override
  String get errorBluetoothTimeout =>
      'Bluetooth operation timed out. Please try again.';

  @override
  String get errorOmapiSecurity =>
      'Security error: Access to the card was denied by the OS or ARA-M rules.';

  @override
  String get errorApplicationNotFound =>
      'eUICC management application (ISD-R) not found. This card may not be a valid eUICC.';

  @override
  String get changeSettings => 'Change Settings';

  @override
  String get connectCompatibleReader => 'Connect a compatible reader to start.';

  @override
  String get connectReaderMessageBle =>
      'You can also scan for compatible Bluetooth devices if you have a Bluetooth-enabled eUICC.';

  @override
  String get connectReaderMessageNoBle =>
      'Ensure your CCID reader is connected to your computer.';

  @override
  String get downloadSmartCardExtension => 'Download Smart Card Extension';

  @override
  String get smartCardExtensionMessage =>
      'The extension is required to access USB CCID readers in this browser.';

  @override
  String get scanForBluetooth => 'Scan for Bluetooth';

  @override
  String get connectRemote => 'Connect Remote';

  @override
  String get noCardDetected => 'No Card Detected';

  @override
  String get noCardDetectedMessage =>
      'No unsupported or active eUICC found in this slot.';

  @override
  String get noDataLoaded => 'Not connected';

  @override
  String get loadProfiles => 'Connect';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get disconnecting => 'Disconnecting...';

  @override
  String get profilesEmpty => 'No Profiles on Card';

  @override
  String get profilesEmptyMessage => 'This eUICC card is empty.';

  @override
  String get renameProfile => 'Rename Profile';

  @override
  String get nickname => 'Nickname';

  @override
  String get enterProfileNickname => 'Enter profile nickname';

  @override
  String get profileNicknameNote =>
      'Note: Tags are managed separately via the \'Manage Tags\' menu.';

  @override
  String get useProfileIcon => 'Use Profile Icon';

  @override
  String get useProfileIconSubtitle => 'Icon from eSIM card';

  @override
  String get removeCustomIcon => 'Remove Custom Icon';

  @override
  String get noRemoteIcon => 'No remote icon available for this operator';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get refresh => 'Refresh';

  @override
  String get initializing => 'Initializing...';

  @override
  String get refreshingProfiles => 'Refreshing profiles...';

  @override
  String get retrievingEid => 'Retrieving EID and Info...';

  @override
  String get updatingProfile => 'Updating profile...';

  @override
  String get manageIsdR => 'Manage ISD-R AIDs';

  @override
  String get manageIsdRSubtitle =>
      'Configure default Application IDs for eUICC';

  @override
  String get transportFailed => 'Transport Failed';

  @override
  String get remoteTransportFailedMessage =>
      'Connected to remote server, but the command failed. This usually means the remote device is momentarily busy or disconnected from the card. Would you like to retry?';

  @override
  String get retry => 'Retry';

  @override
  String get scanningForReaders => 'Scanning for readers...';

  @override
  String get switchedEstkSlot => 'Switched eSTK Slot';

  @override
  String get scanningForUnresponsiveDevices =>
      'Scanning for unresponsive devices...';

  @override
  String get resettingConnection => 'Resetting connection...';

  @override
  String get connectingToReader => 'Connecting to reader...';

  @override
  String get waitingForBluetooth => 'Waiting for Bluetooth to turn on...';

  @override
  String get connectingOverBluetooth => 'Connecting over Bluetooth...';

  @override
  String connectingOverBluetoothAttempt(int attempt, int total) {
    return 'Connecting over Bluetooth (attempt $attempt of $total)...';
  }

  @override
  String get discoveringReaderServices => 'Discovering reader services...';

  @override
  String get settingUpBluetoothLink => 'Setting up the Bluetooth link...';

  @override
  String get authenticatingWithReader => 'Authenticating with the reader...';

  @override
  String get initializingReader => 'Initializing the reader...';

  @override
  String get switchingReaderToEuiccMode =>
      'Switching the reader to eUICC mode...';

  @override
  String get waitingForReaderRestart => 'Waiting for the reader to restart...';

  @override
  String get moreOptions => 'More options';

  @override
  String get retrievingProfiles => 'Retrieving profiles...';

  @override
  String get savingProfileMetadata => 'Saving profile metadata...';

  @override
  String get enablingProfile => 'Enabling profile...';

  @override
  String get disablingProfile => 'Disabling profile...';

  @override
  String get deleteProfile => 'Delete Profile';

  @override
  String deleteProfileConfirmation(Object profileName) {
    return 'Are you sure you want to delete profile $profileName?\nThis action cannot be undone.';
  }

  @override
  String get deletingProfile => 'Deleting profile...';

  @override
  String get deleting => 'Deleting...';

  @override
  String get dataUsage => 'Data Usage';

  @override
  String get details => 'Details';

  @override
  String get rename => 'Rename';

  @override
  String get changeIcon => 'Change Icon';

  @override
  String get manageTags => 'Manage Tags';

  @override
  String get copyIccid => 'Copy ICCID';

  @override
  String get notificationProcessingError =>
      'Cannot perform operations while notifications are processing';

  @override
  String get operationInProgressError => 'Operation in progress, please wait';

  @override
  String iccidCopied(Object iccid) {
    return 'ICCID copied: $iccid';
  }

  @override
  String get operationRestricted => 'Operation Restricted';

  @override
  String get notificationProcessingDownloadError =>
      'Notifications are still being processed. Please wait until completion before downloading new profiles.';

  @override
  String get operational => 'Operational';

  @override
  String get test => 'Test';

  @override
  String get provisioning => 'Provisioning';

  @override
  String get profileDetails => 'Profile Details';

  @override
  String get profileDetailsSubtitle =>
      'Information from the eUICC for this profile slot.';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get tagsManagedSeparately =>
      'Note: Tags are managed separately via the \'Manage Tags\' menu.';

  @override
  String get changeProfileIcon => 'Change Profile Icon';

  @override
  String get selectFromGallery => 'Select from Gallery';

  @override
  String get nekokoOperatorIcon => 'Operator icon';

  @override
  String get iconFromEsim => 'Icon from eSIM card';

  @override
  String updateIconFailed(Object error) {
    return 'Failed to update icon: $error';
  }

  @override
  String get failedToReadImage => 'Failed to read image file';

  @override
  String get failedToProcessImage => 'Failed to process image';

  @override
  String get customIconSet => 'Custom icon set successfully';

  @override
  String get noMccMnc => 'No MCC/MNC available for this profile';

  @override
  String get fetchingRemoteIcon => 'Fetching remote icon...';

  @override
  String get remoteIconSaved => 'Remote icon saved as custom icon';

  @override
  String fetchRemoteIconFailed(Object error) {
    return 'Failed to fetch remote icon: $error';
  }

  @override
  String get noProfileIcon => 'No profile icon available';

  @override
  String get profileIconSaved => 'Profile icon saved as custom icon';

  @override
  String get customIconRemoved => 'Custom icon removed';

  @override
  String get failed => 'Failed';

  @override
  String euiccError(Object action) {
    return 'The eUICC returned an error while attempting to $action the profile.';
  }

  @override
  String get dismiss => 'Dismiss';

  @override
  String get dataPlan => 'Data Plan';

  @override
  String get used => 'used';

  @override
  String get total => 'total';

  @override
  String expires(Object date) {
    return 'Expires: $date';
  }

  @override
  String get close => 'Close';

  @override
  String get server => 'Server';

  @override
  String get switchFailed => 'Switch failed';

  @override
  String get deviceRefreshFailed => 'Device refresh failed';

  @override
  String get euiccOptions => 'eUICC Options';

  @override
  String get euiccInfo => 'eUICC Info';

  @override
  String get hideEid => 'Hide EID';

  @override
  String get showEid => 'Show EID';

  @override
  String get copyEid => 'Copy EID';

  @override
  String get eidCopied => 'EID copied to clipboard';

  @override
  String get connectRemotes => 'Connect Remotes';

  @override
  String get configureRemotes => 'Configure Remotes';

  @override
  String get connectingToRemoteReaders =>
      'Connecting to remote readers in background...';

  @override
  String get noRemoteReadersFound => 'No remote readers found';

  @override
  String connectedRemoteReaders(Object count) {
    return 'Connected $count remote reader(s)';
  }

  @override
  String failedToConnectRemoteReaders(Object error) {
    return 'Failed to connect remote readers: $error';
  }

  @override
  String get remoteReaderPassword => 'Remote Reader Password';

  @override
  String get remoteReaderPasswordSubtitle =>
      'This remote reader requires a password.';

  @override
  String get password => 'Password';

  @override
  String get deleteConnection => 'Delete Connection';

  @override
  String get connect => 'Connect';

  @override
  String get remoteReaderConnectionFailed => 'Remote Reader Connection Failed';

  @override
  String remoteReaderConnectionFailedSubtitle(Object error) {
    return 'Ensure the remote server is running and accessible.\n\n$error';
  }

  @override
  String get connectReader => 'Connect a compatible reader to start.';

  @override
  String get connectReaderSubtitleBle =>
      'You can also scan for compatible Bluetooth devices if you have a Bluetooth-enabled eUICC.';

  @override
  String get connectReaderSubtitleCcid =>
      'Ensure your CCID reader is connected to your computer.';

  @override
  String get downloadExtension => 'Download Smart Card Extension';

  @override
  String get downloadExtensionSubtitle =>
      'The extension is required to access USB CCID readers in this browser.';

  @override
  String get cardUnsupported => 'Card Unsupported';

  @override
  String get cardUnsupportedSubtitle =>
      'This card is likely not an eUICC, or it is not supported by this reader, or being used by others.';

  @override
  String get omapiWelcome =>
      'One good thing — your device does have OMAPI support and is highly likely to be compatible with removable cards!';

  @override
  String get supportedDevices => 'Supported Devices';

  @override
  String get aboutAram => 'About ARA-M';

  @override
  String get accessDenied => 'Access Denied';

  @override
  String get accessDeniedSubtitle =>
      'Carrier privileges are required to access this eUICC. The card\'s ARA-M allowlist does not match the app\'s signature.';

  @override
  String get noCardDetectedSubtitle =>
      'No unsupported or active eUICC found in this slot.';

  @override
  String get noProfilesInstalled => 'No profiles installed';

  @override
  String get noProfilesInstalledSubtitle => 'This eUICC card is empty.';

  @override
  String get cardRefreshingTitle => 'Card is Refreshing';

  @override
  String get cardRefreshingMessage =>
      'The card is currently updating its state. Profile list cannot be retrieved at this moment. Please wait a few seconds and then try again.';

  @override
  String get useRemoteIcon => 'Use Remote Icon';

  @override
  String get bleDisconnectedTitle => 'Bluetooth Connection Lost';

  @override
  String get bleDisconnectedMessage =>
      'The connection to the card reader was suddenly lost. Please ensure it is nearby and turned on.';

  @override
  String get cardStuckRefreshingMessage =>
      'Profile state change ongoing - try manually re-plug the SIM card if it stucks.';

  @override
  String get cardNeedsReplugTitle => 'Re-plug the SIM card';

  @override
  String get cardNeedsReplugMessage =>
      'The card will not hand over its eUICC applet, so it cannot be managed right now. Remove the SIM card and insert it again, then try once more.';

  @override
  String get activationCodeTitle => 'Activation Code';

  @override
  String get activationCodeSubtitle =>
      'Scan a QR code, drop an image, or enter the LPA string manually.';

  @override
  String get fullActivationCodeLabel => 'Full Activation Code';

  @override
  String get fullActivationCodeHint => 'LPA:1\$smdp.io\$MATCHING-ID';

  @override
  String get pasteFromClipboardTooltip => 'Paste from Clipboard';

  @override
  String get selectFromGalleryTooltip => 'Select from Gallery';

  @override
  String get scanQrCodeTooltip => 'Scan QR Code';

  @override
  String get smdpAddressLabel => 'SM-DP+ Address';

  @override
  String get smdpAddressHint => 'smdp.io';

  @override
  String get matchingIdLabel => 'Matching ID';

  @override
  String get matchingIdHint => 'ABC-123';

  @override
  String get smdpOidLabel => 'SM-DP+ OID';

  @override
  String get confirmationCodeLabel => 'Confirmation Code';

  @override
  String get confirmationCodeHint => 'Enter secret code';

  @override
  String get continueButton => 'Continue';

  @override
  String get invalidLpaClipboard =>
      'Clipboard does not contain a valid LPA string.';

  @override
  String get invalidFqdnFormat => 'Invalid FQDN format';

  @override
  String get invalidMatchingIdChars => 'Invalid characters in Matching ID';

  @override
  String get invalidOidFormat => 'Invalid OID format (e.g. 1.2.840...)';

  @override
  String get activationCodeRequired => 'Activation code is required';

  @override
  String get invalidLpaFormatGeneric => 'Invalid LPA format';

  @override
  String get smdpAddressRequired => 'SM-DP+ address is required';

  @override
  String get loadingNotifications => 'Loading notifications...';

  @override
  String get vowifi => 'VoWiFi';

  @override
  String get vowifiSubtitle =>
      'Experimental; requires a compatible external reader';

  @override
  String get vowifiDisclaimerTitle => 'Enable experimental VoWiFi?';

  @override
  String get vowifiDisclaimerBody =>
      'VoWiFi is experimental. It communicates directly with your mobile network operator and only works with a compatible external SIM/eSIM reader that supports raw APDUs. Carrier and reader compatibility may vary.';

  @override
  String get processing => 'Processing...';

  @override
  String get analyzingImage => 'Analyzing image...';

  @override
  String get noQrFoundInImage => 'No QR code found in image';

  @override
  String get invalidAcInImage => 'Invalid activation code found in image';

  @override
  String get invalidAcFormatDetailed =>
      'Invalid Activation Code format. Must start with LPA:1\$...';

  @override
  String get downloadProfileTitle => 'Download Profile';

  @override
  String get connectingToEuicc => 'Connecting to eUICC...';

  @override
  String get gettingChallenge => 'Getting eUICC Challenge...';

  @override
  String get authenticatingWithSmdp => 'Authenticating with SM-DP+...';

  @override
  String get verifyingSignatures => 'Verifying SM-DP+ Signatures...';

  @override
  String get retrievingMetadata => 'Retrieving Profile Metadata...';

  @override
  String get preparingDownload => 'Preparing download...';

  @override
  String get preparingEuicc => 'Preparing eUICC...';

  @override
  String get fetchingProfilePackage => 'Fetching Profile Package...';

  @override
  String installing(Object sent, Object total) {
    return 'Installing ($sent / $total bytes)...';
  }

  @override
  String get finalizing => 'Finalizing (Updating storage info)...';

  @override
  String get profileInstalledSuccessfully => 'Profile installed successfully!';

  @override
  String get provider => 'Provider';

  @override
  String get iccid => 'ICCID';

  @override
  String get plmn => 'PLMN';

  @override
  String get storage => 'Storage';

  @override
  String get free => 'Free';

  @override
  String get nvram => 'NVRAM';

  @override
  String get exportCertificates => 'Export Certificates';

  @override
  String get euiccCert => 'eUICC Cert';

  @override
  String get eumCert => 'EUM Cert';

  @override
  String get enterConfirmationCode => 'Enter the code required by your carrier';

  @override
  String get confirmationCodeRequired => 'Confirmation code is required';

  @override
  String get download => 'Download';

  @override
  String get installationSuccessful => 'Installation Successful';

  @override
  String get installationSuccessMessage =>
      'The profile has been successfully installed on your eUICC.';

  @override
  String get consumed => 'Consumed';

  @override
  String get enableProfileNow => 'Enable Profile Now';

  @override
  String get done => 'Done';

  @override
  String get profileEnabledSuccessfully => 'Profile enabled successfully';

  @override
  String get enterNewProfileName =>
      'Enter a new name for this profile to help you identify it easier.';

  @override
  String get profileName => 'Profile Name';

  @override
  String get profileNameHint => 'e.g. Work Travel';

  @override
  String get profileRenamedSuccessfully => 'Profile renamed successfully';

  @override
  String get downloadFailed => 'Download Failed';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get savedSuccessfully => 'Saved successfully';

  @override
  String get saveCertificate => 'Save Certificate';

  @override
  String get searchingForReaders => 'Searching for readers...';

  @override
  String get initializationError => 'Initialization Error';

  @override
  String get noReadersFound => 'No Readers Found';

  @override
  String get noReadersFoundMessage =>
      'Insert a compatible reader or scan for BLE devices to manage your eSIM profiles.';

  @override
  String get scanBle => 'Scan BLE';

  @override
  String get reminderDetails => 'Reminder Details';

  @override
  String get profileNotFound => 'Profile not found';

  @override
  String get resending => 'Resending...';

  @override
  String get noAddressInNotification => 'No address in notification data';

  @override
  String get sentSuccessfully => 'Sent successfully';

  @override
  String get sendFailed => 'Send failed';

  @override
  String get copiedCurl => 'Copied cURL command to clipboard';

  @override
  String get noAddressToExport => 'No address to export';

  @override
  String get noHistoryAvailable => 'No history available';

  @override
  String get searchByIccid => 'Search by ICCID...';

  @override
  String get resendNotification => 'Resend notification';

  @override
  String get exportAsCurl => 'Export as cURL';

  @override
  String get viewDetails => 'View details';

  @override
  String get deleteEntry => 'Delete entry';

  @override
  String activeReminders(int count) {
    return '$count active reminders';
  }

  @override
  String get noScheduledReminders => 'No scheduled reminders';

  @override
  String get remindersAppearWhen =>
      'Reminders appear when you add date tags to profiles.';

  @override
  String activeTagsCount(int count) {
    return '$count active tags across all profiles';
  }

  @override
  String get searchTagsOrProfiles => 'Search tags or profiles...';

  @override
  String get noTagsFound => 'No tags found';

  @override
  String get addTagsFromProfileMenu =>
      'Add tags to your profiles from the profile edit menu to see them here.';

  @override
  String get expired => 'Expired';

  @override
  String daysLeft(int count) {
    return '${count}d left';
  }

  @override
  String hoursLeft(int count) {
    return '${count}h left';
  }

  @override
  String get expiresSoon => 'Expires soon';

  @override
  String get soon => 'soon';

  @override
  String get activeTags => 'Active Tags';

  @override
  String get addNewTag => 'Add New Tag';

  @override
  String get noTagsAssigned => 'No tags assigned to this profile';

  @override
  String get textTagHint => 'Text tag (e.g. Work, Travel)';

  @override
  String get addDateExpiryTag => 'Add Date/Expiry Tag';

  @override
  String get addNoteOptional => 'Add Note (Optional)';

  @override
  String get add => 'Add';

  @override
  String get noteHint => 'e.g. Expiry, 10GB, etc.';

  @override
  String get invalidHexString => 'Invalid Hex String';

  @override
  String get resetToDefaults => 'Reset to Defaults';

  @override
  String get resetToDefaultsSuccess => 'Reset to defaults';

  @override
  String get addAidHex => 'Add AID (Hex)';

  @override
  String get manageAutoNotif => 'Manage automatic notification processing';

  @override
  String get automaticProcessing => 'AUTOMATIC PROCESSING';

  @override
  String get notifProcessingInfo =>
      'Processing notifications helps synchronization between your eUICC and the SM-DP+ server (carrier). Removing sent notifications keeps your card storage clean.';

  @override
  String get enabling => 'Enabling';

  @override
  String get afterEnabling => 'After enabling profile';

  @override
  String get disabling => 'Disabling';

  @override
  String get afterDisabling => 'After disabling profile';

  @override
  String get installation => 'Installation';

  @override
  String get afterDownload => 'After profile download';

  @override
  String get deletion => 'Deletion';

  @override
  String get afterDeletion => 'After deleting profile';

  @override
  String get autoSend => 'Auto-Send';

  @override
  String get autoSendSubtitle => 'Send to server automatically';

  @override
  String get autoRemove => 'Auto-Remove';

  @override
  String get autoRemoveSubtitle => 'Delete from card after sending';

  @override
  String get removeWithoutSending => 'Remove Without Sending';

  @override
  String get removeWithoutSendingSubtitle =>
      'Use with caution: server won\'t be notified';

  @override
  String get permissionsActive => 'Permissions Active';

  @override
  String get permissionsRequired => 'Permissions Required';

  @override
  String get appCanSendNotif => 'App can send system notifications';

  @override
  String get requiredForReminders => 'Required for reminder alerts';

  @override
  String get unsupportedPlatformCheck =>
      'Permission checking is not supported on this platform. Please do manual testing.';

  @override
  String get couldNotVerifyStatus =>
      'Could not verify status. Please check Settings manually.';

  @override
  String get testNotificationTitle => 'Test Notification';

  @override
  String get seconds => 'seconds';

  @override
  String get startTest => 'Start Test';

  @override
  String get sendingNotif => 'Sending...';

  @override
  String get hostIpLabel => 'Hostname / IP';

  @override
  String get portLabel => 'Port';

  @override
  String get passwordOptionalLabel => 'Password (Optional)';

  @override
  String get configuredServers => 'Configured Servers';

  @override
  String get secureHttps => 'Secure (HTTPS)';

  @override
  String get insecureHttp => 'Insecure (HTTP)';

  @override
  String get urlCopied => 'URL copied';

  @override
  String get serverAddedSuccessfully => 'Server added successfully';

  @override
  String get authFailedCheckPassword =>
      'Authentication failed. Check password.';

  @override
  String get addNewServer => 'Add New Server';

  @override
  String get autoLoadRemotes => 'Auto-load Remote Devices';

  @override
  String get autoLoadRemotesSubtitle =>
      'Automatically connect to configured servers on app startup';

  @override
  String get getRemoCardGitHub => 'Get RemoCard from GitHub';

  @override
  String get instructions => 'Instructions:';

  @override
  String get instruction1 => '1. Install RemoCard app on your Android devices.';

  @override
  String get instruction2 => '2. Start the server in each RemoCard app.';

  @override
  String get instruction3 => '3. Enter the IP addresses here.';

  @override
  String get instruction4 =>
      '4. All remote SIM slots will appear in the device list.';

  @override
  String get appLogsCopied => 'Logs copied to clipboard';

  @override
  String get aramInfoTitle => 'ARA-M Information';

  @override
  String get aramInfoSubtitle => 'Access Rule Applet details';

  @override
  String get whatIsAram => 'What is ARA-M?';

  @override
  String get aramDescription =>
      'Access Rule Applet (ARA-M) is a mechanism on eUICCs (eSIMs) and SIM cards that defines which applications are allowed to manage profiles or perform low-level operations. If the app\'s hash is not present in the card\'s ARA-M allowlist, the Android system will block access, resulting in an \'Access Denied\' error.';

  @override
  String get appCertHashes => 'App Certificate Hashes';

  @override
  String get aramHashInstruction =>
      'To grant this app access, you may need to add the following SHA-1 certificate hash to your card\'s ARA-M rules. This hash is unique to your current app build\'s certificate.';

  @override
  String get aramSigningHistoryInstruction =>
      'For compatibility across Android versions, add all SHA-1 certificate hashes below to your card\'s ARA-M rules. After an app signing key upgrade, different Android versions may check different certificates from the verified signing history.';

  @override
  String get certSha1Hash => 'Certificate SHA-1 Hash';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get troubleshooting => 'Troubleshooting';

  @override
  String get troubleStep1 => 'Ensure you are using the correct Card Reader.';

  @override
  String get troubleStep2 =>
      'If using a physical card, check if it\'s a test card or a production card (production cards often lock ARA-M).';

  @override
  String get troubleStep3 =>
      'The hashes above depend on whether you use the Debug, Regular, or Privileged (Magisk) version of the app.';

  @override
  String get troubleStep4 =>
      'Consider using the Privileged (Magisk) build which can bypass some Android API restrictions.';

  @override
  String get hashCopied => 'Hash copied to clipboard';

  @override
  String get aidCopied => 'AID copied to clipboard';

  @override
  String get lastSeen => 'Last Seen';

  @override
  String get unknownProvider => 'Unknown Provider';

  @override
  String get unknownProfile => 'Unknown Profile';

  @override
  String get tags => 'Tags';

  @override
  String get noTags => 'No tags';

  @override
  String records(int count) {
    return '$count records';
  }

  @override
  String get bytes => 'bytes';

  @override
  String get responseCode => 'Response Code';

  @override
  String get responseBody => 'Response Body';

  @override
  String get type => 'Type';

  @override
  String profileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count profiles',
      one: '1 profile',
    );
    return '$_temp0';
  }

  @override
  String get isdrAids => 'ISD-R AIDs';

  @override
  String get configureDefaultAids => 'Configure default Application IDs';

  @override
  String get addAidHexHint => 'Add AID (Hex)';

  @override
  String get notificationProcessing => 'Notifications';

  @override
  String get manageAutoNotification =>
      'Manage automatic notification processing';

  @override
  String get notificationProcessingHelp =>
      'Processing notifications helps synchronization between your eUICC and the SM-DP+ server (carrier). Removing sent notifications keeps your card storage clean.';

  @override
  String get notificationProcessingTimings => 'Processing timings';

  @override
  String get notificationProcessingTimingsHelp =>
      'Choose when automatic notification processing runs. Some safety-critical timings can only be disabled while Developer Mode is enabled.';

  @override
  String get afterEnablingProfile => 'After enabling profile';

  @override
  String get afterDisablingProfile => 'After disabling profile';

  @override
  String get afterProfileDownload => 'After profile download';

  @override
  String get afterProfileDeletion => 'After deleting profile';

  @override
  String get initialLoad => 'Initial load';

  @override
  String get processNotificationsOnInitialLoad =>
      'Process notifications after profiles finish loading';

  @override
  String get afterSwitchingProfile => 'After switching profile';

  @override
  String get processNotificationsAfterSwitchingProfile =>
      'Process notifications after enabling or disabling a profile';

  @override
  String get beforeProfileDownload => 'Before profile download';

  @override
  String get processNotificationsBeforeProfileDownload =>
      'Process notifications before starting a profile download';

  @override
  String get afterProfileInstalled => 'After profile installed';

  @override
  String get processNotificationsAfterProfileInstalled =>
      'Process notifications after a profile has been installed';

  @override
  String get processNotificationsAfterProfileDeletion =>
      'Process notifications after deleting a profile';

  @override
  String get developerModeRequiredToDisableTiming =>
      'Enable Developer Mode to disable this timing.';

  @override
  String get sendToServerAutomatically => 'Send to server automatically';

  @override
  String get removeFromCardAfterSending => 'Delete from card after sending';

  @override
  String get removeWithoutSendingCaution =>
      'Use with caution: server won\'t be notified';

  @override
  String get reminderSettings => 'Reminder Settings';

  @override
  String get appCanSendNotifications => 'App can send system notifications';

  @override
  String get requiredForReminderAlerts => 'Required for reminder alerts';

  @override
  String get enable => 'Enable';

  @override
  String get permissionCheckNotSupported =>
      'Permission checking is not supported on this platform. Please do manual testing.';

  @override
  String get testNotification => 'Test Notification';

  @override
  String get notificationsDisabledMessage =>
      'Notifications are disabled. Please enable them in system settings to receive reminders.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get applicationLogs => 'Application Logs';

  @override
  String get refreshReload => 'Refresh/Reload';

  @override
  String get toggleAutoScroll => 'Toggle Auto-scroll';

  @override
  String get refreshDevices => 'Refresh devices';

  @override
  String get scanBluetooth => 'Scan Bluetooth';

  @override
  String get lessThan1Kb => '< 1 KB';

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String get downloadRemoCard => 'Download RemoCard';

  @override
  String get remoCardAndroidApp => 'Android app for Remote Controllers';

  @override
  String get resentSuccessfully => 'Resent successfully';

  @override
  String get resendFailed => 'Resend failed';

  @override
  String get eid => 'EID';

  @override
  String get seq => 'Seq';

  @override
  String get date => 'Date';

  @override
  String errorWithDetails(String error) {
    return 'Error: $error';
  }

  @override
  String exportFailed(String error) {
    return 'Failed to export database: $error';
  }

  @override
  String get sasAccreditation => 'SAS Accreditation';

  @override
  String get firmwareVersion => 'Firmware Version';

  @override
  String get beeSimFirmwareAction => 'Update BeeSIM firmware';

  @override
  String get beeSimFirmwareTitle => 'BeeSIM firmware update';

  @override
  String get beeSimFirmwareWarning =>
      'A BeeSIM firmware update is available. Keep the card powered, Bluetooth connected, and the app open until it finishes. Interrupting the update may leave the card temporarily unusable.';

  @override
  String get beeSimFirmwareConfirm => 'Update firmware';

  @override
  String get platformSupport => 'PLATFORM SUPPORT';

  @override
  String get rspVersion => 'RSP Version';

  @override
  String get bppVersion => 'BPP Version';

  @override
  String get gpVersion => 'GlobalPlatform Version';

  @override
  String get certInfrastructure => 'CERTIFICATE INFRASTRUCTURE';

  @override
  String get configuredAddresses => 'CONFIGURED ADDRESSES';

  @override
  String get defaultSmdpAddress => 'Default SM-DP+';

  @override
  String get rootDsAddress => 'Root SM-DS';

  @override
  String get euiccSignCi => 'eUICC Sign CI';

  @override
  String get euiccVerifyCi => 'eUICC Verify CI';

  @override
  String get none => 'None';

  @override
  String keysCount(int count) {
    return '$count key(s)';
  }

  @override
  String get state => 'State';

  @override
  String get profileClass => 'Class';

  @override
  String get aid => 'AID';

  @override
  String get euiccSpecifications => 'EUICC SPECIFICATIONS';

  @override
  String get sending => 'Sending...';

  @override
  String get failedToSaveTags => 'Failed to save tags';

  @override
  String get note => 'Note';

  @override
  String get notificationDetails => 'Notification Details';

  @override
  String get unknown => 'Unknown';

  @override
  String get status => 'Status';

  @override
  String get sent => 'Sent';

  @override
  String get pending => 'Pending';

  @override
  String get notifTypeInstall => 'Install';

  @override
  String get notifTypeDelete => 'Delete';

  @override
  String get notifTypeEnable => 'Enable';

  @override
  String get notifTypeDisable => 'Disable';

  @override
  String get notifTypeRpmEnable => 'RPM Enable';

  @override
  String get notifTypeRpmDisable => 'RPM Disable';

  @override
  String get notifTypeRpmDelete => 'RPM Delete';

  @override
  String get notifTypeLoadRpm => 'Load RPM';

  @override
  String confirmDeleteNotification(int seq) {
    return 'Are you sure you want to delete notification #$seq?';
  }

  @override
  String get notificationRemoved => 'Notification removed';

  @override
  String failedToRemove(String error) {
    return 'Failed to remove: $error';
  }

  @override
  String get curlCopied => 'cURL command extracted to clipboard';

  @override
  String failedToGenerateCurl(String error) {
    return 'Failed to generate cURL: $error';
  }

  @override
  String get noNotificationAddress => 'No notification address available';

  @override
  String get sendingNotification => 'Sending notification...';

  @override
  String get notifSentSuccessfully => 'Notification sent successfully';

  @override
  String get failedToSendNotification => 'Failed to send notification';

  @override
  String errorSendingNotification(String error) {
    return 'Error sending notification: $error';
  }

  @override
  String pendingCount(int count) {
    return '$count pending';
  }

  @override
  String get currentReader => 'Current Reader';

  @override
  String get errorLoadingNotifications => 'Error loading notifications';

  @override
  String get allCaughtUp => 'You\'re all caught up';

  @override
  String get sequence => 'Sequence';

  @override
  String get operation => 'Operation';

  @override
  String get profileNameLabel => 'Profile Name';

  @override
  String get failedToSend => 'Failed to send';

  @override
  String get onCard => 'On card';

  @override
  String get sendNotification => 'Send notification';

  @override
  String get deleteNotification => 'Delete notification';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get batchDownloadTitle => 'Batch Download';

  @override
  String get batchDownloadHint =>
      'Paste multiple LPA codes here (one per line, max 20)';

  @override
  String foundLpaCodes(int count) {
    return '$count LPA codes found';
  }

  @override
  String get startBatch => 'Start Batch';

  @override
  String get noLpaCodesFound => 'No valid LPA codes found';

  @override
  String get insufficientSpaceStoppingBatch =>
      'Insufficient space. Stopping batch download.';

  @override
  String get exportCsv => 'Export to CSV';

  @override
  String get exportedSuccessfully => 'Exported successfully';

  @override
  String get exportResults => 'Export Results';

  @override
  String get lpa => 'LPA';

  @override
  String get smdp => 'SM-DP+';

  @override
  String get confirmationCode => 'Confirmation Code';

  @override
  String get size => 'Size';

  @override
  String get message => 'Message';

  @override
  String get remainingSpace => 'Remaining Space';

  @override
  String get stopBatch => 'Stop Batch';

  @override
  String get stopping => 'Stopping...';

  @override
  String get remove => 'Remove';

  @override
  String get updateAvailable => 'Update Available';

  @override
  String updateAvailableSubtitle(String appName, String version, String build) {
    return 'A new version of $appName is available (v$version b$build). Would you like to update now?';
  }

  @override
  String get updateAction => 'Update';

  @override
  String get later => 'Later';

  @override
  String get changelog => 'Changelog';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortIccid => 'ICCID';

  @override
  String get sortCountry => 'Country';

  @override
  String get sortAscending => 'Ascending';

  @override
  String get sortDescending => 'Descending';

  @override
  String get searchProfiles => 'Search profiles...';

  @override
  String get noProfilesMatch => 'No profiles match your search.';

  @override
  String get sortDefault => 'Default';

  @override
  String get sortNickname => 'Nickname';

  @override
  String get showProfileSearch => 'Show Profile Search';

  @override
  String get showProfileSearchSubtitle =>
      'Show search and sort bar in profile list';

  @override
  String get noReaderFound =>
      'No reader found. Please connect your eUICC adapter.';

  @override
  String get readyToInstallProfile => 'Ready to install profile.';

  @override
  String get downloadHere => 'Download Here';

  @override
  String get manage => 'Manage';

  @override
  String get buyCard => 'Card';

  @override
  String get buyData => 'Data';

  @override
  String get selectDevice => 'Select Device';

  @override
  String get selectReaderTitle => 'Select Card';

  @override
  String get authorizeSigning => 'Authorize Signing';

  @override
  String get signingDescription =>
      'A website is requesting a secure signature from your eUICC.';

  @override
  String get smdpAddress => 'SM-DP+ Address';

  @override
  String get sign => 'Sign';

  @override
  String profilesInstalled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count profiles installed',
      one: '1 profile installed',
    );
    return '$_temp0';
  }

  @override
  String get estimatedDownloadSize => 'Estimated download size';

  @override
  String get phoneFormatInternationalOnly => 'E.164 Int\'l Only';

  @override
  String get phoneFormatInternationalAndMobile => 'Int\'l & Mobile';

  @override
  String get phoneFormatInternationalAndAll => 'Int\'l & National';

  @override
  String get phoneFormatOff => 'Off';

  @override
  String get settings_item_unit_b => 'Bytes';

  @override
  String get settings_item_unit_kb => 'kB (1,000 Bytes)';

  @override
  String get settings_item_unit_kib => 'kiB (1,024 Bytes)';

  @override
  String get settings_item_unit_adaptive_si => 'B / kB Adaptive';

  @override
  String get settings_item_unit_adaptive_bi => 'B / kiB Adaptive';

  @override
  String get insufficientStorageWarning =>
      'Insufficient storage for installation. Installation might fail.';

  @override
  String get estimateProfileSize => 'Estimate Profile Size';

  @override
  String get estimateProfileSizeSubtitle =>
      'Estimate size of profile metadata before download';

  @override
  String get customize => 'Customize';

  @override
  String get customizeDescription =>
      'Specify a new 6-character hex name and password for your writer.';

  @override
  String get customizeSuccess =>
      'Writer customized. Please re-pair the device.';

  @override
  String customizeFailed(String error) {
    return 'Failed to customize writer: $error';
  }

  @override
  String get defaultPasswordWillChangeTitle => 'Default password will change';

  @override
  String defaultPasswordWillChangeMessage(String password) {
    return 'This device is connected with its default password. Renaming it will set the password to $password. Save this password before reconnecting.';
  }

  @override
  String get savedBleDevices => 'Previously connected BLE devices';

  @override
  String get savedBleDevicesSubtitle =>
      'View device names and passwords saved on this device';

  @override
  String get savedBleDevicesDescription =>
      'Each entry is a locally saved NBLESim password. Default passwords are saved too.';

  @override
  String get noSavedBleDevices => 'No previously connected BLE devices.';

  @override
  String get deviceName => 'Device Name';

  @override
  String get success => 'Success';

  @override
  String get devicePasswordHint => '6 hex chars or password string';

  @override
  String get sixHexChars => '6 hex chars';

  @override
  String get database => 'Database';

  @override
  String exportSuccess(String path) {
    return 'Database exported to $path';
  }

  @override
  String get importDatabase => 'Import Database';

  @override
  String get importDatabaseSubtitle => 'Merge rows from another database file';

  @override
  String get importDatabaseDialogTitle => 'Select database file to import';

  @override
  String get importDatabaseTitle => 'Import Database';

  @override
  String get importDatabaseContent =>
      'This will merge rows from the selected database into your current database. Existing rows with the same keys will be overwritten. Continue?';

  @override
  String get import => 'Import';

  @override
  String get importSuccess => 'Database imported successfully';

  @override
  String importFailed(String error) {
    return 'Failed to import database: $error';
  }

  @override
  String get resetDatabase => 'Reset Database';

  @override
  String get resetDatabaseSubtitle => 'Clear all application data and restart';

  @override
  String get resetDatabaseTitle => 'Reset Application Database';

  @override
  String get resetDatabaseContent =>
      'This will completely delete all locally stored data, configurations, and logs. The application will close. Do you want to proceed?';

  @override
  String get deleteDatabase => 'Delete Database';

  @override
  String resetFailed(String error) {
    return 'Failed to reset database: $error';
  }

  @override
  String get deviceImei => 'Device TAC';

  @override
  String get deviceImeiSubtitle => 'Used for profile downloads';

  @override
  String get editDeviceImei => 'Edit Device TAC';

  @override
  String get editDeviceImeiInfo =>
      'Enter an 8-digit TAC, or a 15-digit IMEI. Default TAC: 35383741.';

  @override
  String get imeiDigits => 'TAC or IMEI digits';

  @override
  String get importAction => 'Import';

  @override
  String get transferTitle => 'Transfer eSIM';

  @override
  String get transferAction => 'Transfer to this device';

  @override
  String get transferCheckingEligibility => 'Checking eligibility…';

  @override
  String get transferReadingSource => 'Reading source SIM…';

  @override
  String get transferContactingCarrier => 'Contacting carrier…';

  @override
  String get transferIneligibleReader =>
      'This profile cannot be transferred on this reader. The source SIM\'s authentication (EAP-AKA) is not reachable here.';

  @override
  String get transferNoEntitlement =>
      'No carrier transfer configuration was found for this profile. You can enter the entitlement server manually.';

  @override
  String transferSourceCarrier(String carrier) {
    return 'Source carrier: $carrier';
  }

  @override
  String get transferConfirmTitle => 'Transfer this subscription?';

  @override
  String get transferConfirmBody =>
      'The carrier will re-issue this subscription onto this eUICC. The source profile may be deleted as part of the transfer.';

  @override
  String get transferStart => 'Start transfer';

  @override
  String get transferDownloadingProfile => 'Downloading transferred profile…';

  @override
  String get transferDeleteSourceTitle => 'Delete source profile';

  @override
  String transferDeleteSourceBody(String iccid) {
    return 'The carrier requires the source profile $iccid to be deleted before activation. Delete it now?';
  }

  @override
  String get transferDeleteSourceConfirm => 'Delete and continue';

  @override
  String get transferUserInputSubmit => 'Submit';

  @override
  String get transferAccept => 'Accept';

  @override
  String get transferReject => 'Decline';

  @override
  String get transferPendingActivation =>
      'The carrier is still activating this subscription. It will finish shortly; you can close this and check again later.';

  @override
  String get transferDismissed => 'The carrier dismissed the transfer.';

  @override
  String get transferDelayedDownload =>
      'The carrier will deliver the profile shortly. Once you have installed it, enter the installed ICCID to finish.';

  @override
  String get transferInstalledIccid => 'Installed ICCID';

  @override
  String get transferSuccess => 'Transfer complete';

  @override
  String transferFailed(String error) {
    return 'Transfer failed: $error';
  }

  @override
  String get transferManualServerTitle => 'Entitlement server (advanced)';

  @override
  String get transferManualServerHint => 'https://entitlement.example.com';

  @override
  String get transferEnablingSource => 'Preparing source profile…';

  @override
  String get transferClose => 'Close';

  @override
  String get transferContinue => 'Continue';

  @override
  String get transferSmdsDiscovering => 'Discovering profiles via SM-DS…';

  @override
  String get transferSmdsNoProfiles =>
      'No pending profiles were found via SM-DS discovery.';

  @override
  String get transferSelectProfile => 'Select a profile to download';

  @override
  String get discoverProfiles => 'Discover profiles (SM-DS)';

  @override
  String get discoveringProfiles => 'Discovering profiles…';

  @override
  String get discoveryNoProfiles =>
      'No pending profiles were found via SM-DS discovery.';

  @override
  String get transferSmdsServerTitle => 'SM-DS server';

  @override
  String transferProfileOnServer(String eventId, String address) {
    return '$eventId on $address';
  }

  @override
  String get downloadBusyCannotLeave =>
      'Please wait for the current operation to finish.';

  @override
  String get qrtrReaderTitle => 'Qualcomm modem (QRTR)';

  @override
  String get qrtrReaderSubtitle =>
      'Qualcomm\'s low-level modem protocol (requires Shizuku)';

  @override
  String get voWifiCallHistory => 'Call history';

  @override
  String get voWifiRefreshCallHistory => 'Refresh call history';

  @override
  String get voWifiKeypad => 'Keypad';

  @override
  String get voWifiAllCalls => 'All calls';

  @override
  String get voWifiMissed => 'Missed';

  @override
  String get voWifiCouldNotLoadCallHistoryPullDownToRetry =>
      'Could not load call history. Pull down to retry.';

  @override
  String get voWifiNoCallHistoryYet => 'No call history yet';

  @override
  String get voWifiCompleted => 'Completed';

  @override
  String get voWifiInCall => 'In call';

  @override
  String get voWifiFailed => 'Failed';

  @override
  String get voWifiDeclinedBusy => 'Declined / busy';

  @override
  String get voWifiNotAnswered => 'Not answered';

  @override
  String get voWifiInterruptedFinalStateUnknown =>
      'Interrupted · final state unknown';

  @override
  String get voWifiConnecting => 'Connecting';

  @override
  String get voWifiIncoming => 'Incoming';

  @override
  String get voWifiOutgoing => 'Outgoing';

  @override
  String get voWifiUnknownCaller => 'Unknown caller';

  @override
  String get voWifiDuration => 'Duration';

  @override
  String get voWifiUseNumberInDialer => 'Use number in dialer';

  @override
  String get voWifiFilterMessages => 'Filter messages';

  @override
  String get voWifiAll => 'All';

  @override
  String get voWifiInbox => 'Inbox';

  @override
  String get voWifiSent => 'Sent';

  @override
  String get voWifiUnhideToSearch => 'Unhide to search';

  @override
  String get voWifiSearch => 'Search';

  @override
  String get voWifiNewMessage => 'New message';

  @override
  String get voWifiMessages => 'Messages';

  @override
  String get voWifiCouldNotLoadMessagesPullDownToRetry =>
      'Could not load messages. Pull down to retry.';

  @override
  String get voWifiNoConversations => 'No conversations';

  @override
  String get voWifiNoReceivedMessagesYet => 'No received messages yet';

  @override
  String get voWifiNoSentMessagesYet => 'No sent messages yet';

  @override
  String get voWifiConnectWiFiCallingAndKeepTheAppIn =>
      'Connect Wi-Fi calling and keep the app in the foreground to receive calls and SMS.';

  @override
  String get voWifiMessageHidden => 'Message hidden';

  @override
  String get voWifiYesterday => 'Yesterday';

  @override
  String get voWifiConversations => 'Conversations';

  @override
  String get voWifiReply => 'Reply';

  @override
  String get voWifiReceived => 'Received';

  @override
  String get voWifiSubmittedDeliveryUnconfirmed =>
      'Submitted, delivery unconfirmed';

  @override
  String get voWifiSubmitting => 'Submitting';

  @override
  String get voWifiRecents => 'Recents';

  @override
  String get voWifiCall => 'Call';

  @override
  String get voWifiDeleteDigit => 'Delete digit';

  @override
  String get voWifiIdle => 'Idle';

  @override
  String get voWifiCalling => 'Calling';

  @override
  String get voWifiRinging => 'Ringing';

  @override
  String get voWifiIncomingCall => 'Incoming call';

  @override
  String get voWifiEndingCall => 'Ending call';

  @override
  String get voWifiCallEnded => 'Call ended';

  @override
  String get voWifiDeclined => 'Declined';

  @override
  String get voWifiBusy => 'Busy';

  @override
  String get voWifiSubmitted => 'Submitted';

  @override
  String get voWifiWiFiCalling => 'Wi-Fi calling';

  @override
  String get voWifiDial => 'Dial';

  @override
  String get voWifiBack => 'Back';

  @override
  String get voWifiConnectionSettings => 'Connection settings';

  @override
  String get voWifiConnectionOverview => 'Connection overview';

  @override
  String get voWifiOverview => 'Overview';

  @override
  String get voWifiRecentCalls => 'Recent calls';

  @override
  String get voWifiIncomingOutgoingAndMissed => 'Incoming, outgoing and missed';

  @override
  String get voWifiGroupedBySIMAndNumber => 'Grouped by SIM and number';

  @override
  String get voWifiUSBCCIDSmartCardReader => 'USB CCID smart-card reader';

  @override
  String get voWifiBluetoothSIMReader => 'Bluetooth SIM reader';

  @override
  String get voWifiMyNumber => 'My number';

  @override
  String get voWifiCopied => 'Copied';

  @override
  String get voWifiCopyMyNumber => 'Copy my number';

  @override
  String get voWifiTheCarrierHasNotSuppliedAPhoneNumber =>
      'The carrier has not supplied a phone number';

  @override
  String get voWifiConnectionDetails => 'Connection details';

  @override
  String get voWifiStoppingWiFiCalling => 'Stopping Wi-Fi calling…';

  @override
  String get voWifiPleaseWait => 'Please wait…';

  @override
  String get voWifiStopWiFiCalling => 'Stop Wi-Fi calling';

  @override
  String get voWifiConnect => 'Connect';

  @override
  String get voWifiCarrierSettingsAreDetectedFromTheActiveSIM =>
      'Carrier settings are detected from the active SIM';

  @override
  String get voWifiEPDGHostOptional => 'ePDG host (optional)';

  @override
  String get voWifiProxyURLOptional => 'Proxy URL (optional)';

  @override
  String get voWifi127001RefersToThisIPhoneNot =>
      '127.0.0.1 refers to this iPhone, not your Mac. To use a proxy on your Mac, enter its LAN address.';

  @override
  String get voWifiIMEIOptional => 'IMEI (optional)';

  @override
  String get voWifiStopWiFiCallingBeforeManagingProfilesOrChanging =>
      'Stop Wi-Fi calling before managing profiles or changing readers.';

  @override
  String get voWifiCallsUseTheIPhoneSystemCallScreenReaderSMS =>
      'Calls use the iPhone system call screen. Reader SMS is stored separately from Apple Messages. iOS may pause an idle connection after backgrounding or locking. Returning to the foreground or changing networks checks the connection and reconnects when needed; new calls and SMS wait for verification. Force-quitting ends the session, so reconnect manually after reopening.';

  @override
  String get voWifiPhoneNumber => 'Phone number';

  @override
  String get voWifiCountryCodeAndNumber => '+ country code and number';

  @override
  String get voWifiHideKeyboard => 'Hide keyboard';

  @override
  String get voWifiCalls => 'Calls';

  @override
  String get voWifiReadyForIncomingCallsSystemAnswerDecline =>
      'Ready for incoming calls · system Answer / Decline';

  @override
  String get voWifiConnectWiFiCallingToReceiveCalls =>
      'Connect Wi-Fi calling to receive calls';

  @override
  String get voWifiCallHistoryCouldNotBeSavedOnThisDevice =>
      'Call history could not be saved on this device';

  @override
  String get voWifiIncomingOutgoingAndMissedCalls =>
      'Incoming, outgoing and missed calls';

  @override
  String get voWifiAllMessages => 'All messages';

  @override
  String get voWifiYourRecentReaderMessagesWillAppearHere =>
      'Your recent reader messages will appear here.';

  @override
  String get voWifiStoredOnThisDeviceSubmittedMessagesAreNotConfirmed =>
      'Stored on this device. Submitted messages are not confirmed delivered.';

  @override
  String get voWifiMessage => 'Message';

  @override
  String get voWifiWriteAMessage => 'Write a message…';

  @override
  String get voWifiSending => 'Sending…';

  @override
  String get voWifiSendSMS => 'Send SMS';

  @override
  String get voWifiTo => 'To';

  @override
  String get voWifiFrom => 'From';

  @override
  String get voWifiAudioConnected => 'Audio connected';

  @override
  String get voWifiAnswer => 'Answer';

  @override
  String get voWifiDecline => 'Decline';

  @override
  String get voWifiHangUp => 'Hang up';

  @override
  String get voWifiReader => 'Reader';

  @override
  String get voWifiReady => 'Ready';

  @override
  String get voWifiComplete => 'complete';

  @override
  String get voWifiFailed2 => 'failed';

  @override
  String get voWifiInProgress => 'in progress';

  @override
  String get voWifiWaiting => 'waiting';

  @override
  String get voWifiWiFiCallingConnectionProgress =>
      'Wi-Fi calling connection progress';

  @override
  String get voWifiCheckingConnection => 'Checking connection…';

  @override
  String get voWifiReadingTheActiveSIM => 'Reading the active SIM…';

  @override
  String get voWifiPreparingEPDGNetworkPath => 'Preparing ePDG network path…';

  @override
  String get voWifiWaitingForTheFirstEPDGResponse =>
      'Waiting for the first ePDG response…';

  @override
  String get voWifiWaitingForCarrierAuthentication =>
      'Waiting for carrier authentication…';

  @override
  String get voWifiRespondingToCarrierIdentityRequest =>
      'Responding to carrier identity request…';

  @override
  String get voWifiProcessingSIMAKAAuthentication =>
      'Processing SIM AKA authentication…';

  @override
  String get voWifiWaitingForCarrierAuthenticationResult =>
      'Waiting for carrier authentication result…';

  @override
  String get voWifiConfirmingTheAuthenticatedTunnel =>
      'Confirming the authenticated tunnel…';

  @override
  String get voWifiPreparingTheEncryptedTunnel =>
      'Preparing the encrypted tunnel…';

  @override
  String get voWifiConnectingToTheCarrierEPDG =>
      'Connecting to the carrier ePDG…';

  @override
  String get voWifiRegisteringWithIMS => 'Registering with IMS…';

  @override
  String get voWifiIMSRegistered => 'IMS registered';

  @override
  String get voWifiWaitingForIMSRegistration => 'Waiting for IMS registration…';

  @override
  String get voWifiConnectionInterruptedRetrying =>
      'Connection interrupted; retrying…';

  @override
  String get voWifiConnectionFailed => 'Connection failed';

  @override
  String get voWifiSessionStoppedWhileTheAppWasInTheBackground =>
      'Session stopped while the app was in the background';

  @override
  String get voWifiDisconnected => 'Disconnected';

  @override
  String get voWifiReadyToConnectWithTheActiveSIM =>
      'Ready to connect with the active SIM';

  @override
  String get voWifiShowSensitiveInformation => 'Show sensitive information';

  @override
  String get voWifiHideSensitiveInformation => 'Hide sensitive information';

  @override
  String get voWifiTheActionCouldNotBeCompletedTryAgain =>
      'The action could not be completed. Try again.';

  @override
  String get voWifiSpeaker => 'Speaker';

  @override
  String get voWifiMute => 'Mute';

  @override
  String get voWifiHideKeypad => 'Hide keypad';

  @override
  String get voWifiEndCall => 'End call';

  @override
  String get voWifiDeleteRecords => 'Delete records?';

  @override
  String get voWifiCancel => 'Cancel';

  @override
  String get voWifiDelete => 'Delete';

  @override
  String get voWifiCouldNotUpdateRecordsTryAgain =>
      'Could not update records. Try again.';

  @override
  String get voWifiDone => 'Done';

  @override
  String get voWifiEdit => 'Edit';

  @override
  String get voWifiDeselectAll => 'Deselect all';

  @override
  String get voWifiSelectAll => 'Select all';

  @override
  String get voWifiDeleteSelected => 'Delete selected';

  @override
  String get voWifiRead => 'Read';

  @override
  String voWifiDeleteRecordCount(int count) {
    return 'Delete the $count selected records from this device? This cannot be undone.';
  }

  @override
  String voWifiSelectedRecordCount(int count) {
    return '$count records selected';
  }

  @override
  String get voWifiIMEIMustContain15Digits => 'IMEI must contain 15 digits';

  @override
  String get voWifiIMEIMustHave15DigitsAndAValidCheck =>
      'IMEI must have 15 digits and a valid check digit';

  @override
  String get voWifiCouldNotSaveWiFiCallingSettings =>
      'Could not save Wi-Fi calling settings';

  @override
  String get voWifiTheNativeWiFiCallingEngineIsUnavailableIn =>
      'The native Wi-Fi calling engine is unavailable in this build';

  @override
  String get voWifiCallKitRejectedTheTransactionBecauseTheAppNeedsThe =>
      'CallKit rejected the transaction because the app needs the VoIP background mode.';

  @override
  String get voWifiAWiFiCallingSessionIsAlreadyActive =>
      'A Wi-Fi calling session is already active';

  @override
  String get voWifiThisReaderDoesNotSupportWiFiCalling =>
      'This reader does not support Wi-Fi calling';

  @override
  String get voWifiConnectThisReaderInManageBeforeStartingWiFi =>
      'Connect this reader in Manage before starting Wi-Fi calling';

  @override
  String get voWifiTheSIMReaderDisconnected => 'The SIM reader disconnected';

  @override
  String get voWifiTheActiveSIMDidNotProvideAnIMSI =>
      'The active SIM did not provide an IMSI';

  @override
  String get voWifiWiFiCallingIsNotReady => 'Wi-Fi calling is not ready';

  @override
  String get voWifiIMSMessagingIsNotRegistered =>
      'IMS messaging is not registered';

  @override
  String get voWifiSIMSessionChanged => 'SIM session changed';

  @override
  String get voWifiSIMSessionHasEnded => 'SIM session has ended';

  @override
  String get voWifiSIMSessionWasCancelled => 'SIM session was cancelled.';

  @override
  String get voWifiIncomingSMSCouldNotBeSavedOnThisDevice =>
      'Incoming SMS could not be saved on this device';

  @override
  String get voWifiMicrophonePermissionIsRequiredToMakeACall =>
      'Microphone permission is required to make a call.';

  @override
  String get voWifiOpenTheAppToConnectVoWiFi =>
      'Open the app to connect VoWiFi.';

  @override
  String get voWifiStopTheCurrentVoWiFiSessionBeforeConnecting =>
      'Stop the current VoWiFi session before connecting.';

  @override
  String get voWifiConnectionCancelled => 'Connection cancelled.';

  @override
  String get voWifiTheSIMReaderDidNotAnswerWithin30Seconds =>
      'The SIM reader did not answer within 30 seconds.';

  @override
  String get voWifiNewWiFiSMS => 'New Wi-Fi SMS';

  @override
  String get voWifiOpenToReadYourMessage =>
      'Open the app to read your message.';

  @override
  String get voWifiReaderInUse =>
      'Wi-Fi calling is using the reader. Stop it before managing profiles.';

  @override
  String get voWifiCouldNotConfirmConnectionState =>
      'Could not confirm the current connection state';

  @override
  String get voWifiCannotCorrectSIMCommandLength =>
      'Cannot correct SIM command length';

  @override
  String get voWifiIncompleteSIMResponse => 'Incomplete SIM response';

  @override
  String get voWifiInvalidSIMCommandBatch => 'Invalid SIM command batch';

  @override
  String get voWifiInvalidSIMCommandBatchSize =>
      'Invalid SIM command batch size';

  @override
  String get voWifiInvalidSIMCommandEncoding => 'Invalid SIM command encoding';

  @override
  String get voWifiInvalidWiFiCallingResponse =>
      'Invalid Wi-Fi calling response';

  @override
  String get voWifiInvalidIncomingSMSSegments =>
      'Invalid incoming SMS segments';

  @override
  String get voWifiSIMResponseExceedsSizeLimit =>
      'SIM response exceeds size limit';

  @override
  String get voWifiTheSIMReaderDidNotReconnectPleaseRetry =>
      'The SIM reader did not reconnect. Please retry.';

  @override
  String get voWifiTheSIMReaderDisconnectedReconnectItAndTryWi =>
      'The SIM reader disconnected. Reconnect it and try Wi-Fi calling again.';

  @override
  String get voWifiTheNativeEngineReportedAnError =>
      'The native engine reported an error';

  @override
  String get voWifiTooManySIMResponseContinuations =>
      'Too many SIM response continuations';

  @override
  String get voWifiUnknownWiFiCallingCallback =>
      'Unknown Wi-Fi calling callback';

  @override
  String voWifiSimStatus(String status) {
    return 'SIM status $status';
  }

  @override
  String get adbBridgeTitle => 'Connect using computer';

  @override
  String get adbBridgeSubtitle =>
      'Reach the card over a one-time ADB session — no root, no Shizuku';

  @override
  String get adbBridgeDescription =>
      'Opening a channel to the card needs a caller the system trusts, which the app is not. The shell user is, and a computer can start a helper as shell over ADB.\n\nWith the phone plugged in and USB debugging on, open the connection, copy the command, and run it on the computer while the timer is going. Keep that terminal open — closing it ends the session. Reconnect after a reboot or an app update.';

  @override
  String get adbBridgeStart => 'Start connection';

  @override
  String get adbBridgeRestart => 'Start connection again';

  @override
  String get adbBridgeDisconnect => 'Disconnect';

  @override
  String get adbBridgeCopy => 'Copy ADB command';

  @override
  String get adbBridgeCopied => 'Command copied';

  @override
  String get adbBridgeConnected => 'Connected';

  @override
  String get adbBridgeWaiting => 'Waiting for the computer…';

  @override
  String get adbBridgeDisconnected => 'Not connected';

  @override
  String adbBridgeWindow(int seconds) {
    return 'Run the command within ${seconds}s.';
  }

  @override
  String get seHalReaderTitle => 'SE HAL (direct access)';

  @override
  String get seHalReaderSubtitle =>
      'SIM cards and built-in eSIMs through the Secure Element HAL (requires Shizuku)';

  @override
  String get seHalAdvancedSettings => 'SE HAL advanced settings';

  @override
  String seHalBorrowSlot(int slot) {
    return 'SIM$slot: borrow channel 1';
  }

  @override
  String get seHalBorrowHint =>
      'Off opens a new channel. Turn on only if channel 1 already has ISD-R selected.';

  @override
  String get seHalBorrowTitle => 'Borrow channel 1?';

  @override
  String seHalBorrowWarning(int slot) {
    return 'Turn this on only if channel 1 on SIM$slot has ISD-R selected right now; commands sent to another application can have unpredictable effects. Turn it off again after changing the card.';
  }

  @override
  String get seHalBorrowConfirm => 'Borrow';

  @override
  String get seHalDownloadTitle => 'SE HAL: experimental download';

  @override
  String get seHalInstallWarning =>
      'This installs the profile and keeps the existing ones. Do not use another LPA or remove the SIM until it finishes. If it fails, check the profile list before using the activation code again.';

  @override
  String get seHalPreviewWarning =>
      'The preview talks to the server and the card but installs nothing; you confirm again before installing. Do not use another LPA meanwhile.';

  @override
  String get seHalAcceptInstall => 'Install';

  @override
  String get seHalContinuePreview => 'Continue to preview';

  @override
  String get seHalDownloadUnusedQr => 'Download (unused QR only)';

  @override
  String get seHalReturnToEnable => 'Return to profiles to enable';

  @override
  String get seHalSwitchTitle => 'SE HAL: enable profile';

  @override
  String get seHalDisableTitle => 'SE HAL: disable profile';

  @override
  String get seHalEnableWarning =>
      'The currently enabled profile will be disabled, and the connection may drop for a moment. If the result is unclear, restart the device and check before trying again.';

  @override
  String get seHalDisableWarning =>
      'Calls and data through this profile will stop. If the result is unclear, restart the device and check before trying again.';

  @override
  String get seHalAcceptSwitch => 'Enable';

  @override
  String get seHalAcceptDisable => 'Disable';

  @override
  String get seHalStateChanged =>
      'Profile state changed. Restart the device if the connection does not come back.';

  @override
  String seHalStateUnknown(String error) {
    return 'SE HAL: $error\nThe result is unknown. Refresh to check the profile state before trying again.';
  }

  @override
  String get seHalInstallNotVerified =>
      'SE HAL: the installation could not be confirmed. Check the profile list before using the activation code again.';

  @override
  String seHalDeleteUnknown(String error) {
    return 'The deletion could not be confirmed: $error\nRefresh the profile list to check.';
  }

  @override
  String get pluginEsimCcRewards => 'eSIM.cc Rewards';

  @override
  String get pluginEsimCcPortal => 'eSIM.cc Portal';

  @override
  String get pluginEsimGgProfile => 'eSIM.gg Profile';

  @override
  String get pluginEsimGgPortal => 'eSIM.gg Portal';

  @override
  String get pluginEsimGgWelcome => 'Welcome to eSIM.gg Portal';

  @override
  String get pluginVisitWebsite => 'Visit Website';

  @override
  String get omapiEuiccDetectedTitle => 'Keep this eUICC available';

  @override
  String get omapiEuiccSystemDisableWarning =>
      'Disabling this SIM/eSIM slot in Android system settings may stop OMAPI from detecting it. Enable or switch profiles in this app instead. If the slot is already disabled, re-enable it in system settings and refresh the reader list.';
}
