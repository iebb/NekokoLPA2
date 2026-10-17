// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get displaySettings => 'Anzeige-Einstellungen';

  @override
  String get appearance => 'Erscheinungsbild';

  @override
  String get appearanceSubtitle =>
      'Thema, Layout und Anzeigeeinstellungen anpassen';

  @override
  String get darkMode => 'Dunkelmodus';

  @override
  String get themeStyle => 'Themenstil';

  @override
  String get themeStyleSubtitle =>
      'Zwischen benutzerdefiniertem und MD3-Stil wählen';

  @override
  String get customDesign => 'Nekoko Style';

  @override
  String get stockMD3 => 'Standard MD3';

  @override
  String get waterfallLayout => 'Wasserfall-Layout';

  @override
  String get waterfallLayoutSubtitle =>
      'Masonry-Stil auf breiten Bildschirmen verwenden';

  @override
  String get system => 'System';

  @override
  String get light => 'Hell';

  @override
  String get dark => 'Dunkel';

  @override
  String get language => 'Sprache';

  @override
  String get systemLanguage => 'Systemsprache';

  @override
  String get general => 'Allgemein';

  @override
  String get ui => 'Benutzeroberfläche';

  @override
  String get autoLoadProfiles => 'Profile automatisch laden';

  @override
  String get autoLoadProfilesSubtitle =>
      'Profile laden, wenn ein Lesegerät ausgewählt wird';

  @override
  String get loadProfileIcons => 'Profil-Icons laden';

  @override
  String get loadProfileIconsSubtitle =>
      'Profil-Icons von eUICC abrufen (langsamer)';

  @override
  String get useNekokoIcons => 'Anbieter-Icons verwenden';

  @override
  String get useNekokoIconsSubtitle =>
      'Anbieter-Logos von operator-icons abrufen';

  @override
  String get forceDeviceDropdown => 'Geräte-Dropdown erzwingen';

  @override
  String get forceDeviceDropdownSubtitle =>
      'Immer Dropdown zur Geräteauswahl verwenden';

  @override
  String get sizeDisplayUnit => 'Größen-Anzeigeeinheit';

  @override
  String get sizeDisplayUnitSubtitle =>
      'Einheitenformat für Speicherplatzanzeige';

  @override
  String get phoneFormat => 'Telefonnummernformat';

  @override
  String get phoneFormatSubtitle => 'Format für die Anzeige von Telefonnummern';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get notificationSettings => 'Benachrichtigungseinstellungen';

  @override
  String get notificationSettingsSubtitle =>
      'Automatische Verarbeitung und Entfernung konfigurieren';

  @override
  String get notificationHistory => 'Benachrichtigungsverlauf';

  @override
  String get notificationHistorySubtitle =>
      'Gesendete Benachrichtigungen finden, verwalten und erneut senden';

  @override
  String get tagsAndReminders => 'Tags & Erinnerungen';

  @override
  String get tagManager => 'Tag-Manager';

  @override
  String get tagManagerSubtitle => 'Profil-Tags erstellen und bearbeiten';

  @override
  String get tagReminders => 'Tag-Erinnerungen';

  @override
  String get tagRemindersSubtitle =>
      'Geplante Benachrichtigungen basierend auf Datums-Tags';

  @override
  String get manageTagsAndReminders => 'Tags & Erinnerungen verwalten';

  @override
  String get manageTagsAndRemindersSubtitle =>
      'Tags, Berechtigungen und Testalarme konfigurieren';

  @override
  String get viewScheduledReminders => 'Geplante Erinnerungen anzeigen';

  @override
  String get viewScheduledRemindersSubtitle =>
      'Bevorstehende tag-basierte Benachrichtigungen verwalten';

  @override
  String get connectivity => 'Konnektivität';

  @override
  String get remoteReaders => 'Remote-Leser';

  @override
  String get remoteReadersSubtitle => 'RemoCard-Begleit-Apps konfigurieren';

  @override
  String get enableBle => 'Bluetooth-Anschluss';

  @override
  String get enableBleSubtitle =>
      'Scannen und Verbinden mit Bluetooth-Lesern aktivieren';

  @override
  String get enableCcid => 'USB-CCID-Anschluss';

  @override
  String get enableCcidSubtitle => 'USB-Smartcard-Leser (CCID) aktivieren';

  @override
  String get enableOmapi => 'Android-OMAPI-Anschluss';

  @override
  String get enableOmapiSubtitle =>
      'Integrierten eUICC-Zugriff über OMAPI aktivieren';

  @override
  String get enableTmapi => 'Android-Telephony-Anschluss';

  @override
  String get enableTmapiSubtitle =>
      'Privilegierten Zugriff über Telephony API API aktivieren';

  @override
  String get readerTypes => 'Lesertypen';

  @override
  String get readerTypesSubtitle =>
      'Aktivierte Lesertypen verwalten (CCID, Bluetooth, Remote usw.)';

  @override
  String get enabledReaderTypes => 'Aktivierte Lesertypen';

  @override
  String get enabledReaderTypesSubtitle =>
      'Steuern Sie, welche Lesertypen in der App verfügbar sind';

  @override
  String get remoteReaderSettings => 'Remote-Leser-Einstellungen';

  @override
  String get remoteReaderSettingsSubtitle =>
      'Remote-Leser-Server und Verbindungen konfigurieren';

  @override
  String get ccidReaderTitle => 'CCID (USB/PC/SC)';

  @override
  String get ccidReaderSubtitle => 'USB-Smartcard-Leser und PC/SC-Geräte';

  @override
  String get bluetoothReaderTitle => 'Bluetooth';

  @override
  String get bluetoothReaderSubtitle =>
      'Bluetooth LE Smartcard-Leser und -Schreiber';

  @override
  String get remoteReadersTitle => 'Remote-Leser';

  @override
  String get remoteReadersConnectorSubtitle =>
      'Netzwerkverbundene Remote-Smartcard-Leser';

  @override
  String get omapiReaderTitle => 'OMAPI';

  @override
  String get omapiReaderSubtitle =>
      'Integrierte SIM-Kartensteckplätze über Open Mobile API';

  @override
  String get tmapiReaderTitle => 'Telephony API';

  @override
  String get tmapiReaderSubtitle => 'Integrierte eSIM über Telephony API';

  @override
  String get remoteServerConfiguration => 'Remote-Server-Konfiguration';

  @override
  String get remoteServerConfigurationSubtitle =>
      'Remote-Leser-Server und Verbindungseinstellungen verwalten';

  @override
  String get enableBrowser => 'Browser aktivieren';

  @override
  String get enableBrowserSubtitle =>
      'Zusätzliche Browser-Tabs wie Store, Kauf oder Hilfe anzeigen';

  @override
  String get transport => 'Transport';

  @override
  String get disableRefreshFlags => 'Aktualisierungs-Flags deaktivieren';

  @override
  String get disableRefreshFlagsSubtitle =>
      'Dies gilt nicht für externe Lesegeräte';

  @override
  String get apduMaxSegmentSize => 'Maximale APDU-Segmentgröße';

  @override
  String get apduMaxSegmentSizeSubtitle => 'Maximale Datengröße pro APDU-Block';

  @override
  String get ensureSingleChannel => 'Ensure Single Channel';

  @override
  String get ensureSingleChannelSubtitle =>
      'Close other logical channels before opening a new one';

  @override
  String get analytics => 'Analyse & Cloud-Dienste';

  @override
  String get nekokoCloud => 'Nekoko Cloud';

  @override
  String get nekokoCloudSubtitle =>
      'Installationsdaten für bessere Vorhersagen analysieren';

  @override
  String get developer => 'Entwickler';

  @override
  String get developerMode => 'Entwicklermodus';

  @override
  String get developerModeSubtitle =>
      'Erweiterte Debugging-Funktionen aktivieren';

  @override
  String get exportDatabase => 'Datenbank exportieren';

  @override
  String get exportDatabaseSubtitle =>
      'Eine Kopie der lokalen Datenbank speichern';

  @override
  String get openDatabaseFolder => 'Datenbankordner öffnen';

  @override
  String get openDatabaseFolderSubtitle =>
      'Den Ordner öffnen, der die Datenbankdatei enthält';

  @override
  String get decodeAsn1 => 'ASN.1-Protokolle dekodieren (langsam)';

  @override
  String get decodeAsn1Subtitle => 'Beeinträchtigt die Leistung erheblich';

  @override
  String get viewAppLogs => 'App-Protokolle anzeigen';

  @override
  String get viewAppLogsSubtitle => 'Gesammelte Anwendungsprotokolle anzeigen';

  @override
  String get about => 'Über';

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
  String get profilesTitle => 'Profile';

  @override
  String get switchEstkSlot => 'eSTK-Slot wechseln';

  @override
  String get notificationsButton => 'Benachrichtigungen';

  @override
  String get downloadProfile => 'Profil herunterladen';

  @override
  String get reconnect => 'Erneut verbinden';

  @override
  String get bluetoothNotConnected => 'Bluetooth nicht verbunden';

  @override
  String get bluetoothNotConnectedSubtitle =>
      'Stellen Sie sicher, dass Bluetooth aktiviert ist und das Gerät in der Nähe ist. Tippen Sie auf Verbinden, um dieses Gerät zu verwenden.';

  @override
  String get bluetoothConnectionFailed => 'Bluetooth-Verbindung fehlgeschlagen';

  @override
  String bluetoothConnectionFailedSubtitle(Object error) {
    return 'Verbindung zum Bluetooth-Gerät fehlgeschlagen.\n\n$error';
  }

  @override
  String get removeDevice => 'Gerät entfernen';

  @override
  String get retryConnection => 'Verbinden';

  @override
  String get remoteConnectionFailed => 'Remote-Lese-Verbindung fehlgeschlagen';

  @override
  String remoteConnectionFailedMessage(Object error) {
    return 'Stellen Sie sicher, dass der Remote-Server läuft und erreichbar ist.\n\n$error';
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
  String get changeSettings => 'Einstellungen ändern';

  @override
  String get connectCompatibleReader =>
      'Verbinden Sie ein kompatibles Lesegerät, um zu beginnen.';

  @override
  String get connectReaderMessageBle =>
      'Sie können auch nach kompatiblen Bluetooth-Geräten suchen, wenn Sie eine eUICC mit Bluetooth-Unterstützung haben.';

  @override
  String get connectReaderMessageNoBle =>
      'Stellen Sie sicher, dass Ihr CCID-Leser an Ihren Computer angeschlossen ist.';

  @override
  String get downloadSmartCardExtension =>
      'Smartcard-Erweiterung herunterladen';

  @override
  String get smartCardExtensionMessage =>
      'Die Erweiterung ist erforderlich, um in diesem Browser auf USB-CCID-Leser zuzugreifen.';

  @override
  String get scanForBluetooth => 'Nach Bluetooth scannen';

  @override
  String get connectRemote => 'Remote verbinden';

  @override
  String get noCardDetected => 'Keine Karte erkannt';

  @override
  String get noCardDetectedMessage =>
      'Keine nicht unterstützte oder aktive eUICC in diesem Slot gefunden.';

  @override
  String get noDataLoaded => 'Nicht verbunden';

  @override
  String get loadProfiles => 'Verbinden';

  @override
  String get disconnect => 'Trennen';

  @override
  String get disconnecting => 'Disconnecting...';

  @override
  String get profilesEmpty => 'Keine Profile auf der Karte';

  @override
  String get profilesEmptyMessage => 'Diese eUICC-Karte ist leer.';

  @override
  String get renameProfile => 'Profil umbenennen';

  @override
  String get nickname => 'Spitzname';

  @override
  String get enterProfileNickname => 'Profil-Spitznamen eingeben';

  @override
  String get profileNicknameNote =>
      'Hinweis: Tags werden separat über das Menü \'Tags verwalten\' verwaltet.';

  @override
  String get useProfileIcon => 'Profil-Icon verwenden';

  @override
  String get useProfileIconSubtitle => 'Icon von der eSIM-Karte';

  @override
  String get removeCustomIcon => 'Benutzerdefiniertes Icon entfernen';

  @override
  String get noRemoteIcon => 'Kein Remote-Icon für diesen Anbieter verfügbar';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get initializing => 'Initialisierung...';

  @override
  String get refreshingProfiles => 'Profile werden aktualisiert...';

  @override
  String get retrievingEid => 'EID und Informationen werden abgerufen...';

  @override
  String get updatingProfile => 'Profil wird aktualisiert...';

  @override
  String get manageIsdR => 'ISD-R-AIDs verwalten';

  @override
  String get manageIsdRSubtitle =>
      'Standard-Anwendungs-IDs für eUICC konfigurieren';

  @override
  String get transportFailed => 'Transport fehlgeschlagen';

  @override
  String get remoteTransportFailedMessage =>
      'Mit dem Remote-Server verbunden, aber der Befehl ist fehlgeschlagen. Dies bedeutet normalerweise, dass das Remote-Gerät vorübergehend beschäftigt oder von der Karte getrennt ist. Möchten Sie es erneut versuchen?';

  @override
  String get retry => 'Wiederholen';

  @override
  String get scanningForReaders => 'Suche nach Lesegeräten...';

  @override
  String get switchedEstkSlot => 'eSTK-Slot gewechselt';

  @override
  String get scanningForUnresponsiveDevices =>
      'Suche nach nicht reagierenden Geräten...';

  @override
  String get resettingConnection => 'Verbindung wird zurückgesetzt...';

  @override
  String get connectingToReader =>
      'Verbindung zum Lesegerät wird hergestellt...';

  @override
  String get moreOptions => 'Weitere Optionen';

  @override
  String get retrievingProfiles => 'Profile werden abgerufen...';

  @override
  String get savingProfileMetadata => 'Profil-Metadaten werden gespeichert...';

  @override
  String get enablingProfile => 'Profil wird aktiviert...';

  @override
  String get disablingProfile => 'Profil wird deaktiviert...';

  @override
  String get deleteProfile => 'Profil löschen';

  @override
  String deleteProfileConfirmation(Object profileName) {
    return 'Sind Sie sicher, dass Sie das Profil $profileName löschen möchten?\nDiese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String get deletingProfile => 'Profil wird gelöscht...';

  @override
  String get deleting => 'Deleting...';

  @override
  String get dataUsage => 'Datennutzung';

  @override
  String get details => 'Details';

  @override
  String get rename => 'Umbenennen';

  @override
  String get changeIcon => 'Icon ändern';

  @override
  String get manageTags => 'Tags verwalten';

  @override
  String get copyIccid => 'ICCID kopieren';

  @override
  String get notificationProcessingError =>
      'Aktionen können nicht ausgeführt werden, während Benachrichtigungen verarbeitet werden';

  @override
  String get operationInProgressError => 'Operation in progress, please wait';

  @override
  String iccidCopied(Object iccid) {
    return 'ICCID kopiert: $iccid';
  }

  @override
  String get operationRestricted => 'Vorgang eingeschränkt';

  @override
  String get notificationProcessingDownloadError =>
      'Benachrichtigungen werden noch verarbeitet. Bitte warten Sie bis zum Abschluss, bevor Sie neue Profile herunterladen.';

  @override
  String get operational => 'Operativ';

  @override
  String get test => 'Test';

  @override
  String get provisioning => 'Bereitstellung';

  @override
  String get profileDetails => 'Profildetails';

  @override
  String get profileDetailsSubtitle =>
      'Informationen von der eUICC für diesen Profil-Slot.';

  @override
  String get enabled => 'Aktiviert';

  @override
  String get disabled => 'Deaktiviert';

  @override
  String get tagsManagedSeparately =>
      'Hinweis: Tags werden separat über das Menü \'Tags verwalten\' verwaltet.';

  @override
  String get changeProfileIcon => 'Profil-Icon ändern';

  @override
  String get selectFromGallery => 'Aus Galerie auswählen';

  @override
  String get nekokoOperatorIcon => 'Anbieter-Logo';

  @override
  String get iconFromEsim => 'Icon von der eSIM-Karte';

  @override
  String updateIconFailed(Object error) {
    return 'Icon-Update fehlgeschlagen: $error';
  }

  @override
  String get failedToReadImage => 'Bilddatei konnte nicht gelesen werden';

  @override
  String get failedToProcessImage => 'Bild konnte nicht verarbeitet werden';

  @override
  String get customIconSet => 'Benutzerdefiniertes Icon erfolgreich gesetzt';

  @override
  String get noMccMnc => 'Kein MCC/MNC für dieses Profil verfügbar';

  @override
  String get fetchingRemoteIcon => 'Remote-Icon wird abgerufen...';

  @override
  String get remoteIconSaved =>
      'Remote-Icon als benutzerdefiniertes Icon gespeichert';

  @override
  String fetchRemoteIconFailed(Object error) {
    return 'Abrufen des Remote-Icons fehlgeschlagen: $error';
  }

  @override
  String get noProfileIcon => 'Kein Profil-Icon verfügbar';

  @override
  String get profileIconSaved =>
      'Profil-Icon als benutzerdefiniertes Icon gespeichert';

  @override
  String get customIconRemoved => 'Benutzerdefiniertes Icon entfernt';

  @override
  String get failed => 'Fehlgeschlagen';

  @override
  String euiccError(Object action) {
    return 'Die eUICC hat beim Versuch, das Profil zu $action, einen Fehler zurückgegeben.';
  }

  @override
  String get dismiss => 'Verwerfen';

  @override
  String get dataPlan => 'Datenplan';

  @override
  String get used => 'genutzt';

  @override
  String get total => 'insgesamt';

  @override
  String expires(Object date) {
    return 'Läuft ab am: $date';
  }

  @override
  String get close => 'Schließen';

  @override
  String get server => 'Server';

  @override
  String get switchFailed => 'Wechsel fehlgeschlagen';

  @override
  String get deviceRefreshFailed => 'Geräteaktualisierung fehlgeschlagen';

  @override
  String get euiccOptions => 'eUICC-Optionen';

  @override
  String get euiccInfo => 'eUICC-Info';

  @override
  String get hideEid => 'EID ausblenden';

  @override
  String get showEid => 'EID anzeigen';

  @override
  String get copyEid => 'EID kopieren';

  @override
  String get eidCopied => 'EID in die Zwischenablage kopiert';

  @override
  String get connectRemotes => 'Remote-Geräte verbinden';

  @override
  String get configureRemotes => 'Remote-Geräte konfigurieren';

  @override
  String get connectingToRemoteReaders =>
      'Verbindung zu Remote-Lesern im Hintergrund...';

  @override
  String get noRemoteReadersFound => 'Keine Remote-Leser gefunden';

  @override
  String connectedRemoteReaders(Object count) {
    return '$count Remote-Leser verbunden';
  }

  @override
  String failedToConnectRemoteReaders(Object error) {
    return 'Verbindung zu Remote-Lesern fehlgeschlagen: $error';
  }

  @override
  String get remoteReaderPassword => 'Passwort für Remote-Leser';

  @override
  String get remoteReaderPasswordSubtitle =>
      'Dieses Remote-Lesegerät erfordert ein Passwort.';

  @override
  String get password => 'Passwort';

  @override
  String get deleteConnection => 'Verbindung löschen';

  @override
  String get connect => 'Verbinden';

  @override
  String get remoteReaderConnectionFailed =>
      'Remote-Lese-Verbindung fehlgeschlagen';

  @override
  String remoteReaderConnectionFailedSubtitle(Object error) {
    return 'Stellen Sie sicher, dass der Remote-Server läuft und erreichbar ist.\n\n$error';
  }

  @override
  String get connectReader =>
      'Verbinden Sie ein kompatibles Lesegerät, um zu beginnen.';

  @override
  String get connectReaderSubtitleBle =>
      'Sie können auch nach kompatiblen Bluetooth-Geräten suchen, wenn Sie eine eUICC mit Bluetooth-Unterstützung haben.';

  @override
  String get connectReaderSubtitleCcid =>
      'Stellen Sie sicher, dass Ihr CCID-Leser an Ihren Computer angeschlossen ist.';

  @override
  String get downloadExtension => 'Smartcard-Erweiterung herunterladen';

  @override
  String get downloadExtensionSubtitle =>
      'Die Erweiterung ist erforderlich, um in diesem Browser auf USB-CCID-Leser zuzugreifen.';

  @override
  String get cardUnsupported => 'Karte nicht unterstützt';

  @override
  String get cardUnsupportedSubtitle =>
      'Diese Karte ist wahrscheinlich keine eUICC, wird von diesem Leser nicht unterstützt oder von anderen verwendet.';

  @override
  String get omapiWelcome =>
      'Gute Nachricht — Ihr Gerät unterstützt OMAPI und ist höchstwahrscheinlich mit wechselbaren Karten kompatibel!';

  @override
  String get supportedDevices => 'Unterstützte Geräte';

  @override
  String get aboutAram => 'Über ARA-M';

  @override
  String get accessDenied => 'Zugriff verweigert';

  @override
  String get accessDeniedSubtitle =>
      'Anbieterprivilegien sind erforderlich, um auf diese eUICC zuzugreifen. Die ARA-M-Erlaubnisliste der Karte stimmt nicht mit der Signatur der App überein.';

  @override
  String get noCardDetectedSubtitle =>
      'Keine nicht unterstützte oder aktive eUICC in diesem Slot gefunden.';

  @override
  String get noProfilesInstalled => 'Keine Profile installiert';

  @override
  String get noProfilesInstalledSubtitle => 'Diese eUICC-Karte ist leer.';

  @override
  String get cardRefreshingTitle => 'Card is Refreshing';

  @override
  String get cardRefreshingMessage =>
      'The card is currently updating its state. Profile list cannot be retrieved at this moment. Please wait a few seconds and then try again.';

  @override
  String get useRemoteIcon => 'Remote-Icon verwenden';

  @override
  String get bleDisconnectedTitle => 'Bluetooth Connection Lost';

  @override
  String get bleDisconnectedMessage =>
      'The connection to the card reader was suddenly lost. Please ensure it is nearby and turned on.';

  @override
  String get cardStuckRefreshingMessage =>
      'Profile state change ongoing - try manually re-plug the SIM card if it stucks.';

  @override
  String get activationCodeTitle => 'Aktivierungscode';

  @override
  String get activationCodeSubtitle =>
      'Scannen Sie einen QR-Code, ziehen Sie ein Bild hinein oder geben Sie den LPA-String manuell ein.';

  @override
  String get fullActivationCodeLabel => 'Vollständiger Aktivierungscode';

  @override
  String get fullActivationCodeHint => 'LPA:1\$smdp.io\$MATCHING-ID';

  @override
  String get pasteFromClipboardTooltip => 'Aus Zwischenablage einfügen';

  @override
  String get selectFromGalleryTooltip => 'Aus Galerie auswählen';

  @override
  String get scanQrCodeTooltip => 'QR-Code scannen';

  @override
  String get smdpAddressLabel => 'SM-DP+-Adresse';

  @override
  String get smdpAddressHint => 'smdp.io';

  @override
  String get matchingIdLabel => 'Matching-ID';

  @override
  String get matchingIdHint => 'ABC-123';

  @override
  String get smdpOidLabel => 'SM-DP+-OID';

  @override
  String get confirmationCodeLabel => 'Bestätigungscode';

  @override
  String get confirmationCodeHint => 'Geheimcode eingeben';

  @override
  String get continueButton => 'Weiter';

  @override
  String get invalidLpaClipboard =>
      'Zwischenablage enthält keinen gültigen LPA-String.';

  @override
  String get invalidFqdnFormat => 'Ungültiges FQDN-Format';

  @override
  String get invalidMatchingIdChars => 'Ungültige Zeichen in der Matching-ID';

  @override
  String get invalidOidFormat => 'Ungültiges OID-Format (z. B. 1.2.840...)';

  @override
  String get activationCodeRequired => 'Aktivierungscode ist erforderlich';

  @override
  String get invalidLpaFormatGeneric => 'Ungültiges LPA-Format';

  @override
  String get smdpAddressRequired => 'SM-DP+-Adresse ist erforderlich';

  @override
  String get loadingNotifications => 'Benachrichtigungen werden geladen...';

  @override
  String get processing => 'Wird verarbeitet...';

  @override
  String get analyzingImage => 'Bild wird analysiert...';

  @override
  String get noQrFoundInImage => 'Kein QR-Code im Bild gefunden';

  @override
  String get invalidAcInImage => 'Ungültiger Aktivierungscode im Bild gefunden';

  @override
  String get invalidAcFormatDetailed =>
      'Ungültiges Aktivierungscode-Format. Muss mit LPA:1\$ beginnen...';

  @override
  String get downloadProfileTitle => 'Profil herunterladen';

  @override
  String get connectingToEuicc => 'Verbindung zur eUICC herstellen...';

  @override
  String get gettingChallenge => 'eUICC-Challenge wird abgerufen...';

  @override
  String get authenticatingWithSmdp => 'Authentifizierung bei SM-DP+...';

  @override
  String get verifyingSignatures => 'SM-DP+-Signaturen werden verifiziert...';

  @override
  String get retrievingMetadata => 'Profil-Metadaten werden abgerufen...';

  @override
  String get preparingDownload => 'Download wird vorbereitet...';

  @override
  String get preparingEuicc => 'eUICC wird vorbereitet...';

  @override
  String get fetchingProfilePackage => 'Profilpaket wird abgerufen...';

  @override
  String installing(Object sent, Object total) {
    return 'Installation ($sent / $total Bytes)...';
  }

  @override
  String get finalizing => 'Abschluss (Speicherinfos werden aktualisiert)...';

  @override
  String get profileInstalledSuccessfully => 'Profil erfolgreich installiert!';

  @override
  String get provider => 'Anbieter';

  @override
  String get iccid => 'ICCID';

  @override
  String get plmn => 'PLMN';

  @override
  String get storage => 'Speicher';

  @override
  String get free => 'Frei';

  @override
  String get nvram => 'NVRAM';

  @override
  String get exportCertificates => 'Zertifikate exportieren';

  @override
  String get euiccCert => 'eUICC-Zertifikat';

  @override
  String get eumCert => 'EUM-Zertifikat';

  @override
  String get enterConfirmationCode =>
      'Geben Sie den von Ihrem Anbieter geforderten Code ein';

  @override
  String get confirmationCodeRequired => 'Bestätigungscode ist erforderlich';

  @override
  String get download => 'Herunterladen';

  @override
  String get installationSuccessful => 'Installation erfolgreich';

  @override
  String get installationSuccessMessage =>
      'Das Profil wurde erfolgreich auf Ihrer eUICC installiert.';

  @override
  String get consumed => 'Genutzt';

  @override
  String get enableProfileNow => 'Profil jetzt aktivieren';

  @override
  String get done => 'Fertig';

  @override
  String get profileEnabledSuccessfully => 'Profil erfolgreich aktiviert';

  @override
  String get enterNewProfileName =>
      'Geben Sie einen neuen Namen für dieses Profil ein, um es leichter identifizieren zu können.';

  @override
  String get profileName => 'Profilname';

  @override
  String get profileNameHint => 'z. B. Dienstreise';

  @override
  String get profileRenamedSuccessfully => 'Profil erfolgreich umbenannt';

  @override
  String get downloadFailed => 'Download fehlgeschlagen';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get savedSuccessfully => 'Erfolgreich gespeichert';

  @override
  String get saveCertificate => 'Zertifikat speichern';

  @override
  String get searchingForReaders => 'Suche nach Lesegeräten...';

  @override
  String get initializationError => 'Initialisierungsfehler';

  @override
  String get noReadersFound => 'Keine Lesegeräte gefunden';

  @override
  String get noReadersFoundMessage =>
      'Schließen Sie ein kompatibles Lesegerät an oder scannen Sie nach BLE-Geräten, um Ihre eSIM-Profile zu verwalten.';

  @override
  String get scanBle => 'Nach BLE scannen';

  @override
  String get reminderDetails => 'Erinnerungsdetails';

  @override
  String get profileNotFound => 'Profil nicht gefunden';

  @override
  String get resending => 'Wird erneut gesendet...';

  @override
  String get noAddressInNotification =>
      'Keine Adresse in den Benachrichtigungsdaten';

  @override
  String get sentSuccessfully => 'Erfolgreich gesendet';

  @override
  String get sendFailed => 'Senden fehlgeschlagen';

  @override
  String get copiedCurl => 'cURL-Befehl in Zwischenablage kopiert';

  @override
  String get noAddressToExport => 'Keine Adresse zum Exportieren';

  @override
  String get noHistoryAvailable => 'Kein Verlauf verfügbar';

  @override
  String get searchByIccid => 'Nach ICCID suchen...';

  @override
  String get resendNotification => 'Benachrichtigung erneut senden';

  @override
  String get exportAsCurl => 'Als cURL exportieren';

  @override
  String get viewDetails => 'Details anzeigen';

  @override
  String get deleteEntry => 'Eintrag löschen';

  @override
  String activeReminders(int count) {
    return '$count aktive Erinnerungen';
  }

  @override
  String get noScheduledReminders => 'Keine geplanten Erinnerungen';

  @override
  String get remindersAppearWhen =>
      'Erinnerungen erscheinen, wenn Sie Datums-Tags zu Profilen hinzufügen.';

  @override
  String activeTagsCount(int count) {
    return '$count aktive Tags über alle Profile hinweg';
  }

  @override
  String get searchTagsOrProfiles => 'Tags oder Profile suchen...';

  @override
  String get noTagsFound => 'Keine Tags gefunden';

  @override
  String get addTagsFromProfileMenu =>
      'Fügen Sie Tags zu Ihren Profilen über das Profil-Bearbeitungsmenü hinzu, um sie hier zu sehen.';

  @override
  String get expired => 'Abgelaufen';

  @override
  String daysLeft(int count) {
    return 'Noch $count T.';
  }

  @override
  String hoursLeft(int count) {
    return 'Noch $count Std.';
  }

  @override
  String get expiresSoon => 'Läuft bald ab';

  @override
  String get soon => 'bald';

  @override
  String get activeTags => 'Aktive Tags';

  @override
  String get addNewTag => 'Neuen Tag hinzufügen';

  @override
  String get noTagsAssigned => 'Diesem Profil sind keine Tags zugewiesen';

  @override
  String get textTagHint => 'Text-Tag (z. B. Arbeit, Reise)';

  @override
  String get addDateExpiryTag => 'Datums-/Ablauf-Tag hinzufügen';

  @override
  String get addNoteOptional => 'Notiz hinzufügen (optional)';

  @override
  String get add => 'Hinzufügen';

  @override
  String get noteHint => 'z. B. Ablauf, 10GB usw.';

  @override
  String get invalidHexString => 'Ungültiger Hex-String';

  @override
  String get resetToDefaults => 'Auf Standard zurücksetzen';

  @override
  String get resetToDefaultsSuccess => 'Auf Standard zurückgesetzt';

  @override
  String get addAidHex => 'AID hinzufügen (Hex)';

  @override
  String get manageAutoNotif =>
      'Automatische Benachrichtigungsverarbeitung verwalten';

  @override
  String get automaticProcessing => 'AUTOMATISCHE VERARBEITUNG';

  @override
  String get notifProcessingInfo =>
      'Das Verarbeiten von Benachrichtigungen hilft bei der Synchronisation zwischen Ihrer eUICC und dem SM-DP+-Server (Anbieter). Das Entfernen gesendeter Benachrichtigungen hält Ihren Kartenspeicher sauber.';

  @override
  String get enabling => 'Aktivieren';

  @override
  String get afterEnabling => 'Nach dem Aktivieren des Profils';

  @override
  String get disabling => 'Deaktivieren';

  @override
  String get afterDisabling => 'Nach dem Deaktivieren des Profils';

  @override
  String get installation => 'Installation';

  @override
  String get afterDownload => 'Nach dem Profil-Download';

  @override
  String get deletion => 'Löschen';

  @override
  String get afterDeletion => 'Nach dem Löschen des Profils';

  @override
  String get autoSend => 'Auto-Senden';

  @override
  String get autoSendSubtitle => 'Automatisch an Server senden';

  @override
  String get autoRemove => 'Auto-Entfernen';

  @override
  String get autoRemoveSubtitle => 'Nach dem Senden von der Karte löschen';

  @override
  String get removeWithoutSending => 'Ohne Senden entfernen';

  @override
  String get removeWithoutSendingSubtitle =>
      'Mit Vorsicht verwenden: Server wird nicht benachrichtigt';

  @override
  String get permissionsActive => 'Berechtigungen aktiv';

  @override
  String get permissionsRequired => 'Berechtigungen erforderlich';

  @override
  String get appCanSendNotif => 'App kann Systembenachrichtungen senden';

  @override
  String get requiredForReminders => 'Erforderlich für Erinnerungsalarme';

  @override
  String get unsupportedPlatformCheck =>
      'Berechtigungsprüfung wird auf dieser Plattform nicht unterstützt. Bitte testen Sie manuell.';

  @override
  String get couldNotVerifyStatus =>
      'Status konnte nicht verifiziert werden. Bitte prüfen Sie die Einstellungen manuell.';

  @override
  String get testNotificationTitle => 'Test-Benachrichtigung';

  @override
  String get seconds => 'Sekunden';

  @override
  String get startTest => 'Test starten';

  @override
  String get sendingNotif => 'Wird gesendet...';

  @override
  String get hostIpLabel => 'Hostname / IP';

  @override
  String get portLabel => 'Port';

  @override
  String get passwordOptionalLabel => 'Passwort (optional)';

  @override
  String get configuredServers => 'Konfigurierte Server';

  @override
  String get secureHttps => 'Sicher (HTTPS)';

  @override
  String get insecureHttp => 'Unsicher (HTTP)';

  @override
  String get urlCopied => 'URL kopiert';

  @override
  String get serverAddedSuccessfully => 'Server erfolgreich hinzugefügt';

  @override
  String get authFailedCheckPassword =>
      'Authentifizierung fehlgeschlagen. Passwort prüfen.';

  @override
  String get addNewServer => 'Neuen Server hinzufügen';

  @override
  String get autoLoadRemotes => 'Remote-Geräte automatisch laden';

  @override
  String get autoLoadRemotesSubtitle =>
      'Beim App-Start automatisch mit konfigurierten Servern verbinden';

  @override
  String get getRemoCardGitHub => 'RemoCard von GitHub herunterladen';

  @override
  String get instructions => 'Anleitung:';

  @override
  String get instruction1 =>
      '1. Installieren Sie die RemoCard-App auf Ihren Android-Geräten.';

  @override
  String get instruction2 => '2. Starten Sie den Server in jeder RemoCard-App.';

  @override
  String get instruction3 => '3. Geben Sie die IP-Adressen hier ein.';

  @override
  String get instruction4 =>
      '4. Alle Remote-SIM-Slots erscheinen in der Geräteliste.';

  @override
  String get appLogsCopied => 'Protokolle in die Zwischenablage kopiert';

  @override
  String get aramInfoTitle => 'ARA-M-Informationen';

  @override
  String get aramInfoSubtitle => 'Details zum Access Rule Applet';

  @override
  String get whatIsAram => 'Was ist ARA-M?';

  @override
  String get aramDescription =>
      'Das Access Rule Applet (ARA-M) ist ein Mechanismus auf eUICCs (eSIMs) und SIM-Karten, der festlegt, welche Anwendungen Profile verwalten oder Low-Level-Operationen durchführen dürfen. Wenn der Hash der App nicht in der ARA-M-Erlaubnisliste der Karte enthalten ist, blockiert das Android-System den Zugriff, was zu einem Fehler \'Zugriff verweigert\' führt.';

  @override
  String get appCertHashes => 'App-Zertifikats-Hashes';

  @override
  String get aramHashInstruction =>
      'Fügen Sie für die Kompatibilität mit verschiedenen Android-Versionen alle unten aufgeführten SHA-1-Zertifikatshashes zu den ARA-M-Regeln Ihrer Karte hinzu. Nach einem Upgrade des App-Signaturschlüssels können verschiedene Android-Versionen unterschiedliche Zertifikate aus dem verifizierten Signaturverlauf prüfen.';

  @override
  String get aramSigningHistoryInstruction =>
      'For compatibility across Android versions, add all SHA-1 certificate hashes below to your card\'s ARA-M rules. After an app signing key upgrade, different Android versions may check different certificates from the verified signing history.';

  @override
  String get certSha1Hash => 'Zertifikats-SHA-1-Hash';

  @override
  String get unavailable => 'Nicht verfügbar';

  @override
  String get troubleshooting => 'Fehlerbehebung';

  @override
  String get troubleStep1 =>
      'Stellen Sie sicher, dass Sie das richtige Kartenlesegerät verwenden.';

  @override
  String get troubleStep2 =>
      'Wenn Sie eine physische Karte verwenden, prüfen Sie, ob es eine Testkarte oder eine Produktionskarte ist (Produktionskarten sperren oft ARA-M).';

  @override
  String get troubleStep3 =>
      'Die obigen Hashes hängen davon ab, ob Sie die Debug-, reguläre oder privilegierte (Magisk)-Version der App verwenden.';

  @override
  String get troubleStep4 =>
      'Erwägen Sie die Verwendung des privilegierten (Magisk)-Builds, der einige Android-API-Einschränkungen umgehen kann.';

  @override
  String get hashCopied => 'Hash in die Zwischenablage kopiert';

  @override
  String get aidCopied => 'AID in die Zwischenablage kopiert';

  @override
  String get lastSeen => 'Zuletzt gesehen';

  @override
  String get unknownProvider => 'Unbekannter Anbieter';

  @override
  String get unknownProfile => 'Unbekanntes Profil';

  @override
  String get tags => 'Tags';

  @override
  String get noTags => 'Keine Tags';

  @override
  String records(int count) {
    return '$count Datensätze';
  }

  @override
  String get bytes => 'Bytes';

  @override
  String get responseCode => 'Antwortcode';

  @override
  String get responseBody => 'Antwortkörper';

  @override
  String get type => 'Typ';

  @override
  String profileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Profile',
      one: '1 Profil',
    );
    return '$_temp0';
  }

  @override
  String get isdrAids => 'ISD-R-AIDs';

  @override
  String get configureDefaultAids => 'Standard-Anwendungs-IDs konfigurieren';

  @override
  String get addAidHexHint => 'AID hinzufügen (Hex)';

  @override
  String get notificationProcessing => 'Benachrichtigungen';

  @override
  String get manageAutoNotification =>
      'Automatische Benachrichtigungsverarbeitung verwalten';

  @override
  String get notificationProcessingHelp =>
      'Das Verarbeiten von Benachrichtigungen hilft bei der Synchronisation zwischen Ihrer eUICC und dem SM-DP+-Server (Anbieter). Das Entfernen gesendeter Benachrichtigungen hält Ihren Kartenspeicher sauber.';

  @override
  String get notificationProcessingTimings => 'Processing timings';

  @override
  String get notificationProcessingTimingsHelp =>
      'Choose when automatic notification processing runs. Some safety-critical timings can only be disabled while Developer Mode is enabled.';

  @override
  String get afterEnablingProfile => 'Nach dem Aktivieren des Profils';

  @override
  String get afterDisablingProfile => 'Nach dem Deaktivieren des Profils';

  @override
  String get afterProfileDownload => 'Nach dem Profil-Download';

  @override
  String get afterProfileDeletion => 'Nach dem Löschen des Profils';

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
  String get sendToServerAutomatically => 'Automatisch an Server senden';

  @override
  String get removeFromCardAfterSending =>
      'Nach dem Senden von der Karte löschen';

  @override
  String get removeWithoutSendingCaution =>
      'Mit Vorsicht verwenden: Server wird nicht benachrichtigt';

  @override
  String get reminderSettings => 'Erinnerungseinstellungen';

  @override
  String get appCanSendNotifications =>
      'App kann Systembenachrichtigungen senden';

  @override
  String get requiredForReminderAlerts => 'Erforderlich für Erinnerungsalarme';

  @override
  String get enable => 'Aktivieren';

  @override
  String get permissionCheckNotSupported =>
      'Berechtigungsprüfung wird auf dieser Plattform nicht unterstützt. Bitte testen Sie manuell.';

  @override
  String get testNotification => 'Test-Benachrichtigung';

  @override
  String get notificationsDisabledMessage =>
      'Benachrichtigungen sind deaktiviert. Bitte aktivieren Sie diese in den Systemeinstellungen, um Erinnerungen zu erhalten.';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get applicationLogs => 'Anwendungsprotokolle';

  @override
  String get refreshReload => 'Aktualisieren/Neu laden';

  @override
  String get toggleAutoScroll => 'Auto-Scroll umschalten';

  @override
  String get refreshDevices => 'Geräte aktualisieren';

  @override
  String get scanBluetooth => 'Bluetooth scannen';

  @override
  String get lessThan1Kb => '< 1 KB';

  @override
  String get connectionFailed => 'Verbindung fehlgeschlagen';

  @override
  String get downloadRemoCard => 'RemoCard herunterladen';

  @override
  String get remoCardAndroidApp => 'Android-App für Fernbedienungen';

  @override
  String get resentSuccessfully => 'Erfolgreich erneut gesendet';

  @override
  String get resendFailed => 'Erneutes Senden fehlgeschlagen';

  @override
  String get eid => 'EID';

  @override
  String get seq => 'Seq';

  @override
  String get date => 'Datum';

  @override
  String errorWithDetails(String error) {
    return 'Fehler: $error';
  }

  @override
  String exportFailed(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String get sasAccreditation => 'SAS-Akkreditierung';

  @override
  String get firmwareVersion => 'Firmware-Version';

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
  String get platformSupport => 'PLATTFORMSUPPORT';

  @override
  String get rspVersion => 'RSP-Version';

  @override
  String get bppVersion => 'BPP-Version';

  @override
  String get gpVersion => 'GlobalPlatform-Version';

  @override
  String get certInfrastructure => 'ZERTIFIKATSINFRASTRUKTUR';

  @override
  String get euiccSignCi => 'eUICC-Signatur-CI';

  @override
  String get euiccVerifyCi => 'eUICC-Verifizierungs-CI';

  @override
  String get none => 'Keine';

  @override
  String keysCount(int count) {
    return '$count Schlüssel';
  }

  @override
  String get state => 'Status';

  @override
  String get profileClass => 'Klasse';

  @override
  String get aid => 'AID';

  @override
  String get euiccSpecifications => 'EUICC-SPEZIFIKATIONEN';

  @override
  String get sending => 'Wird gesendet...';

  @override
  String get failedToSaveTags => 'Speichern der Tags fehlgeschlagen';

  @override
  String get note => 'Notiz';

  @override
  String get notificationDetails => 'Benachrichtigungsdetails';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get status => 'Status';

  @override
  String get sent => 'Gesendet';

  @override
  String get pending => 'Ausstehend';

  @override
  String get notifTypeInstall => 'Installation';

  @override
  String get notifTypeDelete => 'Löschen';

  @override
  String get notifTypeEnable => 'Aktivieren';

  @override
  String get notifTypeDisable => 'Deaktivieren';

  @override
  String get notifTypeRpmEnable => 'RPM aktivieren';

  @override
  String get notifTypeRpmDisable => 'RPM deaktivieren';

  @override
  String get notifTypeRpmDelete => 'RPM löschen';

  @override
  String get notifTypeLoadRpm => 'RPM laden';

  @override
  String confirmDeleteNotification(int seq) {
    return 'Sind Sie sicher, dass Sie die Benachrichtigung #$seq löschen möchten?';
  }

  @override
  String get notificationRemoved => 'Benachrichtigung entfernt';

  @override
  String failedToRemove(String error) {
    return 'Entfernen fehlgeschlagen: $error';
  }

  @override
  String get curlCopied => 'cURL-Befehl in Zwischenablage extrahiert';

  @override
  String failedToGenerateCurl(String error) {
    return 'Erzeugen von cURL fehlgeschlagen: $error';
  }

  @override
  String get noNotificationAddress =>
      'Keine Benachrichtigungsadresse verfügbar';

  @override
  String get sendingNotification => 'Benachrichtigung wird gesendet...';

  @override
  String get notifSentSuccessfully => 'Benachrichtigung erfolgreich gesendet';

  @override
  String get failedToSendNotification =>
      'Senden der Benachrichtigung fehlgeschlagen';

  @override
  String errorSendingNotification(String error) {
    return 'Fehler beim Senden der Benachrichtigung: $error';
  }

  @override
  String pendingCount(int count) {
    return '$count ausstehend';
  }

  @override
  String get currentReader => 'Aktuelles Lesegerät';

  @override
  String get errorLoadingNotifications =>
      'Fehler beim Laden der Benachrichtigungen';

  @override
  String get allCaughtUp => 'Alles auf dem neuesten Stand';

  @override
  String get sequence => 'Sequenz';

  @override
  String get operation => 'Vorgang';

  @override
  String get profileNameLabel => 'Profilname';

  @override
  String get failedToSend => 'Senden fehlgeschlagen';

  @override
  String get onCard => 'Auf Karte';

  @override
  String get sendNotification => 'Benachrichtigung senden';

  @override
  String get deleteNotification => 'Benachrichtigung löschen';

  @override
  String get noNotifications => 'Keine Benachrichtigungen';

  @override
  String get batchDownloadTitle => 'Batch-Download';

  @override
  String get batchDownloadHint =>
      'Mehrere LPA-Codes hier einfügen (einer pro Zeile, max. 20)';

  @override
  String foundLpaCodes(int count) {
    return '$count LPA-Codes gefunden';
  }

  @override
  String get startBatch => 'Batch starten';

  @override
  String get noLpaCodesFound => 'Keine gültigen LPA-Codes gefunden';

  @override
  String get insufficientSpaceStoppingBatch =>
      'Nicht genügend Speicherplatz. Batch-Download wird beendet.';

  @override
  String get exportCsv => 'Als CSV exportieren';

  @override
  String get exportedSuccessfully => 'Erfolgreich exportiert';

  @override
  String get exportResults => 'Ergebnisse exportieren';

  @override
  String get lpa => 'LPA';

  @override
  String get smdp => 'SM-DP+';

  @override
  String get confirmationCode => 'Bestätigungscode';

  @override
  String get size => 'Größe';

  @override
  String get message => 'Nachricht';

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
  String get manage => 'Verwalten';

  @override
  String get buyCard => 'Karte';

  @override
  String get buyData => 'Daten';

  @override
  String get selectDevice => 'Gerät auswählen';

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
  String get estimatedDownloadSize => 'Geschätzte Download-Größe';

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
      'Unzureichender Speicherplatz für die Installation. Die Installation könnte fehlschlagen.';

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
  String get deviceImei => 'Geräte-TAC';

  @override
  String get deviceImeiSubtitle => 'Used for profile downloads';

  @override
  String get editDeviceImei => 'Geräte-TAC bearbeiten';

  @override
  String get editDeviceImeiInfo =>
      '8-stellige TAC oder 15-stellige IMEI eingeben. Standard-TAC: 35383741.';

  @override
  String get imeiDigits => 'TAC- oder IMEI-Zahlen';

  @override
  String get importAction => 'Import';

  @override
  String get qrtrReaderTitle => 'Qualcomm modem (QRTR)';

  @override
  String get qrtrReaderSubtitle =>
      'Qualcomm\'s low-level modem protocol (requires Shizuku)';

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
}
