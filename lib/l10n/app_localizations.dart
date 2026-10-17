import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('ru'),
    Locale('zh', 'TW'),
    Locale('zh'),
  ];

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @displaySettings.
  ///
  /// In en, this message translates to:
  /// **'Display Settings'**
  String get displaySettings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize theme, layout, and display preferences'**
  String get appearanceSubtitle;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @themeStyle.
  ///
  /// In en, this message translates to:
  /// **'Theme Style'**
  String get themeStyle;

  /// No description provided for @themeStyleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose between Custom and MD3 style'**
  String get themeStyleSubtitle;

  /// No description provided for @customDesign.
  ///
  /// In en, this message translates to:
  /// **'Nekoko Style'**
  String get customDesign;

  /// No description provided for @stockMD3.
  ///
  /// In en, this message translates to:
  /// **'Stock MD3'**
  String get stockMD3;

  /// No description provided for @waterfallLayout.
  ///
  /// In en, this message translates to:
  /// **'Waterfall Layout'**
  String get waterfallLayout;

  /// No description provided for @waterfallLayoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use Masonry style layout on wide screens'**
  String get waterfallLayoutSubtitle;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System Language'**
  String get systemLanguage;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @ui.
  ///
  /// In en, this message translates to:
  /// **'UI'**
  String get ui;

  /// No description provided for @autoLoadProfiles.
  ///
  /// In en, this message translates to:
  /// **'Auto-load Profiles'**
  String get autoLoadProfiles;

  /// No description provided for @autoLoadProfilesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Load profiles when reader is selected'**
  String get autoLoadProfilesSubtitle;

  /// No description provided for @loadProfileIcons.
  ///
  /// In en, this message translates to:
  /// **'Load Profile Icons'**
  String get loadProfileIcons;

  /// No description provided for @loadProfileIconsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fetch profile icons from eUICC (slower)'**
  String get loadProfileIconsSubtitle;

  /// No description provided for @useNekokoIcons.
  ///
  /// In en, this message translates to:
  /// **'Use Operator Icons'**
  String get useNekokoIcons;

  /// No description provided for @useNekokoIconsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fetch carrier icons from operator-icons'**
  String get useNekokoIconsSubtitle;

  /// No description provided for @forceDeviceDropdown.
  ///
  /// In en, this message translates to:
  /// **'Force Device Dropdown'**
  String get forceDeviceDropdown;

  /// No description provided for @forceDeviceDropdownSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Always use dropdown for device selection'**
  String get forceDeviceDropdownSubtitle;

  /// No description provided for @sizeDisplayUnit.
  ///
  /// In en, this message translates to:
  /// **'Size Display Unit'**
  String get sizeDisplayUnit;

  /// No description provided for @sizeDisplayUnitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unit format for storage size display'**
  String get sizeDisplayUnitSubtitle;

  /// No description provided for @phoneFormat.
  ///
  /// In en, this message translates to:
  /// **'Phone Number Format'**
  String get phoneFormat;

  /// No description provided for @phoneFormatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Format for displaying phone numbers'**
  String get phoneFormatSubtitle;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @notificationSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure automatic processing and removal'**
  String get notificationSettingsSubtitle;

  /// No description provided for @notificationHistory.
  ///
  /// In en, this message translates to:
  /// **'Notification History'**
  String get notificationHistory;

  /// No description provided for @notificationHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find, manage and resend sent notifications'**
  String get notificationHistorySubtitle;

  /// No description provided for @tagsAndReminders.
  ///
  /// In en, this message translates to:
  /// **'Tags & Reminders'**
  String get tagsAndReminders;

  /// No description provided for @tagManager.
  ///
  /// In en, this message translates to:
  /// **'Tag Manager'**
  String get tagManager;

  /// No description provided for @tagManagerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create and edit profile tags'**
  String get tagManagerSubtitle;

  /// No description provided for @tagReminders.
  ///
  /// In en, this message translates to:
  /// **'Tag Reminders'**
  String get tagReminders;

  /// No description provided for @tagRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scheduled notifications based on date tags'**
  String get tagRemindersSubtitle;

  /// No description provided for @manageTagsAndReminders.
  ///
  /// In en, this message translates to:
  /// **'Manage Tags & Reminders'**
  String get manageTagsAndReminders;

  /// No description provided for @manageTagsAndRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure tags, permissions, and test alerts'**
  String get manageTagsAndRemindersSubtitle;

  /// No description provided for @viewScheduledReminders.
  ///
  /// In en, this message translates to:
  /// **'View Scheduled Reminders'**
  String get viewScheduledReminders;

  /// No description provided for @viewScheduledRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your upcoming tag-based notifications'**
  String get viewScheduledRemindersSubtitle;

  /// No description provided for @connectivity.
  ///
  /// In en, this message translates to:
  /// **'Connectivity'**
  String get connectivity;

  /// No description provided for @remoteReaders.
  ///
  /// In en, this message translates to:
  /// **'Remote Readers'**
  String get remoteReaders;

  /// No description provided for @remoteReadersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure RemoCard companion apps'**
  String get remoteReadersSubtitle;

  /// No description provided for @enableBle.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth Connector'**
  String get enableBle;

  /// No description provided for @enableBleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable scanning and connecting to Bluetooth readers'**
  String get enableBleSubtitle;

  /// No description provided for @enableCcid.
  ///
  /// In en, this message translates to:
  /// **'USB CCID Connector'**
  String get enableCcid;

  /// No description provided for @enableCcidSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable USB smart card readers (CCID)'**
  String get enableCcidSubtitle;

  /// No description provided for @enableOmapi.
  ///
  /// In en, this message translates to:
  /// **'OMAPI Connector'**
  String get enableOmapi;

  /// No description provided for @enableOmapiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Open Mobile API functionality for OMAPI-based eUICC management.'**
  String get enableOmapiSubtitle;

  /// No description provided for @enableTmapi.
  ///
  /// In en, this message translates to:
  /// **'Telephony API Connector'**
  String get enableTmapi;

  /// No description provided for @enableTmapiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Telephony API functionality for SIM-based eUICC management.'**
  String get enableTmapiSubtitle;

  /// No description provided for @readerTypes.
  ///
  /// In en, this message translates to:
  /// **'Reader Types'**
  String get readerTypes;

  /// No description provided for @readerTypesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage enabled reader types (CCID, Bluetooth, Remote, etc.)'**
  String get readerTypesSubtitle;

  /// No description provided for @enabledReaderTypes.
  ///
  /// In en, this message translates to:
  /// **'Enabled Reader Types'**
  String get enabledReaderTypes;

  /// No description provided for @enabledReaderTypesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Control which types of readers are available in the app'**
  String get enabledReaderTypesSubtitle;

  /// No description provided for @remoteReaderSettings.
  ///
  /// In en, this message translates to:
  /// **'Remote Reader Settings'**
  String get remoteReaderSettings;

  /// No description provided for @remoteReaderSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure remote reader servers and connections'**
  String get remoteReaderSettingsSubtitle;

  /// No description provided for @ccidReaderTitle.
  ///
  /// In en, this message translates to:
  /// **'CCID (USB/PC/SC)'**
  String get ccidReaderTitle;

  /// No description provided for @ccidReaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'USB smart card readers and PC/SC devices'**
  String get ccidReaderSubtitle;

  /// No description provided for @bluetoothReaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get bluetoothReaderTitle;

  /// No description provided for @bluetoothReaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth LE smart card readers and writers'**
  String get bluetoothReaderSubtitle;

  /// No description provided for @remoteReadersTitle.
  ///
  /// In en, this message translates to:
  /// **'Remote Readers'**
  String get remoteReadersTitle;

  /// No description provided for @remoteReadersConnectorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Network-connected remote smart card readers'**
  String get remoteReadersConnectorSubtitle;

  /// No description provided for @omapiReaderTitle.
  ///
  /// In en, this message translates to:
  /// **'OMAPI'**
  String get omapiReaderTitle;

  /// No description provided for @omapiReaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Built-in SIM card slots via Open Mobile API'**
  String get omapiReaderSubtitle;

  /// No description provided for @tmapiReaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Telephony API'**
  String get tmapiReaderTitle;

  /// No description provided for @tmapiReaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Built-in SIM card slots via Telephony API'**
  String get tmapiReaderSubtitle;

  /// No description provided for @remoteServerConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Remote Server Configuration'**
  String get remoteServerConfiguration;

  /// No description provided for @remoteServerConfigurationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage remote reader servers and connection settings'**
  String get remoteServerConfigurationSubtitle;

  /// No description provided for @enableBrowser.
  ///
  /// In en, this message translates to:
  /// **'Enable Browser'**
  String get enableBrowser;

  /// No description provided for @enableBrowserSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show additional browser tabs like Store, Buy, or Help'**
  String get enableBrowserSubtitle;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @disableRefreshFlags.
  ///
  /// In en, this message translates to:
  /// **'Disable Refresh Flags'**
  String get disableRefreshFlags;

  /// No description provided for @disableRefreshFlagsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This will not apply to external readers'**
  String get disableRefreshFlagsSubtitle;

  /// No description provided for @apduMaxSegmentSize.
  ///
  /// In en, this message translates to:
  /// **'APDU Max Segment Size'**
  String get apduMaxSegmentSize;

  /// No description provided for @apduMaxSegmentSizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Maximum data size per APDU chunk'**
  String get apduMaxSegmentSizeSubtitle;

  /// No description provided for @ensureSingleChannel.
  ///
  /// In en, this message translates to:
  /// **'Ensure Single Channel'**
  String get ensureSingleChannel;

  /// No description provided for @ensureSingleChannelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Close other logical channels before opening a new one'**
  String get ensureSingleChannelSubtitle;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics & Cloud Services'**
  String get analytics;

  /// No description provided for @nekokoCloud.
  ///
  /// In en, this message translates to:
  /// **'Nekoko Cloud'**
  String get nekokoCloud;

  /// No description provided for @nekokoCloudSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Analyze installation data for better prediction'**
  String get nekokoCloudSubtitle;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @developerMode.
  ///
  /// In en, this message translates to:
  /// **'Developer Mode'**
  String get developerMode;

  /// No description provided for @developerModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable advanced debugging features'**
  String get developerModeSubtitle;

  /// No description provided for @exportDatabase.
  ///
  /// In en, this message translates to:
  /// **'Export Database'**
  String get exportDatabase;

  /// No description provided for @exportDatabaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save a copy of your application database to external storage.'**
  String get exportDatabaseSubtitle;

  /// No description provided for @openDatabaseFolder.
  ///
  /// In en, this message translates to:
  /// **'Open Database Folder'**
  String get openDatabaseFolder;

  /// No description provided for @openDatabaseFolderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reveal local storage folder in explorer'**
  String get openDatabaseFolderSubtitle;

  /// No description provided for @decodeAsn1.
  ///
  /// In en, this message translates to:
  /// **'Decode ASN.1 Logs (Slow)'**
  String get decodeAsn1;

  /// No description provided for @decodeAsn1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Heavily impacts performance'**
  String get decodeAsn1Subtitle;

  /// No description provided for @viewAppLogs.
  ///
  /// In en, this message translates to:
  /// **'View App Logs'**
  String get viewAppLogs;

  /// No description provided for @viewAppLogsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View collected application logs'**
  String get viewAppLogsSubtitle;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @build.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get build;

  /// No description provided for @checkUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get checkUpdates;

  /// No description provided for @checkUpdatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically check for new versions on startup'**
  String get checkUpdatesSubtitle;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get licenses;

  /// No description provided for @licensesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'License information for open source libraries used'**
  String get licensesSubtitle;

  /// No description provided for @noUpdatesFound.
  ///
  /// In en, this message translates to:
  /// **'No updates found'**
  String get noUpdatesFound;

  /// No description provided for @profilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get profilesTitle;

  /// No description provided for @switchEstkSlot.
  ///
  /// In en, this message translates to:
  /// **'Switch eSTK Slot'**
  String get switchEstkSlot;

  /// No description provided for @notificationsButton.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsButton;

  /// No description provided for @downloadProfile.
  ///
  /// In en, this message translates to:
  /// **'Download Profile'**
  String get downloadProfile;

  /// No description provided for @reconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reconnect;

  /// No description provided for @bluetoothNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth Not Connected'**
  String get bluetoothNotConnected;

  /// No description provided for @bluetoothNotConnectedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ensure Bluetooth is enabled and the device is nearby. Tap Connect to start using this device.'**
  String get bluetoothNotConnectedSubtitle;

  /// No description provided for @bluetoothConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth Connection Failed'**
  String get bluetoothConnectionFailed;

  /// No description provided for @bluetoothConnectionFailedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to Bluetooth device.\n\n{error}'**
  String bluetoothConnectionFailedSubtitle(Object error);

  /// No description provided for @removeDevice.
  ///
  /// In en, this message translates to:
  /// **'Remove Device'**
  String get removeDevice;

  /// No description provided for @retryConnection.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get retryConnection;

  /// No description provided for @remoteConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Remote Reader Connection Failed'**
  String get remoteConnectionFailed;

  /// No description provided for @remoteConnectionFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Ensure the remote server is running and accessible.\n\n{error}'**
  String remoteConnectionFailedMessage(Object error);

  /// No description provided for @errorBluetoothTimeout.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth operation timed out. Please try again.'**
  String get errorBluetoothTimeout;

  /// No description provided for @errorOmapiSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security error: Access to the card was denied by the OS or ARA-M rules.'**
  String get errorOmapiSecurity;

  /// No description provided for @errorApplicationNotFound.
  ///
  /// In en, this message translates to:
  /// **'eUICC management application (ISD-R) not found. This card may not be a valid eUICC.'**
  String get errorApplicationNotFound;

  /// No description provided for @changeSettings.
  ///
  /// In en, this message translates to:
  /// **'Change Settings'**
  String get changeSettings;

  /// No description provided for @connectCompatibleReader.
  ///
  /// In en, this message translates to:
  /// **'Connect a compatible reader to start.'**
  String get connectCompatibleReader;

  /// No description provided for @connectReaderMessageBle.
  ///
  /// In en, this message translates to:
  /// **'You can also scan for compatible Bluetooth devices if you have a Bluetooth-enabled eUICC.'**
  String get connectReaderMessageBle;

  /// No description provided for @connectReaderMessageNoBle.
  ///
  /// In en, this message translates to:
  /// **'Ensure your CCID reader is connected to your computer.'**
  String get connectReaderMessageNoBle;

  /// No description provided for @downloadSmartCardExtension.
  ///
  /// In en, this message translates to:
  /// **'Download Smart Card Extension'**
  String get downloadSmartCardExtension;

  /// No description provided for @smartCardExtensionMessage.
  ///
  /// In en, this message translates to:
  /// **'The extension is required to access USB CCID readers in this browser.'**
  String get smartCardExtensionMessage;

  /// No description provided for @scanForBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Scan for Bluetooth'**
  String get scanForBluetooth;

  /// No description provided for @connectRemote.
  ///
  /// In en, this message translates to:
  /// **'Connect Remote'**
  String get connectRemote;

  /// No description provided for @noCardDetected.
  ///
  /// In en, this message translates to:
  /// **'No Card Detected'**
  String get noCardDetected;

  /// No description provided for @noCardDetectedMessage.
  ///
  /// In en, this message translates to:
  /// **'No unsupported or active eUICC found in this slot.'**
  String get noCardDetectedMessage;

  /// No description provided for @noDataLoaded.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get noDataLoaded;

  /// No description provided for @loadProfiles.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get loadProfiles;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @disconnecting.
  ///
  /// In en, this message translates to:
  /// **'Disconnecting...'**
  String get disconnecting;

  /// No description provided for @profilesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No Profiles on Card'**
  String get profilesEmpty;

  /// No description provided for @profilesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'This eUICC card is empty.'**
  String get profilesEmptyMessage;

  /// No description provided for @renameProfile.
  ///
  /// In en, this message translates to:
  /// **'Rename Profile'**
  String get renameProfile;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @enterProfileNickname.
  ///
  /// In en, this message translates to:
  /// **'Enter profile nickname'**
  String get enterProfileNickname;

  /// No description provided for @profileNicknameNote.
  ///
  /// In en, this message translates to:
  /// **'Note: Tags are managed separately via the \'Manage Tags\' menu.'**
  String get profileNicknameNote;

  /// No description provided for @useProfileIcon.
  ///
  /// In en, this message translates to:
  /// **'Use Profile Icon'**
  String get useProfileIcon;

  /// No description provided for @useProfileIconSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Icon from eSIM card'**
  String get useProfileIconSubtitle;

  /// No description provided for @removeCustomIcon.
  ///
  /// In en, this message translates to:
  /// **'Remove Custom Icon'**
  String get removeCustomIcon;

  /// No description provided for @noRemoteIcon.
  ///
  /// In en, this message translates to:
  /// **'No remote icon available for this operator'**
  String get noRemoteIcon;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @initializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get initializing;

  /// No description provided for @refreshingProfiles.
  ///
  /// In en, this message translates to:
  /// **'Refreshing profiles...'**
  String get refreshingProfiles;

  /// No description provided for @retrievingEid.
  ///
  /// In en, this message translates to:
  /// **'Retrieving EID and Info...'**
  String get retrievingEid;

  /// No description provided for @updatingProfile.
  ///
  /// In en, this message translates to:
  /// **'Updating profile...'**
  String get updatingProfile;

  /// No description provided for @manageIsdR.
  ///
  /// In en, this message translates to:
  /// **'Manage ISD-R AIDs'**
  String get manageIsdR;

  /// No description provided for @manageIsdRSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure default Application IDs for eUICC'**
  String get manageIsdRSubtitle;

  /// No description provided for @transportFailed.
  ///
  /// In en, this message translates to:
  /// **'Transport Failed'**
  String get transportFailed;

  /// No description provided for @remoteTransportFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Connected to remote server, but the command failed. This usually means the remote device is momentarily busy or disconnected from the card. Would you like to retry?'**
  String get remoteTransportFailedMessage;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @scanningForReaders.
  ///
  /// In en, this message translates to:
  /// **'Scanning for readers...'**
  String get scanningForReaders;

  /// No description provided for @switchedEstkSlot.
  ///
  /// In en, this message translates to:
  /// **'Switched eSTK Slot'**
  String get switchedEstkSlot;

  /// No description provided for @scanningForUnresponsiveDevices.
  ///
  /// In en, this message translates to:
  /// **'Scanning for unresponsive devices...'**
  String get scanningForUnresponsiveDevices;

  /// No description provided for @resettingConnection.
  ///
  /// In en, this message translates to:
  /// **'Resetting connection...'**
  String get resettingConnection;

  /// No description provided for @connectingToReader.
  ///
  /// In en, this message translates to:
  /// **'Connecting to reader...'**
  String get connectingToReader;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @retrievingProfiles.
  ///
  /// In en, this message translates to:
  /// **'Retrieving profiles...'**
  String get retrievingProfiles;

  /// No description provided for @savingProfileMetadata.
  ///
  /// In en, this message translates to:
  /// **'Saving profile metadata...'**
  String get savingProfileMetadata;

  /// No description provided for @enablingProfile.
  ///
  /// In en, this message translates to:
  /// **'Enabling profile...'**
  String get enablingProfile;

  /// No description provided for @disablingProfile.
  ///
  /// In en, this message translates to:
  /// **'Disabling profile...'**
  String get disablingProfile;

  /// No description provided for @deleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Delete Profile'**
  String get deleteProfile;

  /// No description provided for @deleteProfileConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete profile {profileName}?\nThis action cannot be undone.'**
  String deleteProfileConfirmation(Object profileName);

  /// No description provided for @deletingProfile.
  ///
  /// In en, this message translates to:
  /// **'Deleting profile...'**
  String get deletingProfile;

  /// No description provided for @deleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting...'**
  String get deleting;

  /// No description provided for @dataUsage.
  ///
  /// In en, this message translates to:
  /// **'Data Usage'**
  String get dataUsage;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @changeIcon.
  ///
  /// In en, this message translates to:
  /// **'Change Icon'**
  String get changeIcon;

  /// No description provided for @manageTags.
  ///
  /// In en, this message translates to:
  /// **'Manage Tags'**
  String get manageTags;

  /// No description provided for @copyIccid.
  ///
  /// In en, this message translates to:
  /// **'Copy ICCID'**
  String get copyIccid;

  /// No description provided for @notificationProcessingError.
  ///
  /// In en, this message translates to:
  /// **'Cannot perform operations while notifications are processing'**
  String get notificationProcessingError;

  /// No description provided for @operationInProgressError.
  ///
  /// In en, this message translates to:
  /// **'Operation in progress, please wait'**
  String get operationInProgressError;

  /// No description provided for @iccidCopied.
  ///
  /// In en, this message translates to:
  /// **'ICCID copied: {iccid}'**
  String iccidCopied(Object iccid);

  /// No description provided for @operationRestricted.
  ///
  /// In en, this message translates to:
  /// **'Operation Restricted'**
  String get operationRestricted;

  /// No description provided for @notificationProcessingDownloadError.
  ///
  /// In en, this message translates to:
  /// **'Notifications are still being processed. Please wait until completion before downloading new profiles.'**
  String get notificationProcessingDownloadError;

  /// No description provided for @operational.
  ///
  /// In en, this message translates to:
  /// **'Operational'**
  String get operational;

  /// No description provided for @test.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get test;

  /// No description provided for @provisioning.
  ///
  /// In en, this message translates to:
  /// **'Provisioning'**
  String get provisioning;

  /// No description provided for @profileDetails.
  ///
  /// In en, this message translates to:
  /// **'Profile Details'**
  String get profileDetails;

  /// No description provided for @profileDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Information from the eUICC for this profile slot.'**
  String get profileDetailsSubtitle;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @tagsManagedSeparately.
  ///
  /// In en, this message translates to:
  /// **'Note: Tags are managed separately via the \'Manage Tags\' menu.'**
  String get tagsManagedSeparately;

  /// No description provided for @changeProfileIcon.
  ///
  /// In en, this message translates to:
  /// **'Change Profile Icon'**
  String get changeProfileIcon;

  /// No description provided for @selectFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Select from Gallery'**
  String get selectFromGallery;

  /// No description provided for @nekokoOperatorIcon.
  ///
  /// In en, this message translates to:
  /// **'Operator icon'**
  String get nekokoOperatorIcon;

  /// No description provided for @iconFromEsim.
  ///
  /// In en, this message translates to:
  /// **'Icon from eSIM card'**
  String get iconFromEsim;

  /// No description provided for @updateIconFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update icon: {error}'**
  String updateIconFailed(Object error);

  /// No description provided for @failedToReadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to read image file'**
  String get failedToReadImage;

  /// No description provided for @failedToProcessImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to process image'**
  String get failedToProcessImage;

  /// No description provided for @customIconSet.
  ///
  /// In en, this message translates to:
  /// **'Custom icon set successfully'**
  String get customIconSet;

  /// No description provided for @noMccMnc.
  ///
  /// In en, this message translates to:
  /// **'No MCC/MNC available for this profile'**
  String get noMccMnc;

  /// No description provided for @fetchingRemoteIcon.
  ///
  /// In en, this message translates to:
  /// **'Fetching remote icon...'**
  String get fetchingRemoteIcon;

  /// No description provided for @remoteIconSaved.
  ///
  /// In en, this message translates to:
  /// **'Remote icon saved as custom icon'**
  String get remoteIconSaved;

  /// No description provided for @fetchRemoteIconFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch remote icon: {error}'**
  String fetchRemoteIconFailed(Object error);

  /// No description provided for @noProfileIcon.
  ///
  /// In en, this message translates to:
  /// **'No profile icon available'**
  String get noProfileIcon;

  /// No description provided for @profileIconSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile icon saved as custom icon'**
  String get profileIconSaved;

  /// No description provided for @customIconRemoved.
  ///
  /// In en, this message translates to:
  /// **'Custom icon removed'**
  String get customIconRemoved;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @euiccError.
  ///
  /// In en, this message translates to:
  /// **'The eUICC returned an error while attempting to {action} the profile.'**
  String euiccError(Object action);

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @dataPlan.
  ///
  /// In en, this message translates to:
  /// **'Data Plan'**
  String get dataPlan;

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'used'**
  String get used;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get total;

  /// No description provided for @expires.
  ///
  /// In en, this message translates to:
  /// **'Expires: {date}'**
  String expires(Object date);

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @server.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get server;

  /// No description provided for @switchFailed.
  ///
  /// In en, this message translates to:
  /// **'Switch failed'**
  String get switchFailed;

  /// No description provided for @deviceRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Device refresh failed'**
  String get deviceRefreshFailed;

  /// No description provided for @euiccOptions.
  ///
  /// In en, this message translates to:
  /// **'eUICC Options'**
  String get euiccOptions;

  /// No description provided for @euiccInfo.
  ///
  /// In en, this message translates to:
  /// **'eUICC Info'**
  String get euiccInfo;

  /// No description provided for @hideEid.
  ///
  /// In en, this message translates to:
  /// **'Hide EID'**
  String get hideEid;

  /// No description provided for @showEid.
  ///
  /// In en, this message translates to:
  /// **'Show EID'**
  String get showEid;

  /// No description provided for @copyEid.
  ///
  /// In en, this message translates to:
  /// **'Copy EID'**
  String get copyEid;

  /// No description provided for @eidCopied.
  ///
  /// In en, this message translates to:
  /// **'EID copied to clipboard'**
  String get eidCopied;

  /// No description provided for @connectRemotes.
  ///
  /// In en, this message translates to:
  /// **'Connect Remotes'**
  String get connectRemotes;

  /// No description provided for @configureRemotes.
  ///
  /// In en, this message translates to:
  /// **'Configure Remotes'**
  String get configureRemotes;

  /// No description provided for @connectingToRemoteReaders.
  ///
  /// In en, this message translates to:
  /// **'Connecting to remote readers in background...'**
  String get connectingToRemoteReaders;

  /// No description provided for @noRemoteReadersFound.
  ///
  /// In en, this message translates to:
  /// **'No remote readers found'**
  String get noRemoteReadersFound;

  /// No description provided for @connectedRemoteReaders.
  ///
  /// In en, this message translates to:
  /// **'Connected {count} remote reader(s)'**
  String connectedRemoteReaders(Object count);

  /// No description provided for @failedToConnectRemoteReaders.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect remote readers: {error}'**
  String failedToConnectRemoteReaders(Object error);

  /// No description provided for @remoteReaderPassword.
  ///
  /// In en, this message translates to:
  /// **'Remote Reader Password'**
  String get remoteReaderPassword;

  /// No description provided for @remoteReaderPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This remote reader requires a password.'**
  String get remoteReaderPasswordSubtitle;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @deleteConnection.
  ///
  /// In en, this message translates to:
  /// **'Delete Connection'**
  String get deleteConnection;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @remoteReaderConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Remote Reader Connection Failed'**
  String get remoteReaderConnectionFailed;

  /// No description provided for @remoteReaderConnectionFailedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ensure the remote server is running and accessible.\n\n{error}'**
  String remoteReaderConnectionFailedSubtitle(Object error);

  /// No description provided for @connectReader.
  ///
  /// In en, this message translates to:
  /// **'Connect a compatible reader to start.'**
  String get connectReader;

  /// No description provided for @connectReaderSubtitleBle.
  ///
  /// In en, this message translates to:
  /// **'You can also scan for compatible Bluetooth devices if you have a Bluetooth-enabled eUICC.'**
  String get connectReaderSubtitleBle;

  /// No description provided for @connectReaderSubtitleCcid.
  ///
  /// In en, this message translates to:
  /// **'Ensure your CCID reader is connected to your computer.'**
  String get connectReaderSubtitleCcid;

  /// No description provided for @downloadExtension.
  ///
  /// In en, this message translates to:
  /// **'Download Smart Card Extension'**
  String get downloadExtension;

  /// No description provided for @downloadExtensionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The extension is required to access USB CCID readers in this browser.'**
  String get downloadExtensionSubtitle;

  /// No description provided for @cardUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Card Unsupported'**
  String get cardUnsupported;

  /// No description provided for @cardUnsupportedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This card is likely not an eUICC, or it is not supported by this reader, or being used by others.'**
  String get cardUnsupportedSubtitle;

  /// No description provided for @omapiWelcome.
  ///
  /// In en, this message translates to:
  /// **'One good thing — your device does have OMAPI support and is highly likely to be compatible with removable cards!'**
  String get omapiWelcome;

  /// No description provided for @supportedDevices.
  ///
  /// In en, this message translates to:
  /// **'Supported Devices'**
  String get supportedDevices;

  /// No description provided for @aboutAram.
  ///
  /// In en, this message translates to:
  /// **'About ARA-M'**
  String get aboutAram;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access Denied'**
  String get accessDenied;

  /// No description provided for @accessDeniedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Carrier privileges are required to access this eUICC. The card\'s ARA-M allowlist does not match the app\'s signature.'**
  String get accessDeniedSubtitle;

  /// No description provided for @noCardDetectedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No unsupported or active eUICC found in this slot.'**
  String get noCardDetectedSubtitle;

  /// No description provided for @noProfilesInstalled.
  ///
  /// In en, this message translates to:
  /// **'No profiles installed'**
  String get noProfilesInstalled;

  /// No description provided for @noProfilesInstalledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This eUICC card is empty.'**
  String get noProfilesInstalledSubtitle;

  /// No description provided for @cardRefreshingTitle.
  ///
  /// In en, this message translates to:
  /// **'Card is Refreshing'**
  String get cardRefreshingTitle;

  /// No description provided for @cardRefreshingMessage.
  ///
  /// In en, this message translates to:
  /// **'The card is currently updating its state. Profile list cannot be retrieved at this moment. Please wait a few seconds and then try again.'**
  String get cardRefreshingMessage;

  /// No description provided for @useRemoteIcon.
  ///
  /// In en, this message translates to:
  /// **'Use Remote Icon'**
  String get useRemoteIcon;

  /// No description provided for @bleDisconnectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth Connection Lost'**
  String get bleDisconnectedTitle;

  /// No description provided for @bleDisconnectedMessage.
  ///
  /// In en, this message translates to:
  /// **'The connection to the card reader was suddenly lost. Please ensure it is nearby and turned on.'**
  String get bleDisconnectedMessage;

  /// No description provided for @cardStuckRefreshingMessage.
  ///
  /// In en, this message translates to:
  /// **'Profile state change ongoing - try manually re-plug the SIM card if it stucks.'**
  String get cardStuckRefreshingMessage;

  /// No description provided for @activationCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Activation Code'**
  String get activationCodeTitle;

  /// No description provided for @activationCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan a QR code, drop an image, or enter the LPA string manually.'**
  String get activationCodeSubtitle;

  /// No description provided for @fullActivationCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Activation Code'**
  String get fullActivationCodeLabel;

  /// No description provided for @fullActivationCodeHint.
  ///
  /// In en, this message translates to:
  /// **'LPA:1\$smdp.io\$MATCHING-ID'**
  String get fullActivationCodeHint;

  /// No description provided for @pasteFromClipboardTooltip.
  ///
  /// In en, this message translates to:
  /// **'Paste from Clipboard'**
  String get pasteFromClipboardTooltip;

  /// No description provided for @selectFromGalleryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Select from Gallery'**
  String get selectFromGalleryTooltip;

  /// No description provided for @scanQrCodeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrCodeTooltip;

  /// No description provided for @smdpAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'SM-DP+ Address'**
  String get smdpAddressLabel;

  /// No description provided for @smdpAddressHint.
  ///
  /// In en, this message translates to:
  /// **'smdp.io'**
  String get smdpAddressHint;

  /// No description provided for @matchingIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Matching ID'**
  String get matchingIdLabel;

  /// No description provided for @matchingIdHint.
  ///
  /// In en, this message translates to:
  /// **'ABC-123'**
  String get matchingIdHint;

  /// No description provided for @smdpOidLabel.
  ///
  /// In en, this message translates to:
  /// **'SM-DP+ OID'**
  String get smdpOidLabel;

  /// No description provided for @confirmationCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirmation Code'**
  String get confirmationCodeLabel;

  /// No description provided for @confirmationCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter secret code'**
  String get confirmationCodeHint;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @invalidLpaClipboard.
  ///
  /// In en, this message translates to:
  /// **'Clipboard does not contain a valid LPA string.'**
  String get invalidLpaClipboard;

  /// No description provided for @invalidFqdnFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid FQDN format'**
  String get invalidFqdnFormat;

  /// No description provided for @invalidMatchingIdChars.
  ///
  /// In en, this message translates to:
  /// **'Invalid characters in Matching ID'**
  String get invalidMatchingIdChars;

  /// No description provided for @invalidOidFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid OID format (e.g. 1.2.840...)'**
  String get invalidOidFormat;

  /// No description provided for @activationCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Activation code is required'**
  String get activationCodeRequired;

  /// No description provided for @invalidLpaFormatGeneric.
  ///
  /// In en, this message translates to:
  /// **'Invalid LPA format'**
  String get invalidLpaFormatGeneric;

  /// No description provided for @smdpAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'SM-DP+ address is required'**
  String get smdpAddressRequired;

  /// No description provided for @loadingNotifications.
  ///
  /// In en, this message translates to:
  /// **'Loading notifications...'**
  String get loadingNotifications;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @analyzingImage.
  ///
  /// In en, this message translates to:
  /// **'Analyzing image...'**
  String get analyzingImage;

  /// No description provided for @noQrFoundInImage.
  ///
  /// In en, this message translates to:
  /// **'No QR code found in image'**
  String get noQrFoundInImage;

  /// No description provided for @invalidAcInImage.
  ///
  /// In en, this message translates to:
  /// **'Invalid activation code found in image'**
  String get invalidAcInImage;

  /// No description provided for @invalidAcFormatDetailed.
  ///
  /// In en, this message translates to:
  /// **'Invalid Activation Code format. Must start with LPA:1\$...'**
  String get invalidAcFormatDetailed;

  /// No description provided for @downloadProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Download Profile'**
  String get downloadProfileTitle;

  /// No description provided for @connectingToEuicc.
  ///
  /// In en, this message translates to:
  /// **'Connecting to eUICC...'**
  String get connectingToEuicc;

  /// No description provided for @gettingChallenge.
  ///
  /// In en, this message translates to:
  /// **'Getting eUICC Challenge...'**
  String get gettingChallenge;

  /// No description provided for @authenticatingWithSmdp.
  ///
  /// In en, this message translates to:
  /// **'Authenticating with SM-DP+...'**
  String get authenticatingWithSmdp;

  /// No description provided for @verifyingSignatures.
  ///
  /// In en, this message translates to:
  /// **'Verifying SM-DP+ Signatures...'**
  String get verifyingSignatures;

  /// No description provided for @retrievingMetadata.
  ///
  /// In en, this message translates to:
  /// **'Retrieving Profile Metadata...'**
  String get retrievingMetadata;

  /// No description provided for @preparingDownload.
  ///
  /// In en, this message translates to:
  /// **'Preparing download...'**
  String get preparingDownload;

  /// No description provided for @preparingEuicc.
  ///
  /// In en, this message translates to:
  /// **'Preparing eUICC...'**
  String get preparingEuicc;

  /// No description provided for @fetchingProfilePackage.
  ///
  /// In en, this message translates to:
  /// **'Fetching Profile Package...'**
  String get fetchingProfilePackage;

  /// No description provided for @installing.
  ///
  /// In en, this message translates to:
  /// **'Installing ({sent} / {total} bytes)...'**
  String installing(Object sent, Object total);

  /// No description provided for @finalizing.
  ///
  /// In en, this message translates to:
  /// **'Finalizing (Updating storage info)...'**
  String get finalizing;

  /// No description provided for @profileInstalledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile installed successfully!'**
  String get profileInstalledSuccessfully;

  /// No description provided for @provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// No description provided for @iccid.
  ///
  /// In en, this message translates to:
  /// **'ICCID'**
  String get iccid;

  /// No description provided for @plmn.
  ///
  /// In en, this message translates to:
  /// **'PLMN'**
  String get plmn;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @nvram.
  ///
  /// In en, this message translates to:
  /// **'NVRAM'**
  String get nvram;

  /// No description provided for @exportCertificates.
  ///
  /// In en, this message translates to:
  /// **'Export Certificates'**
  String get exportCertificates;

  /// No description provided for @euiccCert.
  ///
  /// In en, this message translates to:
  /// **'eUICC Cert'**
  String get euiccCert;

  /// No description provided for @eumCert.
  ///
  /// In en, this message translates to:
  /// **'EUM Cert'**
  String get eumCert;

  /// No description provided for @enterConfirmationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the code required by your carrier'**
  String get enterConfirmationCode;

  /// No description provided for @confirmationCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirmation code is required'**
  String get confirmationCodeRequired;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @installationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Installation Successful'**
  String get installationSuccessful;

  /// No description provided for @installationSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'The profile has been successfully installed on your eUICC.'**
  String get installationSuccessMessage;

  /// No description provided for @consumed.
  ///
  /// In en, this message translates to:
  /// **'Consumed'**
  String get consumed;

  /// No description provided for @enableProfileNow.
  ///
  /// In en, this message translates to:
  /// **'Enable Profile Now'**
  String get enableProfileNow;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @profileEnabledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile enabled successfully'**
  String get profileEnabledSuccessfully;

  /// No description provided for @enterNewProfileName.
  ///
  /// In en, this message translates to:
  /// **'Enter a new name for this profile to help you identify it easier.'**
  String get enterNewProfileName;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Profile Name'**
  String get profileName;

  /// No description provided for @profileNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Work Travel'**
  String get profileNameHint;

  /// No description provided for @profileRenamedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile renamed successfully'**
  String get profileRenamedSuccessfully;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download Failed'**
  String get downloadFailed;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @savedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get savedSuccessfully;

  /// No description provided for @saveCertificate.
  ///
  /// In en, this message translates to:
  /// **'Save Certificate'**
  String get saveCertificate;

  /// No description provided for @searchingForReaders.
  ///
  /// In en, this message translates to:
  /// **'Searching for readers...'**
  String get searchingForReaders;

  /// No description provided for @initializationError.
  ///
  /// In en, this message translates to:
  /// **'Initialization Error'**
  String get initializationError;

  /// No description provided for @noReadersFound.
  ///
  /// In en, this message translates to:
  /// **'No Readers Found'**
  String get noReadersFound;

  /// No description provided for @noReadersFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Insert a compatible reader or scan for BLE devices to manage your eSIM profiles.'**
  String get noReadersFoundMessage;

  /// No description provided for @scanBle.
  ///
  /// In en, this message translates to:
  /// **'Scan BLE'**
  String get scanBle;

  /// No description provided for @reminderDetails.
  ///
  /// In en, this message translates to:
  /// **'Reminder Details'**
  String get reminderDetails;

  /// No description provided for @profileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get profileNotFound;

  /// No description provided for @resending.
  ///
  /// In en, this message translates to:
  /// **'Resending...'**
  String get resending;

  /// No description provided for @noAddressInNotification.
  ///
  /// In en, this message translates to:
  /// **'No address in notification data'**
  String get noAddressInNotification;

  /// No description provided for @sentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Sent successfully'**
  String get sentSuccessfully;

  /// No description provided for @sendFailed.
  ///
  /// In en, this message translates to:
  /// **'Send failed'**
  String get sendFailed;

  /// No description provided for @copiedCurl.
  ///
  /// In en, this message translates to:
  /// **'Copied cURL command to clipboard'**
  String get copiedCurl;

  /// No description provided for @noAddressToExport.
  ///
  /// In en, this message translates to:
  /// **'No address to export'**
  String get noAddressToExport;

  /// No description provided for @noHistoryAvailable.
  ///
  /// In en, this message translates to:
  /// **'No history available'**
  String get noHistoryAvailable;

  /// No description provided for @searchByIccid.
  ///
  /// In en, this message translates to:
  /// **'Search by ICCID...'**
  String get searchByIccid;

  /// No description provided for @resendNotification.
  ///
  /// In en, this message translates to:
  /// **'Resend notification'**
  String get resendNotification;

  /// No description provided for @exportAsCurl.
  ///
  /// In en, this message translates to:
  /// **'Export as cURL'**
  String get exportAsCurl;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @deleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get deleteEntry;

  /// No description provided for @activeReminders.
  ///
  /// In en, this message translates to:
  /// **'{count} active reminders'**
  String activeReminders(int count);

  /// No description provided for @noScheduledReminders.
  ///
  /// In en, this message translates to:
  /// **'No scheduled reminders'**
  String get noScheduledReminders;

  /// No description provided for @remindersAppearWhen.
  ///
  /// In en, this message translates to:
  /// **'Reminders appear when you add date tags to profiles.'**
  String get remindersAppearWhen;

  /// No description provided for @activeTagsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active tags across all profiles'**
  String activeTagsCount(int count);

  /// No description provided for @searchTagsOrProfiles.
  ///
  /// In en, this message translates to:
  /// **'Search tags or profiles...'**
  String get searchTagsOrProfiles;

  /// No description provided for @noTagsFound.
  ///
  /// In en, this message translates to:
  /// **'No tags found'**
  String get noTagsFound;

  /// No description provided for @addTagsFromProfileMenu.
  ///
  /// In en, this message translates to:
  /// **'Add tags to your profiles from the profile edit menu to see them here.'**
  String get addTagsFromProfileMenu;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count}d left'**
  String daysLeft(int count);

  /// No description provided for @hoursLeft.
  ///
  /// In en, this message translates to:
  /// **'{count}h left'**
  String hoursLeft(int count);

  /// No description provided for @expiresSoon.
  ///
  /// In en, this message translates to:
  /// **'Expires soon'**
  String get expiresSoon;

  /// No description provided for @soon.
  ///
  /// In en, this message translates to:
  /// **'soon'**
  String get soon;

  /// No description provided for @activeTags.
  ///
  /// In en, this message translates to:
  /// **'Active Tags'**
  String get activeTags;

  /// No description provided for @addNewTag.
  ///
  /// In en, this message translates to:
  /// **'Add New Tag'**
  String get addNewTag;

  /// No description provided for @noTagsAssigned.
  ///
  /// In en, this message translates to:
  /// **'No tags assigned to this profile'**
  String get noTagsAssigned;

  /// No description provided for @textTagHint.
  ///
  /// In en, this message translates to:
  /// **'Text tag (e.g. Work, Travel)'**
  String get textTagHint;

  /// No description provided for @addDateExpiryTag.
  ///
  /// In en, this message translates to:
  /// **'Add Date/Expiry Tag'**
  String get addDateExpiryTag;

  /// No description provided for @addNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Add Note (Optional)'**
  String get addNoteOptional;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Expiry, 10GB, etc.'**
  String get noteHint;

  /// No description provided for @invalidHexString.
  ///
  /// In en, this message translates to:
  /// **'Invalid Hex String'**
  String get invalidHexString;

  /// No description provided for @resetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get resetToDefaults;

  /// No description provided for @resetToDefaultsSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get resetToDefaultsSuccess;

  /// No description provided for @addAidHex.
  ///
  /// In en, this message translates to:
  /// **'Add AID (Hex)'**
  String get addAidHex;

  /// No description provided for @manageAutoNotif.
  ///
  /// In en, this message translates to:
  /// **'Manage automatic notification processing'**
  String get manageAutoNotif;

  /// No description provided for @automaticProcessing.
  ///
  /// In en, this message translates to:
  /// **'AUTOMATIC PROCESSING'**
  String get automaticProcessing;

  /// No description provided for @notifProcessingInfo.
  ///
  /// In en, this message translates to:
  /// **'Processing notifications helps synchronization between your eUICC and the SM-DP+ server (carrier). Removing sent notifications keeps your card storage clean.'**
  String get notifProcessingInfo;

  /// No description provided for @enabling.
  ///
  /// In en, this message translates to:
  /// **'Enabling'**
  String get enabling;

  /// No description provided for @afterEnabling.
  ///
  /// In en, this message translates to:
  /// **'After enabling profile'**
  String get afterEnabling;

  /// No description provided for @disabling.
  ///
  /// In en, this message translates to:
  /// **'Disabling'**
  String get disabling;

  /// No description provided for @afterDisabling.
  ///
  /// In en, this message translates to:
  /// **'After disabling profile'**
  String get afterDisabling;

  /// No description provided for @installation.
  ///
  /// In en, this message translates to:
  /// **'Installation'**
  String get installation;

  /// No description provided for @afterDownload.
  ///
  /// In en, this message translates to:
  /// **'After profile download'**
  String get afterDownload;

  /// No description provided for @deletion.
  ///
  /// In en, this message translates to:
  /// **'Deletion'**
  String get deletion;

  /// No description provided for @afterDeletion.
  ///
  /// In en, this message translates to:
  /// **'After deleting profile'**
  String get afterDeletion;

  /// No description provided for @autoSend.
  ///
  /// In en, this message translates to:
  /// **'Auto-Send'**
  String get autoSend;

  /// No description provided for @autoSendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send to server automatically'**
  String get autoSendSubtitle;

  /// No description provided for @autoRemove.
  ///
  /// In en, this message translates to:
  /// **'Auto-Remove'**
  String get autoRemove;

  /// No description provided for @autoRemoveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Delete from card after sending'**
  String get autoRemoveSubtitle;

  /// No description provided for @removeWithoutSending.
  ///
  /// In en, this message translates to:
  /// **'Remove Without Sending'**
  String get removeWithoutSending;

  /// No description provided for @removeWithoutSendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use with caution: server won\'t be notified'**
  String get removeWithoutSendingSubtitle;

  /// No description provided for @permissionsActive.
  ///
  /// In en, this message translates to:
  /// **'Permissions Active'**
  String get permissionsActive;

  /// No description provided for @permissionsRequired.
  ///
  /// In en, this message translates to:
  /// **'Permissions Required'**
  String get permissionsRequired;

  /// No description provided for @appCanSendNotif.
  ///
  /// In en, this message translates to:
  /// **'App can send system notifications'**
  String get appCanSendNotif;

  /// No description provided for @requiredForReminders.
  ///
  /// In en, this message translates to:
  /// **'Required for reminder alerts'**
  String get requiredForReminders;

  /// No description provided for @unsupportedPlatformCheck.
  ///
  /// In en, this message translates to:
  /// **'Permission checking is not supported on this platform. Please do manual testing.'**
  String get unsupportedPlatformCheck;

  /// No description provided for @couldNotVerifyStatus.
  ///
  /// In en, this message translates to:
  /// **'Could not verify status. Please check Settings manually.'**
  String get couldNotVerifyStatus;

  /// No description provided for @testNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Test Notification'**
  String get testNotificationTitle;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// No description provided for @startTest.
  ///
  /// In en, this message translates to:
  /// **'Start Test'**
  String get startTest;

  /// No description provided for @sendingNotif.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sendingNotif;

  /// No description provided for @hostIpLabel.
  ///
  /// In en, this message translates to:
  /// **'Hostname / IP'**
  String get hostIpLabel;

  /// No description provided for @portLabel.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get portLabel;

  /// No description provided for @passwordOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Password (Optional)'**
  String get passwordOptionalLabel;

  /// No description provided for @configuredServers.
  ///
  /// In en, this message translates to:
  /// **'Configured Servers'**
  String get configuredServers;

  /// No description provided for @secureHttps.
  ///
  /// In en, this message translates to:
  /// **'Secure (HTTPS)'**
  String get secureHttps;

  /// No description provided for @insecureHttp.
  ///
  /// In en, this message translates to:
  /// **'Insecure (HTTP)'**
  String get insecureHttp;

  /// No description provided for @urlCopied.
  ///
  /// In en, this message translates to:
  /// **'URL copied'**
  String get urlCopied;

  /// No description provided for @serverAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Server added successfully'**
  String get serverAddedSuccessfully;

  /// No description provided for @authFailedCheckPassword.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Check password.'**
  String get authFailedCheckPassword;

  /// No description provided for @addNewServer.
  ///
  /// In en, this message translates to:
  /// **'Add New Server'**
  String get addNewServer;

  /// No description provided for @autoLoadRemotes.
  ///
  /// In en, this message translates to:
  /// **'Auto-load Remote Devices'**
  String get autoLoadRemotes;

  /// No description provided for @autoLoadRemotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically connect to configured servers on app startup'**
  String get autoLoadRemotesSubtitle;

  /// No description provided for @getRemoCardGitHub.
  ///
  /// In en, this message translates to:
  /// **'Get RemoCard from GitHub'**
  String get getRemoCardGitHub;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions:'**
  String get instructions;

  /// No description provided for @instruction1.
  ///
  /// In en, this message translates to:
  /// **'1. Install RemoCard app on your Android devices.'**
  String get instruction1;

  /// No description provided for @instruction2.
  ///
  /// In en, this message translates to:
  /// **'2. Start the server in each RemoCard app.'**
  String get instruction2;

  /// No description provided for @instruction3.
  ///
  /// In en, this message translates to:
  /// **'3. Enter the IP addresses here.'**
  String get instruction3;

  /// No description provided for @instruction4.
  ///
  /// In en, this message translates to:
  /// **'4. All remote SIM slots will appear in the device list.'**
  String get instruction4;

  /// No description provided for @appLogsCopied.
  ///
  /// In en, this message translates to:
  /// **'Logs copied to clipboard'**
  String get appLogsCopied;

  /// No description provided for @aramInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'ARA-M Information'**
  String get aramInfoTitle;

  /// No description provided for @aramInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Access Rule Applet details'**
  String get aramInfoSubtitle;

  /// No description provided for @whatIsAram.
  ///
  /// In en, this message translates to:
  /// **'What is ARA-M?'**
  String get whatIsAram;

  /// No description provided for @aramDescription.
  ///
  /// In en, this message translates to:
  /// **'Access Rule Applet (ARA-M) is a mechanism on eUICCs (eSIMs) and SIM cards that defines which applications are allowed to manage profiles or perform low-level operations. If the app\'s hash is not present in the card\'s ARA-M allowlist, the Android system will block access, resulting in an \'Access Denied\' error.'**
  String get aramDescription;

  /// No description provided for @appCertHashes.
  ///
  /// In en, this message translates to:
  /// **'App Certificate Hashes'**
  String get appCertHashes;

  /// No description provided for @aramHashInstruction.
  ///
  /// In en, this message translates to:
  /// **'To grant this app access, you may need to add the following SHA-1 certificate hash to your card\'s ARA-M rules. This hash is unique to your current app build\'s certificate.'**
  String get aramHashInstruction;

  /// No description provided for @aramSigningHistoryInstruction.
  ///
  /// In en, this message translates to:
  /// **'For compatibility across Android versions, add all SHA-1 certificate hashes below to your card\'s ARA-M rules. After an app signing key upgrade, different Android versions may check different certificates from the verified signing history.'**
  String get aramSigningHistoryInstruction;

  /// No description provided for @certSha1Hash.
  ///
  /// In en, this message translates to:
  /// **'Certificate SHA-1 Hash'**
  String get certSha1Hash;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @troubleshooting.
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting'**
  String get troubleshooting;

  /// No description provided for @troubleStep1.
  ///
  /// In en, this message translates to:
  /// **'Ensure you are using the correct Card Reader.'**
  String get troubleStep1;

  /// No description provided for @troubleStep2.
  ///
  /// In en, this message translates to:
  /// **'If using a physical card, check if it\'s a test card or a production card (production cards often lock ARA-M).'**
  String get troubleStep2;

  /// No description provided for @troubleStep3.
  ///
  /// In en, this message translates to:
  /// **'The hashes above depend on whether you use the Debug, Regular, or Privileged (Magisk) version of the app.'**
  String get troubleStep3;

  /// No description provided for @troubleStep4.
  ///
  /// In en, this message translates to:
  /// **'Consider using the Privileged (Magisk) build which can bypass some Android API restrictions.'**
  String get troubleStep4;

  /// No description provided for @hashCopied.
  ///
  /// In en, this message translates to:
  /// **'Hash copied to clipboard'**
  String get hashCopied;

  /// No description provided for @aidCopied.
  ///
  /// In en, this message translates to:
  /// **'AID copied to clipboard'**
  String get aidCopied;

  /// No description provided for @lastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last Seen'**
  String get lastSeen;

  /// No description provided for @unknownProvider.
  ///
  /// In en, this message translates to:
  /// **'Unknown Provider'**
  String get unknownProvider;

  /// No description provided for @unknownProfile.
  ///
  /// In en, this message translates to:
  /// **'Unknown Profile'**
  String get unknownProfile;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @noTags.
  ///
  /// In en, this message translates to:
  /// **'No tags'**
  String get noTags;

  /// No description provided for @records.
  ///
  /// In en, this message translates to:
  /// **'{count} records'**
  String records(int count);

  /// No description provided for @bytes.
  ///
  /// In en, this message translates to:
  /// **'bytes'**
  String get bytes;

  /// No description provided for @responseCode.
  ///
  /// In en, this message translates to:
  /// **'Response Code'**
  String get responseCode;

  /// No description provided for @responseBody.
  ///
  /// In en, this message translates to:
  /// **'Response Body'**
  String get responseBody;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @profileCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 profile} other{{count} profiles}}'**
  String profileCount(int count);

  /// No description provided for @isdrAids.
  ///
  /// In en, this message translates to:
  /// **'ISD-R AIDs'**
  String get isdrAids;

  /// No description provided for @configureDefaultAids.
  ///
  /// In en, this message translates to:
  /// **'Configure default Application IDs'**
  String get configureDefaultAids;

  /// No description provided for @addAidHexHint.
  ///
  /// In en, this message translates to:
  /// **'Add AID (Hex)'**
  String get addAidHexHint;

  /// No description provided for @notificationProcessing.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationProcessing;

  /// No description provided for @manageAutoNotification.
  ///
  /// In en, this message translates to:
  /// **'Manage automatic notification processing'**
  String get manageAutoNotification;

  /// No description provided for @notificationProcessingHelp.
  ///
  /// In en, this message translates to:
  /// **'Processing notifications helps synchronization between your eUICC and the SM-DP+ server (carrier). Removing sent notifications keeps your card storage clean.'**
  String get notificationProcessingHelp;

  /// No description provided for @notificationProcessingTimings.
  ///
  /// In en, this message translates to:
  /// **'Processing timings'**
  String get notificationProcessingTimings;

  /// No description provided for @notificationProcessingTimingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose when automatic notification processing runs. Some safety-critical timings can only be disabled while Developer Mode is enabled.'**
  String get notificationProcessingTimingsHelp;

  /// No description provided for @afterEnablingProfile.
  ///
  /// In en, this message translates to:
  /// **'After enabling profile'**
  String get afterEnablingProfile;

  /// No description provided for @afterDisablingProfile.
  ///
  /// In en, this message translates to:
  /// **'After disabling profile'**
  String get afterDisablingProfile;

  /// No description provided for @afterProfileDownload.
  ///
  /// In en, this message translates to:
  /// **'After profile download'**
  String get afterProfileDownload;

  /// No description provided for @afterProfileDeletion.
  ///
  /// In en, this message translates to:
  /// **'After deleting profile'**
  String get afterProfileDeletion;

  /// No description provided for @initialLoad.
  ///
  /// In en, this message translates to:
  /// **'Initial load'**
  String get initialLoad;

  /// No description provided for @processNotificationsOnInitialLoad.
  ///
  /// In en, this message translates to:
  /// **'Process notifications after profiles finish loading'**
  String get processNotificationsOnInitialLoad;

  /// No description provided for @afterSwitchingProfile.
  ///
  /// In en, this message translates to:
  /// **'After switching profile'**
  String get afterSwitchingProfile;

  /// No description provided for @processNotificationsAfterSwitchingProfile.
  ///
  /// In en, this message translates to:
  /// **'Process notifications after enabling or disabling a profile'**
  String get processNotificationsAfterSwitchingProfile;

  /// No description provided for @beforeProfileDownload.
  ///
  /// In en, this message translates to:
  /// **'Before profile download'**
  String get beforeProfileDownload;

  /// No description provided for @processNotificationsBeforeProfileDownload.
  ///
  /// In en, this message translates to:
  /// **'Process notifications before starting a profile download'**
  String get processNotificationsBeforeProfileDownload;

  /// No description provided for @afterProfileInstalled.
  ///
  /// In en, this message translates to:
  /// **'After profile installed'**
  String get afterProfileInstalled;

  /// No description provided for @processNotificationsAfterProfileInstalled.
  ///
  /// In en, this message translates to:
  /// **'Process notifications after a profile has been installed'**
  String get processNotificationsAfterProfileInstalled;

  /// No description provided for @processNotificationsAfterProfileDeletion.
  ///
  /// In en, this message translates to:
  /// **'Process notifications after deleting a profile'**
  String get processNotificationsAfterProfileDeletion;

  /// No description provided for @developerModeRequiredToDisableTiming.
  ///
  /// In en, this message translates to:
  /// **'Enable Developer Mode to disable this timing.'**
  String get developerModeRequiredToDisableTiming;

  /// No description provided for @sendToServerAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Send to server automatically'**
  String get sendToServerAutomatically;

  /// No description provided for @removeFromCardAfterSending.
  ///
  /// In en, this message translates to:
  /// **'Delete from card after sending'**
  String get removeFromCardAfterSending;

  /// No description provided for @removeWithoutSendingCaution.
  ///
  /// In en, this message translates to:
  /// **'Use with caution: server won\'t be notified'**
  String get removeWithoutSendingCaution;

  /// No description provided for @reminderSettings.
  ///
  /// In en, this message translates to:
  /// **'Reminder Settings'**
  String get reminderSettings;

  /// No description provided for @appCanSendNotifications.
  ///
  /// In en, this message translates to:
  /// **'App can send system notifications'**
  String get appCanSendNotifications;

  /// No description provided for @requiredForReminderAlerts.
  ///
  /// In en, this message translates to:
  /// **'Required for reminder alerts'**
  String get requiredForReminderAlerts;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @permissionCheckNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Permission checking is not supported on this platform. Please do manual testing.'**
  String get permissionCheckNotSupported;

  /// No description provided for @testNotification.
  ///
  /// In en, this message translates to:
  /// **'Test Notification'**
  String get testNotification;

  /// No description provided for @notificationsDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled. Please enable them in system settings to receive reminders.'**
  String get notificationsDisabledMessage;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @applicationLogs.
  ///
  /// In en, this message translates to:
  /// **'Application Logs'**
  String get applicationLogs;

  /// No description provided for @refreshReload.
  ///
  /// In en, this message translates to:
  /// **'Refresh/Reload'**
  String get refreshReload;

  /// No description provided for @toggleAutoScroll.
  ///
  /// In en, this message translates to:
  /// **'Toggle Auto-scroll'**
  String get toggleAutoScroll;

  /// No description provided for @refreshDevices.
  ///
  /// In en, this message translates to:
  /// **'Refresh devices'**
  String get refreshDevices;

  /// No description provided for @scanBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Scan Bluetooth'**
  String get scanBluetooth;

  /// No description provided for @lessThan1Kb.
  ///
  /// In en, this message translates to:
  /// **'< 1 KB'**
  String get lessThan1Kb;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailed;

  /// No description provided for @downloadRemoCard.
  ///
  /// In en, this message translates to:
  /// **'Download RemoCard'**
  String get downloadRemoCard;

  /// No description provided for @remoCardAndroidApp.
  ///
  /// In en, this message translates to:
  /// **'Android app for Remote Controllers'**
  String get remoCardAndroidApp;

  /// No description provided for @resentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Resent successfully'**
  String get resentSuccessfully;

  /// No description provided for @resendFailed.
  ///
  /// In en, this message translates to:
  /// **'Resend failed'**
  String get resendFailed;

  /// No description provided for @eid.
  ///
  /// In en, this message translates to:
  /// **'EID'**
  String get eid;

  /// No description provided for @seq.
  ///
  /// In en, this message translates to:
  /// **'Seq'**
  String get seq;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @errorWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithDetails(String error);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to export database: {error}'**
  String exportFailed(String error);

  /// No description provided for @sasAccreditation.
  ///
  /// In en, this message translates to:
  /// **'SAS Accreditation'**
  String get sasAccreditation;

  /// No description provided for @firmwareVersion.
  ///
  /// In en, this message translates to:
  /// **'Firmware Version'**
  String get firmwareVersion;

  /// No description provided for @beeSimFirmwareAction.
  ///
  /// In en, this message translates to:
  /// **'Update BeeSIM firmware'**
  String get beeSimFirmwareAction;

  /// No description provided for @beeSimFirmwareTitle.
  ///
  /// In en, this message translates to:
  /// **'BeeSIM firmware update'**
  String get beeSimFirmwareTitle;

  /// No description provided for @beeSimFirmwareWarning.
  ///
  /// In en, this message translates to:
  /// **'A BeeSIM firmware update is available. Keep the card powered, Bluetooth connected, and the app open until it finishes. Interrupting the update may leave the card temporarily unusable.'**
  String get beeSimFirmwareWarning;

  /// No description provided for @beeSimFirmwareConfirm.
  ///
  /// In en, this message translates to:
  /// **'Update firmware'**
  String get beeSimFirmwareConfirm;

  /// No description provided for @platformSupport.
  ///
  /// In en, this message translates to:
  /// **'PLATFORM SUPPORT'**
  String get platformSupport;

  /// No description provided for @rspVersion.
  ///
  /// In en, this message translates to:
  /// **'RSP Version'**
  String get rspVersion;

  /// No description provided for @bppVersion.
  ///
  /// In en, this message translates to:
  /// **'BPP Version'**
  String get bppVersion;

  /// No description provided for @gpVersion.
  ///
  /// In en, this message translates to:
  /// **'GlobalPlatform Version'**
  String get gpVersion;

  /// No description provided for @certInfrastructure.
  ///
  /// In en, this message translates to:
  /// **'CERTIFICATE INFRASTRUCTURE'**
  String get certInfrastructure;

  /// No description provided for @euiccSignCi.
  ///
  /// In en, this message translates to:
  /// **'eUICC Sign CI'**
  String get euiccSignCi;

  /// No description provided for @euiccVerifyCi.
  ///
  /// In en, this message translates to:
  /// **'eUICC Verify CI'**
  String get euiccVerifyCi;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @keysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} key(s)'**
  String keysCount(int count);

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @profileClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get profileClass;

  /// No description provided for @aid.
  ///
  /// In en, this message translates to:
  /// **'AID'**
  String get aid;

  /// No description provided for @euiccSpecifications.
  ///
  /// In en, this message translates to:
  /// **'EUICC SPECIFICATIONS'**
  String get euiccSpecifications;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @failedToSaveTags.
  ///
  /// In en, this message translates to:
  /// **'Failed to save tags'**
  String get failedToSaveTags;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @notificationDetails.
  ///
  /// In en, this message translates to:
  /// **'Notification Details'**
  String get notificationDetails;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @notifTypeInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get notifTypeInstall;

  /// No description provided for @notifTypeDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get notifTypeDelete;

  /// No description provided for @notifTypeEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get notifTypeEnable;

  /// No description provided for @notifTypeDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get notifTypeDisable;

  /// No description provided for @notifTypeRpmEnable.
  ///
  /// In en, this message translates to:
  /// **'RPM Enable'**
  String get notifTypeRpmEnable;

  /// No description provided for @notifTypeRpmDisable.
  ///
  /// In en, this message translates to:
  /// **'RPM Disable'**
  String get notifTypeRpmDisable;

  /// No description provided for @notifTypeRpmDelete.
  ///
  /// In en, this message translates to:
  /// **'RPM Delete'**
  String get notifTypeRpmDelete;

  /// No description provided for @notifTypeLoadRpm.
  ///
  /// In en, this message translates to:
  /// **'Load RPM'**
  String get notifTypeLoadRpm;

  /// No description provided for @confirmDeleteNotification.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete notification #{seq}?'**
  String confirmDeleteNotification(int seq);

  /// No description provided for @notificationRemoved.
  ///
  /// In en, this message translates to:
  /// **'Notification removed'**
  String get notificationRemoved;

  /// No description provided for @failedToRemove.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove: {error}'**
  String failedToRemove(String error);

  /// No description provided for @curlCopied.
  ///
  /// In en, this message translates to:
  /// **'cURL command extracted to clipboard'**
  String get curlCopied;

  /// No description provided for @failedToGenerateCurl.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate cURL: {error}'**
  String failedToGenerateCurl(String error);

  /// No description provided for @noNotificationAddress.
  ///
  /// In en, this message translates to:
  /// **'No notification address available'**
  String get noNotificationAddress;

  /// No description provided for @sendingNotification.
  ///
  /// In en, this message translates to:
  /// **'Sending notification...'**
  String get sendingNotification;

  /// No description provided for @notifSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Notification sent successfully'**
  String get notifSentSuccessfully;

  /// No description provided for @failedToSendNotification.
  ///
  /// In en, this message translates to:
  /// **'Failed to send notification'**
  String get failedToSendNotification;

  /// No description provided for @errorSendingNotification.
  ///
  /// In en, this message translates to:
  /// **'Error sending notification: {error}'**
  String errorSendingNotification(String error);

  /// No description provided for @pendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String pendingCount(int count);

  /// No description provided for @currentReader.
  ///
  /// In en, this message translates to:
  /// **'Current Reader'**
  String get currentReader;

  /// No description provided for @errorLoadingNotifications.
  ///
  /// In en, this message translates to:
  /// **'Error loading notifications'**
  String get errorLoadingNotifications;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get allCaughtUp;

  /// No description provided for @sequence.
  ///
  /// In en, this message translates to:
  /// **'Sequence'**
  String get sequence;

  /// No description provided for @operation.
  ///
  /// In en, this message translates to:
  /// **'Operation'**
  String get operation;

  /// No description provided for @profileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile Name'**
  String get profileNameLabel;

  /// No description provided for @failedToSend.
  ///
  /// In en, this message translates to:
  /// **'Failed to send'**
  String get failedToSend;

  /// No description provided for @onCard.
  ///
  /// In en, this message translates to:
  /// **'On card'**
  String get onCard;

  /// No description provided for @sendNotification.
  ///
  /// In en, this message translates to:
  /// **'Send notification'**
  String get sendNotification;

  /// No description provided for @deleteNotification.
  ///
  /// In en, this message translates to:
  /// **'Delete notification'**
  String get deleteNotification;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @batchDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Batch Download'**
  String get batchDownloadTitle;

  /// No description provided for @batchDownloadHint.
  ///
  /// In en, this message translates to:
  /// **'Paste multiple LPA codes here (one per line, max 20)'**
  String get batchDownloadHint;

  /// No description provided for @foundLpaCodes.
  ///
  /// In en, this message translates to:
  /// **'{count} LPA codes found'**
  String foundLpaCodes(int count);

  /// No description provided for @startBatch.
  ///
  /// In en, this message translates to:
  /// **'Start Batch'**
  String get startBatch;

  /// No description provided for @noLpaCodesFound.
  ///
  /// In en, this message translates to:
  /// **'No valid LPA codes found'**
  String get noLpaCodesFound;

  /// No description provided for @insufficientSpaceStoppingBatch.
  ///
  /// In en, this message translates to:
  /// **'Insufficient space. Stopping batch download.'**
  String get insufficientSpaceStoppingBatch;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export to CSV'**
  String get exportCsv;

  /// No description provided for @exportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Exported successfully'**
  String get exportedSuccessfully;

  /// No description provided for @exportResults.
  ///
  /// In en, this message translates to:
  /// **'Export Results'**
  String get exportResults;

  /// No description provided for @lpa.
  ///
  /// In en, this message translates to:
  /// **'LPA'**
  String get lpa;

  /// No description provided for @smdp.
  ///
  /// In en, this message translates to:
  /// **'SM-DP+'**
  String get smdp;

  /// No description provided for @confirmationCode.
  ///
  /// In en, this message translates to:
  /// **'Confirmation Code'**
  String get confirmationCode;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @remainingSpace.
  ///
  /// In en, this message translates to:
  /// **'Remaining Space'**
  String get remainingSpace;

  /// No description provided for @stopBatch.
  ///
  /// In en, this message translates to:
  /// **'Stop Batch'**
  String get stopBatch;

  /// No description provided for @stopping.
  ///
  /// In en, this message translates to:
  /// **'Stopping...'**
  String get stopping;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailable;

  /// No description provided for @updateAvailableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A new version of {appName} is available (v{version} b{build}). Would you like to update now?'**
  String updateAvailableSubtitle(String appName, String version, String build);

  /// No description provided for @updateAction.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateAction;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @changelog.
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get changelog;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sortIccid.
  ///
  /// In en, this message translates to:
  /// **'ICCID'**
  String get sortIccid;

  /// No description provided for @sortCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get sortCountry;

  /// No description provided for @sortAscending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get sortAscending;

  /// No description provided for @sortDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get sortDescending;

  /// No description provided for @searchProfiles.
  ///
  /// In en, this message translates to:
  /// **'Search profiles...'**
  String get searchProfiles;

  /// No description provided for @noProfilesMatch.
  ///
  /// In en, this message translates to:
  /// **'No profiles match your search.'**
  String get noProfilesMatch;

  /// No description provided for @sortDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get sortDefault;

  /// No description provided for @sortNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get sortNickname;

  /// No description provided for @showProfileSearch.
  ///
  /// In en, this message translates to:
  /// **'Show Profile Search'**
  String get showProfileSearch;

  /// No description provided for @showProfileSearchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show search and sort bar in profile list'**
  String get showProfileSearchSubtitle;

  /// No description provided for @noReaderFound.
  ///
  /// In en, this message translates to:
  /// **'No reader found. Please connect your eUICC adapter.'**
  String get noReaderFound;

  /// No description provided for @readyToInstallProfile.
  ///
  /// In en, this message translates to:
  /// **'Ready to install profile.'**
  String get readyToInstallProfile;

  /// No description provided for @downloadHere.
  ///
  /// In en, this message translates to:
  /// **'Download Here'**
  String get downloadHere;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @buyCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get buyCard;

  /// No description provided for @buyData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get buyData;

  /// No description provided for @selectDevice.
  ///
  /// In en, this message translates to:
  /// **'Select Device'**
  String get selectDevice;

  /// No description provided for @selectReaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Card'**
  String get selectReaderTitle;

  /// No description provided for @authorizeSigning.
  ///
  /// In en, this message translates to:
  /// **'Authorize Signing'**
  String get authorizeSigning;

  /// No description provided for @signingDescription.
  ///
  /// In en, this message translates to:
  /// **'A website is requesting a secure signature from your eUICC.'**
  String get signingDescription;

  /// No description provided for @smdpAddress.
  ///
  /// In en, this message translates to:
  /// **'SM-DP+ Address'**
  String get smdpAddress;

  /// No description provided for @sign.
  ///
  /// In en, this message translates to:
  /// **'Sign'**
  String get sign;

  /// No description provided for @profilesInstalled.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 profile installed} other{{count} profiles installed}}'**
  String profilesInstalled(int count);

  /// No description provided for @estimatedDownloadSize.
  ///
  /// In en, this message translates to:
  /// **'Estimated download size'**
  String get estimatedDownloadSize;

  /// No description provided for @phoneFormatInternationalOnly.
  ///
  /// In en, this message translates to:
  /// **'E.164 Int\'l Only'**
  String get phoneFormatInternationalOnly;

  /// No description provided for @phoneFormatInternationalAndMobile.
  ///
  /// In en, this message translates to:
  /// **'Int\'l & Mobile'**
  String get phoneFormatInternationalAndMobile;

  /// No description provided for @phoneFormatInternationalAndAll.
  ///
  /// In en, this message translates to:
  /// **'Int\'l & National'**
  String get phoneFormatInternationalAndAll;

  /// No description provided for @phoneFormatOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get phoneFormatOff;

  /// No description provided for @settings_item_unit_b.
  ///
  /// In en, this message translates to:
  /// **'Bytes'**
  String get settings_item_unit_b;

  /// No description provided for @settings_item_unit_kb.
  ///
  /// In en, this message translates to:
  /// **'kB (1,000 Bytes)'**
  String get settings_item_unit_kb;

  /// No description provided for @settings_item_unit_kib.
  ///
  /// In en, this message translates to:
  /// **'kiB (1,024 Bytes)'**
  String get settings_item_unit_kib;

  /// No description provided for @settings_item_unit_adaptive_si.
  ///
  /// In en, this message translates to:
  /// **'B / kB Adaptive'**
  String get settings_item_unit_adaptive_si;

  /// No description provided for @settings_item_unit_adaptive_bi.
  ///
  /// In en, this message translates to:
  /// **'B / kiB Adaptive'**
  String get settings_item_unit_adaptive_bi;

  /// No description provided for @insufficientStorageWarning.
  ///
  /// In en, this message translates to:
  /// **'Insufficient storage for installation. Installation might fail.'**
  String get insufficientStorageWarning;

  /// No description provided for @estimateProfileSize.
  ///
  /// In en, this message translates to:
  /// **'Estimate Profile Size'**
  String get estimateProfileSize;

  /// No description provided for @estimateProfileSizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Estimate size of profile metadata before download'**
  String get estimateProfileSizeSubtitle;

  /// No description provided for @customize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get customize;

  /// No description provided for @customizeDescription.
  ///
  /// In en, this message translates to:
  /// **'Specify a new 6-character hex name and password for your writer.'**
  String get customizeDescription;

  /// No description provided for @customizeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Writer customized. Please re-pair the device.'**
  String get customizeSuccess;

  /// No description provided for @customizeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to customize writer: {error}'**
  String customizeFailed(String error);

  /// No description provided for @deviceName.
  ///
  /// In en, this message translates to:
  /// **'Device Name'**
  String get deviceName;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @devicePasswordHint.
  ///
  /// In en, this message translates to:
  /// **'6 hex chars or password string'**
  String get devicePasswordHint;

  /// No description provided for @sixHexChars.
  ///
  /// In en, this message translates to:
  /// **'6 hex chars'**
  String get sixHexChars;

  /// No description provided for @database.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get database;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Database exported to {path}'**
  String exportSuccess(String path);

  /// No description provided for @importDatabase.
  ///
  /// In en, this message translates to:
  /// **'Import Database'**
  String get importDatabase;

  /// No description provided for @importDatabaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Merge rows from another database file'**
  String get importDatabaseSubtitle;

  /// No description provided for @importDatabaseDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Select database file to import'**
  String get importDatabaseDialogTitle;

  /// No description provided for @importDatabaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Database'**
  String get importDatabaseTitle;

  /// No description provided for @importDatabaseContent.
  ///
  /// In en, this message translates to:
  /// **'This will merge rows from the selected database into your current database. Existing rows with the same keys will be overwritten. Continue?'**
  String get importDatabaseContent;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Database imported successfully'**
  String get importSuccess;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to import database: {error}'**
  String importFailed(String error);

  /// No description provided for @resetDatabase.
  ///
  /// In en, this message translates to:
  /// **'Reset Database'**
  String get resetDatabase;

  /// No description provided for @resetDatabaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all application data and restart'**
  String get resetDatabaseSubtitle;

  /// No description provided for @resetDatabaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Application Database'**
  String get resetDatabaseTitle;

  /// No description provided for @resetDatabaseContent.
  ///
  /// In en, this message translates to:
  /// **'This will completely delete all locally stored data, configurations, and logs. The application will close. Do you want to proceed?'**
  String get resetDatabaseContent;

  /// No description provided for @deleteDatabase.
  ///
  /// In en, this message translates to:
  /// **'Delete Database'**
  String get deleteDatabase;

  /// No description provided for @resetFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset database: {error}'**
  String resetFailed(String error);

  /// No description provided for @deviceImei.
  ///
  /// In en, this message translates to:
  /// **'Device TAC'**
  String get deviceImei;

  /// No description provided for @deviceImeiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used for profile downloads'**
  String get deviceImeiSubtitle;

  /// No description provided for @editDeviceImei.
  ///
  /// In en, this message translates to:
  /// **'Edit Device TAC'**
  String get editDeviceImei;

  /// No description provided for @editDeviceImeiInfo.
  ///
  /// In en, this message translates to:
  /// **'Enter an 8-digit TAC, or a 15-digit IMEI. Default TAC: 35383741.'**
  String get editDeviceImeiInfo;

  /// No description provided for @imeiDigits.
  ///
  /// In en, this message translates to:
  /// **'TAC or IMEI digits'**
  String get imeiDigits;

  /// No description provided for @importAction.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importAction;

  /// No description provided for @qrtrReaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Qualcomm modem (QRTR)'**
  String get qrtrReaderTitle;

  /// No description provided for @qrtrReaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Qualcomm\'s low-level modem protocol (requires Shizuku)'**
  String get qrtrReaderSubtitle;

  /// No description provided for @seHalReaderTitle.
  ///
  /// In en, this message translates to:
  /// **'SE HAL (direct access)'**
  String get seHalReaderTitle;

  /// No description provided for @seHalReaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'SIM cards and built-in eSIMs through the Secure Element HAL (requires Shizuku)'**
  String get seHalReaderSubtitle;

  /// No description provided for @seHalAdvancedSettings.
  ///
  /// In en, this message translates to:
  /// **'SE HAL advanced settings'**
  String get seHalAdvancedSettings;

  /// No description provided for @seHalBorrowSlot.
  ///
  /// In en, this message translates to:
  /// **'SIM{slot}: borrow channel 1'**
  String seHalBorrowSlot(int slot);

  /// No description provided for @seHalBorrowHint.
  ///
  /// In en, this message translates to:
  /// **'Off opens a new channel. Turn on only if channel 1 already has ISD-R selected.'**
  String get seHalBorrowHint;

  /// No description provided for @seHalBorrowTitle.
  ///
  /// In en, this message translates to:
  /// **'Borrow channel 1?'**
  String get seHalBorrowTitle;

  /// No description provided for @seHalBorrowWarning.
  ///
  /// In en, this message translates to:
  /// **'Turn this on only if channel 1 on SIM{slot} has ISD-R selected right now; commands sent to another application can have unpredictable effects. Turn it off again after changing the card.'**
  String seHalBorrowWarning(int slot);

  /// No description provided for @seHalBorrowConfirm.
  ///
  /// In en, this message translates to:
  /// **'Borrow'**
  String get seHalBorrowConfirm;

  /// No description provided for @seHalDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'SE HAL: experimental download'**
  String get seHalDownloadTitle;

  /// No description provided for @seHalInstallWarning.
  ///
  /// In en, this message translates to:
  /// **'This installs the profile and keeps the existing ones. Do not use another LPA or remove the SIM until it finishes. If it fails, check the profile list before using the activation code again.'**
  String get seHalInstallWarning;

  /// No description provided for @seHalPreviewWarning.
  ///
  /// In en, this message translates to:
  /// **'The preview talks to the server and the card but installs nothing; you confirm again before installing. Do not use another LPA meanwhile.'**
  String get seHalPreviewWarning;

  /// No description provided for @seHalAcceptInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get seHalAcceptInstall;

  /// No description provided for @seHalContinuePreview.
  ///
  /// In en, this message translates to:
  /// **'Continue to preview'**
  String get seHalContinuePreview;

  /// No description provided for @seHalDownloadUnusedQr.
  ///
  /// In en, this message translates to:
  /// **'Download (unused QR only)'**
  String get seHalDownloadUnusedQr;

  /// No description provided for @seHalReturnToEnable.
  ///
  /// In en, this message translates to:
  /// **'Return to profiles to enable'**
  String get seHalReturnToEnable;

  /// No description provided for @seHalSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'SE HAL: enable profile'**
  String get seHalSwitchTitle;

  /// No description provided for @seHalDisableTitle.
  ///
  /// In en, this message translates to:
  /// **'SE HAL: disable profile'**
  String get seHalDisableTitle;

  /// No description provided for @seHalEnableWarning.
  ///
  /// In en, this message translates to:
  /// **'The currently enabled profile will be disabled, and the connection may drop for a moment. If the result is unclear, restart the device and check before trying again.'**
  String get seHalEnableWarning;

  /// No description provided for @seHalDisableWarning.
  ///
  /// In en, this message translates to:
  /// **'Calls and data through this profile will stop. If the result is unclear, restart the device and check before trying again.'**
  String get seHalDisableWarning;

  /// No description provided for @seHalAcceptSwitch.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get seHalAcceptSwitch;

  /// No description provided for @seHalAcceptDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get seHalAcceptDisable;

  /// No description provided for @seHalStateChanged.
  ///
  /// In en, this message translates to:
  /// **'Profile state changed. Restart the device if the connection does not come back.'**
  String get seHalStateChanged;

  /// No description provided for @seHalStateUnknown.
  ///
  /// In en, this message translates to:
  /// **'SE HAL: {error}\nThe result is unknown. Refresh to check the profile state before trying again.'**
  String seHalStateUnknown(String error);

  /// No description provided for @seHalInstallNotVerified.
  ///
  /// In en, this message translates to:
  /// **'SE HAL: the installation could not be confirmed. Check the profile list before using the activation code again.'**
  String get seHalInstallNotVerified;

  /// No description provided for @seHalDeleteUnknown.
  ///
  /// In en, this message translates to:
  /// **'The deletion could not be confirmed: {error}\nRefresh the profile list to check.'**
  String seHalDeleteUnknown(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'ja',
    'ko',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
