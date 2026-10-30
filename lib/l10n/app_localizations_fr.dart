// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get addBluetoothReader => 'Add Bluetooth reader';

  @override
  String get bluetoothSetupFailed =>
      'Unable to set up the Bluetooth reader. Check that Bluetooth is on and the reader is nearby, then try again.';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get displaySettings => 'Paramètres d\'affichage';

  @override
  String get appearance => 'Apparence';

  @override
  String get appearanceSubtitle =>
      'Personnaliser le thème, la mise en page et les préférences d\'affichage';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get themeStyle => 'Style de thème';

  @override
  String get themeStyleSubtitle => 'Choisir entre le style personnalisé et MD3';

  @override
  String get customDesign => 'Style Nekoko';

  @override
  String get stockMD3 => 'MD3 standard';

  @override
  String get waterfallLayout => 'Disposition en cascade';

  @override
  String get waterfallLayoutSubtitle =>
      'Utiliser le style Masonry sur les écrans larges';

  @override
  String get system => 'Système';

  @override
  String get light => 'Clair';

  @override
  String get dark => 'Sombre';

  @override
  String get language => 'Langue';

  @override
  String get systemLanguage => 'Langue du système';

  @override
  String get general => 'Général';

  @override
  String get ui => 'Interface';

  @override
  String get autoLoadProfiles => 'Charger automatiquement les profils';

  @override
  String get autoLoadProfilesSubtitle =>
      'Charger les profils lors de la sélection du lecteur';

  @override
  String get loadProfileIcons => 'Charger les icônes de profil';

  @override
  String get loadProfileIconsSubtitle =>
      'Récupérer les icônes depuis l\'eUICC (plus lent)';

  @override
  String get useNekokoIcons => 'Utiliser les icônes Nekoko Cloud';

  @override
  String get useNekokoIconsSubtitle =>
      'Récupérer les logos opérateurs depuis Nekoko';

  @override
  String get forceDeviceDropdown => 'Forcer la liste déroulante';

  @override
  String get forceDeviceDropdownSubtitle =>
      'Toujours utiliser une liste pour choisir l\'appareil';

  @override
  String get sizeDisplayUnit => 'Unité d\'affichage de taille';

  @override
  String get sizeDisplayUnitSubtitle => 'Format d\'unité pour le stockage';

  @override
  String get phoneFormat => 'Format de numéro de téléphone';

  @override
  String get phoneFormatSubtitle => 'Format d\'affichage des numéros';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationSettings => 'Paramètres de notification';

  @override
  String get notificationSettingsSubtitle =>
      'Configurer le traitement automatique et la suppression';

  @override
  String get notificationHistory => 'Historique des notifications';

  @override
  String get notificationHistorySubtitle =>
      'Rechercher, gérer et renvoyer les notifications';

  @override
  String get tagsAndReminders => 'Tags et Rappels';

  @override
  String get tagManager => 'Gestionnaire de tags';

  @override
  String get tagManagerSubtitle => 'Créer et modifier des tags de profil';

  @override
  String get tagReminders => 'Rappels de tags';

  @override
  String get tagRemindersSubtitle => 'Notifications basées sur les dates';

  @override
  String get manageTagsAndReminders => 'Gérer les tags et rappels';

  @override
  String get manageTagsAndRemindersSubtitle =>
      'Configurer les tags, permissions et alertes de test';

  @override
  String get viewScheduledReminders => 'Voir les rappels programmés';

  @override
  String get viewScheduledRemindersSubtitle =>
      'Gérer vos notifications à venir';

  @override
  String get connectivity => 'Connectivité';

  @override
  String get remoteReaders => 'Lecteurs distants';

  @override
  String get remoteReadersSubtitle =>
      'Configurer les applications compagnon RemoCard';

  @override
  String get enableBle => 'Connecteur Bluetooth';

  @override
  String get enableBleSubtitle =>
      'Activer le scan et la connexion aux lecteurs Bluetooth';

  @override
  String get enableCcid => 'Connecteur USB CCID';

  @override
  String get enableCcidSubtitle =>
      'Activer les lecteurs de cartes à puce USB (CCID)';

  @override
  String get enableOmapi => 'Connecteur OMAPI';

  @override
  String get enableOmapiSubtitle => 'Activer l\'accès eUICC intégré via OMAPI';

  @override
  String get enableTmapi => 'Connecteur Telephony API';

  @override
  String get enableTmapiSubtitle =>
      'Activer l\'accès privilégié via l\'API Telephony API';

  @override
  String get readerTypes => 'Types de Lecteur';

  @override
  String get readerTypesSubtitle =>
      'Gérer les types de lecteurs activés (CCID, Bluetooth, Distant, etc.)';

  @override
  String get enabledReaderTypes => 'Types de Lecteur Activés';

  @override
  String get enabledReaderTypesSubtitle =>
      'Contrôler quels types de lecteurs sont disponibles dans l\'application';

  @override
  String get remoteReaderSettings => 'Paramètres des Lecteurs Distants';

  @override
  String get remoteReaderSettingsSubtitle =>
      'Configurer les serveurs et connexions de lecteurs distants';

  @override
  String get ccidReaderTitle => 'CCID (USB/PC/SC)';

  @override
  String get ccidReaderSubtitle =>
      'Lecteurs de cartes à puce USB et périphériques PC/SC';

  @override
  String get bluetoothReaderTitle => 'Bluetooth';

  @override
  String get bluetoothReaderSubtitle =>
      'Lecteurs et graveurs de cartes à puce Bluetooth LE';

  @override
  String get remoteReadersTitle => 'Lecteurs Distants';

  @override
  String get remoteReadersConnectorSubtitle =>
      'Lecteurs de cartes à puce distants connectés au réseau';

  @override
  String get omapiReaderTitle => 'OMAPI';

  @override
  String get omapiReaderSubtitle =>
      'Emplacements de carte SIM intégrés via Open Mobile API';

  @override
  String get tmapiReaderTitle => 'Telephony API';

  @override
  String get tmapiReaderSubtitle => 'eSIM intégrée via Telephony API';

  @override
  String get remoteServerConfiguration => 'Configuration du Serveur Distant';

  @override
  String get remoteServerConfigurationSubtitle =>
      'Gérer les serveurs de lecteurs distants et les paramètres de connexion';

  @override
  String get enableBrowser => 'Activer le Navigateur';

  @override
  String get enableBrowserSubtitle =>
      'Afficher des onglets de navigateur supplémentaires comme Boutique, Achat ou Aide';

  @override
  String get transport => 'Transport';

  @override
  String get disableRefreshFlags =>
      'Désactiver les indicateurs de rafraîchissement';

  @override
  String get disableRefreshFlagsSubtitle =>
      'Ne s\'applique pas aux lecteurs externes';

  @override
  String get apduMaxSegmentSize => 'Taille max segment APDU';

  @override
  String get apduMaxSegmentSizeSubtitle =>
      'Taille maximale de données par bloc APDU';

  @override
  String get ensureSingleChannel => 'Garantir un canal unique';

  @override
  String get ensureSingleChannelSubtitle =>
      'Fermer les autres canaux logiques avant d\'en ouvrir un nouveau';

  @override
  String get analytics => 'Analytique et services cloud';

  @override
  String get nekokoCloud => 'Nekoko Cloud';

  @override
  String get nekokoCloudSubtitle => 'Analyser les données d\'installation';

  @override
  String get developer => 'Développeur';

  @override
  String get developerMode => 'Mode développeur';

  @override
  String get developerModeSubtitle =>
      'Activer les fonctionnalités de débogage avancées';

  @override
  String get exportDatabase => 'Exporter la base de données';

  @override
  String get exportDatabaseSubtitle =>
      'Sauvegarder une copie de la base locale';

  @override
  String get openDatabaseFolder => 'Ouvrir le dossier de la base de données';

  @override
  String get openDatabaseFolderSubtitle =>
      'Ouvrir le dossier contenant le fichier DB';

  @override
  String get decodeAsn1 => 'Décoder les logs ASN.1 (Lent)';

  @override
  String get decodeAsn1Subtitle => 'Impacte fortement les performances';

  @override
  String get viewAppLogs => 'Voir les logs de l\'application';

  @override
  String get viewAppLogsSubtitle => 'Voir les journaux collectés';

  @override
  String get about => 'À propos';

  @override
  String get version => 'Version';

  @override
  String get build => 'Build';

  @override
  String get checkUpdates => 'Vérifier les mises à jour';

  @override
  String get checkUpdatesSubtitle =>
      'Vérifier automatiquement les nouvelles versions au démarrage';

  @override
  String get licenses => 'Licences open source';

  @override
  String get licensesSubtitle =>
      'Informations de licence des bibliothèques open source utilisées';

  @override
  String get noUpdatesFound => 'Aucune mise à jour trouvée';

  @override
  String get profilesTitle => 'Profils';

  @override
  String get switchEstkSlot => 'Changer slot eSTK';

  @override
  String get notificationsButton => 'Notifications';

  @override
  String get downloadProfile => 'Télécharger un profil';

  @override
  String get reconnect => 'Reconnecter';

  @override
  String get bluetoothNotConnected => 'Bluetooth Non Connecté';

  @override
  String get bluetoothNotConnectedSubtitle =>
      'Assurez-vous que le Bluetooth est activé et que l\'appareil est à proximité. Appuyez sur connecter pour commencer à utiliser cet appareil.';

  @override
  String get bluetoothConnectionFailed => 'Échec de Connexion Bluetooth';

  @override
  String bluetoothConnectionFailedSubtitle(Object error) {
    return 'Impossible de se connecter à l\'appareil Bluetooth.\n\n$error';
  }

  @override
  String get removeDevice => 'Supprimer l\'appareil';

  @override
  String get retryConnection => 'Se connecter';

  @override
  String get remoteConnectionFailed => 'Échec connexion lecteur distant';

  @override
  String remoteConnectionFailedMessage(Object error) {
    return 'Assurez-vous que le serveur distant fonctionne et est accessible.\n\n$error';
  }

  @override
  String get errorBluetoothTimeout =>
      'Délai d\'attente Bluetooth dépassé. Veuillez réessayer.';

  @override
  String get errorOmapiSecurity =>
      'Erreur de sécurité : l\'accès à la carte a été refusé par le système ou les règles ARA-M.';

  @override
  String get errorApplicationNotFound =>
      'Application de gestion eUICC (ISD-R) introuvable. Cette carte n\'est peut-être pas une eUICC valide.';

  @override
  String get changeSettings => 'Changer les paramètres';

  @override
  String get connectCompatibleReader =>
      'Connectez un lecteur compatible pour commencer.';

  @override
  String get connectReaderMessageBle =>
      'Vous pouvez aussi scanner les appareils Bluetooth si vous avez un eUICC compatible Bluetooth.';

  @override
  String get connectReaderMessageNoBle =>
      'Assurez-vous que votre lecteur CCID est connecté à l\'ordinateur.';

  @override
  String get downloadSmartCardExtension =>
      'Télécharger l\'extension Smart Card';

  @override
  String get smartCardExtensionMessage =>
      'L\'extension est requise pour accéder aux lecteurs USB CCID dans ce navigateur.';

  @override
  String get scanForBluetooth => 'Scanner Bluetooth';

  @override
  String get connectRemote => 'Connexion distante';

  @override
  String get noCardDetected => 'Aucune carte détectée';

  @override
  String get noCardDetectedMessage =>
      'Aucun eUICC supporté ou actif trouvé dans cet emplacement.';

  @override
  String get noDataLoaded => 'Non connecté';

  @override
  String get loadProfiles => 'Connecter';

  @override
  String get disconnect => 'Déconnecter';

  @override
  String get disconnecting => 'Déconnexion...';

  @override
  String get profilesEmpty => 'Aucun profil sur la carte';

  @override
  String get profilesEmptyMessage => 'Cette carte eUICC est vide.';

  @override
  String get renameProfile => 'Renommer le profil';

  @override
  String get nickname => 'Surnom';

  @override
  String get enterProfileNickname => 'Entrer un surnom';

  @override
  String get profileNicknameNote =>
      'Note : Les tags sont gérés séparément via le menu \'Gestionnaire de tags\'.';

  @override
  String get useProfileIcon => 'Utiliser l\'icône du profil';

  @override
  String get useProfileIconSubtitle => 'Icône de la carte eSIM';

  @override
  String get removeCustomIcon => 'Supprimer l\'icône personnalisée';

  @override
  String get noRemoteIcon => 'Pas d\'icône distante pour cet opérateur';

  @override
  String get cancel => 'Annuler';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get refresh => 'Actualiser';

  @override
  String get initializing => 'Initialisation...';

  @override
  String get refreshingProfiles => 'Actualisation des profils...';

  @override
  String get retrievingEid => 'Récupération EID et infos...';

  @override
  String get updatingProfile => 'Mise à jour du profil...';

  @override
  String get manageIsdR => 'Gérer les AID ISD-R';

  @override
  String get manageIsdRSubtitle =>
      'Configurer les ID d\'application par défaut pour l\'eUICC';

  @override
  String get transportFailed => 'Échec du transport';

  @override
  String get remoteTransportFailedMessage =>
      'Connecté au serveur distant, mais la commande a échoué. Cela signifie généralement que l\'appareil distant est momentanément occupé ou déconnecté de la carte. Souhaitez-vous réessayer ?';

  @override
  String get retry => 'Réessayer';

  @override
  String get scanningForReaders => 'Recherche de lecteurs...';

  @override
  String get switchedEstkSlot => 'Slot eSTK changé';

  @override
  String get scanningForUnresponsiveDevices =>
      'Recherche d\'appareils qui ne répondent pas...';

  @override
  String get resettingConnection => 'Réinitialisation de la connexion...';

  @override
  String get connectingToReader => 'Connexion au lecteur...';

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
  String get moreOptions => 'Plus d\'options';

  @override
  String get retrievingProfiles => 'Récupération des profils...';

  @override
  String get savingProfileMetadata =>
      'Enregistrement des métadonnées du profil...';

  @override
  String get enablingProfile => 'Activation du profil...';

  @override
  String get disablingProfile => 'Désactivation du profil...';

  @override
  String get deleteProfile => 'Supprimer le profil';

  @override
  String deleteProfileConfirmation(Object profileName) {
    return 'Êtes-vous sûr de vouloir supprimer le profil $profileName ?\nCette action est irréversible.';
  }

  @override
  String get deletingProfile => 'Suppression du profil...';

  @override
  String get deleting => 'Suppression...';

  @override
  String get dataUsage => 'Consommation de données';

  @override
  String get details => 'Détails';

  @override
  String get rename => 'Renommer';

  @override
  String get changeIcon => 'Changer l\'icône';

  @override
  String get manageTags => 'Gérer les tags';

  @override
  String get copyIccid => 'Copier l\'ICCID';

  @override
  String get notificationProcessingError =>
      'Impossible d\'effectuer des opérations pendant le traitement des notifications';

  @override
  String get operationInProgressError =>
      'Opération en cours, veuillez patienter';

  @override
  String iccidCopied(Object iccid) {
    return 'ICCID copié : $iccid';
  }

  @override
  String get operationRestricted => 'Opération restreinte';

  @override
  String get notificationProcessingDownloadError =>
      'Les notifications sont toujours en cours de traitement. Veuillez attendre la fin du traitement avant de télécharger de nouveaux profils.';

  @override
  String get operational => 'Opérationnel';

  @override
  String get test => 'Test';

  @override
  String get provisioning => 'Provisionnement';

  @override
  String get profileDetails => 'Détails du profil';

  @override
  String get profileDetailsSubtitle =>
      'Informations de l\'eUICC pour cet emplacement de profil.';

  @override
  String get enabled => 'Activé';

  @override
  String get disabled => 'Désactivé';

  @override
  String get tagsManagedSeparately =>
      'Note : Les tags sont gérés séparément via le menu \'Gérer les tags\'.';

  @override
  String get changeProfileIcon => 'Changer l\'icône du profil';

  @override
  String get selectFromGallery => 'Sélectionner dans la galerie';

  @override
  String get nekokoOperatorIcon => 'Icône opérateur Nekoko';

  @override
  String get iconFromEsim => 'Icône de la carte eSIM';

  @override
  String updateIconFailed(Object error) {
    return 'Échec de la mise à jour de l\'icône : $error';
  }

  @override
  String get failedToReadImage => 'Échec de la lecture du fichier image';

  @override
  String get failedToProcessImage => 'Échec du traitement de l\'image';

  @override
  String get customIconSet => 'Icône personnalisée définie avec succès';

  @override
  String get noMccMnc => 'Aucun MCC/MNC disponible pour ce profil';

  @override
  String get fetchingRemoteIcon => 'Récupération de l\'icône distante...';

  @override
  String get remoteIconSaved =>
      'Icône distante enregistrée comme icône personnalisée';

  @override
  String fetchRemoteIconFailed(Object error) {
    return 'Échec de la récupération de l\'icône distante : $error';
  }

  @override
  String get noProfileIcon => 'Aucune icône de profil disponible';

  @override
  String get profileIconSaved =>
      'Icône de profil enregistrée comme icône personnalisée';

  @override
  String get customIconRemoved => 'Icône personnalisée supprimée';

  @override
  String get failed => 'Échoué';

  @override
  String euiccError(Object action) {
    return 'L\'eUICC a renvoyé une erreur lors de la tentative de $action du profil.';
  }

  @override
  String get dismiss => 'Ignorer';

  @override
  String get dataPlan => 'Forfait de données';

  @override
  String get used => 'utilisé';

  @override
  String get total => 'total';

  @override
  String expires(Object date) {
    return 'Expire le : $date';
  }

  @override
  String get close => 'Fermer';

  @override
  String get server => 'Serveur';

  @override
  String get switchFailed => 'Le changement a échoué';

  @override
  String get deviceRefreshFailed => 'L\'actualisation de l\'appareil a échoué';

  @override
  String get euiccOptions => 'Options eUICC';

  @override
  String get euiccInfo => 'Infos eUICC';

  @override
  String get hideEid => 'Masquer l\'EID';

  @override
  String get showEid => 'Afficher l\'EID';

  @override
  String get copyEid => 'Copier l\'EID';

  @override
  String get eidCopied => 'EID copié dans le presse-papiers';

  @override
  String get connectRemotes => 'Connecter serveurs distants';

  @override
  String get configureRemotes => 'Configurer serveurs distants';

  @override
  String get connectingToRemoteReaders =>
      'Connexion aux lecteurs distants en arrière-plan...';

  @override
  String get noRemoteReadersFound => 'Aucun lecteur distant trouvé';

  @override
  String connectedRemoteReaders(Object count) {
    return '$count lecteur(s) distant(s) connecté(s)';
  }

  @override
  String failedToConnectRemoteReaders(Object error) {
    return 'Échec de la connexion aux lecteurs distants : $error';
  }

  @override
  String get remoteReaderPassword => 'Mot de passe du lecteur distant';

  @override
  String get remoteReaderPasswordSubtitle =>
      'Ce lecteur distant nécessite un mot de passe.';

  @override
  String get password => 'Mot de passe';

  @override
  String get deleteConnection => 'Supprimer la connexion';

  @override
  String get connect => 'Connecter';

  @override
  String get remoteReaderConnectionFailed =>
      'Échec de connexion du lecteur distant';

  @override
  String remoteReaderConnectionFailedSubtitle(Object error) {
    return 'Assurez-vous que le serveur distant fonctionne et est accessible.\n\n$error';
  }

  @override
  String get connectReader => 'Connectez un lecteur compatible pour commencer.';

  @override
  String get connectReaderSubtitleBle =>
      'Vous pouvez également scanner les appareils Bluetooth compatibles si vous avez un eUICC compatible Bluetooth.';

  @override
  String get connectReaderSubtitleCcid =>
      'Assurez-vous que votre lecteur CCID est connecté à votre ordinateur.';

  @override
  String get downloadExtension => 'Télécharger l\'extension Smart Card';

  @override
  String get downloadExtensionSubtitle =>
      'L\'extension est requise pour accéder aux lecteurs USB CCID dans ce navigateur.';

  @override
  String get cardUnsupported => 'Carte non supportée';

  @override
  String get cardUnsupportedSubtitle =>
      'Cette carte n\'est probablement pas un eUICC, ou elle n\'est pas supportée par ce lecteur, ou elle est utilisée par d\'autres.';

  @override
  String get omapiWelcome =>
      'Bonne nouvelle — votre appareil supporte l\'OMAPI et est très probablement compatible avec les cartes eUICC amovibles !';

  @override
  String get supportedDevices => 'Appareils supportés';

  @override
  String get aboutAram => 'À propos d\'ARA-M';

  @override
  String get accessDenied => 'Accès refusé';

  @override
  String get accessDeniedSubtitle =>
      'Des privilèges opérateur sont requis pour accéder à cet eUICC. La liste d\'autorisation ARA-M de la carte ne correspond pas à la signature de l\'application.';

  @override
  String get noCardDetectedSubtitle =>
      'Aucun eUICC non supporté ou actif trouvé dans cet emplacement.';

  @override
  String get noProfilesInstalled => 'Aucun profil installé';

  @override
  String get noProfilesInstalledSubtitle => 'Cette carte eUICC est vide.';

  @override
  String get cardRefreshingTitle => 'Actualisation de la carte';

  @override
  String get cardRefreshingMessage =>
      'La carte met actuellement à jour son état. La liste des profils ne peut pas être récupérée pour le moment. Veuillez patienter quelques secondes, puis réessayer.';

  @override
  String get useRemoteIcon => 'Utiliser l\'icône distante';

  @override
  String get bleDisconnectedTitle => 'Connexion Bluetooth perdue';

  @override
  String get bleDisconnectedMessage =>
      'La connexion au lecteur de carte a été brusquement perdue. Assurez-vous qu\'il est à proximité et allumé.';

  @override
  String get cardStuckRefreshingMessage =>
      'Changement d\'état du profil en cours - réinsérez manuellement la carte SIM si cela bloque.';

  @override
  String get cardNeedsReplugTitle => 'Réinsérez la carte SIM';

  @override
  String get cardNeedsReplugMessage =>
      'La carte ne libère pas son applet eUICC, elle ne peut donc pas être gérée pour le moment. Retirez la carte SIM, réinsérez-la, puis réessayez.';

  @override
  String get activationCodeTitle => 'Code d\'activation';

  @override
  String get activationCodeSubtitle =>
      'Scannez un QR code, déposez une image ou entrez manuellement la chaîne LPA.';

  @override
  String get fullActivationCodeLabel => 'Code d\'activation complet';

  @override
  String get fullActivationCodeHint => 'LPA:1\$smdp.io\$MATCHING-ID';

  @override
  String get pasteFromClipboardTooltip => 'Coller depuis le presse-papiers';

  @override
  String get selectFromGalleryTooltip => 'Sélectionner dans la galerie';

  @override
  String get scanQrCodeTooltip => 'Scanner le QR code';

  @override
  String get smdpAddressLabel => 'Adresse SM-DP+';

  @override
  String get smdpAddressHint => 'smdp.io';

  @override
  String get matchingIdLabel => 'ID de correspondance';

  @override
  String get matchingIdHint => 'ABC-123';

  @override
  String get smdpOidLabel => 'OID SM-DP+';

  @override
  String get confirmationCodeLabel => 'Code de confirmation';

  @override
  String get confirmationCodeHint => 'Entrez le code secret';

  @override
  String get continueButton => 'Continuer';

  @override
  String get invalidLpaClipboard =>
      'Le presse-papiers ne contient pas de chaîne LPA valide.';

  @override
  String get invalidFqdnFormat => 'Format FQDN invalide';

  @override
  String get invalidMatchingIdChars =>
      'L\'ID de correspondance contient des caractères invalides';

  @override
  String get invalidOidFormat => 'Format OID invalide (ex: 1.2.840...)';

  @override
  String get activationCodeRequired => 'Le code d\'activation est requis';

  @override
  String get invalidLpaFormatGeneric => 'Format LPA invalide';

  @override
  String get smdpAddressRequired => 'L\'adresse SM-DP+ est requise';

  @override
  String get loadingNotifications => 'Chargement des notifications...';

  @override
  String get vowifi => 'VoWiFi';

  @override
  String get vowifiSubtitle =>
      'Expérimental ; nécessite un lecteur externe compatible';

  @override
  String get vowifiDisclaimerTitle => 'Activer la VoWiFi expérimentale ?';

  @override
  String get vowifiDisclaimerBody =>
      'La VoWiFi est expérimentale. Elle communique directement avec votre opérateur mobile et ne fonctionne qu\'avec un lecteur SIM/eSIM externe compatible prenant en charge les APDU brutes. La compatibilité des opérateurs et des lecteurs peut varier.';

  @override
  String get processing => 'Traitement...';

  @override
  String get analyzingImage => 'Analyse de l\'image...';

  @override
  String get noQrFoundInImage => 'Aucun QR code trouvé dans l\'image';

  @override
  String get invalidAcInImage => 'Code d\'activation invalide dans l\'image';

  @override
  String get invalidAcFormatDetailed =>
      'Format de code d\'activation invalide. Doit commencer par LPA:1\$...';

  @override
  String get downloadProfileTitle => 'Télécharger un profil';

  @override
  String get connectingToEuicc => 'Connexion à l\'eUICC...';

  @override
  String get gettingChallenge => 'Récupération du défi eUICC...';

  @override
  String get authenticatingWithSmdp => 'Authentification auprès du SM-DP+...';

  @override
  String get verifyingSignatures => 'Vérification des signatures SM-DP+...';

  @override
  String get retrievingMetadata => 'Récupération des métadonnées du profil...';

  @override
  String get preparingDownload => 'Préparation du téléchargement...';

  @override
  String get preparingEuicc => 'Préparation de l\'eUICC...';

  @override
  String get fetchingProfilePackage => 'Récupération du paquet de profil...';

  @override
  String installing(Object sent, Object total) {
    return 'Installation ($sent / $total bytes)...';
  }

  @override
  String get finalizing =>
      'Finalisation (Mise à jour des infos de stockage)...';

  @override
  String get profileInstalledSuccessfully => 'Profil installé avec succès !';

  @override
  String get provider => 'Fournisseur';

  @override
  String get iccid => 'ICCID';

  @override
  String get plmn => 'PLMN';

  @override
  String get storage => 'Stockage';

  @override
  String get free => 'Libre';

  @override
  String get nvram => 'NVRAM';

  @override
  String get exportCertificates => 'Exporter les certificats';

  @override
  String get euiccCert => 'Cert. eUICC';

  @override
  String get eumCert => 'Cert. EUM';

  @override
  String get enterConfirmationCode =>
      'Entrez le code requis par votre opérateur';

  @override
  String get confirmationCodeRequired => 'Le code de confirmation est requis';

  @override
  String get download => 'Télécharger';

  @override
  String get installationSuccessful => 'Installation réussie';

  @override
  String get installationSuccessMessage =>
      'Le profil a été installé avec succès sur votre eUICC.';

  @override
  String get consumed => 'Consommé';

  @override
  String get enableProfileNow => 'Activer le profil maintenant';

  @override
  String get done => 'Terminé';

  @override
  String get profileEnabledSuccessfully => 'Profil activé avec succès';

  @override
  String get enterNewProfileName =>
      'Entrez un nouveau nom pour ce profil pour vous aider à l\'identifier plus facilement.';

  @override
  String get profileName => 'Nom du profil';

  @override
  String get profileNameHint => 'ex: Voyage';

  @override
  String get profileRenamedSuccessfully => 'Profil renommé avec succès';

  @override
  String get downloadFailed => 'Échec du téléchargement';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get savedSuccessfully => 'Enregistré avec succès';

  @override
  String get saveCertificate => 'Enregistrer le certificat';

  @override
  String get searchingForReaders => 'Recherche de lecteurs...';

  @override
  String get initializationError => 'Erreur d\'initialisation';

  @override
  String get noReadersFound => 'Aucun lecteur trouvé';

  @override
  String get noReadersFoundMessage =>
      'Insérez un lecteur compatible ou recherchez des appareils BLE pour gérer vos profils eSIM.';

  @override
  String get scanBle => 'Rechercher en BLE';

  @override
  String get reminderDetails => 'Détails du rappel';

  @override
  String get profileNotFound => 'Profil introuvable';

  @override
  String get resending => 'Renvoi...';

  @override
  String get noAddressInNotification =>
      'Aucune adresse dans les données de notification';

  @override
  String get sentSuccessfully => 'Envoyé avec succès';

  @override
  String get sendFailed => 'Échec de l\'envoi';

  @override
  String get copiedCurl => 'Commande cURL copiée dans le presse-papiers';

  @override
  String get noAddressToExport => 'Aucune adresse à exporter';

  @override
  String get noHistoryAvailable => 'Aucun historique disponible';

  @override
  String get searchByIccid => 'Rechercher par ICCID...';

  @override
  String get resendNotification => 'Renvoyer la notification';

  @override
  String get exportAsCurl => 'Exporter en cURL';

  @override
  String get viewDetails => 'Voir les détails';

  @override
  String get deleteEntry => 'Supprimer l\'entrée';

  @override
  String activeReminders(int count) {
    return '$count rappels actifs';
  }

  @override
  String get noScheduledReminders => 'Aucun rappel programmé';

  @override
  String get remindersAppearWhen =>
      'Les rappels apparaissent lorsque vous ajoutez des tags de date aux profils.';

  @override
  String activeTagsCount(int count) {
    return '$count tags actifs sur tous les profils';
  }

  @override
  String get searchTagsOrProfiles => 'Rechercher des tags ou des profils...';

  @override
  String get noTagsFound => 'Aucun tag trouvé';

  @override
  String get addTagsFromProfileMenu =>
      'Ajoutez des tags à vos profils depuis le menu d\'édition pour les voir ici.';

  @override
  String get expired => 'Expiré';

  @override
  String daysLeft(int count) {
    return '$count j restants';
  }

  @override
  String hoursLeft(int count) {
    return '$count h restantes';
  }

  @override
  String get expiresSoon => 'Expire bientôt';

  @override
  String get soon => 'bientôt';

  @override
  String get activeTags => 'Tags actifs';

  @override
  String get addNewTag => 'Ajouter un tag';

  @override
  String get noTagsAssigned => 'Aucun tag attribué à ce profil';

  @override
  String get textTagHint => 'Tag texte (ex. Travail, Voyage)';

  @override
  String get addDateExpiryTag => 'Ajouter un tag de date/expiration';

  @override
  String get addNoteOptional => 'Ajouter une note (facultatif)';

  @override
  String get add => 'Ajouter';

  @override
  String get noteHint => 'ex. Expiration, 10 Go, etc.';

  @override
  String get invalidHexString => 'Chaîne hexadécimale invalide';

  @override
  String get resetToDefaults => 'Réinitialiser les valeurs par défaut';

  @override
  String get resetToDefaultsSuccess => 'Valeurs par défaut restaurées';

  @override
  String get addAidHex => 'Ajouter un AID (hex)';

  @override
  String get manageAutoNotif =>
      'Gérer le traitement automatique des notifications';

  @override
  String get automaticProcessing => 'TRAITEMENT AUTOMATIQUE';

  @override
  String get notifProcessingInfo =>
      'Le traitement des notifications facilite la synchronisation entre votre eUICC et le serveur SM-DP+ (opérateur). Supprimer les notifications envoyées permet de garder le stockage de votre carte propre.';

  @override
  String get enabling => 'Activation';

  @override
  String get afterEnabling => 'Après l\'activation d\'un profil';

  @override
  String get disabling => 'Désactivation';

  @override
  String get afterDisabling => 'Après la désactivation d\'un profil';

  @override
  String get installation => 'Installation';

  @override
  String get afterDownload => 'Après le téléchargement d\'un profil';

  @override
  String get deletion => 'Suppression';

  @override
  String get afterDeletion => 'Après la suppression d\'un profil';

  @override
  String get autoSend => 'Envoi automatique';

  @override
  String get autoSendSubtitle => 'Envoyer automatiquement au serveur';

  @override
  String get autoRemove => 'Suppression automatique';

  @override
  String get autoRemoveSubtitle => 'Supprimer de la carte après l\'envoi';

  @override
  String get removeWithoutSending => 'Supprimer sans envoyer';

  @override
  String get removeWithoutSendingSubtitle =>
      'À utiliser avec précaution : le serveur ne sera pas notifié';

  @override
  String get permissionsActive => 'Permissions actives';

  @override
  String get permissionsRequired => 'Permissions requises';

  @override
  String get appCanSendNotif =>
      'L\'application peut envoyer des notifications système';

  @override
  String get requiredForReminders => 'Nécessaire pour les alertes de rappel';

  @override
  String get unsupportedPlatformCheck =>
      'La vérification des permissions n\'est pas prise en charge sur cette plateforme. Veuillez effectuer un test manuel.';

  @override
  String get couldNotVerifyStatus =>
      'Impossible de vérifier l\'état. Veuillez consulter les Paramètres manuellement.';

  @override
  String get testNotificationTitle => 'Notification de test';

  @override
  String get seconds => 'secondes';

  @override
  String get startTest => 'Démarrer le test';

  @override
  String get sendingNotif => 'Envoi...';

  @override
  String get hostIpLabel => 'Nom d\'hôte / IP';

  @override
  String get portLabel => 'Port';

  @override
  String get passwordOptionalLabel => 'Mot de passe (facultatif)';

  @override
  String get configuredServers => 'Serveurs configurés';

  @override
  String get secureHttps => 'Sécurisé (HTTPS)';

  @override
  String get insecureHttp => 'Non sécurisé (HTTP)';

  @override
  String get urlCopied => 'URL copiée';

  @override
  String get serverAddedSuccessfully => 'Serveur ajouté avec succès';

  @override
  String get authFailedCheckPassword =>
      'Échec de l\'authentification. Vérifiez le mot de passe.';

  @override
  String get addNewServer => 'Ajouter un serveur';

  @override
  String get autoLoadRemotes =>
      'Charger automatiquement les appareils distants';

  @override
  String get autoLoadRemotesSubtitle =>
      'Se connecter automatiquement aux serveurs configurés au démarrage de l\'application';

  @override
  String get getRemoCardGitHub => 'Obtenir RemoCard sur GitHub';

  @override
  String get instructions => 'Instructions :';

  @override
  String get instruction1 =>
      '1. Installez l\'application RemoCard sur vos appareils Android.';

  @override
  String get instruction2 =>
      '2. Démarrez le serveur dans chaque application RemoCard.';

  @override
  String get instruction3 => '3. Saisissez les adresses IP ici.';

  @override
  String get instruction4 =>
      '4. Tous les emplacements SIM distants apparaîtront dans la liste des appareils.';

  @override
  String get appLogsCopied => 'Journaux copiés dans le presse-papiers';

  @override
  String get aramInfoTitle => 'Informations ARA-M';

  @override
  String get aramInfoSubtitle => 'Détails de l\'Access Rule Applet';

  @override
  String get whatIsAram => 'Qu\'est-ce que l\'ARA-M ?';

  @override
  String get aramDescription =>
      'L\'Access Rule Applet (ARA-M) est un mécanisme présent sur les eUICC (eSIM) et les cartes SIM qui définit quelles applications sont autorisées à gérer des profils ou à effectuer des opérations de bas niveau. Si l\'empreinte de l\'application ne figure pas dans la liste d\'autorisation ARA-M de la carte, le système Android bloquera l\'accès, ce qui provoquera une erreur « Accès refusé ».';

  @override
  String get appCertHashes => 'Empreintes du certificat de l\'application';

  @override
  String get aramHashInstruction =>
      'Pour accorder l\'accès à cette application, vous devrez peut-être ajouter l\'empreinte de certificat SHA-1 suivante aux règles ARA-M de votre carte. Cette empreinte est propre au certificat de votre version actuelle de l\'application.';

  @override
  String get aramSigningHistoryInstruction =>
      'Pour assurer la compatibilité entre les versions d\'Android, ajoutez toutes les empreintes de certificat SHA-1 ci-dessous aux règles ARA-M de votre carte. Après un changement de clé de signature, différentes versions d\'Android peuvent vérifier différents certificats issus de l\'historique de signature vérifié.';

  @override
  String get certSha1Hash => 'Empreinte SHA-1 du certificat';

  @override
  String get unavailable => 'Indisponible';

  @override
  String get troubleshooting => 'Dépannage';

  @override
  String get troubleStep1 =>
      'Assurez-vous d\'utiliser le bon lecteur de carte.';

  @override
  String get troubleStep2 =>
      'Si vous utilisez une carte physique, vérifiez s\'il s\'agit d\'une carte de test ou d\'une carte de production (les cartes de production verrouillent souvent l\'ARA-M).';

  @override
  String get troubleStep3 =>
      'Les empreintes ci-dessus dépendent de la version de l\'application utilisée : Debug, Regular ou Privileged (Magisk).';

  @override
  String get troubleStep4 =>
      'Envisagez d\'utiliser la version Privileged (Magisk), qui peut contourner certaines restrictions des API Android.';

  @override
  String get hashCopied => 'Empreinte copiée dans le presse-papiers';

  @override
  String get aidCopied => 'AID copié dans le presse-papiers';

  @override
  String get lastSeen => 'Dernière détection';

  @override
  String get unknownProvider => 'Fournisseur inconnu';

  @override
  String get unknownProfile => 'Profil inconnu';

  @override
  String get tags => 'Tags';

  @override
  String get noTags => 'Aucun tag';

  @override
  String records(int count) {
    return '$count enregistrements';
  }

  @override
  String get bytes => 'octets';

  @override
  String get responseCode => 'Code de réponse';

  @override
  String get responseBody => 'Corps de la réponse';

  @override
  String get type => 'Type';

  @override
  String profileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count profils',
      one: '1 profil',
    );
    return '$_temp0';
  }

  @override
  String get isdrAids => 'AID ISD-R';

  @override
  String get configureDefaultAids =>
      'Configurer les identifiants d\'application par défaut';

  @override
  String get addAidHexHint => 'Ajouter un AID (hex)';

  @override
  String get notificationProcessing => 'Notifications';

  @override
  String get manageAutoNotification =>
      'Gérer le traitement automatique des notifications';

  @override
  String get notificationProcessingHelp =>
      'Le traitement des notifications facilite la synchronisation entre votre eUICC et le serveur SM-DP+ (opérateur). Supprimer les notifications envoyées permet de garder le stockage de votre carte propre.';

  @override
  String get notificationProcessingTimings => 'Moments de traitement';

  @override
  String get notificationProcessingTimingsHelp =>
      'Choisissez quand le traitement automatique des notifications s\'exécute. Certains moments critiques pour la sécurité ne peuvent être désactivés que lorsque le mode développeur est activé.';

  @override
  String get afterEnablingProfile => 'Après l\'activation d\'un profil';

  @override
  String get afterDisablingProfile => 'Après la désactivation d\'un profil';

  @override
  String get afterProfileDownload => 'Après le téléchargement d\'un profil';

  @override
  String get afterProfileDeletion => 'Après la suppression d\'un profil';

  @override
  String get initialLoad => 'Chargement initial';

  @override
  String get processNotificationsOnInitialLoad =>
      'Traiter les notifications une fois le chargement des profils terminé';

  @override
  String get afterSwitchingProfile => 'Après un changement de profil';

  @override
  String get processNotificationsAfterSwitchingProfile =>
      'Traiter les notifications après l\'activation ou la désactivation d\'un profil';

  @override
  String get beforeProfileDownload => 'Avant le téléchargement d\'un profil';

  @override
  String get processNotificationsBeforeProfileDownload =>
      'Traiter les notifications avant de démarrer le téléchargement d\'un profil';

  @override
  String get afterProfileInstalled => 'Après l\'installation d\'un profil';

  @override
  String get processNotificationsAfterProfileInstalled =>
      'Traiter les notifications après l\'installation d\'un profil';

  @override
  String get processNotificationsAfterProfileDeletion =>
      'Traiter les notifications après la suppression d\'un profil';

  @override
  String get developerModeRequiredToDisableTiming =>
      'Activez le mode développeur pour désactiver ce moment.';

  @override
  String get sendToServerAutomatically => 'Envoyer automatiquement au serveur';

  @override
  String get removeFromCardAfterSending =>
      'Supprimer de la carte après l\'envoi';

  @override
  String get removeWithoutSendingCaution =>
      'À utiliser avec précaution : le serveur ne sera pas notifié';

  @override
  String get reminderSettings => 'Paramètres des rappels';

  @override
  String get appCanSendNotifications =>
      'L\'application peut envoyer des notifications système';

  @override
  String get requiredForReminderAlerts =>
      'Nécessaire pour les alertes de rappel';

  @override
  String get enable => 'Activer';

  @override
  String get permissionCheckNotSupported =>
      'La vérification des permissions n\'est pas prise en charge sur cette plateforme. Veuillez effectuer un test manuel.';

  @override
  String get testNotification => 'Notification de test';

  @override
  String get notificationsDisabledMessage =>
      'Les notifications sont désactivées. Activez-les dans les paramètres système pour recevoir des rappels.';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get applicationLogs => 'Journaux de l\'application';

  @override
  String get refreshReload => 'Actualiser/Recharger';

  @override
  String get toggleAutoScroll => 'Activer/désactiver le défilement automatique';

  @override
  String get refreshDevices => 'Actualiser les appareils';

  @override
  String get scanBluetooth => 'Rechercher en Bluetooth';

  @override
  String get lessThan1Kb => '< 1 Ko';

  @override
  String get connectionFailed => 'Échec de la connexion';

  @override
  String get downloadRemoCard => 'Télécharger RemoCard';

  @override
  String get remoCardAndroidApp => 'Application Android pour télécommandes';

  @override
  String get resentSuccessfully => 'Renvoyé avec succès';

  @override
  String get resendFailed => 'Échec du renvoi';

  @override
  String get eid => 'EID';

  @override
  String get seq => 'Séquence';

  @override
  String get date => 'Date';

  @override
  String errorWithDetails(String error) {
    return 'Erreur : $error';
  }

  @override
  String exportFailed(String error) {
    return 'Échec de l\'exportation : $error';
  }

  @override
  String get sasAccreditation => 'Accréditation SAS';

  @override
  String get firmwareVersion => 'Version du micrologiciel';

  @override
  String get beeSimFirmwareAction => 'Mettre à jour le firmware BeeSIM';

  @override
  String get beeSimFirmwareTitle => 'Mise à jour du firmware BeeSIM';

  @override
  String get beeSimFirmwareWarning =>
      'Une mise à jour du firmware BeeSIM est disponible. Gardez la carte alimentée, le Bluetooth connecté et l\'application ouverte jusqu\'à la fin de l\'opération. Interrompre la mise à jour peut rendre la carte temporairement inutilisable.';

  @override
  String get beeSimFirmwareConfirm => 'Mettre à jour le firmware';

  @override
  String get platformSupport => 'SUPPORT DE PLATEFORME';

  @override
  String get rspVersion => 'Version RSP';

  @override
  String get bppVersion => 'Version BPP';

  @override
  String get gpVersion => 'Version GlobalPlatform';

  @override
  String get certInfrastructure => 'INFRASTRUCTURE DE CERTIFICATS';

  @override
  String get configuredAddresses => 'ADRESSES CONFIGURÉES';

  @override
  String get defaultSmdpAddress => 'SM-DP+ par défaut';

  @override
  String get rootDsAddress => 'SM-DS racine';

  @override
  String get euiccSignCi => 'CI de signature eUICC';

  @override
  String get euiccVerifyCi => 'CI de vérification eUICC';

  @override
  String get none => 'Aucun';

  @override
  String keysCount(int count) {
    return '$count clé(s)';
  }

  @override
  String get state => 'État';

  @override
  String get profileClass => 'Classe';

  @override
  String get aid => 'AID';

  @override
  String get euiccSpecifications => 'SPÉCIFICATIONS EUICC';

  @override
  String get sending => 'Envoi...';

  @override
  String get failedToSaveTags => 'Échec de l\'enregistrement des tags';

  @override
  String get note => 'Note';

  @override
  String get notificationDetails => 'Détails de la notification';

  @override
  String get unknown => 'Inconnu';

  @override
  String get status => 'État';

  @override
  String get sent => 'Envoyé';

  @override
  String get pending => 'En attente';

  @override
  String get notifTypeInstall => 'Installer';

  @override
  String get notifTypeDelete => 'Supprimer';

  @override
  String get notifTypeEnable => 'Activer';

  @override
  String get notifTypeDisable => 'Désactiver';

  @override
  String get notifTypeRpmEnable => 'RPM Activer';

  @override
  String get notifTypeRpmDisable => 'RPM Désactiver';

  @override
  String get notifTypeRpmDelete => 'RPM Supprimer';

  @override
  String get notifTypeLoadRpm => 'Charger RPM';

  @override
  String confirmDeleteNotification(int seq) {
    return 'Voulez-vous vraiment supprimer la notification #$seq ?';
  }

  @override
  String get notificationRemoved => 'Notification supprimée';

  @override
  String failedToRemove(String error) {
    return 'Échec de la suppression : $error';
  }

  @override
  String get curlCopied => 'Commande cURL copiée dans le presse-papiers';

  @override
  String failedToGenerateCurl(String error) {
    return 'Échec de la génération de cURL : $error';
  }

  @override
  String get noNotificationAddress =>
      'Aucune adresse de notification disponible';

  @override
  String get sendingNotification => 'Envoi de la notification...';

  @override
  String get notifSentSuccessfully => 'Notification envoyée avec succès';

  @override
  String get failedToSendNotification => 'Échec de l\'envoi de la notification';

  @override
  String errorSendingNotification(String error) {
    return 'Erreur lors de l\'envoi de la notification : $error';
  }

  @override
  String pendingCount(int count) {
    return '$count en attente';
  }

  @override
  String get currentReader => 'Lecteur actuel';

  @override
  String get errorLoadingNotifications =>
      'Erreur lors du chargement des notifications';

  @override
  String get allCaughtUp => 'Vous êtes à jour';

  @override
  String get sequence => 'Séquence';

  @override
  String get operation => 'Opération';

  @override
  String get profileNameLabel => 'Nom du profil';

  @override
  String get failedToSend => 'Échec de l\'envoi';

  @override
  String get onCard => 'Sur la carte';

  @override
  String get sendNotification => 'Envoyer la notification';

  @override
  String get deleteNotification => 'Supprimer la notification';

  @override
  String get noNotifications => 'Aucune notification';

  @override
  String get batchDownloadTitle => 'Téléchargement par lot';

  @override
  String get batchDownloadHint =>
      'Collez plusieurs codes LPA ici (un par ligne, 20 maximum)';

  @override
  String foundLpaCodes(int count) {
    return '$count codes LPA trouvés';
  }

  @override
  String get startBatch => 'Démarrer le lot';

  @override
  String get noLpaCodesFound => 'Aucun code LPA valide trouvé';

  @override
  String get insufficientSpaceStoppingBatch =>
      'Espace insuffisant. Arrêt du téléchargement par lot.';

  @override
  String get exportCsv => 'Exporter en CSV';

  @override
  String get exportedSuccessfully => 'Exporté avec succès';

  @override
  String get exportResults => 'Exporter les résultats';

  @override
  String get lpa => 'LPA';

  @override
  String get smdp => 'SM-DP+';

  @override
  String get confirmationCode => 'Code de confirmation';

  @override
  String get size => 'Taille';

  @override
  String get message => 'Message';

  @override
  String get remainingSpace => 'Espace restant';

  @override
  String get stopBatch => 'Arrêter le lot';

  @override
  String get stopping => 'Arrêt...';

  @override
  String get remove => 'Supprimer';

  @override
  String get updateAvailable => 'Mise à jour disponible';

  @override
  String updateAvailableSubtitle(String appName, String version, String build) {
    return 'Une nouvelle version de $appName est disponible (v$version b$build). Voulez-vous la mettre à jour maintenant ?';
  }

  @override
  String get updateAction => 'Mettre à jour';

  @override
  String get later => 'Plus tard';

  @override
  String get changelog => 'Journal des modifications';

  @override
  String get sortBy => 'Trier par';

  @override
  String get sortIccid => 'ICCID';

  @override
  String get sortCountry => 'Pays';

  @override
  String get sortAscending => 'Croissant';

  @override
  String get sortDescending => 'Décroissant';

  @override
  String get searchProfiles => 'Rechercher des profils...';

  @override
  String get noProfilesMatch => 'Aucun profil ne correspond à votre recherche.';

  @override
  String get sortDefault => 'Par défaut';

  @override
  String get sortNickname => 'Surnom';

  @override
  String get showProfileSearch => 'Afficher la recherche de profils';

  @override
  String get showProfileSearchSubtitle =>
      'Afficher la barre de recherche et de tri dans la liste des profils';

  @override
  String get noReaderFound =>
      'Aucun lecteur trouvé. Veuillez connecter votre adaptateur eUICC.';

  @override
  String get readyToInstallProfile => 'Prêt à installer le profil.';

  @override
  String get downloadHere => 'Télécharger ici';

  @override
  String get manage => 'Gérer';

  @override
  String get buyCard => 'Carte';

  @override
  String get buyData => 'Données';

  @override
  String get selectDevice => 'Sélectionner un appareil';

  @override
  String get selectReaderTitle => 'Sélectionner une carte';

  @override
  String get authorizeSigning => 'Autoriser la signature';

  @override
  String get signingDescription =>
      'Un site web demande une signature sécurisée à votre eUICC.';

  @override
  String get smdpAddress => 'Adresse SM-DP+';

  @override
  String get sign => 'Signer';

  @override
  String profilesInstalled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count profils installés',
      one: '1 profil installé',
    );
    return '$_temp0';
  }

  @override
  String get estimatedDownloadSize => 'Taille de téléchargement estimée';

  @override
  String get phoneFormatInternationalOnly => 'E.164 int. uniquement';

  @override
  String get phoneFormatInternationalAndMobile => 'Int. et mobile';

  @override
  String get phoneFormatInternationalAndAll => 'Int. et national';

  @override
  String get phoneFormatOff => 'Désactivé';

  @override
  String get settings_item_unit_b => 'Octets';

  @override
  String get settings_item_unit_kb => 'ko (1 000 octets)';

  @override
  String get settings_item_unit_kib => 'kio (1 024 octets)';

  @override
  String get settings_item_unit_adaptive_si => 'o / ko adaptatif';

  @override
  String get settings_item_unit_adaptive_bi => 'o / kio adaptatif';

  @override
  String get insufficientStorageWarning =>
      'Espace de stockage insuffisant pour l\'installation. Celle-ci risque d\'échouer.';

  @override
  String get estimateProfileSize => 'Estimer la taille du profil';

  @override
  String get estimateProfileSizeSubtitle =>
      'Estimer la taille des métadonnées du profil avant le téléchargement';

  @override
  String get customize => 'Personnaliser';

  @override
  String get customizeDescription =>
      'Indiquez un nouveau nom hexadécimal de 6 caractères et un mot de passe pour votre lecteur.';

  @override
  String get customizeSuccess =>
      'Lecteur personnalisé. Veuillez ré-appairer l\'appareil.';

  @override
  String customizeFailed(String error) {
    return 'Échec de la personnalisation du lecteur : $error';
  }

  @override
  String get defaultPasswordWillChangeTitle =>
      'Le mot de passe par défaut va changer';

  @override
  String defaultPasswordWillChangeMessage(String password) {
    return 'Cet appareil est connecté avec son mot de passe par défaut. Le renommer définira le mot de passe sur $password. Enregistrez ce mot de passe avant de vous reconnecter.';
  }

  @override
  String get savedBleDevices => 'Appareils BLE déjà connectés';

  @override
  String get savedBleDevicesSubtitle =>
      'Afficher les noms et mots de passe des appareils enregistrés sur cet appareil';

  @override
  String get savedBleDevicesDescription =>
      'Chaque entrée correspond à un mot de passe NBLESim enregistré localement. Les mots de passe par défaut sont également enregistrés.';

  @override
  String get noSavedBleDevices => 'Aucun appareil BLE déjà connecté.';

  @override
  String get deviceName => 'Nom de l\'appareil';

  @override
  String get success => 'Succès';

  @override
  String get devicePasswordHint => '6 caractères hex ou mot de passe';

  @override
  String get sixHexChars => '6 caractères hex';

  @override
  String get database => 'Base de données';

  @override
  String exportSuccess(String path) {
    return 'Base de données exportée vers $path';
  }

  @override
  String get importDatabase => 'Importer la base de données';

  @override
  String get importDatabaseSubtitle =>
      'Fusionner les entrées d\'un autre fichier de base de données';

  @override
  String get importDatabaseDialogTitle =>
      'Sélectionnez le fichier de base de données à importer';

  @override
  String get importDatabaseTitle => 'Importer la base de données';

  @override
  String get importDatabaseContent =>
      'Les entrées de la base sélectionnée seront fusionnées avec votre base actuelle. Les entrées existantes ayant les mêmes clés seront écrasées. Continuer ?';

  @override
  String get import => 'Importer';

  @override
  String get importSuccess => 'Base de données importée avec succès';

  @override
  String importFailed(String error) {
    return 'Échec de l\'importation de la base de données : $error';
  }

  @override
  String get resetDatabase => 'Réinitialiser la base de données';

  @override
  String get resetDatabaseSubtitle =>
      'Effacer toutes les données de l\'application et redémarrer';

  @override
  String get resetDatabaseTitle =>
      'Réinitialiser la base de données de l\'application';

  @override
  String get resetDatabaseContent =>
      'Cette action supprimera définitivement toutes les données, configurations et journaux stockés localement. L\'application se fermera. Voulez-vous continuer ?';

  @override
  String get deleteDatabase => 'Supprimer la base de données';

  @override
  String resetFailed(String error) {
    return 'Échec de la réinitialisation de la base de données : $error';
  }

  @override
  String get deviceImei => 'TAC de l\'appareil';

  @override
  String get deviceImeiSubtitle =>
      'Utilisé pour les téléchargements de profils';

  @override
  String get editDeviceImei => 'Modifier le TAC de l\'appareil';

  @override
  String get editDeviceImeiInfo =>
      'Saisissez un TAC à 8 chiffres ou un IMEI à 15 chiffres. TAC par défaut : 35383741.';

  @override
  String get imeiDigits => 'Chiffres du TAC ou de l\'IMEI';

  @override
  String get importAction => 'Importer';

  @override
  String get transferTitle => 'Transférer l\'eSIM';

  @override
  String get transferAction => 'Transférer vers cet appareil';

  @override
  String get transferCheckingEligibility => 'Vérification de l\'éligibilité…';

  @override
  String get transferReadingSource => 'Lecture de la SIM source…';

  @override
  String get transferContactingCarrier => 'Contact de l\'opérateur…';

  @override
  String get transferIneligibleReader =>
      'Ce profil ne peut pas être transféré avec ce lecteur. L\'authentification de la SIM source (EAP-AKA) n\'est pas accessible ici.';

  @override
  String get transferNoEntitlement =>
      'Aucune configuration de transfert de l\'opérateur n\'a été trouvée pour ce profil. Vous pouvez saisir le serveur d\'entitlement manuellement.';

  @override
  String transferSourceCarrier(String carrier) {
    return 'Opérateur source : $carrier';
  }

  @override
  String get transferConfirmTitle => 'Transférer cet abonnement ?';

  @override
  String get transferConfirmBody =>
      'L\'opérateur réémettra cet abonnement sur cette eUICC. Le profil source pourra être supprimé dans le cadre du transfert.';

  @override
  String get transferStart => 'Démarrer le transfert';

  @override
  String get transferDownloadingProfile =>
      'Téléchargement du profil transféré…';

  @override
  String get transferDeleteSourceTitle => 'Supprimer le profil source';

  @override
  String transferDeleteSourceBody(String iccid) {
    return 'L\'opérateur exige la suppression du profil source $iccid avant l\'activation. Le supprimer maintenant ?';
  }

  @override
  String get transferDeleteSourceConfirm => 'Supprimer et continuer';

  @override
  String get transferUserInputSubmit => 'Valider';

  @override
  String get transferAccept => 'Accepter';

  @override
  String get transferReject => 'Refuser';

  @override
  String get transferPendingActivation =>
      'L\'opérateur active encore cet abonnement. L\'opération se terminera sous peu ; vous pouvez fermer cette fenêtre et vérifier plus tard.';

  @override
  String get transferDismissed => 'L\'opérateur a rejeté le transfert.';

  @override
  String get transferDelayedDownload =>
      'L\'opérateur livrera le profil sous peu. Une fois que vous l\'aurez installé, saisissez l\'ICCID installé pour terminer.';

  @override
  String get transferInstalledIccid => 'ICCID installé';

  @override
  String get transferSuccess => 'Transfert terminé';

  @override
  String transferFailed(String error) {
    return 'Échec du transfert : $error';
  }

  @override
  String get transferManualServerTitle => 'Serveur d\'entitlement (avancé)';

  @override
  String get transferManualServerHint => 'https://entitlement.example.com';

  @override
  String get transferEnablingSource => 'Préparation du profil source…';

  @override
  String get transferClose => 'Fermer';

  @override
  String get transferContinue => 'Continuer';

  @override
  String get transferSmdsDiscovering => 'Découverte des profils via SM-DS…';

  @override
  String get transferSmdsNoProfiles =>
      'Aucun profil en attente n\'a été trouvé via la découverte SM-DS.';

  @override
  String get transferSelectProfile => 'Sélectionnez un profil à télécharger';

  @override
  String get discoverProfiles => 'Découvrir les profils (SM-DS)';

  @override
  String get discoveringProfiles => 'Découverte des profils…';

  @override
  String get discoveryNoProfiles =>
      'Aucun profil en attente n\'a été trouvé via la découverte SM-DS.';

  @override
  String get transferSmdsServerTitle => 'Serveur SM-DS';

  @override
  String transferProfileOnServer(String eventId, String address) {
    return '$eventId sur $address';
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
