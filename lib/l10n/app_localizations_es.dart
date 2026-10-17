// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get displaySettings => 'Ajustes de pantalla';

  @override
  String get appearance => 'Apariencia';

  @override
  String get appearanceSubtitle =>
      'Personalizar tema, diseño y preferencias de pantalla';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get themeStyle => 'Estilo del tema';

  @override
  String get themeStyleSubtitle => 'Elegir entre estilo personalizado y MD3';

  @override
  String get customDesign => 'Nekoko Style';

  @override
  String get stockMD3 => 'Stock MD3';

  @override
  String get waterfallLayout => 'Diseño de cascada';

  @override
  String get waterfallLayoutSubtitle =>
      'Usar el estilo Masonry en pantallas anchas';

  @override
  String get system => 'Sistema';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Oscuro';

  @override
  String get language => 'Idioma';

  @override
  String get systemLanguage => 'Idioma del sistema';

  @override
  String get general => 'General';

  @override
  String get ui => 'Interfaz';

  @override
  String get autoLoadProfiles => 'Cargar perfiles automáticamente';

  @override
  String get autoLoadProfilesSubtitle =>
      'Cargar perfiles al seleccionar lector';

  @override
  String get loadProfileIcons => 'Cargar iconos de perfil';

  @override
  String get loadProfileIconsSubtitle =>
      'Obtener iconos de la eUICC (más lento)';

  @override
  String get useNekokoIcons => 'Usar iconos de operador';

  @override
  String get useNekokoIconsSubtitle =>
      'Obtener logos de operador desde operator-icons';

  @override
  String get forceDeviceDropdown => 'Forzar menú desplegable';

  @override
  String get forceDeviceDropdownSubtitle =>
      'Usar siempre lista para elegir dispositivo';

  @override
  String get sizeDisplayUnit => 'Unidad de visualización de tamaño';

  @override
  String get sizeDisplayUnitSubtitle => 'Formato de unidad para almacenamiento';

  @override
  String get phoneFormat => 'Formato de número de teléfono';

  @override
  String get phoneFormatSubtitle => 'Formato para mostrar números';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get notificationSettings => 'Ajustes de notificación';

  @override
  String get notificationSettingsSubtitle =>
      'Configurar procesamiento automático y eliminación';

  @override
  String get notificationHistory => 'Historial de notificaciones';

  @override
  String get notificationHistorySubtitle =>
      'Buscar, administrar y reenviar notificaciones';

  @override
  String get tagsAndReminders => 'Etiquetas y Recordatorios';

  @override
  String get tagManager => 'Gestor de etiquetas';

  @override
  String get tagManagerSubtitle => 'Crear y editar etiquetas de perfil';

  @override
  String get tagReminders => 'Recordatorios de etiquetas';

  @override
  String get tagRemindersSubtitle =>
      'Notificaciones programadas basadas en etiquetas';

  @override
  String get manageTagsAndReminders => 'Gestionar etiquetas y recordatorios';

  @override
  String get manageTagsAndRemindersSubtitle =>
      'Configurar etiquetas, permisos y alertas de prueba';

  @override
  String get viewScheduledReminders => 'Ver recordatorios programados';

  @override
  String get viewScheduledRemindersSubtitle =>
      'Gestionar notificaciones próximas';

  @override
  String get connectivity => 'Conectividad';

  @override
  String get remoteReaders => 'Lectores remotos';

  @override
  String get remoteReadersSubtitle =>
      'Configure las aplicaciones complementarias RemoCard';

  @override
  String get enableBle => 'Conector Bluetooth';

  @override
  String get enableBleSubtitle =>
      'Habilitar el escaneo y la conexión a lectores Bluetooth';

  @override
  String get enableCcid => 'Conector USB CCID';

  @override
  String get enableCcidSubtitle =>
      'Habilitar lectores de tarjetas inteligentes USB (CCID)';

  @override
  String get enableOmapi => 'Conector OMAPI';

  @override
  String get enableOmapiSubtitle =>
      'Habilitar el acceso eUICC integrado a través de OMAPI';

  @override
  String get enableTmapi => 'Conector Telephony API';

  @override
  String get enableTmapiSubtitle =>
      'Habilitar el acceso privilegiado a través de la API Telephony API';

  @override
  String get readerTypes => 'Tipos de Lector';

  @override
  String get readerTypesSubtitle =>
      'Administrar tipos de lector habilitados (CCID, Bluetooth, Remoto, etc.)';

  @override
  String get enabledReaderTypes => 'Tipos de Lector Habilitados';

  @override
  String get enabledReaderTypesSubtitle =>
      'Controlar qué tipos de lectores están disponibles en la aplicación';

  @override
  String get remoteReaderSettings => 'Configuración de Lectores Remotos';

  @override
  String get remoteReaderSettingsSubtitle =>
      'Configurar servidores y conexiones de lectores remotos';

  @override
  String get ccidReaderTitle => 'CCID (USB/PC/SC)';

  @override
  String get ccidReaderSubtitle =>
      'Lectores de tarjetas inteligentes USB y dispositivos PC/SC';

  @override
  String get bluetoothReaderTitle => 'Bluetooth';

  @override
  String get bluetoothReaderSubtitle =>
      'Lectores y escritores de tarjetas inteligentes Bluetooth LE';

  @override
  String get remoteReadersTitle => 'Lectores Remotos';

  @override
  String get remoteReadersConnectorSubtitle =>
      'Lectores de tarjetas inteligentes remotos conectados a la red';

  @override
  String get omapiReaderTitle => 'OMAPI';

  @override
  String get omapiReaderSubtitle =>
      'Ranuras de tarjeta SIM integradas a través de Open Mobile API';

  @override
  String get tmapiReaderTitle => 'Telephony API';

  @override
  String get tmapiReaderSubtitle => 'eSIM integrada a través de Telephony API';

  @override
  String get remoteServerConfiguration => 'Configuración del Servidor Remoto';

  @override
  String get remoteServerConfigurationSubtitle =>
      'Administrar servidores de lectores remotos y configuración de conexión';

  @override
  String get enableBrowser => 'Habilitar Navegador';

  @override
  String get enableBrowserSubtitle =>
      'Mostrar pestañas de navegador adicionales como Tienda, Compra o Ayuda';

  @override
  String get transport => 'Transporte';

  @override
  String get disableRefreshFlags => 'Desactivar indicadores de actualización';

  @override
  String get disableRefreshFlagsSubtitle => 'No se aplica a lectores externos';

  @override
  String get apduMaxSegmentSize => 'Tamaño máx. segmento APDU';

  @override
  String get apduMaxSegmentSizeSubtitle =>
      'Tamaño máximo de datos por bloque APDU';

  @override
  String get ensureSingleChannel => 'Ensure Single Channel';

  @override
  String get ensureSingleChannelSubtitle =>
      'Close other logical channels before opening a new one';

  @override
  String get analytics => 'Análisis y servicios en la nube';

  @override
  String get nekokoCloud => 'Nekoko Cloud';

  @override
  String get nekokoCloudSubtitle => 'Analizar datos de instalación';

  @override
  String get developer => 'Desarrollador';

  @override
  String get developerMode => 'Modo desarrollador';

  @override
  String get developerModeSubtitle =>
      'Habilitar funciones avanzadas de depuración';

  @override
  String get exportDatabase => 'Exportar base de datos';

  @override
  String get exportDatabaseSubtitle => 'Guardar copia de base de datos local';

  @override
  String get openDatabaseFolder => 'Abrir carpeta de base de datos';

  @override
  String get openDatabaseFolderSubtitle =>
      'Abrir carpeta que contiene el archivo DB';

  @override
  String get decodeAsn1 => 'Decodificar registros ASN.1 (Lento)';

  @override
  String get decodeAsn1Subtitle => 'Impacta fuertemente el rendimiento';

  @override
  String get viewAppLogs => 'Ver registros de la app';

  @override
  String get viewAppLogsSubtitle => 'Ver registros recopilados';

  @override
  String get about => 'Acerca de';

  @override
  String get version => 'Versión';

  @override
  String get build => 'Compilación';

  @override
  String get checkUpdates => 'Buscar actualizaciones';

  @override
  String get checkUpdatesSubtitle => 'Buscar versiones nuevas al iniciar';

  @override
  String get licenses => 'Open Source Licenses';

  @override
  String get licensesSubtitle =>
      'License information for open source libraries used';

  @override
  String get noUpdatesFound => 'No updates found';

  @override
  String get profilesTitle => 'Perfiles';

  @override
  String get switchEstkSlot => 'Cambiar ranura eSTK';

  @override
  String get notificationsButton => 'Notificaciones';

  @override
  String get downloadProfile => 'Descargar perfil';

  @override
  String get reconnect => 'Reconectar';

  @override
  String get bluetoothNotConnected => 'Bluetooth No Conectado';

  @override
  String get bluetoothNotConnectedSubtitle =>
      'Asegúrese de que el Bluetooth esté activado y el dispositivo esté cerca. Toque conectar para comenzar a usar este dispositivo.';

  @override
  String get bluetoothConnectionFailed => 'Error de Conexión Bluetooth';

  @override
  String bluetoothConnectionFailedSubtitle(Object error) {
    return 'No se pudo conectar al dispositivo Bluetooth.\n\n$error';
  }

  @override
  String get removeDevice => 'Eliminar Dispositivo';

  @override
  String get retryConnection => 'Conectar conexión';

  @override
  String get remoteConnectionFailed => 'Error conexión lector remoto';

  @override
  String remoteConnectionFailedMessage(Object error) {
    return 'Asegúrese de que el servidor remoto esté funcionando y sea accesible.\n\n$error';
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
  String get changeSettings => 'Cambiar ajustes';

  @override
  String get connectCompatibleReader =>
      'Conecte un lector compatible para comenzar.';

  @override
  String get connectReaderMessageBle =>
      'Puede escanear dispositivos Bluetooth si tiene una eUICC compatible.';

  @override
  String get connectReaderMessageNoBle =>
      'Asegúrese de que su lector CCID est connecté al ordenador.';

  @override
  String get downloadSmartCardExtension => 'Descargar extensión Smart Card';

  @override
  String get smartCardExtensionMessage =>
      'La extensión es necesaria para acceder a lectores USB CCID en este navegador.';

  @override
  String get scanForBluetooth => 'Escanear Bluetooth';

  @override
  String get connectRemote => 'Conectar remoto';

  @override
  String get noCardDetected => 'No se detectó tarjeta';

  @override
  String get noCardDetectedMessage =>
      'No se encontró eUICC compatible o activa en esta ranura.';

  @override
  String get noDataLoaded => 'No conectado';

  @override
  String get loadProfiles => 'Conectar';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get disconnecting => 'Desconectando...';

  @override
  String get profilesEmpty => 'Sin perfiles en la tarjeta';

  @override
  String get profilesEmptyMessage => 'Esta tarjeta eUICC está vacía.';

  @override
  String get renameProfile => 'Renombrar perfil';

  @override
  String get nickname => 'Apodo';

  @override
  String get enterProfileNickname => 'Introducir apodo del perfil';

  @override
  String get profileNicknameNote =>
      'Nota: Las etiquetas se gestionan por separado en el menú \'Gestor de etiquetas\'.';

  @override
  String get useProfileIcon => 'Usar icono del perfil';

  @override
  String get useProfileIconSubtitle => 'Icono de la tarjeta eSIM';

  @override
  String get removeCustomIcon => 'Eliminar icono personalizado';

  @override
  String get noRemoteIcon => 'No hay icono remoto para este operador';

  @override
  String get cancel => 'Cancelar';

  @override
  String get ok => 'Aceptar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get refresh => 'Actualizar';

  @override
  String get initializing => 'Inicializando...';

  @override
  String get refreshingProfiles => 'Actualizando perfiles...';

  @override
  String get retrievingEid => 'Recuperando EID e información...';

  @override
  String get updatingProfile => 'Actualizando perfil...';

  @override
  String get manageIsdR => 'Gestionar AID ISD-R';

  @override
  String get manageIsdRSubtitle =>
      'Configurar ID de aplicación predeterminados para eUICC';

  @override
  String get transportFailed => 'Fallo de transporte';

  @override
  String get remoteTransportFailedMessage =>
      'Conectado al servidor remoto, pero el comando falló. Esto suele significar que el dispositivo remoto está momentáneamente ocupado o desconectado de la tarjeta. ¿Desea reintentar?';

  @override
  String get retry => 'Reintentar';

  @override
  String get scanningForReaders => 'Buscando lectores...';

  @override
  String get switchedEstkSlot => 'Ranura eSTK cambiada';

  @override
  String get scanningForUnresponsiveDevices =>
      'Buscando dispositivos que no responden...';

  @override
  String get resettingConnection => 'Restableciendo conexión...';

  @override
  String get connectingToReader => 'Conectando al lector...';

  @override
  String get moreOptions => 'Más opciones';

  @override
  String get retrievingProfiles => 'Recuperando perfiles...';

  @override
  String get savingProfileMetadata => 'Guardando metadatos del perfil...';

  @override
  String get enablingProfile => 'Activando perfil...';

  @override
  String get disablingProfile => 'Desactivando perfil...';

  @override
  String get deleteProfile => 'Eliminar perfil';

  @override
  String deleteProfileConfirmation(Object profileName) {
    return '¿Está seguro de que desea eliminar el perfil $profileName?\nEsta acción es irreversible.';
  }

  @override
  String get deletingProfile => 'Eliminando perfil...';

  @override
  String get deleting => 'Deleting...';

  @override
  String get dataUsage => 'Uso de datos';

  @override
  String get details => 'Detalles';

  @override
  String get rename => 'Renombrar';

  @override
  String get changeIcon => 'Cambiar icono';

  @override
  String get manageTags => 'Gestionar etiquetas';

  @override
  String get copyIccid => 'Copiar ICCID';

  @override
  String get notificationProcessingError =>
      'No se pueden realizar operaciones mientras se procesan las notificaciones';

  @override
  String get operationInProgressError => 'Operation in progress, please wait';

  @override
  String iccidCopied(Object iccid) {
    return 'ICCID copiado: $iccid';
  }

  @override
  String get operationRestricted => 'Operación restringida';

  @override
  String get notificationProcessingDownloadError =>
      'Las notificaciones aún se están procesando. Espere hasta que se completen antes de descargar nuevos perfiles.';

  @override
  String get operational => 'Operacional';

  @override
  String get test => 'Prueba';

  @override
  String get provisioning => 'Aprovisionamiento';

  @override
  String get profileDetails => 'Detalles del perfil';

  @override
  String get profileDetailsSubtitle =>
      'Información del eUICC para esta ranura de perfil.';

  @override
  String get enabled => 'Activado';

  @override
  String get disabled => 'Desactivado';

  @override
  String get tagsManagedSeparately =>
      'Nota: Las etiquetas se gestionan por separado a través del menú \'Gestionar etiquetas\'.';

  @override
  String get changeProfileIcon => 'Cambiar icono del perfil';

  @override
  String get selectFromGallery => 'Seleccionar de la galería';

  @override
  String get nekokoOperatorIcon => 'Icono de operador';

  @override
  String get iconFromEsim => 'Icono de la tarjeta eSIM';

  @override
  String updateIconFailed(Object error) {
    return 'Error al actualizar el icono: $error';
  }

  @override
  String get failedToReadImage => 'Error al leer el archivo de imagen';

  @override
  String get failedToProcessImage => 'Error al procesar la imagen';

  @override
  String get customIconSet => 'Icono personalizado establecido con éxito';

  @override
  String get noMccMnc => 'No hay MCC/MNC disponible para este perfil';

  @override
  String get fetchingRemoteIcon => 'Obteniendo icono remoto...';

  @override
  String get remoteIconSaved =>
      'Icono remoto guardado como icono personalizado';

  @override
  String fetchRemoteIconFailed(Object error) {
    return 'Error al obtener el icono remoto: $error';
  }

  @override
  String get noProfileIcon => 'No hay icono de perfil disponible';

  @override
  String get profileIconSaved =>
      'Icono de perfil guardado como icono personalizado';

  @override
  String get customIconRemoved => 'Icono personalizado eliminado';

  @override
  String get failed => 'Falló';

  @override
  String euiccError(Object action) {
    return 'El eUICC devolvió un error al intentar $action el perfil.';
  }

  @override
  String get dismiss => 'Descartar';

  @override
  String get dataPlan => 'Plan de datos';

  @override
  String get used => 'usado';

  @override
  String get total => 'total';

  @override
  String expires(Object date) {
    return 'Expira el: $date';
  }

  @override
  String get close => 'Cerrar';

  @override
  String get server => 'Servidor';

  @override
  String get switchFailed => 'Fallo al cambiar';

  @override
  String get deviceRefreshFailed => 'Fallo al actualizar el dispositivo';

  @override
  String get euiccOptions => 'Opciones eUICC';

  @override
  String get euiccInfo => 'Información eUICC';

  @override
  String get hideEid => 'Ocultar EID';

  @override
  String get showEid => 'Mostrar EID';

  @override
  String get copyEid => 'Copiar EID';

  @override
  String get eidCopied => 'EID copiado al portapapeles';

  @override
  String get connectRemotes => 'Conectar remotos';

  @override
  String get configureRemotes => 'Configurar remotos';

  @override
  String get connectingToRemoteReaders =>
      'Conectando a lectores remotos en segundo plano...';

  @override
  String get noRemoteReadersFound => 'No se encontraron lectores remotos';

  @override
  String connectedRemoteReaders(Object count) {
    return 'Conectado $count lector(es) remoto(s)';
  }

  @override
  String failedToConnectRemoteReaders(Object error) {
    return 'Error al conectar lectores remotos: $error';
  }

  @override
  String get remoteReaderPassword => 'Contraseña del lector remoto';

  @override
  String get remoteReaderPasswordSubtitle =>
      'Este lector remoto requiere una contraseña.';

  @override
  String get password => 'Contraseña';

  @override
  String get deleteConnection => 'Eliminar conexión';

  @override
  String get connect => 'Conectar';

  @override
  String get remoteReaderConnectionFailed =>
      'Error de conexión del lector remoto';

  @override
  String remoteReaderConnectionFailedSubtitle(Object error) {
    return 'Asegúrese de que el servidor remoto esté funcionando y sea accesible.\n\n$error';
  }

  @override
  String get connectReader => 'Conecte un lector compatible para comenzar.';

  @override
  String get connectReaderSubtitleBle =>
      'También puede buscar dispositivos Bluetooth compatibles si tiene un eUICC habilitado para Bluetooth.';

  @override
  String get connectReaderSubtitleCcid =>
      'Asegúrese de que su lector CCID esté conectado al ordenador.';

  @override
  String get downloadExtension => 'Descargar extensión de Smart Card';

  @override
  String get downloadExtensionSubtitle =>
      'La extensión es necesaria para acceder a lectores USB CCID en este navegador.';

  @override
  String get cardUnsupported => 'Tarjeta no compatible';

  @override
  String get cardUnsupportedSubtitle =>
      'Es probable que esta tarjeta no sea un eUICC, o no sea compatible con este lector, o esté siendo usada por otros.';

  @override
  String get omapiWelcome =>
      '¡Buenas noticias! Su dispositivo tiene soporte OMAPI y es muy probable que sea compatible con tarjetas extraíbles.';

  @override
  String get supportedDevices => 'Dispositivos compatibles';

  @override
  String get aboutAram => 'Acerca de ARA-M';

  @override
  String get accessDenied => 'Acceso denegado';

  @override
  String get accessDeniedSubtitle =>
      'Se requieren privilegios de operador para acceder a este eUICC. La lista blanca ARA-M de la tarjeta no coincide con la firma de la aplicación.';

  @override
  String get noCardDetectedSubtitle =>
      'No se encontró ningún eUICC no compatible o activo en esta ranura.';

  @override
  String get noProfilesInstalled => 'No hay perfiles instalados';

  @override
  String get noProfilesInstalledSubtitle => 'Esta tarjeta eUICC está vacía.';

  @override
  String get cardRefreshingTitle => 'Card is Refreshing';

  @override
  String get cardRefreshingMessage =>
      'The card is currently updating its state. Profile list cannot be retrieved at this moment. Please wait a few seconds and then try again.';

  @override
  String get useRemoteIcon => 'Usar icono remoto';

  @override
  String get bleDisconnectedTitle => 'Bluetooth Connection Lost';

  @override
  String get bleDisconnectedMessage =>
      'The connection to the card reader was suddenly lost. Please ensure it is nearby and turned on.';

  @override
  String get cardStuckRefreshingMessage =>
      'Profile state change ongoing - try manually re-plug the SIM card if it stucks.';

  @override
  String get activationCodeTitle => 'Código de activación';

  @override
  String get activationCodeSubtitle =>
      'Escanee un código QR, arrastre una imagen o ingrese manualmente la cadena LPA.';

  @override
  String get fullActivationCodeLabel => 'Código de activación completo';

  @override
  String get fullActivationCodeHint => 'LPA:1\$smdp.io\$MATCHING-ID';

  @override
  String get pasteFromClipboardTooltip => 'Pegar desde el portapapeles';

  @override
  String get selectFromGalleryTooltip => 'Seleccionar de la galería';

  @override
  String get scanQrCodeTooltip => 'Escanear código QR';

  @override
  String get smdpAddressLabel => 'Dirección SM-DP+';

  @override
  String get smdpAddressHint => 'smdp.io';

  @override
  String get matchingIdLabel => 'ID de coincidencia';

  @override
  String get matchingIdHint => 'ABC-123';

  @override
  String get smdpOidLabel => 'OID SM-DP+';

  @override
  String get confirmationCodeLabel => 'Código de confirmación';

  @override
  String get confirmationCodeHint => 'Ingrese código de confirmación';

  @override
  String get continueButton => 'Continuar';

  @override
  String get invalidLpaClipboard =>
      'El portapapeles no contiene una cadena LPA válida.';

  @override
  String get invalidFqdnFormat => 'Formato FQDN no válido';

  @override
  String get invalidMatchingIdChars =>
      'El ID de coincidencia contiene caracteres no válidos';

  @override
  String get invalidOidFormat => 'Formato OID no válido (p. ej., 1.2.840...)';

  @override
  String get activationCodeRequired => 'El código de activación es obligatorio';

  @override
  String get invalidLpaFormatGeneric => 'Formato LPA no válido';

  @override
  String get smdpAddressRequired => 'La dirección SM-DP+ es obligatoria';

  @override
  String get loadingNotifications => 'Cargando notificaciones...';

  @override
  String get processing => 'Procesando...';

  @override
  String get analyzingImage => 'Analizando imagen...';

  @override
  String get noQrFoundInImage => 'No se encontró ningún código QR en la imagen';

  @override
  String get invalidAcInImage => 'Código de activación no válido en la imagen';

  @override
  String get invalidAcFormatDetailed =>
      'Formato de código de activación no válido. Debe comenzar con LPA:1\$...';

  @override
  String get downloadProfileTitle => 'Descargar perfil';

  @override
  String get connectingToEuicc => 'Conectando al eUICC...';

  @override
  String get gettingChallenge => 'Obteniendo desafío eUICC...';

  @override
  String get authenticatingWithSmdp => 'Autenticando con SM-DP+...';

  @override
  String get verifyingSignatures => 'Verificando firmas SM-DP+...';

  @override
  String get retrievingMetadata => 'Obteniendo metadatos del perfil...';

  @override
  String get preparingDownload => 'Preparando descarga...';

  @override
  String get preparingEuicc => 'Preparando eUICC...';

  @override
  String get fetchingProfilePackage => 'Obteniendo paquete del perfil...';

  @override
  String installing(Object sent, Object total) {
    return 'Instalando ($sent / $total bytes)...';
  }

  @override
  String get finalizing =>
      'Finalizando (actualizando información de almacenamiento)...';

  @override
  String get profileInstalledSuccessfully => '¡Perfil instalado con éxito!';

  @override
  String get provider => 'Proveedor';

  @override
  String get iccid => 'ICCID';

  @override
  String get plmn => 'PLMN';

  @override
  String get storage => 'Almacenamiento';

  @override
  String get free => 'Libre';

  @override
  String get nvram => 'NVRAM';

  @override
  String get exportCertificates => 'Exportar certificados';

  @override
  String get euiccCert => 'Cert. eUICC';

  @override
  String get eumCert => 'Cert. EUM';

  @override
  String get enterConfirmationCode =>
      'Ingrese el código requerido por su operador';

  @override
  String get confirmationCodeRequired =>
      'El código de confirmación es obligatorio';

  @override
  String get download => 'Descargar';

  @override
  String get installationSuccessful => 'Instalación exitosa';

  @override
  String get installationSuccessMessage =>
      'El perfil se ha instalado correctamente en su eUICC.';

  @override
  String get consumed => 'Consumido';

  @override
  String get enableProfileNow => 'Activar perfil ahora';

  @override
  String get done => 'Hecho';

  @override
  String get profileEnabledSuccessfully => 'Perfil activado con éxito';

  @override
  String get enterNewProfileName =>
      'Ingrese un nuevo nombre para este perfil para ayudarlo a identificarlo más fácilmente.';

  @override
  String get profileName => 'Nombre del perfil';

  @override
  String get profileNameHint => 'ej. Viaje de trabajo';

  @override
  String get profileRenamedSuccessfully => 'Perfil renombrado con éxito';

  @override
  String get downloadFailed => 'Fallo en la descarga';

  @override
  String get tryAgain => 'Intentar de nuevo';

  @override
  String get savedSuccessfully => 'Guardado con éxito';

  @override
  String get saveCertificate => 'Guardar certificado';

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
      'Para mantener la compatibilidad entre versiones de Android, añade todos los hashes SHA-1 de certificados que aparecen a continuación a las reglas ARA-M de la tarjeta. Tras actualizar la clave de firma de la aplicación, distintas versiones de Android pueden comprobar certificados diferentes del historial de firma verificado.';

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
  String get unknownProfile => 'Perfil Desconocido';

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
  String get connectionFailed => 'Conexión fallida';

  @override
  String get downloadRemoCard => 'Descargar RemoCard';

  @override
  String get remoCardAndroidApp => 'Aplicación Android para controles remotos';

  @override
  String get resentSuccessfully => 'Reenviado con éxito';

  @override
  String get resendFailed => 'Error al reenviar';

  @override
  String get eid => 'EID';

  @override
  String get seq => 'Secuencia';

  @override
  String get date => 'Fecha';

  @override
  String errorWithDetails(String error) {
    return 'Error: $error';
  }

  @override
  String exportFailed(String error) {
    return 'Error al exportar: $error';
  }

  @override
  String get sasAccreditation => 'Acreditación SAS';

  @override
  String get firmwareVersion => 'Versión del firmware';

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
  String get platformSupport => 'SOPORTE DE PLATAFORMA';

  @override
  String get rspVersion => 'Versión RSP';

  @override
  String get bppVersion => 'Versión BPP';

  @override
  String get gpVersion => 'Versión GlobalPlatform';

  @override
  String get certInfrastructure => 'INFRAESTRUCTURA DE CERTIFICADOS';

  @override
  String get euiccSignCi => 'CI de firma eUICC';

  @override
  String get euiccVerifyCi => 'CI de verificación eUICC';

  @override
  String get none => 'Ninguno';

  @override
  String keysCount(int count) {
    return '$count clave(s)';
  }

  @override
  String get state => 'Estado';

  @override
  String get profileClass => 'Clase';

  @override
  String get aid => 'AID';

  @override
  String get euiccSpecifications => 'ESPECIFICACIONES EUICC';

  @override
  String get sending => 'Enviando...';

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
  String get pending => 'Pendiente';

  @override
  String get notifTypeInstall => 'Instalar';

  @override
  String get notifTypeDelete => 'Eliminar';

  @override
  String get notifTypeEnable => 'Habilitar';

  @override
  String get notifTypeDisable => 'Deshabilitar';

  @override
  String get notifTypeRpmEnable => 'RPM Habilitar';

  @override
  String get notifTypeRpmDisable => 'RPM Deshabilitar';

  @override
  String get notifTypeRpmDelete => 'RPM Eliminar';

  @override
  String get notifTypeLoadRpm => 'Cargar RPM';

  @override
  String confirmDeleteNotification(int seq) {
    return '¿Está seguro de que desea eliminar la notificación #$seq?';
  }

  @override
  String get notificationRemoved => 'Notificación eliminada';

  @override
  String failedToRemove(String error) {
    return 'Error al eliminar: $error';
  }

  @override
  String get curlCopied => 'Comando cURL copiado al portapapeles';

  @override
  String failedToGenerateCurl(String error) {
    return 'Error al generar cURL: $error';
  }

  @override
  String get noNotificationAddress =>
      'No hay dirección de notificación disponible';

  @override
  String get sendingNotification => 'Enviando notificación...';

  @override
  String get notifSentSuccessfully => 'Notificación enviada con éxito';

  @override
  String get failedToSendNotification => 'Error al enviar la notificación';

  @override
  String errorSendingNotification(String error) {
    return 'Error enviando notificación: $error';
  }

  @override
  String pendingCount(int count) {
    return '$count pendientes';
  }

  @override
  String get currentReader => 'Lector Actual';

  @override
  String get errorLoadingNotifications => 'Error cargando notificaciones';

  @override
  String get allCaughtUp => 'Estás al día';

  @override
  String get sequence => 'Secuencia';

  @override
  String get operation => 'Operación';

  @override
  String get profileNameLabel => 'Nombre del Perfil';

  @override
  String get failedToSend => 'Fallo al enviar';

  @override
  String get onCard => 'En tarjeta';

  @override
  String get sendNotification => 'Enviar notificación';

  @override
  String get deleteNotification => 'Eliminar notificación';

  @override
  String get noNotifications => 'No hay notificaciones';

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
  String get manage => 'Gestionar';

  @override
  String get buyCard => 'Tarjeta';

  @override
  String get buyData => 'Datos';

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
  String get estimatedDownloadSize => 'Tamaño de descarga estimado';

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
      'Espacio de almacenamiento insuficiente para la instalación. La instalación podría fallar.';

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
