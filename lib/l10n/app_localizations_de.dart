// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get addBluetoothReader => 'Add Bluetooth reader';

  @override
  String get bluetoothSetupFailed =>
      'Unable to set up the Bluetooth reader. Check that Bluetooth is on and the reader is nearby, then try again.';

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
  String get customDesign => 'Nekoko-Stil';

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
  String get useNekokoIcons => 'Icons von Nekoko Cloud verwenden';

  @override
  String get useNekokoIconsSubtitle => 'Anbieter-Logos von Nekoko abrufen';

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
  String get ensureSingleChannel => 'Einzelnen Kanal erzwingen';

  @override
  String get ensureSingleChannelSubtitle =>
      'Andere logische Kanäle schließen, bevor ein neuer geöffnet wird';

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
  String get checkUpdates => 'Nach Updates suchen';

  @override
  String get checkUpdatesSubtitle =>
      'Beim Start automatisch nach neuen Versionen suchen';

  @override
  String get licenses => 'Open-Source-Lizenzen';

  @override
  String get licensesSubtitle =>
      'Lizenzinformationen für verwendete Open-Source-Libraries';

  @override
  String get noUpdatesFound => 'Keine Updates verfügbar';

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
      'Bluetooth Timeout. Bitte erneut versuchen.';

  @override
  String get errorOmapiSecurity =>
      'Sicherheitsfehler: Eine Regel im Betriebssystem oder der ARA-M hat einen Zugriff auf die Karte blockiert.';

  @override
  String get errorApplicationNotFound =>
      'eUICC Management Application (ISD-R) nicht gefunden. Diese Karte ist möglicherweise keine gültige eUICC.';

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
  String get disconnecting => 'Verbindung wird getrennt...';

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
  String get deleting => 'Löschvorgang...';

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
  String get operationInProgressError =>
      'Vorgang wird ausgeführt, bitte warten';

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
  String get nekokoOperatorIcon => 'Nekoko-Anbieter-Logo';

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
  String get cardRefreshingTitle => 'Karte wird neu eingelesen';

  @override
  String get cardRefreshingMessage =>
      'Die Profilliste kann im Moment nicht geladen werden da die Karte aktuell umgeschalten wird. Bitte versuche es in ein paar Sekunden erneut.';

  @override
  String get useRemoteIcon => 'Remote-Icon verwenden';

  @override
  String get bleDisconnectedTitle => 'Bluetooth-Verbindung verloren';

  @override
  String get bleDisconnectedMessage =>
      'Die Verbindung zum Kartenlesegerät wurde unerwartet unterbrochen. Bitte stelle sicher, dass dieser sich in der Nähe befindet und eingeschalten ist.';

  @override
  String get cardStuckRefreshingMessage =>
      'Profilstatus wird gerade geändert – falls es hängen bleibt, die SIM-Karte manuell neu einstecken.';

  @override
  String get cardNeedsReplugTitle => 'SIM-Karte neu einstecken';

  @override
  String get cardNeedsReplugMessage =>
      'Die Karte gibt ihr eUICC-Applet nicht frei und kann daher derzeit nicht verwaltet werden. Entfernen Sie die SIM-Karte, stecken Sie sie erneut ein und versuchen Sie es noch einmal.';

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
  String get vowifi => 'WLAN-Telefonie';

  @override
  String get vowifiSubtitle => 'WLAN-Telefonie aktivieren (BETA)';

  @override
  String get vowifiDisclaimerTitle => 'Experimentelles VoWiFi aktivieren?';

  @override
  String get vowifiDisclaimerBody =>
      'VoWiFi ist experimentell. Es kommuniziert direkt mit Ihrem Mobilfunkanbieter und funktioniert nur mit einem kompatiblen externen SIM-/eSIM-Leser, der rohe APDUs unterstützt. Die Kompatibilität von Anbietern und Lesern kann variieren.';

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
      'Um dieser App Zugriff zu gewähren, müssen Sie möglicherweise den folgenden SHA-1-Zertifikatshash zu den ARA-M-Regeln Ihrer Karte hinzufügen. Dieser Hash ist für das Zertifikat Ihres aktuellen App-Builds einzigartig.';

  @override
  String get aramSigningHistoryInstruction =>
      'Fügen Sie für die Kompatibilität mit verschiedenen Android-Versionen alle unten aufgeführten SHA-1-Zertifikats-Hashes zu den ARA-M-Regeln Ihrer Karte hinzu. Nach einem Wechsel des App-Signaturschlüssels können unterschiedliche Android-Versionen verschiedene Zertifikate aus dem verifizierten Signaturverlauf prüfen.';

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
  String get tags => 'Etiketten';

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
  String get notificationProcessingTimings => 'Verarbeitungszeitpunkte';

  @override
  String get notificationProcessingTimingsHelp =>
      'Legen Sie fest, wann die automatische Benachrichtigungsverarbeitung ausgeführt wird. Einige sicherheitskritische Zeitpunkte lassen sich nur bei aktiviertem Entwicklermodus deaktivieren.';

  @override
  String get afterEnablingProfile => 'Nach dem Aktivieren des Profils';

  @override
  String get afterDisablingProfile => 'Nach dem Deaktivieren des Profils';

  @override
  String get afterProfileDownload => 'Nach dem Profil-Download';

  @override
  String get afterProfileDeletion => 'Nach dem Löschen des Profils';

  @override
  String get initialLoad => 'Erstes Laden';

  @override
  String get processNotificationsOnInitialLoad =>
      'Benachrichtigungen verarbeiten, nachdem die Profile geladen wurden';

  @override
  String get afterSwitchingProfile => 'Nach dem Profilwechsel';

  @override
  String get processNotificationsAfterSwitchingProfile =>
      'Benachrichtigungen nach dem Aktivieren oder Deaktivieren eines Profils verarbeiten';

  @override
  String get beforeProfileDownload => 'Vor dem Profil-Download';

  @override
  String get processNotificationsBeforeProfileDownload =>
      'Benachrichtigungen vor dem Start eines Profil-Downloads verarbeiten';

  @override
  String get afterProfileInstalled => 'Nach der Profilinstallation';

  @override
  String get processNotificationsAfterProfileInstalled =>
      'Benachrichtigungen nach der Installation eines Profils verarbeiten';

  @override
  String get processNotificationsAfterProfileDeletion =>
      'Benachrichtigungen nach dem Löschen eines Profils verarbeiten';

  @override
  String get developerModeRequiredToDisableTiming =>
      'Aktivieren Sie den Entwicklermodus, um diesen Zeitpunkt zu deaktivieren.';

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
  String get beeSimFirmwareAction => 'BeeSIM-Firmware aktualisieren';

  @override
  String get beeSimFirmwareTitle => 'BeeSIM-Firmware-Update';

  @override
  String get beeSimFirmwareWarning =>
      'Ein BeeSIM-Firmware-Update ist verfügbar. Halten Sie die Karte mit Strom versorgt, Bluetooth verbunden und die App geöffnet, bis der Vorgang abgeschlossen ist. Ein Abbruch des Updates kann die Karte vorübergehend unbrauchbar machen.';

  @override
  String get beeSimFirmwareConfirm => 'Firmware aktualisieren';

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
  String get configuredAddresses => 'KONFIGURIERTE ADRESSEN';

  @override
  String get defaultSmdpAddress => 'Standard-SM-DP+';

  @override
  String get rootDsAddress => 'Root-SM-DS';

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
  String get remainingSpace => 'Verbleibender Speicherplatz';

  @override
  String get stopBatch => 'Stapel stoppen';

  @override
  String get stopping => 'Wird beendet...';

  @override
  String get remove => 'Entfernen';

  @override
  String get updateAvailable => 'Update verfügbar';

  @override
  String updateAvailableSubtitle(String appName, String version, String build) {
    return 'Eine neue Version von $appName ist verfügbar (v$version b$build). Möchten Sie jetzt aktualisieren?';
  }

  @override
  String get updateAction => 'Aktualisieren';

  @override
  String get later => 'Später';

  @override
  String get changelog => 'Änderungsverlauf';

  @override
  String get sortBy => 'Sortieren nach';

  @override
  String get sortIccid => 'ICCID';

  @override
  String get sortCountry => 'Land';

  @override
  String get sortAscending => 'Aufsteigend';

  @override
  String get sortDescending => 'Absteigend';

  @override
  String get searchProfiles => 'Profile suchen...';

  @override
  String get noProfilesMatch => 'Keine Profile entsprechen deiner Suche.';

  @override
  String get sortDefault => 'Standard';

  @override
  String get sortNickname => 'Anzeigename';

  @override
  String get showProfileSearch => 'Profilsuche anzeigen';

  @override
  String get showProfileSearchSubtitle =>
      'Such- und Sortierleiste in Profilliste anzeigen';

  @override
  String get noReaderFound =>
      'Reader nicht gefunden. Bitte verbinde deinen eUICC Adapter.';

  @override
  String get readyToInstallProfile => 'Bereit zum Installieren des Profils.';

  @override
  String get downloadHere => 'Hier herunterladen';

  @override
  String get manage => 'Verwalten';

  @override
  String get buyCard => 'Karte';

  @override
  String get buyData => 'Daten';

  @override
  String get selectDevice => 'Gerät auswählen';

  @override
  String get selectReaderTitle => 'Karte wählen';

  @override
  String get authorizeSigning => 'Signieren autorisieren';

  @override
  String get signingDescription =>
      'Eine Website verlangt eine sichere Signatur von dieser eUICC.';

  @override
  String get smdpAddress => 'SM-DP+-Adresse';

  @override
  String get sign => 'Signieren';

  @override
  String profilesInstalled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Profile installiert',
      one: '1 Profil installiert',
    );
    return '$_temp0';
  }

  @override
  String get estimatedDownloadSize => 'Geschätzte Download-Größe';

  @override
  String get phoneFormatInternationalOnly => 'nur E.164 Int\'l';

  @override
  String get phoneFormatInternationalAndMobile => 'Int. & Mobil';

  @override
  String get phoneFormatInternationalAndAll => 'Int. & National';

  @override
  String get phoneFormatOff => 'Deaktiviert';

  @override
  String get settings_item_unit_b => 'Bytes';

  @override
  String get settings_item_unit_kb => 'kB (1.000 Bytes)';

  @override
  String get settings_item_unit_kib => 'kiB (1.024 Bytes)';

  @override
  String get settings_item_unit_adaptive_si => 'B / KiB Adaptiv';

  @override
  String get settings_item_unit_adaptive_bi => 'B / KiB Adaptiv';

  @override
  String get insufficientStorageWarning =>
      'Unzureichender Speicherplatz für die Installation. Die Installation könnte fehlschlagen.';

  @override
  String get estimateProfileSize => 'Geschätzte Profilgröße';

  @override
  String get estimateProfileSizeSubtitle =>
      'Schätzung der Größe der Profil-Metadaten vor dem Download';

  @override
  String get customize => 'Anpassen';

  @override
  String get customizeDescription =>
      'Geben Sie einen neuen 6-stelligen Hex-Namen und ein Passwort für Ihren Writer an.';

  @override
  String get customizeSuccess =>
      'Writer angepasst. Bitte koppeln Sie das Gerät erneut.';

  @override
  String customizeFailed(String error) {
    return 'Writer konnte nicht angepasst werden: $error';
  }

  @override
  String get defaultPasswordWillChangeTitle =>
      'Das Standardpasswort wird geändert';

  @override
  String defaultPasswordWillChangeMessage(String password) {
    return 'Dieses Gerät ist mit seinem Standardpasswort verbunden. Beim Umbenennen wird das Passwort auf $password gesetzt. Speichern Sie dieses Passwort, bevor Sie sich erneut verbinden.';
  }

  @override
  String get savedBleDevices => 'Zuvor verbundene BLE-Geräte';

  @override
  String get savedBleDevicesSubtitle =>
      'Auf diesem Gerät gespeicherte Gerätenamen und Passwörter anzeigen';

  @override
  String get savedBleDevicesDescription =>
      'Jeder Eintrag ist ein lokal gespeichertes NBLESim-Passwort. Standardpasswörter werden ebenfalls gespeichert.';

  @override
  String get noSavedBleDevices => 'Keine zuvor verbundenen BLE-Geräte.';

  @override
  String get deviceName => 'Gerätename';

  @override
  String get success => 'Abgeschlossen';

  @override
  String get devicePasswordHint => '6 Hex-Zeichen oder Passwort-String';

  @override
  String get sixHexChars => '6 Hex-Zeichen';

  @override
  String get database => 'Datenbank';

  @override
  String exportSuccess(String path) {
    return 'Datenbank wurde nach $path exportiert';
  }

  @override
  String get importDatabase => 'Datenbank importieren';

  @override
  String get importDatabaseSubtitle =>
      'Datensätze aus einer anderen Datenbankdatei zusammenführen';

  @override
  String get importDatabaseDialogTitle =>
      'Zu importierende Datenbankdatei auswählen';

  @override
  String get importDatabaseTitle => 'Datenbank importieren';

  @override
  String get importDatabaseContent =>
      'Dadurch werden Zeilen aus der ausgewählten Datenbank in Ihre aktuelle Datenbank übernommen. Vorhandene Zeilen mit denselben Schlüsseln werden überschrieben. Fortfahren?';

  @override
  String get import => 'Importieren';

  @override
  String get importSuccess => 'Datenbank erfolgreich importiert';

  @override
  String importFailed(String error) {
    return 'Datenbank konnte nicht importiert werden: $error';
  }

  @override
  String get resetDatabase => 'Datenbanken zurücksetzen';

  @override
  String get resetDatabaseSubtitle =>
      'Alle Anwendungsdaten löschen und neu starten';

  @override
  String get resetDatabaseTitle => 'Anwendungsdatenbank zurücksetzen';

  @override
  String get resetDatabaseContent =>
      'Alle lokal gespeicherten Daten, Konfigurationen und Logs werden jetzt gelöscht. Die Anwendung wird geschlossen. Möchtest du wirklich fortfahren?';

  @override
  String get deleteDatabase => 'Datenbank löschen';

  @override
  String resetFailed(String error) {
    return 'Fehler beim Zurücksetzen der Datenbank: $error';
  }

  @override
  String get deviceImei => 'Geräte-IMEI (TAC)';

  @override
  String get deviceImeiSubtitle => 'Für Profil-Downloads verwendet';

  @override
  String get editDeviceImei => 'Geräte-IMEI bearbeiten';

  @override
  String get editDeviceImeiInfo =>
      'Geben Sie einen 8-stelligen TAC oder eine 15-stellige IMEI ein. Standard-TAC: 35383741.';

  @override
  String get imeiDigits => 'IMEI (Zahlen)';

  @override
  String get importAction => 'Importieren';

  @override
  String get transferTitle => 'eSIM übertragen';

  @override
  String get transferAction => 'Auf dieses Gerät übertragen';

  @override
  String get transferCheckingEligibility => 'Berechtigung wird geprüft…';

  @override
  String get transferReadingSource => 'Quell-SIM wird gelesen…';

  @override
  String get transferContactingCarrier => 'Anbieter wird kontaktiert…';

  @override
  String get transferIneligibleReader =>
      'Dieses Profil kann mit diesem Leser nicht übertragen werden. Die Authentifizierung der Quell-SIM (EAP-AKA) ist hier nicht erreichbar.';

  @override
  String get transferNoEntitlement =>
      'Für dieses Profil wurde keine Übertragungskonfiguration des Anbieters gefunden. Sie können den Entitlement-Server manuell eingeben.';

  @override
  String transferSourceCarrier(String carrier) {
    return 'Quellanbieter: $carrier';
  }

  @override
  String get transferConfirmTitle => 'Dieses Abonnement übertragen?';

  @override
  String get transferConfirmBody =>
      'Der Anbieter stellt dieses Abonnement erneut auf dieser eUICC aus. Das Quellprofil wird im Rahmen der Übertragung möglicherweise gelöscht.';

  @override
  String get transferStart => 'Übertragung starten';

  @override
  String get transferDownloadingProfile =>
      'Übertragenes Profil wird heruntergeladen…';

  @override
  String get transferDeleteSourceTitle => 'Quellprofil löschen';

  @override
  String transferDeleteSourceBody(String iccid) {
    return 'Der Anbieter verlangt, dass das Quellprofil $iccid vor der Aktivierung gelöscht wird. Jetzt löschen?';
  }

  @override
  String get transferDeleteSourceConfirm => 'Löschen und fortfahren';

  @override
  String get transferUserInputSubmit => 'Absenden';

  @override
  String get transferAccept => 'Annehmen';

  @override
  String get transferReject => 'Ablehnen';

  @override
  String get transferPendingActivation =>
      'Der Anbieter aktiviert dieses Abonnement noch. Es wird in Kürze abgeschlossen; Sie können dieses Fenster schließen und später erneut nachsehen.';

  @override
  String get transferDismissed => 'Der Anbieter hat die Übertragung abgelehnt.';

  @override
  String get transferDelayedDownload =>
      'Der Anbieter stellt das Profil in Kürze bereit. Geben Sie nach der Installation die installierte ICCID ein, um den Vorgang abzuschließen.';

  @override
  String get transferInstalledIccid => 'Installierte ICCID';

  @override
  String get transferSuccess => 'Übertragung abgeschlossen';

  @override
  String transferFailed(String error) {
    return 'Übertragung fehlgeschlagen: $error';
  }

  @override
  String get transferManualServerTitle => 'Entitlement-Server (erweitert)';

  @override
  String get transferManualServerHint => 'https://entitlement.example.com';

  @override
  String get transferEnablingSource => 'Quellprofil wird vorbereitet…';

  @override
  String get transferClose => 'Schließen';

  @override
  String get transferContinue => 'Fortfahren';

  @override
  String get transferSmdsDiscovering => 'Profile werden über SM-DS gesucht…';

  @override
  String get transferSmdsNoProfiles =>
      'Über die SM-DS-Suche wurden keine ausstehenden Profile gefunden.';

  @override
  String get transferSelectProfile => 'Wählen Sie ein Profil zum Herunterladen';

  @override
  String get discoverProfiles => 'Profile suchen (SM-DS)';

  @override
  String get discoveringProfiles => 'Profile werden gesucht…';

  @override
  String get discoveryNoProfiles =>
      'Über die SM-DS-Suche wurden keine ausstehenden Profile gefunden.';

  @override
  String get transferSmdsServerTitle => 'SM-DS-Server';

  @override
  String transferProfileOnServer(String eventId, String address) {
    return '$eventId auf $address';
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

  @override
  String get deleteNotificationHistoryEntry => 'Delete local history entry';
}
