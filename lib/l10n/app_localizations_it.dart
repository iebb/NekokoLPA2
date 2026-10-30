// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get addBluetoothReader => 'Add Bluetooth reader';

  @override
  String get bluetoothSetupFailed =>
      'Unable to set up the Bluetooth reader. Check that Bluetooth is on and the reader is nearby, then try again.';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get displaySettings => 'Impostazioni display';

  @override
  String get appearance => 'Aspetto';

  @override
  String get appearanceSubtitle =>
      'Personalizza tema, layout e preferenze di visualizzazione';

  @override
  String get darkMode => 'Modalità scura';

  @override
  String get themeStyle => 'Stile del tema';

  @override
  String get themeStyleSubtitle => 'Scegli tra stile personalizzato e MD3';

  @override
  String get customDesign => 'Stile Nekoko';

  @override
  String get stockMD3 => 'MD3 standard';

  @override
  String get waterfallLayout => 'Layout a cascata';

  @override
  String get waterfallLayoutSubtitle =>
      'Usa lo stile Masonry su schermi larghi';

  @override
  String get system => 'Sistema';

  @override
  String get light => 'Chiaro';

  @override
  String get dark => 'Scuro';

  @override
  String get language => 'Lingua';

  @override
  String get systemLanguage => 'Lingua di sistema';

  @override
  String get general => 'Generale';

  @override
  String get ui => 'Interfaccia';

  @override
  String get autoLoadProfiles => 'Carica automaticamente i profili';

  @override
  String get autoLoadProfilesSubtitle =>
      'Carica i profili quando è stato selezionato il lettore';

  @override
  String get loadProfileIcons => 'Icone profilo';

  @override
  String get loadProfileIconsSubtitle =>
      'Utilizza le icone dei profili da eUICC (può rallentare)';

  @override
  String get useNekokoIcons => 'Icone da Nekoko Cloud';

  @override
  String get useNekokoIconsSubtitle =>
      'Utilizza le icone operatore fornite da Nekoko Cloud';

  @override
  String get forceDeviceDropdown => 'Forza menu a tendina';

  @override
  String get forceDeviceDropdownSubtitle =>
      'Usa sempre il menu a tendina per i dispositivi';

  @override
  String get sizeDisplayUnit => 'Unità capacità';

  @override
  String get sizeDisplayUnitSubtitle =>
      'Formato visualizzazione capacità della memoria';

  @override
  String get phoneFormat => 'Formato numero di telefono';

  @override
  String get phoneFormatSubtitle =>
      'Formato di visualizzazione del numero di telefono';

  @override
  String get notifications => 'Notifiche';

  @override
  String get notificationSettings => 'Impostazioni notifiche';

  @override
  String get notificationSettingsSubtitle =>
      'Configura l\'elaborazione e la rimozione automatica';

  @override
  String get notificationHistory => 'Cronologia notifiche';

  @override
  String get notificationHistorySubtitle =>
      'Trova, gestisci e reinvia le notifiche inviate';

  @override
  String get tagsAndReminders => 'Tag e Promemoria';

  @override
  String get tagManager => 'Gestione Tag';

  @override
  String get tagManagerSubtitle => 'Crea e modifica i Tag dei profili';

  @override
  String get tagReminders => 'Promemoria Tag';

  @override
  String get tagRemindersSubtitle =>
      'Pianifica notifiche basate sulla data di scadenza dei Tag';

  @override
  String get manageTagsAndReminders => 'Gestisci Tag e Promemoria';

  @override
  String get manageTagsAndRemindersSubtitle =>
      'Configura tag, permessi e avvisi di test';

  @override
  String get viewScheduledReminders => 'Visualizza promemoria pianificati';

  @override
  String get viewScheduledRemindersSubtitle =>
      'Gestisci le prossime notifiche basate sui tag';

  @override
  String get connectivity => 'Connettività';

  @override
  String get remoteReaders => 'Lettori remoti';

  @override
  String get remoteReadersSubtitle => 'Configura app companion RemoCard';

  @override
  String get enableBle => 'Connettore Bluetooth';

  @override
  String get enableBleSubtitle =>
      'Abilita la scansione e la connessione ai lettori Bluetooth';

  @override
  String get enableCcid => 'Connettore USB CCID';

  @override
  String get enableCcidSubtitle => 'Abilita i lettori di smart card USB (CCID)';

  @override
  String get enableOmapi => 'Connettore OMAPI';

  @override
  String get enableOmapiSubtitle =>
      'Abilita l\'accesso eUICC integrato tramite OMAPI';

  @override
  String get enableTmapi => 'Connettore Telephony API';

  @override
  String get enableTmapiSubtitle =>
      'Abilita l\'accesso privilegiato tramite Telephony API API';

  @override
  String get readerTypes => 'Tipi di Lettore';

  @override
  String get readerTypesSubtitle =>
      'Gestisci i tipi di lettori abilitati (CCID, Bluetooth, Remoto, ecc.)';

  @override
  String get enabledReaderTypes => 'Tipi di Lettore Abilitati';

  @override
  String get enabledReaderTypesSubtitle =>
      'Controlla quali tipi di lettori sono disponibili nell\'app';

  @override
  String get remoteReaderSettings => 'Impostazioni Lettori Remoti';

  @override
  String get remoteReaderSettingsSubtitle =>
      'Configura server e connessioni dei lettori remoti';

  @override
  String get ccidReaderTitle => 'CCID (USB/PC/SC)';

  @override
  String get ccidReaderSubtitle =>
      'Lettori di smart card USB e dispositivi PC/SC';

  @override
  String get bluetoothReaderTitle => 'Bluetooth';

  @override
  String get bluetoothReaderSubtitle =>
      'Lettori e scrittori di smart card Bluetooth LE';

  @override
  String get remoteReadersTitle => 'Lettori Remoti';

  @override
  String get remoteReadersConnectorSubtitle =>
      'Lettori di smart card remoti connessi alla rete';

  @override
  String get omapiReaderTitle => 'OMAPI';

  @override
  String get omapiReaderSubtitle =>
      'Slot per schede SIM integrati tramite Open Mobile API';

  @override
  String get tmapiReaderTitle => 'Telephony API';

  @override
  String get tmapiReaderSubtitle => 'eSIM integrata tramite Telephony API';

  @override
  String get remoteServerConfiguration => 'Configurazione Server Remoto';

  @override
  String get remoteServerConfigurationSubtitle =>
      'Gestisci server di lettori remoti e impostazioni di connessione';

  @override
  String get enableBrowser => 'Abilita Browser';

  @override
  String get enableBrowserSubtitle =>
      'Mostra schede del browser aggiuntive come Negozio, Acquisto o Aiuto';

  @override
  String get transport => 'Trasporto dati';

  @override
  String get disableRefreshFlags => 'Disabilita flag di aggiornamento';

  @override
  String get disableRefreshFlagsSubtitle =>
      'Questo non si applicherà ai lettori esterni';

  @override
  String get apduMaxSegmentSize => 'Segmentazione APDU';

  @override
  String get apduMaxSegmentSizeSubtitle =>
      'Dimensione massima dei dati per ogni blocco APDU';

  @override
  String get ensureSingleChannel => 'Garantisci un canale singolo';

  @override
  String get ensureSingleChannelSubtitle =>
      'Chiudi gli altri canali logici prima di aprirne uno nuovo';

  @override
  String get analytics => 'Analitica e servizio cloud';

  @override
  String get nekokoCloud => 'Nekoko Cloud';

  @override
  String get nekokoCloudSubtitle =>
      'Invia dati anonimi per migliorare le prestazioni del servizio';

  @override
  String get developer => 'Sviluppatore';

  @override
  String get developerMode => 'Modalità sviluppatore';

  @override
  String get developerModeSubtitle => 'Abilita funzionalità di debug avanzate';

  @override
  String get exportDatabase => 'Esporta database';

  @override
  String get exportDatabaseSubtitle => 'Crea un backup del database locale';

  @override
  String get openDatabaseFolder => 'Cartella database';

  @override
  String get openDatabaseFolderSubtitle =>
      'Apri la cartella contenente il file del database';

  @override
  String get decodeAsn1 => 'Decodifica Log ASN.1 (Lento)';

  @override
  String get decodeAsn1Subtitle => 'Impatta pesantemente sulle prestazioni';

  @override
  String get viewAppLogs => 'Visualizza Log App';

  @override
  String get viewAppLogsSubtitle =>
      'Visualizza i log raccolti dall\'applicazione ';

  @override
  String get about => 'Informazioni';

  @override
  String get version => 'Versione';

  @override
  String get build => 'Build';

  @override
  String get checkUpdates => 'Controlla aggiornamenti';

  @override
  String get checkUpdatesSubtitle =>
      'Controlla automaticamente le nuove versioni all\'avvio';

  @override
  String get licenses => 'Licenze open source';

  @override
  String get licensesSubtitle =>
      'Informazioni sulle licenze delle librerie open source utilizzate';

  @override
  String get noUpdatesFound => 'Nessun aggiornamento trovato';

  @override
  String get profilesTitle => 'Profili';

  @override
  String get switchEstkSlot => 'Cambia Slot eSTK';

  @override
  String get notificationsButton => 'Notifiche';

  @override
  String get downloadProfile => 'Scarica profilo';

  @override
  String get reconnect => 'Riconnetti';

  @override
  String get bluetoothNotConnected => 'Bluetooth non connesso';

  @override
  String get bluetoothNotConnectedSubtitle =>
      'Assicurati che il Bluetooth sia attivo e il dispositivo sia vicino. Tocca Connetti per iniziare.';

  @override
  String get bluetoothConnectionFailed => 'Connessione Bluetooth Fallita';

  @override
  String bluetoothConnectionFailedSubtitle(Object error) {
    return 'Impossibile connettersi al dispositivo Bluetooth.\n\n$error';
  }

  @override
  String get removeDevice => 'Rimuovi Dispositivo';

  @override
  String get retryConnection => 'Connetti';

  @override
  String get remoteConnectionFailed => 'Connessione Lettore Remoto Fallita';

  @override
  String remoteConnectionFailedMessage(Object error) {
    return 'Assicurati che il server remoto sia attivo e raggiungibile.\n\n$error';
  }

  @override
  String get errorBluetoothTimeout => 'Operazione Bluetooth scaduta. Riprova.';

  @override
  String get errorOmapiSecurity =>
      'Errore di sicurezza: l\'accesso alla carta è stato negato dal sistema operativo o dalle regole ARA-M.';

  @override
  String get errorApplicationNotFound =>
      'Applicazione di gestione eUICC (ISD-R) non trovata. Questa carta potrebbe non essere una eUICC valida.';

  @override
  String get changeSettings => 'Cambia impostazioni';

  @override
  String get connectCompatibleReader =>
      'Connetti un lettore compatibile per iniziare.';

  @override
  String get connectReaderMessageBle =>
      'Puoi anche cercare dispositivi Bluetooth compatibili se hai una eUICC abilitata al Bluetooth.';

  @override
  String get connectReaderMessageNoBle =>
      'Assicurati che il tuo lettore CCID sia collegato al computer.';

  @override
  String get downloadSmartCardExtension => 'Scarica estensione Smart Card';

  @override
  String get smartCardExtensionMessage =>
      'L\'estensione è necessaria per gestire i lettori USB CCID tramite browser.';

  @override
  String get scanForBluetooth => 'Scansione Bluetooth';

  @override
  String get connectRemote => 'Connetti in remoto';

  @override
  String get noCardDetected => 'Nessuna scheda rilevata';

  @override
  String get noCardDetectedMessage =>
      'Nessuna eUICC supportata o attiva in questo slot.';

  @override
  String get noDataLoaded => 'Non connesso';

  @override
  String get loadProfiles => 'Connetti';

  @override
  String get disconnect => 'Disconnetti';

  @override
  String get disconnecting => 'Disconnessione...';

  @override
  String get profilesEmpty => 'Nessun profilo';

  @override
  String get profilesEmptyMessage =>
      'Questa scheda eUICC non contiene profili installati.';

  @override
  String get renameProfile => 'Rinomina Profilo';

  @override
  String get nickname => 'Nome profilo';

  @override
  String get enterProfileNickname => 'Inserisci nome profilo';

  @override
  String get profileNicknameNote =>
      'Nota: I Tag sono gestiti separatamente tramite il menu \'Gestisci Tag\'.';

  @override
  String get useProfileIcon => 'Icona profilo';

  @override
  String get useProfileIconSubtitle => 'Usa l\'icona predefinita della eSIM';

  @override
  String get removeCustomIcon => 'Rimuovi icona personalizzata';

  @override
  String get noRemoteIcon =>
      'Nessuna icona sul cloud disponibile per questo operatore';

  @override
  String get cancel => 'Annulla';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Salva';

  @override
  String get delete => 'Elimina';

  @override
  String get refresh => 'Aggiorna';

  @override
  String get initializing => 'Inizializzazione...';

  @override
  String get refreshingProfiles => 'Aggiornamento profili...';

  @override
  String get retrievingEid => 'Recupero EID e Info...';

  @override
  String get updatingProfile => 'Aggiornamento profilo...';

  @override
  String get manageIsdR => 'Gestione AID ISD-R';

  @override
  String get manageIsdRSubtitle =>
      'Configura gli Application ID predefiniti per eUICC';

  @override
  String get transportFailed => 'Errore di trasporto';

  @override
  String get remoteTransportFailedMessage =>
      'Connesso al server, ma l\'invio del comando è fallito. Il dispositivo remoto potrebbe essere occupato o disconnesso dalla scheda. Riprovare?';

  @override
  String get retry => 'Riprova';

  @override
  String get scanningForReaders => 'Ricerca lettori...';

  @override
  String get switchedEstkSlot => 'Slot eSTK aggiornato';

  @override
  String get scanningForUnresponsiveDevices => 'Ricontrollo dispositivi...';

  @override
  String get resettingConnection => 'Ripristino connessione...';

  @override
  String get connectingToReader => 'Connessione al lettore...';

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
  String get moreOptions => 'Altre opzioni';

  @override
  String get retrievingProfiles => 'Recupero profili...';

  @override
  String get savingProfileMetadata => 'Salvataggio metadati profilo...';

  @override
  String get enablingProfile => 'Abilitazione profilo...';

  @override
  String get disablingProfile => 'Disabilitazione profilo...';

  @override
  String get deleteProfile => 'Elimina profilo';

  @override
  String deleteProfileConfirmation(Object profileName) {
    return 'Sei sicuro di voler eliminare il profilo $profileName?\nQuesta azione è irreversibile.';
  }

  @override
  String get deletingProfile => 'Eliminazione profilo...';

  @override
  String get deleting => 'Eliminazione...';

  @override
  String get dataUsage => 'Utilizzo dati';

  @override
  String get details => 'Dettagli';

  @override
  String get rename => 'Rinomina';

  @override
  String get changeIcon => 'Cambia icona';

  @override
  String get manageTags => 'Gestisci Tag';

  @override
  String get copyIccid => 'Copia ICCID';

  @override
  String get notificationProcessingError =>
      'Impossibile eseguire operazioni durante l\'elaborazione delle notifiche';

  @override
  String get operationInProgressError => 'Operazione in corso, attendi';

  @override
  String iccidCopied(Object iccid) {
    return 'ICCID copiato: $iccid';
  }

  @override
  String get operationRestricted => 'Operazione limitata';

  @override
  String get notificationProcessingDownloadError =>
      'Le notifiche sono ancora in fase di elaborazione. Attendi il completamento prima di scaricare nuovi profili.';

  @override
  String get operational => 'Operativo';

  @override
  String get test => 'Test';

  @override
  String get provisioning => 'Provisioning';

  @override
  String get profileDetails => 'Dettagli profilo';

  @override
  String get profileDetailsSubtitle =>
      'Informazioni dalla eUICC per questo slot profilo.';

  @override
  String get enabled => 'Abilitato';

  @override
  String get disabled => 'Disabilitato';

  @override
  String get tagsManagedSeparately =>
      'Nota: I tag sono gestiti separatamente tramite il menu \'Gestisci Tag\'.';

  @override
  String get changeProfileIcon => 'Cambia icona profilo';

  @override
  String get selectFromGallery => 'Seleziona dalla galleria';

  @override
  String get nekokoOperatorIcon => 'Icona operatore da Nekoko Cloud';

  @override
  String get iconFromEsim => 'Icona dalla scheda eSIM';

  @override
  String updateIconFailed(Object error) {
    return 'Impossibile aggiornare l\'icona: $error';
  }

  @override
  String get failedToReadImage => 'Impossibile leggere il file dell\'immagine';

  @override
  String get failedToProcessImage => 'Impossibile elaborare l\'immagine';

  @override
  String get customIconSet => 'Icona personalizzata impostata con successo';

  @override
  String get noMccMnc => 'Nessun MCC/MNC disponibile per questo profilo';

  @override
  String get fetchingRemoteIcon => 'Recupero icona da Nekoko Cloud...';

  @override
  String get remoteIconSaved =>
      'Icona da Nekoko Cloud salvata come icona personalizzata';

  @override
  String fetchRemoteIconFailed(Object error) {
    return 'Impossibile utilizzare l\'icona da Nekoko Cloud: $error';
  }

  @override
  String get noProfileIcon => 'Nessuna icona profilo disponibile';

  @override
  String get profileIconSaved =>
      'Icona profilo salvata come icona personalizzata';

  @override
  String get customIconRemoved => 'Icona personalizzata è stata rimossa';

  @override
  String get failed => 'Fallito';

  @override
  String euiccError(Object action) {
    return 'La eUICC ha restituito un errore durante il tentativo di $action il profilo.';
  }

  @override
  String get dismiss => 'Chiudi';

  @override
  String get dataPlan => 'Piano dati';

  @override
  String get used => 'usati';

  @override
  String get total => 'totali';

  @override
  String expires(Object date) {
    return 'Scadenza: $date';
  }

  @override
  String get close => 'Chiudi';

  @override
  String get server => 'Server';

  @override
  String get switchFailed => 'Cambio fallito';

  @override
  String get deviceRefreshFailed => 'Aggiornamento dispositivo fallito';

  @override
  String get euiccOptions => 'Opzioni eUICC';

  @override
  String get euiccInfo => 'Info eUICC';

  @override
  String get hideEid => 'Nascondi EID';

  @override
  String get showEid => 'Mostra EID';

  @override
  String get copyEid => 'Copia EID';

  @override
  String get eidCopied => 'EID copiato negli appunti';

  @override
  String get connectRemotes => 'Connetti lettore remoto';

  @override
  String get configureRemotes => 'Configura lettore remoto';

  @override
  String get connectingToRemoteReaders =>
      'Connessione ai lettori remoti in background...';

  @override
  String get noRemoteReadersFound => 'Nessun lettore remoto trovato';

  @override
  String connectedRemoteReaders(Object count) {
    return 'Connesso a $count lettori remoti';
  }

  @override
  String failedToConnectRemoteReaders(Object error) {
    return 'Impossibile connettersi al lettore remoto: $error';
  }

  @override
  String get remoteReaderPassword => 'Password lettore remoto';

  @override
  String get remoteReaderPasswordSubtitle =>
      'Questo lettore remoto richiede una password.';

  @override
  String get password => 'Password';

  @override
  String get deleteConnection => 'Elimina connessione';

  @override
  String get connect => 'Connetti';

  @override
  String get remoteReaderConnectionFailed =>
      'Connessione lettore remoto fallita';

  @override
  String remoteReaderConnectionFailedSubtitle(Object error) {
    return 'Assicurati che il server remoto sia attivo e accessibile.\n\n$error';
  }

  @override
  String get connectReader => 'Connetti un lettore compatibile per iniziare.';

  @override
  String get connectReaderSubtitleBle =>
      'Puoi anche cercare dispositivi Bluetooth compatibili se hai una eUICC abilitata al Bluetooth.';

  @override
  String get connectReaderSubtitleCcid =>
      'Assicurati che il tuo lettore CCID sia connesso al computer.';

  @override
  String get downloadExtension => 'Scarica Estensione Smart Card';

  @override
  String get downloadExtensionSubtitle =>
      'L\'estensione è richiesta per accedere ai lettori USB CCID in questo browser.';

  @override
  String get cardUnsupported => 'Scheda non supportata';

  @override
  String get cardUnsupportedSubtitle =>
      'Questa scheda probabilmente non è una eUICC, o non è supportata da questo lettore, o è già in uso.';

  @override
  String get omapiWelcome =>
      'Una buona notizia — il tuo dispositivo supporta OMAPI ed è molto probabilmente compatibile con le schede rimovibili!';

  @override
  String get supportedDevices => 'Dispositivi supportati';

  @override
  String get aboutAram => 'Informazioni su ARA-M';

  @override
  String get accessDenied => 'Accesso negato';

  @override
  String get accessDeniedSubtitle =>
      'I privilegi dell\'operatore sono richiesti per accedere a questa eUICC. La lista ARA-M consentite della scheda non corrisponde alla firma dell\'app.';

  @override
  String get noCardDetectedSubtitle =>
      'Nessuna eUICC supportata o attiva in questo slot.';

  @override
  String get noProfilesInstalled => 'Nessun profilo installato';

  @override
  String get noProfilesInstalledSubtitle => 'Questa scheda eUICC è vuota.';

  @override
  String get cardRefreshingTitle => 'Aggiornamento della carta in corso';

  @override
  String get cardRefreshingMessage =>
      'La carta sta aggiornando il proprio stato. Al momento non è possibile recuperare l\'elenco dei profili. Attendi qualche secondo e riprova.';

  @override
  String get useRemoteIcon => 'Usa icona remota';

  @override
  String get bleDisconnectedTitle => 'Connessione Bluetooth persa';

  @override
  String get bleDisconnectedMessage =>
      'La connessione al lettore di carte è stata persa improvvisamente. Assicurati che sia nelle vicinanze e acceso.';

  @override
  String get cardStuckRefreshingMessage =>
      'Cambio di stato del profilo in corso: se si blocca, prova a reinserire manualmente la SIM.';

  @override
  String get cardNeedsReplugTitle => 'Reinserisci la SIM';

  @override
  String get cardNeedsReplugMessage =>
      'La carta non rilascia la sua applet eUICC, quindi non può essere gestita in questo momento. Rimuovi la SIM, reinseriscila e riprova.';

  @override
  String get activationCodeTitle => 'Codice di attivazione';

  @override
  String get activationCodeSubtitle =>
      'Scansiona un codice QR, trascina un\'immagine o inserisci manualmente la stringa LPA.';

  @override
  String get fullActivationCodeLabel => 'Codice di attivazione completo';

  @override
  String get fullActivationCodeHint => 'LPA:1\$smdp.io\$MATCHING-ID';

  @override
  String get pasteFromClipboardTooltip => 'Incolla dagli appunti';

  @override
  String get selectFromGalleryTooltip => 'Seleziona dalla galleria';

  @override
  String get scanQrCodeTooltip => 'Scansiona codice QR';

  @override
  String get smdpAddressLabel => 'Indirizzo SM-DP+';

  @override
  String get smdpAddressHint => 'smdp.io';

  @override
  String get matchingIdLabel => 'ID corrispondenza';

  @override
  String get matchingIdHint => 'ABC-123';

  @override
  String get smdpOidLabel => 'OID SM-DP+';

  @override
  String get confirmationCodeLabel => 'Codice di conferma';

  @override
  String get confirmationCodeHint => 'Inserisci codice di conferma';

  @override
  String get continueButton => 'Continua';

  @override
  String get invalidLpaClipboard =>
      'Non è stata trovata una stringa LPA valida dagli appunti.';

  @override
  String get invalidFqdnFormat => 'Formato FQDN non valido';

  @override
  String get invalidMatchingIdChars =>
      'Caratteri non validi nell\'ID corrispondenza';

  @override
  String get invalidOidFormat => 'Formato OID non valido (es. 1.2.840...)';

  @override
  String get activationCodeRequired => 'Il codice di attivazione è richiesto';

  @override
  String get invalidLpaFormatGeneric => 'Formato LPA non valido';

  @override
  String get smdpAddressRequired => 'L\'indirizzo SM-DP+ è richiesto';

  @override
  String get loadingNotifications => 'Caricamento notifiche...';

  @override
  String get vowifi => 'VoWiFi';

  @override
  String get vowifiSubtitle =>
      'Sperimentale; richiede un lettore esterno compatibile';

  @override
  String get vowifiDisclaimerTitle => 'Abilitare il VoWiFi sperimentale?';

  @override
  String get vowifiDisclaimerBody =>
      'Il VoWiFi è sperimentale. Comunica direttamente con il tuo operatore di rete mobile e funziona solo con un lettore SIM/eSIM esterno compatibile che supporti le APDU grezze. La compatibilità con operatori e lettori può variare.';

  @override
  String get processing => 'Elaborazione...';

  @override
  String get analyzingImage => 'Analisi immagine...';

  @override
  String get noQrFoundInImage => 'Nessun codice QR trovato nell\'immagine';

  @override
  String get invalidAcInImage =>
      'Il codice di attivazione trovato nell\'immagine non è valido.';

  @override
  String get invalidAcFormatDetailed =>
      'Formato codice di attivazione non è valido. Deve iniziare con LPA:1\$...';

  @override
  String get downloadProfileTitle => 'Scarica profilo';

  @override
  String get connectingToEuicc => 'Connessione all\'eUICC...';

  @override
  String get gettingChallenge => 'Recupero challenge eUICC...';

  @override
  String get authenticatingWithSmdp => 'Autenticazione con SM-DP+...';

  @override
  String get verifyingSignatures => 'Verifica firme SM-DP+...';

  @override
  String get retrievingMetadata => 'Recupero metadati profilo...';

  @override
  String get preparingDownload => 'Preparazione download...';

  @override
  String get preparingEuicc => 'Preparazione eUICC...';

  @override
  String get fetchingProfilePackage => 'Recupero pacchetto profilo...';

  @override
  String installing(Object sent, Object total) {
    return 'Installazione ($sent / $total byte)...';
  }

  @override
  String get finalizing =>
      'Finalizzazione (Aggiornamento informazioni memoria)...';

  @override
  String get profileInstalledSuccessfully => 'Profilo installato con successo!';

  @override
  String get provider => 'Operatore';

  @override
  String get iccid => 'ICCID';

  @override
  String get plmn => 'PLMN';

  @override
  String get storage => 'Spazio totale';

  @override
  String get free => 'Spazio disponibile';

  @override
  String get nvram => 'NVRAM';

  @override
  String get exportCertificates => 'Esporta certificati';

  @override
  String get euiccCert => 'Cert. eUICC';

  @override
  String get eumCert => 'Cert. EUM';

  @override
  String get enterConfirmationCode =>
      'Inserisci il codice richiesto dal tuo operatore';

  @override
  String get confirmationCodeRequired => 'Il codice di conferma è richiesto';

  @override
  String get download => 'Scarica';

  @override
  String get installationSuccessful => 'Installazione riuscita';

  @override
  String get installationSuccessMessage =>
      'Il profilo è stato installato con successo sulla tua eUICC.';

  @override
  String get consumed => 'Consumati';

  @override
  String get enableProfileNow => 'Abilita profilo scaricato';

  @override
  String get done => 'Fatto';

  @override
  String get profileEnabledSuccessfully => 'Profilo abilitato con successo';

  @override
  String get enterNewProfileName =>
      'Inserisci un nome profilo per questo profilo per aiutarti a identificarlo più facilmente.';

  @override
  String get profileName => 'Nome profilo';

  @override
  String get profileNameHint => 'es. Viaggio Lavoro';

  @override
  String get profileRenamedSuccessfully =>
      'Il profilo è stato modificato con successo';

  @override
  String get downloadFailed => 'Download fallito';

  @override
  String get tryAgain => 'Riprova';

  @override
  String get savedSuccessfully => 'Salvato con successo';

  @override
  String get saveCertificate => 'Salva Certificato';

  @override
  String get searchingForReaders => 'Ricerca lettori...';

  @override
  String get initializationError => 'Errore di inizializzazione';

  @override
  String get noReadersFound => 'Nessun lettore trovato';

  @override
  String get noReadersFoundMessage =>
      'Inserisci un lettore compatibile o scansiona dispositivi BLE per gestire i tuoi profili eSIM.';

  @override
  String get scanBle => 'Scansione BLE';

  @override
  String get reminderDetails => 'Dettagli Promemoria';

  @override
  String get profileNotFound => 'Profilo non trovato';

  @override
  String get resending => 'Reinvio...';

  @override
  String get noAddressInNotification => 'Nessun indirizzo nei dati notifica';

  @override
  String get sentSuccessfully => 'Inviato con successo';

  @override
  String get sendFailed => 'Invio fallito';

  @override
  String get copiedCurl => 'Comando cURL copiato negli appunti';

  @override
  String get noAddressToExport => 'Nessun indirizzo da esportare';

  @override
  String get noHistoryAvailable => 'Nessuna cronologia disponibile';

  @override
  String get searchByIccid => 'Cerca per ICCID...';

  @override
  String get resendNotification => 'Reinvia notifica';

  @override
  String get exportAsCurl => 'Esporta come cURL';

  @override
  String get viewDetails => 'Visualizza dettagli';

  @override
  String get deleteEntry => 'Elimina voce';

  @override
  String activeReminders(int count) {
    return '$count promemoria attivi';
  }

  @override
  String get noScheduledReminders => 'Nessun promemoria pianificato';

  @override
  String get remindersAppearWhen =>
      'I promemoria appaiono quando aggiungi tag data ai profili.';

  @override
  String activeTagsCount(int count) {
    return '$count tag attivi su tutti i profili';
  }

  @override
  String get searchTagsOrProfiles => 'Cerca tag o profili...';

  @override
  String get noTagsFound => 'Nessun tag trovato';

  @override
  String get addTagsFromProfileMenu =>
      'Aggiungi tag ai tuoi profili dal menu di modifica profilo per vederli qui.';

  @override
  String get expired => 'Scaduto';

  @override
  String daysLeft(int count) {
    return '$count gg rimasti';
  }

  @override
  String hoursLeft(int count) {
    return '$count ore rimaste';
  }

  @override
  String get expiresSoon => 'Scade a breve';

  @override
  String get soon => 'presto';

  @override
  String get activeTags => 'Tag attivi';

  @override
  String get addNewTag => 'Aggiungi nuovo Tag';

  @override
  String get noTagsAssigned => 'Nessun tag assegnato a questo profilo';

  @override
  String get textTagHint => 'Tag di testo (es. Lavoro, Viaggi)';

  @override
  String get addDateExpiryTag => 'Aggiungi Tag data/scadenza';

  @override
  String get addNoteOptional => 'Aggiungi nota (Opzionale)';

  @override
  String get add => 'Aggiungi';

  @override
  String get noteHint => 'es. Scadenza, 10GB, ecc.';

  @override
  String get invalidHexString => 'Stringa Esadecimale non valida';

  @override
  String get resetToDefaults => 'Ripristina predefiniti';

  @override
  String get resetToDefaultsSuccess => 'Ripristinato ai valori predefiniti';

  @override
  String get addAidHex => 'Aggiungi AID (Hex)';

  @override
  String get manageAutoNotif => 'Gestisci elaborazione automatica notifiche';

  @override
  String get automaticProcessing => 'ELABORAZIONE AUTOMATICA';

  @override
  String get notifProcessingInfo =>
      'L\'elaborazione delle notifiche aiuta la sincronizzazione tra la tua eUICC e il server SM-DP+ (operatore). Rimuovere le notifiche inviate mantiene pulita la memoria della scheda.';

  @override
  String get enabling => 'Abilitazione';

  @override
  String get afterEnabling => 'Dopo abilitazione profilo';

  @override
  String get disabling => 'Disabilitazione';

  @override
  String get afterDisabling => 'Dopo disabilitazione profilo';

  @override
  String get installation => 'Installazione';

  @override
  String get afterDownload => 'Dopo aver scaricato il profilo';

  @override
  String get deletion => 'Eliminazione';

  @override
  String get afterDeletion => 'Dopo eliminazione profilo';

  @override
  String get autoSend => 'Invio Automatico';

  @override
  String get autoSendSubtitle => 'Invia al server automaticamente';

  @override
  String get autoRemove => 'Rimozione Automatica';

  @override
  String get autoRemoveSubtitle => 'Elimina dalla scheda dopo l\'invio';

  @override
  String get removeWithoutSending => 'Rimuovi senza inviare';

  @override
  String get removeWithoutSendingSubtitle =>
      'Usare con cautela: il server non sarà notificato';

  @override
  String get permissionsActive => 'Permessi attivi';

  @override
  String get permissionsRequired => 'Permessi richiesti';

  @override
  String get appCanSendNotif => 'L\'app può inviare notifiche di sistema';

  @override
  String get requiredForReminders => 'Richiesto per gli avvisi promemoria';

  @override
  String get unsupportedPlatformCheck =>
      'Il controllo dei permessi non è supportato su questa piattaforma. Eseguire test manuali.';

  @override
  String get couldNotVerifyStatus =>
      'Impossibile verificare lo stato. Controllare le impostazioni manualmente.';

  @override
  String get testNotificationTitle => 'Notifica di test';

  @override
  String get seconds => 'secondi';

  @override
  String get startTest => 'Inizia test';

  @override
  String get sendingNotif => 'Invio...';

  @override
  String get hostIpLabel => 'Nome host / IP';

  @override
  String get portLabel => 'Porta';

  @override
  String get passwordOptionalLabel => 'Password (Opzionale)';

  @override
  String get configuredServers => 'Server configurati';

  @override
  String get secureHttps => 'Sicuro (HTTPS)';

  @override
  String get insecureHttp => 'Non sicuro (HTTP)';

  @override
  String get urlCopied => 'URL copiato';

  @override
  String get serverAddedSuccessfully => 'Server aggiunto con successo';

  @override
  String get authFailedCheckPassword =>
      'Autenticazione fallita. Controlla la password.';

  @override
  String get addNewServer => 'Aggiungi nuovo server';

  @override
  String get autoLoadRemotes => 'Caricamento automatico dispositivi remoti';

  @override
  String get autoLoadRemotesSubtitle =>
      'Connettiti automaticamente verso i server all\'avvio dell\'app';

  @override
  String get getRemoCardGitHub => 'Ottieni RemoCard da GitHub';

  @override
  String get instructions => 'Istruzioni:';

  @override
  String get instruction1 =>
      '1. Installa l\'app RemoCard sui tuoi dispositivi Android.';

  @override
  String get instruction2 => '2. Avvia il server in ogni app RemoCard.';

  @override
  String get instruction3 => '3. Inserisci gli indirizzi IP qui.';

  @override
  String get instruction4 =>
      '4. Tutti gli slot SIM remoti appariranno nella lista dispositivi.';

  @override
  String get appLogsCopied => 'Log copiati negli appunti';

  @override
  String get aramInfoTitle => 'Informazioni ARA-M';

  @override
  String get aramInfoSubtitle => 'Dettagli Access Rule Applet';

  @override
  String get whatIsAram => 'Cos\'è ARA-M?';

  @override
  String get aramDescription =>
      'Access Rule Applet (ARA-M) è un meccanismo su eUICC (eSIM) e schede SIM che definisce quali applicazioni sono autorizzate a gestire i profili o eseguire operazioni di basso livello. Se l\'hash dell\'app non è presente nella lista ARA-M consentita della scheda, il sistema Android bloccherà l\'accesso, restituendo un errore \'Accesso Negato\'.';

  @override
  String get appCertHashes => 'Hash Certificati App';

  @override
  String get aramHashInstruction =>
      'Per concedere l\'accesso a questa app, potrebbe essere necessario aggiungere il seguente hash certificato SHA-1 alle regole ARA-M della tua scheda. Questo hash è unico per il certificato della tua build attuale dell\'app.';

  @override
  String get aramSigningHistoryInstruction =>
      'Per garantire la compatibilità tra le versioni di Android, aggiungi tutti gli hash dei certificati SHA-1 riportati di seguito alle regole ARA-M della tua carta. Dopo un cambio della chiave di firma, versioni diverse di Android potrebbero verificare certificati diversi presi dalla cronologia di firma verificata.';

  @override
  String get certSha1Hash => 'Hash Certificato SHA-1';

  @override
  String get unavailable => 'Non disponibile';

  @override
  String get troubleshooting => 'Risoluzione problemi';

  @override
  String get troubleStep1 =>
      'Assicurati di utilizzare il Lettore di Schede corretto.';

  @override
  String get troubleStep2 =>
      'Se usi una scheda fisica, controlla se è una scheda di test o una scheda di produzione (le schede di produzione spesso bloccano ARA-M).';

  @override
  String get troubleStep3 =>
      'Gli hash sopra dipendono dal fatto che tu usi la versione Debug, Regolare o Privilegiata (Magisk) dell\'app.';

  @override
  String get troubleStep4 =>
      'Considera l\'uso della build Privilegiata (Magisk) che può bypassare alcune restrizioni API di Android.';

  @override
  String get hashCopied => 'Hash copiato negli appunti';

  @override
  String get aidCopied => 'AID copiato negli appunti';

  @override
  String get lastSeen => 'Ultima attività';

  @override
  String get unknownProvider => 'Operatore sconosciuto';

  @override
  String get unknownProfile => 'Profilo sconosciuto';

  @override
  String get tags => 'Tag';

  @override
  String get noTags => 'Nessun Tag';

  @override
  String records(int count) {
    return '$count record';
  }

  @override
  String get bytes => 'byte';

  @override
  String get responseCode => 'Codice risposta';

  @override
  String get responseBody => 'Corpo risposta';

  @override
  String get type => 'Tipo';

  @override
  String profileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count profili',
      one: '1 profilo',
    );
    return '$_temp0';
  }

  @override
  String get isdrAids => 'AID ISD-R';

  @override
  String get configureDefaultAids => 'Configura Application ID predefiniti';

  @override
  String get addAidHexHint => 'Aggiungi AID (Hex)';

  @override
  String get notificationProcessing => 'Notifiche';

  @override
  String get manageAutoNotification =>
      'Gestisci elaborazione automatica notifiche';

  @override
  String get notificationProcessingHelp =>
      'L\'elaborazione delle notifiche aiuta la sincronizzazione tra la tua eUICC e il server SM-DP+ (operatore). Rimuovere le notifiche inviate mantiene pulita la memoria della scheda.';

  @override
  String get notificationProcessingTimings => 'Momenti di elaborazione';

  @override
  String get notificationProcessingTimingsHelp =>
      'Scegli quando viene eseguita l\'elaborazione automatica delle notifiche. Alcuni momenti critici per la sicurezza possono essere disattivati solo con la Modalità sviluppatore attiva.';

  @override
  String get afterEnablingProfile => 'Dopo abilitazione profilo';

  @override
  String get afterDisablingProfile => 'Dopo disabilitazione profilo';

  @override
  String get afterProfileDownload => 'Dopo aver scaricato il profilo';

  @override
  String get afterProfileDeletion => 'Dopo eliminazione profilo';

  @override
  String get initialLoad => 'Caricamento iniziale';

  @override
  String get processNotificationsOnInitialLoad =>
      'Elabora le notifiche al termine del caricamento dei profili';

  @override
  String get afterSwitchingProfile => 'Dopo il cambio di profilo';

  @override
  String get processNotificationsAfterSwitchingProfile =>
      'Elabora le notifiche dopo aver abilitato o disabilitato un profilo';

  @override
  String get beforeProfileDownload => 'Prima del download del profilo';

  @override
  String get processNotificationsBeforeProfileDownload =>
      'Elabora le notifiche prima di avviare il download di un profilo';

  @override
  String get afterProfileInstalled => 'Dopo l\'installazione del profilo';

  @override
  String get processNotificationsAfterProfileInstalled =>
      'Elabora le notifiche dopo l\'installazione di un profilo';

  @override
  String get processNotificationsAfterProfileDeletion =>
      'Elabora le notifiche dopo l\'eliminazione di un profilo';

  @override
  String get developerModeRequiredToDisableTiming =>
      'Abilita la Modalità sviluppatore per disattivare questo momento.';

  @override
  String get sendToServerAutomatically => 'Invia al server automaticamente';

  @override
  String get removeFromCardAfterSending => 'Elimina dalla scheda dopo l\'invio';

  @override
  String get removeWithoutSendingCaution =>
      'Usare con cautela: il server non sarà notificato';

  @override
  String get reminderSettings => 'Impostazioni promemoria';

  @override
  String get appCanSendNotifications =>
      'L\'app può inviare notifiche di sistema';

  @override
  String get requiredForReminderAlerts => 'Richiesto per gli avvisi promemoria';

  @override
  String get enable => 'Abilita';

  @override
  String get permissionCheckNotSupported =>
      'Il controllo dei permessi non è supportato su questa piattaforma. Eseguire il test manualmente.';

  @override
  String get testNotification => 'Notifica di test';

  @override
  String get notificationsDisabledMessage =>
      'Le notifiche sono disabilitate. Abilitale nelle impostazioni di sistema per ricevere promemoria.';

  @override
  String get openSettings => 'Apri impostazioni';

  @override
  String get applicationLogs => 'Log applicazione';

  @override
  String get refreshReload => 'Aggiorna/Ricarica';

  @override
  String get toggleAutoScroll => 'Attiva/Disattiva scorrimento automatico';

  @override
  String get refreshDevices => 'Aggiorna dispositivi';

  @override
  String get scanBluetooth => 'Scansione Bluetooth';

  @override
  String get lessThan1Kb => '< 1 KB';

  @override
  String get connectionFailed => 'Connessione fallita';

  @override
  String get downloadRemoCard => 'Scarica RemoCard';

  @override
  String get remoCardAndroidApp => 'App Android per Controller Remoti';

  @override
  String get resentSuccessfully => 'Reinviato con successo';

  @override
  String get resendFailed => 'Reinvio fallito';

  @override
  String get eid => 'EID';

  @override
  String get seq => 'Seq';

  @override
  String get date => 'Data';

  @override
  String errorWithDetails(String error) {
    return 'Errore: $error';
  }

  @override
  String exportFailed(String error) {
    return 'Esportazione fallita: $error';
  }

  @override
  String get sasAccreditation => 'Accreditamento SAS';

  @override
  String get firmwareVersion => 'Versione Firmware';

  @override
  String get beeSimFirmwareAction => 'Aggiorna il firmware BeeSIM';

  @override
  String get beeSimFirmwareTitle => 'Aggiornamento firmware BeeSIM';

  @override
  String get beeSimFirmwareWarning =>
      'È disponibile un aggiornamento del firmware BeeSIM. Mantieni la carta alimentata, il Bluetooth connesso e l\'app aperta fino al termine. Interrompere l\'aggiornamento potrebbe rendere la carta temporaneamente inutilizzabile.';

  @override
  String get beeSimFirmwareConfirm => 'Aggiorna firmware';

  @override
  String get platformSupport => 'SUPPORTO PIATTAFORMA';

  @override
  String get rspVersion => 'Versione RSP';

  @override
  String get bppVersion => 'Versione BPP';

  @override
  String get gpVersion => 'Versione GlobalPlatform';

  @override
  String get certInfrastructure => 'INFRASTRUTTURA CERTIFICATI';

  @override
  String get configuredAddresses => 'INDIRIZZI CONFIGURATI';

  @override
  String get defaultSmdpAddress => 'SM-DP+ predefinito';

  @override
  String get rootDsAddress => 'SM-DS radice';

  @override
  String get euiccSignCi => 'CI di firma eUICC';

  @override
  String get euiccVerifyCi => 'CI di verifica eUICC';

  @override
  String get none => 'Nessuno';

  @override
  String keysCount(int count) {
    return '$count chiavi';
  }

  @override
  String get state => 'Stato';

  @override
  String get profileClass => 'Classe';

  @override
  String get aid => 'AID';

  @override
  String get euiccSpecifications => 'SPECIFICHE EUICC';

  @override
  String get sending => 'Invio...';

  @override
  String get failedToSaveTags => 'Salvataggio Tag fallito';

  @override
  String get note => 'Nota';

  @override
  String get notificationDetails => 'Dettagli notifica';

  @override
  String get unknown => 'Sconosciuto';

  @override
  String get status => 'Stato';

  @override
  String get sent => 'Inviato';

  @override
  String get pending => 'In attesa';

  @override
  String get notifTypeInstall => 'Installazione';

  @override
  String get notifTypeDelete => 'Eliminazione';

  @override
  String get notifTypeEnable => 'Abilitazione';

  @override
  String get notifTypeDisable => 'Disabilitazione';

  @override
  String get notifTypeRpmEnable => 'Abilitazione RPM';

  @override
  String get notifTypeRpmDisable => 'Disabilitazione RPM';

  @override
  String get notifTypeRpmDelete => 'Eliminazione RPM';

  @override
  String get notifTypeLoadRpm => 'Caricamento RPM';

  @override
  String confirmDeleteNotification(int seq) {
    return 'Sei sicuro di voler eliminare la notifica #$seq?';
  }

  @override
  String get notificationRemoved => 'Notifica rimossa';

  @override
  String failedToRemove(String error) {
    return 'Rimozione fallita: $error';
  }

  @override
  String get curlCopied => 'Comando cURL estratto negli appunti';

  @override
  String failedToGenerateCurl(String error) {
    return 'Generazione cURL fallita: $error';
  }

  @override
  String get noNotificationAddress => 'Nessun indirizzo notifica disponibile';

  @override
  String get sendingNotification => 'Invio notifica...';

  @override
  String get notifSentSuccessfully => 'Notifica inviata con successo';

  @override
  String get failedToSendNotification => 'Invio notifica fallito';

  @override
  String errorSendingNotification(String error) {
    return 'Errore durante l\'invio della notifica: $error';
  }

  @override
  String pendingCount(int count) {
    return '$count in attesa';
  }

  @override
  String get currentReader => 'Lettore attuale';

  @override
  String get errorLoadingNotifications => 'Errore caricamento notifiche';

  @override
  String get allCaughtUp => 'Non hai niente in sospeso';

  @override
  String get sequence => 'Sequenza';

  @override
  String get operation => 'Operazione';

  @override
  String get profileNameLabel => 'Nome profilo';

  @override
  String get failedToSend => 'Invio fallito';

  @override
  String get onCard => 'nella scheda';

  @override
  String get sendNotification => 'Invia notifica';

  @override
  String get deleteNotification => 'Elimina notifica';

  @override
  String get noNotifications => 'Nessuna notifica';

  @override
  String get batchDownloadTitle => 'Download multiplo';

  @override
  String get batchDownloadHint =>
      'Incolla qui più codici LPA (uno per riga, max 20)';

  @override
  String foundLpaCodes(int count) {
    return '$count codici LPA trovati';
  }

  @override
  String get startBatch => 'Avvia batch';

  @override
  String get noLpaCodesFound => 'Nessun codice LPA valido trovato';

  @override
  String get insufficientSpaceStoppingBatch =>
      'Spazio insufficiente. Interruzione del download batch.';

  @override
  String get exportCsv => 'Esporta in CSV';

  @override
  String get exportedSuccessfully => 'Esportato con successo';

  @override
  String get exportResults => 'Esporta risultati';

  @override
  String get lpa => 'LPA';

  @override
  String get smdp => 'SM-DP+';

  @override
  String get confirmationCode => 'Codice di conferma';

  @override
  String get size => 'Dimensione';

  @override
  String get message => 'Messaggio';

  @override
  String get remainingSpace => 'Spazio rimanente';

  @override
  String get stopBatch => 'Interrompi il lotto';

  @override
  String get stopping => 'Interruzione...';

  @override
  String get remove => 'Rimuovi';

  @override
  String get updateAvailable => 'Aggiornamento disponibile';

  @override
  String updateAvailableSubtitle(String appName, String version, String build) {
    return 'È disponibile una nuova versione di $appName (v$version b$build). Vuoi aggiornare ora?';
  }

  @override
  String get updateAction => 'Aggiorna';

  @override
  String get later => 'Più tardi';

  @override
  String get changelog => 'Registro delle modifiche';

  @override
  String get sortBy => 'Ordina per';

  @override
  String get sortIccid => 'ICCID';

  @override
  String get sortCountry => 'Paese';

  @override
  String get sortAscending => 'Crescente';

  @override
  String get sortDescending => 'Decrescente';

  @override
  String get searchProfiles => 'Cerca profili...';

  @override
  String get noProfilesMatch => 'Nessun profilo corrisponde alla tua ricerca.';

  @override
  String get sortDefault => 'Predefinito';

  @override
  String get sortNickname => 'Nome profilo';

  @override
  String get showProfileSearch => 'Mostra la ricerca dei profili';

  @override
  String get showProfileSearchSubtitle =>
      'Mostra la barra di ricerca e ordinamento nell\'elenco dei profili';

  @override
  String get noReaderFound =>
      'Nessun lettore trovato. Collega il tuo adattatore eUICC.';

  @override
  String get readyToInstallProfile => 'Pronto per installare il profilo.';

  @override
  String get downloadHere => 'Scarica qui';

  @override
  String get manage => 'Gestisci';

  @override
  String get buyCard => 'Acquista adattatore eUICC';

  @override
  String get buyData => 'Acquista piano dati';

  @override
  String get selectDevice => 'Seleziona dispositivo';

  @override
  String get selectReaderTitle => 'Seleziona carta';

  @override
  String get authorizeSigning => 'Autorizza la firma';

  @override
  String get signingDescription =>
      'Un sito web sta richiedendo una firma sicura alla tua eUICC.';

  @override
  String get smdpAddress => 'Indirizzo SM-DP+';

  @override
  String get sign => 'Firma';

  @override
  String profilesInstalled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count profili installati',
      one: '1 profilo installato',
    );
    return '$_temp0';
  }

  @override
  String get estimatedDownloadSize => 'Dimensione di download stimata';

  @override
  String get phoneFormatInternationalOnly => 'Solo E.164 int.';

  @override
  String get phoneFormatInternationalAndMobile => 'Int. e mobile';

  @override
  String get phoneFormatInternationalAndAll => 'Int. e nazionale';

  @override
  String get phoneFormatOff => 'Disattivato';

  @override
  String get settings_item_unit_b => 'Byte';

  @override
  String get settings_item_unit_kb => 'kB (1.000 byte)';

  @override
  String get settings_item_unit_kib => 'kiB (1.024 byte)';

  @override
  String get settings_item_unit_adaptive_si => 'B / kB adattivo';

  @override
  String get settings_item_unit_adaptive_bi => 'B / kiB adattivo';

  @override
  String get insufficientStorageWarning =>
      'Spazio di archiviazione insufficiente per l\'installazione. L\'installazione potrebbe fallire.';

  @override
  String get estimateProfileSize => 'Stima la dimensione del profilo';

  @override
  String get estimateProfileSizeSubtitle =>
      'Stima la dimensione dei metadati del profilo prima del download';

  @override
  String get customize => 'Personalizza';

  @override
  String get customizeDescription =>
      'Specifica un nuovo nome esadecimale di 6 caratteri e una password per il tuo lettore.';

  @override
  String get customizeSuccess =>
      'Lettore personalizzato. Riassocia il dispositivo.';

  @override
  String customizeFailed(String error) {
    return 'Impossibile personalizzare il lettore: $error';
  }

  @override
  String get defaultPasswordWillChangeTitle =>
      'La password predefinita cambierà';

  @override
  String defaultPasswordWillChangeMessage(String password) {
    return 'Questo dispositivo è connesso con la sua password predefinita. Rinominandolo, la password diventerà $password. Salva questa password prima di riconnetterti.';
  }

  @override
  String get savedBleDevices => 'Dispositivi BLE connessi in precedenza';

  @override
  String get savedBleDevicesSubtitle =>
      'Visualizza i nomi e le password dei dispositivi salvati su questo dispositivo';

  @override
  String get savedBleDevicesDescription =>
      'Ogni voce è una password NBLESim salvata localmente. Vengono salvate anche le password predefinite.';

  @override
  String get noSavedBleDevices =>
      'Nessun dispositivo BLE connesso in precedenza.';

  @override
  String get deviceName => 'Nome dispositivo';

  @override
  String get success => 'Operazione riuscita';

  @override
  String get devicePasswordHint => '6 caratteri esadecimali o una password';

  @override
  String get sixHexChars => '6 caratteri esadecimali';

  @override
  String get database => 'Database';

  @override
  String exportSuccess(String path) {
    return 'Database esportato in $path';
  }

  @override
  String get importDatabase => 'Importa database';

  @override
  String get importDatabaseSubtitle =>
      'Unisci le righe da un altro file di database';

  @override
  String get importDatabaseDialogTitle =>
      'Seleziona il file di database da importare';

  @override
  String get importDatabaseTitle => 'Importa database';

  @override
  String get importDatabaseContent =>
      'Le righe del database selezionato verranno unite al tuo database attuale. Le righe esistenti con le stesse chiavi verranno sovrascritte. Vuoi continuare?';

  @override
  String get import => 'Importa';

  @override
  String get importSuccess => 'Database importato correttamente';

  @override
  String importFailed(String error) {
    return 'Impossibile importare il database: $error';
  }

  @override
  String get resetDatabase => 'Reimposta il database';

  @override
  String get resetDatabaseSubtitle =>
      'Cancella tutti i dati dell\'applicazione e riavvia';

  @override
  String get resetDatabaseTitle => 'Reimposta il database dell\'applicazione';

  @override
  String get resetDatabaseContent =>
      'Questa operazione eliminerà completamente tutti i dati, le configurazioni e i registri memorizzati localmente. L\'applicazione verrà chiusa. Vuoi procedere?';

  @override
  String get deleteDatabase => 'Elimina il database';

  @override
  String resetFailed(String error) {
    return 'Impossibile reimpostare il database: $error';
  }

  @override
  String get deviceImei => 'TAC del dispositivo';

  @override
  String get deviceImeiSubtitle => 'Usato per i download dei profili';

  @override
  String get editDeviceImei => 'Modifica il TAC del dispositivo';

  @override
  String get editDeviceImeiInfo =>
      'Inserisci un TAC di 8 cifre o un IMEI di 15 cifre. TAC predefinito: 35383741.';

  @override
  String get imeiDigits => 'Cifre del TAC o dell\'IMEI';

  @override
  String get importAction => 'Importa';

  @override
  String get transferTitle => 'Trasferisci eSIM';

  @override
  String get transferAction => 'Trasferisci su questo dispositivo';

  @override
  String get transferCheckingEligibility => 'Verifica dell\'idoneità…';

  @override
  String get transferReadingSource => 'Lettura della SIM di origine…';

  @override
  String get transferContactingCarrier => 'Contatto con l\'operatore…';

  @override
  String get transferIneligibleReader =>
      'Questo profilo non può essere trasferito con questo lettore. L\'autenticazione della SIM di origine (EAP-AKA) non è raggiungibile qui.';

  @override
  String get transferNoEntitlement =>
      'Non è stata trovata alcuna configurazione di trasferimento dell\'operatore per questo profilo. Puoi inserire manualmente il server entitlement.';

  @override
  String transferSourceCarrier(String carrier) {
    return 'Operatore di origine: $carrier';
  }

  @override
  String get transferConfirmTitle => 'Trasferire questo abbonamento?';

  @override
  String get transferConfirmBody =>
      'L\'operatore riemetterà questo abbonamento su questa eUICC. Il profilo di origine potrebbe essere eliminato come parte del trasferimento.';

  @override
  String get transferStart => 'Avvia il trasferimento';

  @override
  String get transferDownloadingProfile => 'Download del profilo trasferito…';

  @override
  String get transferDeleteSourceTitle => 'Elimina il profilo di origine';

  @override
  String transferDeleteSourceBody(String iccid) {
    return 'L\'operatore richiede l\'eliminazione del profilo di origine $iccid prima dell\'attivazione. Vuoi eliminarlo ora?';
  }

  @override
  String get transferDeleteSourceConfirm => 'Elimina e continua';

  @override
  String get transferUserInputSubmit => 'Invia';

  @override
  String get transferAccept => 'Accetta';

  @override
  String get transferReject => 'Rifiuta';

  @override
  String get transferPendingActivation =>
      'L\'operatore sta ancora attivando questo abbonamento. Terminerà a breve; puoi chiudere questa finestra e ricontrollare più tardi.';

  @override
  String get transferDismissed => 'L\'operatore ha rifiutato il trasferimento.';

  @override
  String get transferDelayedDownload =>
      'L\'operatore consegnerà il profilo a breve. Una volta installato, inserisci l\'ICCID installato per completare.';

  @override
  String get transferInstalledIccid => 'ICCID installato';

  @override
  String get transferSuccess => 'Trasferimento completato';

  @override
  String transferFailed(String error) {
    return 'Trasferimento non riuscito: $error';
  }

  @override
  String get transferManualServerTitle => 'Server entitlement (avanzato)';

  @override
  String get transferManualServerHint => 'https://entitlement.example.com';

  @override
  String get transferEnablingSource => 'Preparazione del profilo di origine…';

  @override
  String get transferClose => 'Chiudi';

  @override
  String get transferContinue => 'Continua';

  @override
  String get transferSmdsDiscovering => 'Ricerca dei profili tramite SM-DS…';

  @override
  String get transferSmdsNoProfiles =>
      'Nessun profilo in sospeso trovato tramite la ricerca SM-DS.';

  @override
  String get transferSelectProfile => 'Seleziona un profilo da scaricare';

  @override
  String get discoverProfiles => 'Cerca profili (SM-DS)';

  @override
  String get discoveringProfiles => 'Ricerca dei profili…';

  @override
  String get discoveryNoProfiles =>
      'Nessun profilo in sospeso trovato tramite la ricerca SM-DS.';

  @override
  String get transferSmdsServerTitle => 'Server SM-DS';

  @override
  String transferProfileOnServer(String eventId, String address) {
    return '$eventId su $address';
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
