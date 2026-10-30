// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get addBluetoothReader => 'Add Bluetooth reader';

  @override
  String get bluetoothSetupFailed =>
      'Unable to set up the Bluetooth reader. Check that Bluetooth is on and the reader is nearby, then try again.';

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
  String get customDesign => 'Estilo Nekoko';

  @override
  String get stockMD3 => 'MD3 estándar';

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
  String get useNekokoIcons => 'Usar iconos de Nekoko Cloud';

  @override
  String get useNekokoIconsSubtitle => 'Obtener logos de operador de Nekoko';

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
  String get ensureSingleChannel => 'Garantizar un solo canal';

  @override
  String get ensureSingleChannelSubtitle =>
      'Cerrar los demás canales lógicos antes de abrir uno nuevo';

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
  String get licenses => 'Licencias de código abierto';

  @override
  String get licensesSubtitle =>
      'Información de licencia de las bibliotecas de código abierto utilizadas';

  @override
  String get noUpdatesFound => 'No se encontraron actualizaciones';

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
      'Se agotó el tiempo de espera de la operación Bluetooth. Inténtelo de nuevo.';

  @override
  String get errorOmapiSecurity =>
      'Error de seguridad: el sistema operativo o las reglas ARA-M denegaron el acceso a la tarjeta.';

  @override
  String get errorApplicationNotFound =>
      'No se encontró la aplicación de gestión de eUICC (ISD-R). Puede que esta tarjeta no sea una eUICC válida.';

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
      'Asegúrese de que su lector CCID esté conectado al ordenador.';

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
  String get deleting => 'Eliminando...';

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
  String get operationInProgressError =>
      'Operación en curso, espere un momento';

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
  String get nekokoOperatorIcon => 'Icono de operador Nekoko';

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
  String get cardRefreshingTitle => 'La tarjeta se está actualizando';

  @override
  String get cardRefreshingMessage =>
      'La tarjeta está actualizando su estado. No se puede obtener la lista de perfiles en este momento. Espere unos segundos e inténtelo de nuevo.';

  @override
  String get useRemoteIcon => 'Usar icono remoto';

  @override
  String get bleDisconnectedTitle => 'Conexión Bluetooth perdida';

  @override
  String get bleDisconnectedMessage =>
      'Se perdió repentinamente la conexión con el lector de tarjetas. Asegúrese de que esté cerca y encendido.';

  @override
  String get cardStuckRefreshingMessage =>
      'Cambio de estado del perfil en curso: si se bloquea, vuelva a insertar manualmente la tarjeta SIM.';

  @override
  String get cardNeedsReplugTitle => 'Vuelva a insertar la tarjeta SIM';

  @override
  String get cardNeedsReplugMessage =>
      'La tarjeta no cede su applet eUICC, por lo que no se puede gestionar en este momento. Retire la tarjeta SIM, vuelva a insertarla e inténtelo de nuevo.';

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
  String get vowifi => 'VoWiFi';

  @override
  String get vowifiSubtitle =>
      'Experimental; requiere un lector externo compatible';

  @override
  String get vowifiDisclaimerTitle => '¿Activar VoWiFi experimental?';

  @override
  String get vowifiDisclaimerBody =>
      'VoWiFi es experimental. Se comunica directamente con su operador de red móvil y solo funciona con un lector SIM/eSIM externo compatible que admita APDU sin procesar. La compatibilidad con operadores y lectores puede variar.';

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
  String get searchingForReaders => 'Buscando lectores...';

  @override
  String get initializationError => 'Error de inicialización';

  @override
  String get noReadersFound => 'No se encontraron lectores';

  @override
  String get noReadersFoundMessage =>
      'Inserte un lector compatible o busque dispositivos BLE para gestionar sus perfiles eSIM.';

  @override
  String get scanBle => 'Buscar por BLE';

  @override
  String get reminderDetails => 'Detalles del recordatorio';

  @override
  String get profileNotFound => 'Perfil no encontrado';

  @override
  String get resending => 'Reenviando...';

  @override
  String get noAddressInNotification =>
      'No hay dirección en los datos de la notificación';

  @override
  String get sentSuccessfully => 'Enviado correctamente';

  @override
  String get sendFailed => 'Error al enviar';

  @override
  String get copiedCurl => 'Comando cURL copiado al portapapeles';

  @override
  String get noAddressToExport => 'No hay dirección para exportar';

  @override
  String get noHistoryAvailable => 'No hay historial disponible';

  @override
  String get searchByIccid => 'Buscar por ICCID...';

  @override
  String get resendNotification => 'Reenviar notificación';

  @override
  String get exportAsCurl => 'Exportar como cURL';

  @override
  String get viewDetails => 'Ver detalles';

  @override
  String get deleteEntry => 'Eliminar entrada';

  @override
  String activeReminders(int count) {
    return '$count recordatorios activos';
  }

  @override
  String get noScheduledReminders => 'No hay recordatorios programados';

  @override
  String get remindersAppearWhen =>
      'Los recordatorios aparecen cuando añade etiquetas de fecha a los perfiles.';

  @override
  String activeTagsCount(int count) {
    return '$count etiquetas activas en todos los perfiles';
  }

  @override
  String get searchTagsOrProfiles => 'Buscar etiquetas o perfiles...';

  @override
  String get noTagsFound => 'No se encontraron etiquetas';

  @override
  String get addTagsFromProfileMenu =>
      'Añada etiquetas a sus perfiles desde el menú de edición para verlas aquí.';

  @override
  String get expired => 'Caducado';

  @override
  String daysLeft(int count) {
    return '$count d restantes';
  }

  @override
  String hoursLeft(int count) {
    return '$count h restantes';
  }

  @override
  String get expiresSoon => 'Caduca pronto';

  @override
  String get soon => 'pronto';

  @override
  String get activeTags => 'Etiquetas activas';

  @override
  String get addNewTag => 'Añadir etiqueta';

  @override
  String get noTagsAssigned => 'No hay etiquetas asignadas a este perfil';

  @override
  String get textTagHint => 'Etiqueta de texto (p. ej. Trabajo, Viaje)';

  @override
  String get addDateExpiryTag => 'Añadir etiqueta de fecha/caducidad';

  @override
  String get addNoteOptional => 'Añadir nota (opcional)';

  @override
  String get add => 'Añadir';

  @override
  String get noteHint => 'p. ej. Caducidad, 10 GB, etc.';

  @override
  String get invalidHexString => 'Cadena hexadecimal no válida';

  @override
  String get resetToDefaults => 'Restablecer valores predeterminados';

  @override
  String get resetToDefaultsSuccess => 'Valores predeterminados restablecidos';

  @override
  String get addAidHex => 'Añadir AID (hex)';

  @override
  String get manageAutoNotif =>
      'Gestionar el procesamiento automático de notificaciones';

  @override
  String get automaticProcessing => 'PROCESAMIENTO AUTOMÁTICO';

  @override
  String get notifProcessingInfo =>
      'Procesar las notificaciones facilita la sincronización entre su eUICC y el servidor SM-DP+ (operador). Eliminar las notificaciones enviadas mantiene limpio el almacenamiento de la tarjeta.';

  @override
  String get enabling => 'Activación';

  @override
  String get afterEnabling => 'Tras activar un perfil';

  @override
  String get disabling => 'Desactivación';

  @override
  String get afterDisabling => 'Tras desactivar un perfil';

  @override
  String get installation => 'Instalación';

  @override
  String get afterDownload => 'Tras descargar un perfil';

  @override
  String get deletion => 'Eliminación';

  @override
  String get afterDeletion => 'Tras eliminar un perfil';

  @override
  String get autoSend => 'Envío automático';

  @override
  String get autoSendSubtitle => 'Enviar al servidor automáticamente';

  @override
  String get autoRemove => 'Eliminación automática';

  @override
  String get autoRemoveSubtitle => 'Eliminar de la tarjeta tras el envío';

  @override
  String get removeWithoutSending => 'Eliminar sin enviar';

  @override
  String get removeWithoutSendingSubtitle =>
      'Úselo con precaución: no se notificará al servidor';

  @override
  String get permissionsActive => 'Permisos activos';

  @override
  String get permissionsRequired => 'Permisos necesarios';

  @override
  String get appCanSendNotif =>
      'La aplicación puede enviar notificaciones del sistema';

  @override
  String get requiredForReminders =>
      'Necesario para las alertas de recordatorio';

  @override
  String get unsupportedPlatformCheck =>
      'La comprobación de permisos no es compatible con esta plataforma. Realice una prueba manual.';

  @override
  String get couldNotVerifyStatus =>
      'No se pudo verificar el estado. Consulte los Ajustes manualmente.';

  @override
  String get testNotificationTitle => 'Notificación de prueba';

  @override
  String get seconds => 'segundos';

  @override
  String get startTest => 'Iniciar prueba';

  @override
  String get sendingNotif => 'Enviando...';

  @override
  String get hostIpLabel => 'Nombre de host / IP';

  @override
  String get portLabel => 'Puerto';

  @override
  String get passwordOptionalLabel => 'Contraseña (opcional)';

  @override
  String get configuredServers => 'Servidores configurados';

  @override
  String get secureHttps => 'Seguro (HTTPS)';

  @override
  String get insecureHttp => 'No seguro (HTTP)';

  @override
  String get urlCopied => 'URL copiada';

  @override
  String get serverAddedSuccessfully => 'Servidor añadido correctamente';

  @override
  String get authFailedCheckPassword =>
      'Error de autenticación. Compruebe la contraseña.';

  @override
  String get addNewServer => 'Añadir servidor';

  @override
  String get autoLoadRemotes => 'Cargar dispositivos remotos automáticamente';

  @override
  String get autoLoadRemotesSubtitle =>
      'Conectarse automáticamente a los servidores configurados al iniciar la aplicación';

  @override
  String get getRemoCardGitHub => 'Obtener RemoCard en GitHub';

  @override
  String get instructions => 'Instrucciones:';

  @override
  String get instruction1 =>
      '1. Instale la aplicación RemoCard en sus dispositivos Android.';

  @override
  String get instruction2 =>
      '2. Inicie el servidor en cada aplicación RemoCard.';

  @override
  String get instruction3 => '3. Introduzca aquí las direcciones IP.';

  @override
  String get instruction4 =>
      '4. Todas las ranuras SIM remotas aparecerán en la lista de dispositivos.';

  @override
  String get appLogsCopied => 'Registros copiados al portapapeles';

  @override
  String get aramInfoTitle => 'Información de ARA-M';

  @override
  String get aramInfoSubtitle => 'Detalles del Access Rule Applet';

  @override
  String get whatIsAram => '¿Qué es ARA-M?';

  @override
  String get aramDescription =>
      'El Access Rule Applet (ARA-M) es un mecanismo presente en las eUICC (eSIM) y las tarjetas SIM que define qué aplicaciones pueden gestionar perfiles o realizar operaciones de bajo nivel. Si el hash de la aplicación no está en la lista de permitidos ARA-M de la tarjeta, el sistema Android bloqueará el acceso y se producirá un error de «Acceso denegado».';

  @override
  String get appCertHashes => 'Hashes del certificado de la aplicación';

  @override
  String get aramHashInstruction =>
      'Para conceder acceso a esta aplicación, puede que tenga que añadir el siguiente hash de certificado SHA-1 a las reglas ARA-M de su tarjeta. Este hash es exclusivo del certificado de su versión actual de la aplicación.';

  @override
  String get aramSigningHistoryInstruction =>
      'Para garantizar la compatibilidad entre versiones de Android, añada todos los hashes de certificado SHA-1 siguientes a las reglas ARA-M de su tarjeta. Tras cambiar la clave de firma, distintas versiones de Android pueden comprobar certificados diferentes del historial de firma verificado.';

  @override
  String get certSha1Hash => 'Hash SHA-1 del certificado';

  @override
  String get unavailable => 'No disponible';

  @override
  String get troubleshooting => 'Solución de problemas';

  @override
  String get troubleStep1 =>
      'Asegúrese de estar usando el lector de tarjetas correcto.';

  @override
  String get troubleStep2 =>
      'Si usa una tarjeta física, compruebe si es una tarjeta de prueba o de producción (las de producción suelen bloquear ARA-M).';

  @override
  String get troubleStep3 =>
      'Los hashes anteriores dependen de si usa la versión Debug, Regular o Privileged (Magisk) de la aplicación.';

  @override
  String get troubleStep4 =>
      'Considere usar la versión Privileged (Magisk), que puede eludir algunas restricciones de las API de Android.';

  @override
  String get hashCopied => 'Hash copiado al portapapeles';

  @override
  String get aidCopied => 'AID copiado al portapapeles';

  @override
  String get lastSeen => 'Última detección';

  @override
  String get unknownProvider => 'Proveedor desconocido';

  @override
  String get unknownProfile => 'Perfil Desconocido';

  @override
  String get tags => 'Etiquetas';

  @override
  String get noTags => 'Sin etiquetas';

  @override
  String records(int count) {
    return '$count registros';
  }

  @override
  String get bytes => 'bytes';

  @override
  String get responseCode => 'Código de respuesta';

  @override
  String get responseBody => 'Cuerpo de la respuesta';

  @override
  String get type => 'Tipo';

  @override
  String profileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count perfiles',
      one: '1 perfil',
    );
    return '$_temp0';
  }

  @override
  String get isdrAids => 'AID de ISD-R';

  @override
  String get configureDefaultAids =>
      'Configurar los identificadores de aplicación predeterminados';

  @override
  String get addAidHexHint => 'Añadir AID (hex)';

  @override
  String get notificationProcessing => 'Notificaciones';

  @override
  String get manageAutoNotification =>
      'Gestionar el procesamiento automático de notificaciones';

  @override
  String get notificationProcessingHelp =>
      'Procesar las notificaciones facilita la sincronización entre su eUICC y el servidor SM-DP+ (operador). Eliminar las notificaciones enviadas mantiene limpio el almacenamiento de la tarjeta.';

  @override
  String get notificationProcessingTimings => 'Momentos de procesamiento';

  @override
  String get notificationProcessingTimingsHelp =>
      'Elija cuándo se ejecuta el procesamiento automático de notificaciones. Algunos momentos críticos para la seguridad solo pueden desactivarse con el modo de desarrollador activado.';

  @override
  String get afterEnablingProfile => 'Tras activar un perfil';

  @override
  String get afterDisablingProfile => 'Tras desactivar un perfil';

  @override
  String get afterProfileDownload => 'Tras descargar un perfil';

  @override
  String get afterProfileDeletion => 'Tras eliminar un perfil';

  @override
  String get initialLoad => 'Carga inicial';

  @override
  String get processNotificationsOnInitialLoad =>
      'Procesar las notificaciones cuando termine la carga de perfiles';

  @override
  String get afterSwitchingProfile => 'Tras cambiar de perfil';

  @override
  String get processNotificationsAfterSwitchingProfile =>
      'Procesar las notificaciones tras activar o desactivar un perfil';

  @override
  String get beforeProfileDownload => 'Antes de descargar un perfil';

  @override
  String get processNotificationsBeforeProfileDownload =>
      'Procesar las notificaciones antes de iniciar la descarga de un perfil';

  @override
  String get afterProfileInstalled => 'Tras instalar un perfil';

  @override
  String get processNotificationsAfterProfileInstalled =>
      'Procesar las notificaciones después de instalar un perfil';

  @override
  String get processNotificationsAfterProfileDeletion =>
      'Procesar las notificaciones después de eliminar un perfil';

  @override
  String get developerModeRequiredToDisableTiming =>
      'Active el modo de desarrollador para desactivar este momento.';

  @override
  String get sendToServerAutomatically => 'Enviar al servidor automáticamente';

  @override
  String get removeFromCardAfterSending =>
      'Eliminar de la tarjeta tras el envío';

  @override
  String get removeWithoutSendingCaution =>
      'Úselo con precaución: no se notificará al servidor';

  @override
  String get reminderSettings => 'Ajustes de recordatorios';

  @override
  String get appCanSendNotifications =>
      'La aplicación puede enviar notificaciones del sistema';

  @override
  String get requiredForReminderAlerts =>
      'Necesario para las alertas de recordatorio';

  @override
  String get enable => 'Activar';

  @override
  String get permissionCheckNotSupported =>
      'La comprobación de permisos no es compatible con esta plataforma. Realice una prueba manual.';

  @override
  String get testNotification => 'Notificación de prueba';

  @override
  String get notificationsDisabledMessage =>
      'Las notificaciones están desactivadas. Actívelas en los ajustes del sistema para recibir recordatorios.';

  @override
  String get openSettings => 'Abrir ajustes';

  @override
  String get applicationLogs => 'Registros de la aplicación';

  @override
  String get refreshReload => 'Actualizar/Recargar';

  @override
  String get toggleAutoScroll =>
      'Activar/desactivar el desplazamiento automático';

  @override
  String get refreshDevices => 'Actualizar dispositivos';

  @override
  String get scanBluetooth => 'Buscar por Bluetooth';

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
  String get beeSimFirmwareAction => 'Actualizar el firmware de BeeSIM';

  @override
  String get beeSimFirmwareTitle => 'Actualización del firmware de BeeSIM';

  @override
  String get beeSimFirmwareWarning =>
      'Hay disponible una actualización del firmware de BeeSIM. Mantenga la tarjeta alimentada, el Bluetooth conectado y la aplicación abierta hasta que termine. Interrumpir la actualización puede dejar la tarjeta temporalmente inutilizable.';

  @override
  String get beeSimFirmwareConfirm => 'Actualizar firmware';

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
  String get configuredAddresses => 'DIRECCIONES CONFIGURADAS';

  @override
  String get defaultSmdpAddress => 'SM-DP+ predeterminado';

  @override
  String get rootDsAddress => 'SM-DS raíz';

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
  String get failedToSaveTags => 'No se pudieron guardar las etiquetas';

  @override
  String get note => 'Nota';

  @override
  String get notificationDetails => 'Detalles de la notificación';

  @override
  String get unknown => 'Desconocido';

  @override
  String get status => 'Estado';

  @override
  String get sent => 'Enviado';

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
  String get batchDownloadTitle => 'Descarga por lotes';

  @override
  String get batchDownloadHint =>
      'Pegue aquí varios códigos LPA (uno por línea, máximo 20)';

  @override
  String foundLpaCodes(int count) {
    return '$count códigos LPA encontrados';
  }

  @override
  String get startBatch => 'Iniciar lote';

  @override
  String get noLpaCodesFound => 'No se encontraron códigos LPA válidos';

  @override
  String get insufficientSpaceStoppingBatch =>
      'Espacio insuficiente. Se detiene la descarga por lotes.';

  @override
  String get exportCsv => 'Exportar a CSV';

  @override
  String get exportedSuccessfully => 'Exportado correctamente';

  @override
  String get exportResults => 'Exportar resultados';

  @override
  String get lpa => 'LPA';

  @override
  String get smdp => 'SM-DP+';

  @override
  String get confirmationCode => 'Código de confirmación';

  @override
  String get size => 'Tamaño';

  @override
  String get message => 'Mensaje';

  @override
  String get remainingSpace => 'Espacio restante';

  @override
  String get stopBatch => 'Detener lote';

  @override
  String get stopping => 'Deteniendo...';

  @override
  String get remove => 'Eliminar';

  @override
  String get updateAvailable => 'Actualización disponible';

  @override
  String updateAvailableSubtitle(String appName, String version, String build) {
    return 'Hay una nueva versión de $appName disponible (v$version b$build). ¿Desea actualizar ahora?';
  }

  @override
  String get updateAction => 'Actualizar';

  @override
  String get later => 'Más tarde';

  @override
  String get changelog => 'Registro de cambios';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get sortIccid => 'ICCID';

  @override
  String get sortCountry => 'País';

  @override
  String get sortAscending => 'Ascendente';

  @override
  String get sortDescending => 'Descendente';

  @override
  String get searchProfiles => 'Buscar perfiles...';

  @override
  String get noProfilesMatch => 'Ningún perfil coincide con su búsqueda.';

  @override
  String get sortDefault => 'Predeterminado';

  @override
  String get sortNickname => 'Apodo';

  @override
  String get showProfileSearch => 'Mostrar la búsqueda de perfiles';

  @override
  String get showProfileSearchSubtitle =>
      'Mostrar la barra de búsqueda y orden en la lista de perfiles';

  @override
  String get noReaderFound =>
      'No se encontró ningún lector. Conecte su adaptador eUICC.';

  @override
  String get readyToInstallProfile => 'Listo para instalar el perfil.';

  @override
  String get downloadHere => 'Descargar aquí';

  @override
  String get manage => 'Gestionar';

  @override
  String get buyCard => 'Tarjeta';

  @override
  String get buyData => 'Datos';

  @override
  String get selectDevice => 'Seleccionar dispositivo';

  @override
  String get selectReaderTitle => 'Seleccionar tarjeta';

  @override
  String get authorizeSigning => 'Autorizar la firma';

  @override
  String get signingDescription =>
      'Un sitio web está solicitando una firma segura a su eUICC.';

  @override
  String get smdpAddress => 'Dirección SM-DP+';

  @override
  String get sign => 'Firmar';

  @override
  String profilesInstalled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count perfiles instalados',
      one: '1 perfil instalado',
    );
    return '$_temp0';
  }

  @override
  String get estimatedDownloadSize => 'Tamaño de descarga estimado';

  @override
  String get phoneFormatInternationalOnly => 'Solo E.164 int.';

  @override
  String get phoneFormatInternationalAndMobile => 'Int. y móvil';

  @override
  String get phoneFormatInternationalAndAll => 'Int. y nacional';

  @override
  String get phoneFormatOff => 'Desactivado';

  @override
  String get settings_item_unit_b => 'Bytes';

  @override
  String get settings_item_unit_kb => 'kB (1000 bytes)';

  @override
  String get settings_item_unit_kib => 'kiB (1024 bytes)';

  @override
  String get settings_item_unit_adaptive_si => 'B / kB adaptativo';

  @override
  String get settings_item_unit_adaptive_bi => 'B / kiB adaptativo';

  @override
  String get insufficientStorageWarning =>
      'Espacio de almacenamiento insuficiente para la instalación. La instalación podría fallar.';

  @override
  String get estimateProfileSize => 'Estimar el tamaño del perfil';

  @override
  String get estimateProfileSizeSubtitle =>
      'Estimar el tamaño de los metadatos del perfil antes de la descarga';

  @override
  String get customize => 'Personalizar';

  @override
  String get customizeDescription =>
      'Especifique un nuevo nombre hexadecimal de 6 caracteres y una contraseña para su lector.';

  @override
  String get customizeSuccess =>
      'Lector personalizado. Vuelva a emparejar el dispositivo.';

  @override
  String customizeFailed(String error) {
    return 'No se pudo personalizar el lector: $error';
  }

  @override
  String get defaultPasswordWillChangeTitle =>
      'La contraseña predeterminada cambiará';

  @override
  String defaultPasswordWillChangeMessage(String password) {
    return 'Este dispositivo está conectado con su contraseña predeterminada. Al cambiarle el nombre, la contraseña pasará a ser $password. Guarde esta contraseña antes de volver a conectarse.';
  }

  @override
  String get savedBleDevices => 'Dispositivos BLE conectados anteriormente';

  @override
  String get savedBleDevicesSubtitle =>
      'Ver los nombres y contraseñas de dispositivos guardados en este dispositivo';

  @override
  String get savedBleDevicesDescription =>
      'Cada entrada es una contraseña NBLESim guardada localmente. Las contraseñas predeterminadas también se guardan.';

  @override
  String get noSavedBleDevices =>
      'No hay dispositivos BLE conectados anteriormente.';

  @override
  String get deviceName => 'Nombre del dispositivo';

  @override
  String get success => 'Correcto';

  @override
  String get devicePasswordHint => '6 caracteres hex o contraseña';

  @override
  String get sixHexChars => '6 caracteres hex';

  @override
  String get database => 'Base de datos';

  @override
  String exportSuccess(String path) {
    return 'Base de datos exportada a $path';
  }

  @override
  String get importDatabase => 'Importar base de datos';

  @override
  String get importDatabaseSubtitle =>
      'Combinar entradas de otro archivo de base de datos';

  @override
  String get importDatabaseDialogTitle =>
      'Seleccione el archivo de base de datos que desea importar';

  @override
  String get importDatabaseTitle => 'Importar base de datos';

  @override
  String get importDatabaseContent =>
      'Se combinarán las entradas de la base de datos seleccionada con su base de datos actual. Las entradas existentes con las mismas claves se sobrescribirán. ¿Desea continuar?';

  @override
  String get import => 'Importar';

  @override
  String get importSuccess => 'Base de datos importada correctamente';

  @override
  String importFailed(String error) {
    return 'No se pudo importar la base de datos: $error';
  }

  @override
  String get resetDatabase => 'Restablecer la base de datos';

  @override
  String get resetDatabaseSubtitle =>
      'Borrar todos los datos de la aplicación y reiniciar';

  @override
  String get resetDatabaseTitle =>
      'Restablecer la base de datos de la aplicación';

  @override
  String get resetDatabaseContent =>
      'Se eliminarán por completo todos los datos, configuraciones y registros almacenados localmente. La aplicación se cerrará. ¿Desea continuar?';

  @override
  String get deleteDatabase => 'Eliminar la base de datos';

  @override
  String resetFailed(String error) {
    return 'No se pudo restablecer la base de datos: $error';
  }

  @override
  String get deviceImei => 'TAC del dispositivo';

  @override
  String get deviceImeiSubtitle => 'Se usa para las descargas de perfiles';

  @override
  String get editDeviceImei => 'Editar el TAC del dispositivo';

  @override
  String get editDeviceImeiInfo =>
      'Introduzca un TAC de 8 dígitos o un IMEI de 15 dígitos. TAC predeterminado: 35383741.';

  @override
  String get imeiDigits => 'Dígitos del TAC o del IMEI';

  @override
  String get importAction => 'Importar';

  @override
  String get transferTitle => 'Transferir eSIM';

  @override
  String get transferAction => 'Transferir a este dispositivo';

  @override
  String get transferCheckingEligibility => 'Comprobando la elegibilidad…';

  @override
  String get transferReadingSource => 'Leyendo la SIM de origen…';

  @override
  String get transferContactingCarrier => 'Contactando con el operador…';

  @override
  String get transferIneligibleReader =>
      'Este perfil no se puede transferir con este lector. La autenticación de la SIM de origen (EAP-AKA) no es accesible aquí.';

  @override
  String get transferNoEntitlement =>
      'No se encontró ninguna configuración de transferencia del operador para este perfil. Puede introducir el servidor de entitlement manualmente.';

  @override
  String transferSourceCarrier(String carrier) {
    return 'Operador de origen: $carrier';
  }

  @override
  String get transferConfirmTitle => '¿Transferir esta suscripción?';

  @override
  String get transferConfirmBody =>
      'El operador volverá a emitir esta suscripción en esta eUICC. Es posible que el perfil de origen se elimine como parte de la transferencia.';

  @override
  String get transferStart => 'Iniciar la transferencia';

  @override
  String get transferDownloadingProfile => 'Descargando el perfil transferido…';

  @override
  String get transferDeleteSourceTitle => 'Eliminar el perfil de origen';

  @override
  String transferDeleteSourceBody(String iccid) {
    return 'El operador exige que se elimine el perfil de origen $iccid antes de la activación. ¿Desea eliminarlo ahora?';
  }

  @override
  String get transferDeleteSourceConfirm => 'Eliminar y continuar';

  @override
  String get transferUserInputSubmit => 'Enviar';

  @override
  String get transferAccept => 'Aceptar';

  @override
  String get transferReject => 'Rechazar';

  @override
  String get transferPendingActivation =>
      'El operador todavía está activando esta suscripción. Terminará en breve; puede cerrar esta ventana y comprobarlo más tarde.';

  @override
  String get transferDismissed => 'El operador rechazó la transferencia.';

  @override
  String get transferDelayedDownload =>
      'El operador entregará el perfil en breve. Una vez que lo haya instalado, introduzca el ICCID instalado para finalizar.';

  @override
  String get transferInstalledIccid => 'ICCID instalado';

  @override
  String get transferSuccess => 'Transferencia completada';

  @override
  String transferFailed(String error) {
    return 'Error en la transferencia: $error';
  }

  @override
  String get transferManualServerTitle => 'Servidor de entitlement (avanzado)';

  @override
  String get transferManualServerHint => 'https://entitlement.example.com';

  @override
  String get transferEnablingSource => 'Preparando el perfil de origen…';

  @override
  String get transferClose => 'Cerrar';

  @override
  String get transferContinue => 'Continuar';

  @override
  String get transferSmdsDiscovering => 'Detectando perfiles mediante SM-DS…';

  @override
  String get transferSmdsNoProfiles =>
      'No se encontraron perfiles pendientes mediante la detección SM-DS.';

  @override
  String get transferSelectProfile => 'Seleccione un perfil para descargar';

  @override
  String get discoverProfiles => 'Detectar perfiles (SM-DS)';

  @override
  String get discoveringProfiles => 'Detectando perfiles…';

  @override
  String get discoveryNoProfiles =>
      'No se encontraron perfiles pendientes mediante la detección SM-DS.';

  @override
  String get transferSmdsServerTitle => 'Servidor SM-DS';

  @override
  String transferProfileOnServer(String eventId, String address) {
    return '$eventId en $address';
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
