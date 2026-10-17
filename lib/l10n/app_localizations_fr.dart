// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

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
  String get customDesign => 'Nekoko Style';

  @override
  String get stockMD3 => 'Stock MD3';

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
  String get useNekokoIcons => 'Utiliser les icônes opérateur';

  @override
  String get useNekokoIconsSubtitle =>
      'Récupérer les logos opérateurs depuis operator-icons';

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
  String get ensureSingleChannel => 'Ensure Single Channel';

  @override
  String get ensureSingleChannelSubtitle =>
      'Close other logical channels before opening a new one';

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
  String get licenses => 'Open Source Licenses';

  @override
  String get licensesSubtitle =>
      'License information for open source libraries used';

  @override
  String get noUpdatesFound => 'No updates found';

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
      'Bluetooth operation timed out. Please try again.';

  @override
  String get errorOmapiSecurity =>
      'Security error: Access to the card was denied by the OS or ARA-M rules.';

  @override
  String get errorApplicationNotFound =>
      'eUICC management application (ISD-R) not found. This card may not be a valid eUICC.';

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
  String get deleting => 'Deleting...';

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
  String get operationInProgressError => 'Operation in progress, please wait';

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
  String get nekokoOperatorIcon => 'Icône opérateur';

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
  String get cardRefreshingTitle => 'Card is Refreshing';

  @override
  String get cardRefreshingMessage =>
      'The card is currently updating its state. Profile list cannot be retrieved at this moment. Please wait a few seconds and then try again.';

  @override
  String get useRemoteIcon => 'Utiliser l\'icône distante';

  @override
  String get bleDisconnectedTitle => 'Bluetooth Connection Lost';

  @override
  String get bleDisconnectedMessage =>
      'The connection to the card reader was suddenly lost. Please ensure it is nearby and turned on.';

  @override
  String get cardStuckRefreshingMessage =>
      'Profile state change ongoing - try manually re-plug the SIM card if it stucks.';

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
      'Pour assurer la compatibilité entre les versions d\'Android, ajoutez toutes les empreintes SHA-1 de certificat ci-dessous aux règles ARA-M de votre carte. Après une mise à niveau de la clé de signature de l\'application, différentes versions d\'Android peuvent vérifier des certificats différents de l\'historique de signature validé.';

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
  String get unknownProfile => 'Profil inconnu';

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
  String get beeSimFirmwareAction => 'Update BeeSIM firmware';

  @override
  String get beeSimFirmwareTitle => 'BeeSIM firmware update';

  @override
  String get beeSimFirmwareWarning =>
      'A BeeSIM firmware update is available. Keep the card powered, Bluetooth connected, and the app open until it finishes. Interrupting the update may leave the card temporarily unusable.';

  @override
  String get beeSimFirmwareConfirm => 'Update firmware';

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
  String get manage => 'Gérer';

  @override
  String get buyCard => 'Carte';

  @override
  String get buyData => 'Données';

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
