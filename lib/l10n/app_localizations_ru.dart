// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get addBluetoothReader => 'Add Bluetooth reader';

  @override
  String get bluetoothSetupFailed =>
      'Unable to set up the Bluetooth reader. Check that Bluetooth is on and the reader is nearby, then try again.';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get displaySettings => 'Настройки отображения';

  @override
  String get appearance => 'Оформление';

  @override
  String get appearanceSubtitle => 'Настройка темы, макета и отображения';

  @override
  String get darkMode => 'Тёмный режим';

  @override
  String get themeStyle => 'Стиль темы';

  @override
  String get themeStyleSubtitle =>
      'Выберите между пользовательским и MD3 стилем';

  @override
  String get customDesign => 'Стиль Nekoko';

  @override
  String get stockMD3 => 'Стоковый MD3';

  @override
  String get waterfallLayout => 'Макет Водопад';

  @override
  String get waterfallLayoutSubtitle =>
      'Использовать стиль макета Masonry на широких экранах';

  @override
  String get system => 'Система';

  @override
  String get light => 'Светлый';

  @override
  String get dark => 'Тёмный';

  @override
  String get language => 'Язык';

  @override
  String get systemLanguage => 'Системный язык';

  @override
  String get general => 'Общее';

  @override
  String get ui => 'Интерфейс';

  @override
  String get autoLoadProfiles => 'Автозагрузка профилей';

  @override
  String get autoLoadProfilesSubtitle =>
      'Загружать профили автоматически при выборе считывателя';

  @override
  String get loadProfileIcons => 'Загружать иконки профилей';

  @override
  String get loadProfileIconsSubtitle =>
      'Получать значки профилей из eUICC (медленнее)';

  @override
  String get useNekokoIcons => 'Использовать иконки операторов';

  @override
  String get useNekokoIconsSubtitle => 'Загрузить иконки операторов';

  @override
  String get forceDeviceDropdown => 'Принудительный выпадающий список';

  @override
  String get forceDeviceDropdownSubtitle =>
      'Всегда использовать выпадающий список для выбора устройства';

  @override
  String get sizeDisplayUnit => 'Единицы измерения размера';

  @override
  String get sizeDisplayUnitSubtitle => 'Единицы измерения размера хранилища';

  @override
  String get phoneFormat => 'Формат номера телефона';

  @override
  String get phoneFormatSubtitle => 'Формат отображения телефонных номеров';

  @override
  String get notifications => 'Уведомления';

  @override
  String get notificationSettings => 'Параметры уведомлений';

  @override
  String get notificationSettingsSubtitle =>
      'Настройка автоматической обработки и удаления';

  @override
  String get notificationHistory => 'История уведомлений';

  @override
  String get notificationHistorySubtitle =>
      'Найти, управлять и повторно отправить отправленные уведомления';

  @override
  String get tagsAndReminders => 'Теги и напоминания';

  @override
  String get tagManager => 'Менеджер тегов';

  @override
  String get tagManagerSubtitle => 'Создать и редактировать теги профиля';

  @override
  String get tagReminders => 'Напоминания о тегах';

  @override
  String get tagRemindersSubtitle =>
      'Запланированные уведомления, основанные на тегах даты';

  @override
  String get manageTagsAndReminders => 'Управление тегами и напоминаниями';

  @override
  String get manageTagsAndRemindersSubtitle =>
      'Настройка меток, прав доступа и оповещений';

  @override
  String get viewScheduledReminders => 'Просмотр запланированных напоминаний';

  @override
  String get viewScheduledRemindersSubtitle =>
      'Управление предстоящими уведомлениями на основе тегов';

  @override
  String get connectivity => 'Соединение';

  @override
  String get remoteReaders => 'Удаленные ридеры';

  @override
  String get remoteReadersSubtitle => 'Приложение RemoCard';

  @override
  String get enableBle => 'Bluetooth-ридер';

  @override
  String get enableBleSubtitle =>
      'Включить сканирование и подключение к Bluetooth-ридерам';

  @override
  String get enableCcid => 'USB CCID ридер';

  @override
  String get enableCcidSubtitle => 'Включить USB кард ридер (CCID)';

  @override
  String get enableOmapi => 'OMAPI считыватель';

  @override
  String get enableOmapiSubtitle => 'Включить Open Mobile API.';

  @override
  String get enableTmapi => 'Tmapi считыватель';

  @override
  String get enableTmapiSubtitle =>
      'Включить Telephony API для управления eUICC.';

  @override
  String get readerTypes => 'Типы считывателей';

  @override
  String get readerTypesSubtitle =>
      'Управление включенными типами считывателя (CCID, Bluetooth, Remote, и т. д.)';

  @override
  String get enabledReaderTypes => 'Разрешенные типы считывателей';

  @override
  String get enabledReaderTypesSubtitle =>
      'Управление доступными в приложении типами считывателей';

  @override
  String get remoteReaderSettings => 'Настройки удаленных кард ридеров';

  @override
  String get remoteReaderSettingsSubtitle =>
      'Настройка удаленных серверов и подключений';

  @override
  String get ccidReaderTitle => 'CCID (USB/PC/SC)';

  @override
  String get ccidReaderSubtitle =>
      'USB смарт-карты считыватели и PC/SC устройства';

  @override
  String get bluetoothReaderTitle => 'Bluetooth';

  @override
  String get bluetoothReaderSubtitle => 'Bluetooth LE кард ридеры';

  @override
  String get remoteReadersTitle => 'Удаленные считыватели';

  @override
  String get remoteReadersConnectorSubtitle => 'Удаленные считыватели по сети';

  @override
  String get omapiReaderTitle => 'OMAPI';

  @override
  String get omapiReaderSubtitle =>
      'Встроенные слоты SIM-карты через Open Mobile API';

  @override
  String get tmapiReaderTitle => 'Telephony API';

  @override
  String get tmapiReaderSubtitle =>
      'Встроенные слоты SIM-карт через Telephony API';

  @override
  String get remoteServerConfiguration => 'Настройка удалённого сервера';

  @override
  String get remoteServerConfigurationSubtitle =>
      'Управление удалёнными серверами считывателей и параметрами подключения';

  @override
  String get enableBrowser => 'Включить браузер';

  @override
  String get enableBrowserSubtitle =>
      'Показывать дополнительные вкладки: Магазин, Покупка, Помощь';

  @override
  String get transport => 'Передача данных';

  @override
  String get disableRefreshFlags => 'Отключить флаги обновления';

  @override
  String get disableRefreshFlagsSubtitle =>
      'Не применяется к внешним считывателям';

  @override
  String get apduMaxSegmentSize => 'Максимальный размер сегмента APDU';

  @override
  String get apduMaxSegmentSizeSubtitle =>
      'Максимальный объём данных в одном фрагменте APDU';

  @override
  String get ensureSingleChannel => 'Только один логический канал';

  @override
  String get ensureSingleChannelSubtitle =>
      'Закрывать другие логические каналы перед открытием нового';

  @override
  String get analytics => 'Аналитика и облачные сервисы';

  @override
  String get nekokoCloud => 'Nekoko Cloud';

  @override
  String get nekokoCloudSubtitle =>
      'Анализ данных об установке для более точного прогноза';

  @override
  String get developer => 'Разработчик';

  @override
  String get developerMode => 'Режим разработчика';

  @override
  String get developerModeSubtitle => 'Включить расширенные средства отладки';

  @override
  String get exportDatabase => 'Экспорт базы данных';

  @override
  String get exportDatabaseSubtitle =>
      'Сохранить копию базы данных приложения во внешнее хранилище.';

  @override
  String get openDatabaseFolder => 'Открыть папку базы данных';

  @override
  String get openDatabaseFolderSubtitle =>
      'Показать папку локального хранилища в проводнике';

  @override
  String get decodeAsn1 => 'Декодировать журналы ASN.1 (медленно)';

  @override
  String get decodeAsn1Subtitle => 'Существенно снижает производительность';

  @override
  String get viewAppLogs => 'Просмотр журналов приложения';

  @override
  String get viewAppLogsSubtitle => 'Просмотр собранных журналов приложения';

  @override
  String get about => 'О приложении';

  @override
  String get version => 'Версия';

  @override
  String get build => 'Сборка';

  @override
  String get checkUpdates => 'Проверять обновления';

  @override
  String get checkUpdatesSubtitle =>
      'Автоматически проверять новые версии при запуске';

  @override
  String get licenses => 'Лицензии открытого ПО';

  @override
  String get licensesSubtitle =>
      'Сведения о лицензиях используемых библиотек с открытым исходным кодом';

  @override
  String get noUpdatesFound => 'Обновлений не найдено';

  @override
  String get profilesTitle => 'Профили';

  @override
  String get switchEstkSlot => 'Переключить слот eSTK';

  @override
  String get notificationsButton => 'Уведомления';

  @override
  String get downloadProfile => 'Загрузить профиль';

  @override
  String get reconnect => 'Переподключить';

  @override
  String get bluetoothNotConnected => 'Bluetooth не подключён';

  @override
  String get bluetoothNotConnectedSubtitle =>
      'Убедитесь, что Bluetooth включён и устройство находится рядом. Нажмите «Подключить», чтобы начать работу с этим устройством.';

  @override
  String get bluetoothConnectionFailed =>
      'Не удалось подключиться по Bluetooth';

  @override
  String bluetoothConnectionFailedSubtitle(Object error) {
    return 'Не удалось подключиться к устройству Bluetooth.\n\n$error';
  }

  @override
  String get removeDevice => 'Удалить устройство';

  @override
  String get retryConnection => 'Подключить';

  @override
  String get remoteConnectionFailed =>
      'Не удалось подключиться к удалённому считывателю';

  @override
  String remoteConnectionFailedMessage(Object error) {
    return 'Убедитесь, что удалённый сервер запущен и доступен.\n\n$error';
  }

  @override
  String get errorBluetoothTimeout =>
      'Истекло время ожидания операции Bluetooth. Повторите попытку.';

  @override
  String get errorOmapiSecurity =>
      'Ошибка безопасности: доступ к карте запрещён операционной системой или правилами ARA-M.';

  @override
  String get errorApplicationNotFound =>
      'Управляющее приложение eUICC (ISD-R) не найдено. Возможно, эта карта не является eUICC.';

  @override
  String get changeSettings => 'Изменить настройки';

  @override
  String get connectCompatibleReader =>
      'Подключите совместимый считыватель, чтобы начать.';

  @override
  String get connectReaderMessageBle =>
      'Также можно выполнить поиск совместимых устройств Bluetooth, если у вас есть eUICC с поддержкой Bluetooth.';

  @override
  String get connectReaderMessageNoBle =>
      'Убедитесь, что считыватель CCID подключён к компьютеру.';

  @override
  String get downloadSmartCardExtension =>
      'Загрузить расширение для смарт-карт';

  @override
  String get smartCardExtensionMessage =>
      'Расширение необходимо для доступа к USB-считывателям CCID в этом браузере.';

  @override
  String get scanForBluetooth => 'Искать по Bluetooth';

  @override
  String get connectRemote => 'Подключить удалённый';

  @override
  String get noCardDetected => 'Карта не обнаружена';

  @override
  String get noCardDetectedMessage =>
      'В этом слоте не найдено активной или поддерживаемой eUICC.';

  @override
  String get noDataLoaded => 'Не подключено';

  @override
  String get loadProfiles => 'Подключить';

  @override
  String get disconnect => 'Отключить';

  @override
  String get disconnecting => 'Отключение…';

  @override
  String get profilesEmpty => 'На карте нет профилей';

  @override
  String get profilesEmptyMessage => 'Эта карта eUICC пуста.';

  @override
  String get renameProfile => 'Переименовать профиль';

  @override
  String get nickname => 'Имя';

  @override
  String get enterProfileNickname => 'Введите имя профиля';

  @override
  String get profileNicknameNote =>
      'Примечание: метки настраиваются отдельно в меню «Управление метками».';

  @override
  String get useProfileIcon => 'Использовать значок профиля';

  @override
  String get useProfileIconSubtitle => 'Значок с карты eSIM';

  @override
  String get removeCustomIcon => 'Удалить свой значок';

  @override
  String get noRemoteIcon => 'Для этого оператора нет доступного значка';

  @override
  String get cancel => 'Отмена';

  @override
  String get ok => 'ОК';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get refresh => 'Обновить';

  @override
  String get initializing => 'Инициализация…';

  @override
  String get refreshingProfiles => 'Обновление профилей…';

  @override
  String get retrievingEid => 'Получение EID и сведений…';

  @override
  String get updatingProfile => 'Обновление профиля…';

  @override
  String get manageIsdR => 'Управление AID для ISD-R';

  @override
  String get manageIsdRSubtitle =>
      'Настройка идентификаторов приложений по умолчанию для eUICC';

  @override
  String get transportFailed => 'Сбой передачи данных';

  @override
  String get remoteTransportFailedMessage =>
      'Подключение к удалённому серверу установлено, но команда не выполнена. Обычно это означает, что удалённое устройство временно занято или потеряло связь с картой. Повторить попытку?';

  @override
  String get retry => 'Повторить';

  @override
  String get scanningForReaders => 'Поиск считывателей…';

  @override
  String get switchedEstkSlot => 'Слот eSTK переключён';

  @override
  String get scanningForUnresponsiveDevices => 'Поиск не отвечающих устройств…';

  @override
  String get resettingConnection => 'Сброс подключения…';

  @override
  String get connectingToReader => 'Подключение к считывателю…';

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
  String get moreOptions => 'Дополнительно';

  @override
  String get retrievingProfiles => 'Получение профилей…';

  @override
  String get savingProfileMetadata => 'Сохранение метаданных профиля…';

  @override
  String get enablingProfile => 'Включение профиля…';

  @override
  String get disablingProfile => 'Отключение профиля…';

  @override
  String get deleteProfile => 'Удалить профиль';

  @override
  String deleteProfileConfirmation(Object profileName) {
    return 'Удалить профиль $profileName?\nЭто действие нельзя отменить.';
  }

  @override
  String get deletingProfile => 'Удаление профиля…';

  @override
  String get deleting => 'Удаление…';

  @override
  String get dataUsage => 'Использование трафика';

  @override
  String get details => 'Подробности';

  @override
  String get rename => 'Переименовать';

  @override
  String get changeIcon => 'Изменить значок';

  @override
  String get manageTags => 'Управление метками';

  @override
  String get copyIccid => 'Копировать ICCID';

  @override
  String get notificationProcessingError =>
      'Операции недоступны, пока обрабатываются уведомления';

  @override
  String get operationInProgressError => 'Операция выполняется, подождите';

  @override
  String iccidCopied(Object iccid) {
    return 'ICCID скопирован: $iccid';
  }

  @override
  String get operationRestricted => 'Операция недоступна';

  @override
  String get notificationProcessingDownloadError =>
      'Уведомления ещё обрабатываются. Дождитесь завершения, прежде чем загружать новые профили.';

  @override
  String get operational => 'Рабочий';

  @override
  String get test => 'Тестовый';

  @override
  String get provisioning => 'Инициализационный';

  @override
  String get profileDetails => 'Сведения о профиле';

  @override
  String get profileDetailsSubtitle => 'Данные eUICC для этого слота профиля.';

  @override
  String get enabled => 'Включён';

  @override
  String get disabled => 'Отключён';

  @override
  String get tagsManagedSeparately =>
      'Примечание: метки настраиваются отдельно в меню «Управление метками».';

  @override
  String get changeProfileIcon => 'Изменить значок профиля';

  @override
  String get selectFromGallery => 'Выбрать из галереи';

  @override
  String get nekokoOperatorIcon => 'Значок оператора';

  @override
  String get iconFromEsim => 'Значок с карты eSIM';

  @override
  String updateIconFailed(Object error) {
    return 'Не удалось обновить значок: $error';
  }

  @override
  String get failedToReadImage => 'Не удалось прочитать файл изображения';

  @override
  String get failedToProcessImage => 'Не удалось обработать изображение';

  @override
  String get customIconSet => 'Свой значок установлен';

  @override
  String get noMccMnc => 'Для этого профиля нет данных MCC/MNC';

  @override
  String get fetchingRemoteIcon => 'Загрузка значка…';

  @override
  String get remoteIconSaved => 'Значок сохранён как пользовательский';

  @override
  String fetchRemoteIconFailed(Object error) {
    return 'Не удалось загрузить значок: $error';
  }

  @override
  String get noProfileIcon => 'У профиля нет значка';

  @override
  String get profileIconSaved => 'Значок профиля сохранён как пользовательский';

  @override
  String get customIconRemoved => 'Пользовательский значок удалён';

  @override
  String get failed => 'Ошибка';

  @override
  String euiccError(Object action) {
    return 'eUICC вернула ошибку при попытке выполнить действие «$action» с профилем.';
  }

  @override
  String get dismiss => 'Закрыть';

  @override
  String get dataPlan => 'Тарифный план';

  @override
  String get used => 'использовано';

  @override
  String get total => 'всего';

  @override
  String expires(Object date) {
    return 'Истекает: $date';
  }

  @override
  String get close => 'Закрыть';

  @override
  String get server => 'Сервер';

  @override
  String get switchFailed => 'Не удалось переключить';

  @override
  String get deviceRefreshFailed => 'Не удалось обновить устройство';

  @override
  String get euiccOptions => 'Параметры eUICC';

  @override
  String get euiccInfo => 'Сведения об eUICC';

  @override
  String get hideEid => 'Скрыть EID';

  @override
  String get showEid => 'Показать EID';

  @override
  String get copyEid => 'Копировать EID';

  @override
  String get eidCopied => 'EID скопирован в буфер обмена';

  @override
  String get connectRemotes => 'Подключить удалённые';

  @override
  String get configureRemotes => 'Настроить удалённые';

  @override
  String get connectingToRemoteReaders =>
      'Фоновое подключение к удалённым считывателям…';

  @override
  String get noRemoteReadersFound => 'Удалённые считыватели не найдены';

  @override
  String connectedRemoteReaders(Object count) {
    return 'Подключено удалённых считывателей: $count';
  }

  @override
  String failedToConnectRemoteReaders(Object error) {
    return 'Не удалось подключить удалённые считыватели: $error';
  }

  @override
  String get remoteReaderPassword => 'Пароль удалённого считывателя';

  @override
  String get remoteReaderPasswordSubtitle =>
      'Этот удалённый считыватель требует пароль.';

  @override
  String get password => 'Пароль';

  @override
  String get deleteConnection => 'Удалить подключение';

  @override
  String get connect => 'Подключить';

  @override
  String get remoteReaderConnectionFailed =>
      'Не удалось подключиться к удалённому считывателю';

  @override
  String remoteReaderConnectionFailedSubtitle(Object error) {
    return 'Убедитесь, что удалённый сервер запущен и доступен.\n\n$error';
  }

  @override
  String get connectReader =>
      'Подключите совместимый считыватель, чтобы начать.';

  @override
  String get connectReaderSubtitleBle =>
      'Также можно выполнить поиск совместимых устройств Bluetooth, если у вас есть eUICC с поддержкой Bluetooth.';

  @override
  String get connectReaderSubtitleCcid =>
      'Убедитесь, что считыватель CCID подключён к компьютеру.';

  @override
  String get downloadExtension => 'Загрузить расширение для смарт-карт';

  @override
  String get downloadExtensionSubtitle =>
      'Расширение необходимо для доступа к USB-считывателям CCID в этом браузере.';

  @override
  String get cardUnsupported => 'Карта не поддерживается';

  @override
  String get cardUnsupportedSubtitle =>
      'Скорее всего, это не eUICC, либо она не поддерживается этим считывателем, либо занята другим приложением.';

  @override
  String get omapiWelcome =>
      'Хорошая новость: ваше устройство поддерживает OMAPI и, скорее всего, совместимо со съёмными картами!';

  @override
  String get supportedDevices => 'Поддерживаемые устройства';

  @override
  String get aboutAram => 'Об ARA-M';

  @override
  String get accessDenied => 'Доступ запрещён';

  @override
  String get accessDeniedSubtitle =>
      'Для доступа к этой eUICC нужны привилегии оператора. Список разрешений ARA-M на карте не соответствует подписи приложения.';

  @override
  String get noCardDetectedSubtitle =>
      'В этом слоте не найдено активной или поддерживаемой eUICC.';

  @override
  String get noProfilesInstalled => 'Профили не установлены';

  @override
  String get noProfilesInstalledSubtitle => 'Эта карта eUICC пуста.';

  @override
  String get cardRefreshingTitle => 'Карта обновляется';

  @override
  String get cardRefreshingMessage =>
      'Карта сейчас обновляет своё состояние. Получить список профилей пока невозможно. Подождите несколько секунд и повторите попытку.';

  @override
  String get useRemoteIcon => 'Использовать значок из сети';

  @override
  String get bleDisconnectedTitle => 'Соединение Bluetooth потеряно';

  @override
  String get bleDisconnectedMessage =>
      'Связь со считывателем неожиданно прервалась. Убедитесь, что он находится рядом и включён.';

  @override
  String get cardStuckRefreshingMessage =>
      'Идёт смена состояния профиля — если процесс завис, попробуйте вручную переустановить SIM-карту.';

  @override
  String get cardNeedsReplugTitle => 'Переустановите SIM-карту';

  @override
  String get cardNeedsReplugMessage =>
      'Карта не передаёт свой апплет eUICC, поэтому управлять ею сейчас нельзя. Извлеките SIM-карту, вставьте её снова и повторите попытку.';

  @override
  String get activationCodeTitle => 'Код активации';

  @override
  String get activationCodeSubtitle =>
      'Отсканируйте QR-код, перетащите изображение или введите строку LPA вручную.';

  @override
  String get fullActivationCodeLabel => 'Полный код активации';

  @override
  String get fullActivationCodeHint => 'LPA:1\$smdp.io\$MATCHING-ID';

  @override
  String get pasteFromClipboardTooltip => 'Вставить из буфера обмена';

  @override
  String get selectFromGalleryTooltip => 'Выбрать из галереи';

  @override
  String get scanQrCodeTooltip => 'Сканировать QR-код';

  @override
  String get smdpAddressLabel => 'Адрес SM-DP+';

  @override
  String get smdpAddressHint => 'smdp.io';

  @override
  String get matchingIdLabel => 'Matching ID';

  @override
  String get matchingIdHint => 'ABC-123';

  @override
  String get smdpOidLabel => 'OID SM-DP+';

  @override
  String get confirmationCodeLabel => 'Код подтверждения';

  @override
  String get confirmationCodeHint => 'Введите секретный код';

  @override
  String get continueButton => 'Продолжить';

  @override
  String get invalidLpaClipboard =>
      'В буфере обмена нет корректной строки LPA.';

  @override
  String get invalidFqdnFormat => 'Неверный формат FQDN';

  @override
  String get invalidMatchingIdChars => 'Недопустимые символы в Matching ID';

  @override
  String get invalidOidFormat => 'Неверный формат OID (например, 1.2.840…)';

  @override
  String get activationCodeRequired => 'Требуется код активации';

  @override
  String get invalidLpaFormatGeneric => 'Неверный формат LPA';

  @override
  String get smdpAddressRequired => 'Требуется адрес SM-DP+';

  @override
  String get loadingNotifications => 'Загрузка уведомлений…';

  @override
  String get vowifi => 'VoWiFi';

  @override
  String get vowifiSubtitle =>
      'Экспериментально; требуется совместимый внешний считыватель';

  @override
  String get vowifiDisclaimerTitle => 'Включить экспериментальный VoWiFi?';

  @override
  String get vowifiDisclaimerBody =>
      'VoWiFi — экспериментальная функция. Она напрямую взаимодействует с вашим мобильным оператором и работает только с совместимым внешним считывателем SIM/eSIM, поддерживающим сырые APDU. Совместимость с оператором и считывателем может отличаться.';

  @override
  String get processing => 'Обработка…';

  @override
  String get analyzingImage => 'Анализ изображения…';

  @override
  String get noQrFoundInImage => 'На изображении не найден QR-код';

  @override
  String get invalidAcInImage =>
      'На изображении найден недействительный код активации';

  @override
  String get invalidAcFormatDetailed =>
      'Неверный формат кода активации. Он должен начинаться с LPA:1\$…';

  @override
  String get downloadProfileTitle => 'Загрузка профиля';

  @override
  String get connectingToEuicc => 'Подключение к eUICC…';

  @override
  String get gettingChallenge => 'Получение запроса eUICC…';

  @override
  String get authenticatingWithSmdp => 'Аутентификация на SM-DP+…';

  @override
  String get verifyingSignatures => 'Проверка подписей SM-DP+…';

  @override
  String get retrievingMetadata => 'Получение метаданных профиля…';

  @override
  String get preparingDownload => 'Подготовка к загрузке…';

  @override
  String get preparingEuicc => 'Подготовка eUICC…';

  @override
  String get fetchingProfilePackage => 'Получение пакета профиля…';

  @override
  String installing(Object sent, Object total) {
    return 'Установка ($sent из $total байт)…';
  }

  @override
  String get finalizing => 'Завершение (обновление сведений о памяти)…';

  @override
  String get profileInstalledSuccessfully => 'Профиль успешно установлен!';

  @override
  String get provider => 'Оператор';

  @override
  String get iccid => 'ICCID';

  @override
  String get plmn => 'PLMN';

  @override
  String get storage => 'Память';

  @override
  String get free => 'Свободно';

  @override
  String get nvram => 'NVRAM';

  @override
  String get exportCertificates => 'Экспорт сертификатов';

  @override
  String get euiccCert => 'Сертификат eUICC';

  @override
  String get eumCert => 'Сертификат EUM';

  @override
  String get enterConfirmationCode =>
      'Введите код, который требует ваш оператор';

  @override
  String get confirmationCodeRequired => 'Требуется код подтверждения';

  @override
  String get download => 'Загрузить';

  @override
  String get installationSuccessful => 'Установка завершена';

  @override
  String get installationSuccessMessage =>
      'Профиль успешно установлен на вашу eUICC.';

  @override
  String get consumed => 'Занято';

  @override
  String get enableProfileNow => 'Включить профиль';

  @override
  String get done => 'Готово';

  @override
  String get profileEnabledSuccessfully => 'Профиль успешно включён';

  @override
  String get enterNewProfileName =>
      'Введите новое имя для этого профиля, чтобы легче его различать.';

  @override
  String get profileName => 'Имя профиля';

  @override
  String get profileNameHint => 'например, Рабочие поездки';

  @override
  String get profileRenamedSuccessfully => 'Профиль переименован';

  @override
  String get downloadFailed => 'Не удалось загрузить';

  @override
  String get tryAgain => 'Повторить';

  @override
  String get savedSuccessfully => 'Сохранено';

  @override
  String get saveCertificate => 'Сохранить сертификат';

  @override
  String get searchingForReaders => 'Поиск считывателей…';

  @override
  String get initializationError => 'Ошибка инициализации';

  @override
  String get noReadersFound => 'Считыватели не найдены';

  @override
  String get noReadersFoundMessage =>
      'Подключите совместимый считыватель или выполните поиск BLE-устройств, чтобы управлять профилями eSIM.';

  @override
  String get scanBle => 'Искать BLE';

  @override
  String get reminderDetails => 'Сведения о напоминании';

  @override
  String get profileNotFound => 'Профиль не найден';

  @override
  String get resending => 'Повторная отправка…';

  @override
  String get noAddressInNotification => 'В данных уведомления нет адреса';

  @override
  String get sentSuccessfully => 'Отправлено';

  @override
  String get sendFailed => 'Не удалось отправить';

  @override
  String get copiedCurl => 'Команда cURL скопирована в буфер обмена';

  @override
  String get noAddressToExport => 'Нет адреса для экспорта';

  @override
  String get noHistoryAvailable => 'История недоступна';

  @override
  String get searchByIccid => 'Поиск по ICCID…';

  @override
  String get resendNotification => 'Отправить уведомление повторно';

  @override
  String get exportAsCurl => 'Экспортировать как cURL';

  @override
  String get viewDetails => 'Показать подробности';

  @override
  String get deleteEntry => 'Удалить запись';

  @override
  String activeReminders(int count) {
    return 'Активных напоминаний: $count';
  }

  @override
  String get noScheduledReminders => 'Нет запланированных напоминаний';

  @override
  String get remindersAppearWhen =>
      'Напоминания появляются, когда вы добавляете к профилям метки с датой.';

  @override
  String activeTagsCount(int count) {
    return 'Активных меток по всем профилям: $count';
  }

  @override
  String get searchTagsOrProfiles => 'Поиск меток или профилей…';

  @override
  String get noTagsFound => 'Метки не найдены';

  @override
  String get addTagsFromProfileMenu =>
      'Добавьте метки к профилям в меню редактирования профиля, чтобы увидеть их здесь.';

  @override
  String get expired => 'Истёк';

  @override
  String daysLeft(int count) {
    return 'осталось $count дн.';
  }

  @override
  String hoursLeft(int count) {
    return 'осталось $count ч.';
  }

  @override
  String get expiresSoon => 'Скоро истекает';

  @override
  String get soon => 'скоро';

  @override
  String get activeTags => 'Активные метки';

  @override
  String get addNewTag => 'Добавить метку';

  @override
  String get noTagsAssigned => 'Этому профилю не назначены метки';

  @override
  String get textTagHint => 'Текстовая метка (например, Работа, Поездка)';

  @override
  String get addDateExpiryTag => 'Добавить метку с датой или сроком';

  @override
  String get addNoteOptional => 'Добавить заметку (необязательно)';

  @override
  String get add => 'Добавить';

  @override
  String get noteHint => 'например, Срок, 10 ГБ и т. п.';

  @override
  String get invalidHexString => 'Неверная шестнадцатеричная строка';

  @override
  String get resetToDefaults => 'Сбросить по умолчанию';

  @override
  String get resetToDefaultsSuccess => 'Сброшено к значениям по умолчанию';

  @override
  String get addAidHex => 'Добавить AID (hex)';

  @override
  String get manageAutoNotif =>
      'Управление автоматической обработкой уведомлений';

  @override
  String get automaticProcessing => 'АВТОМАТИЧЕСКАЯ ОБРАБОТКА';

  @override
  String get notifProcessingInfo =>
      'Обработка уведомлений помогает синхронизировать вашу eUICC с сервером SM-DP+ (оператором). Удаление отправленных уведомлений освобождает память карты.';

  @override
  String get enabling => 'Включение';

  @override
  String get afterEnabling => 'После включения профиля';

  @override
  String get disabling => 'Отключение';

  @override
  String get afterDisabling => 'После отключения профиля';

  @override
  String get installation => 'Установка';

  @override
  String get afterDownload => 'После загрузки профиля';

  @override
  String get deletion => 'Удаление';

  @override
  String get afterDeletion => 'После удаления профиля';

  @override
  String get autoSend => 'Автоотправка';

  @override
  String get autoSendSubtitle => 'Отправлять на сервер автоматически';

  @override
  String get autoRemove => 'Автоудаление';

  @override
  String get autoRemoveSubtitle => 'Удалять с карты после отправки';

  @override
  String get removeWithoutSending => 'Удалять без отправки';

  @override
  String get removeWithoutSendingSubtitle =>
      'Используйте с осторожностью: сервер не будет уведомлён';

  @override
  String get permissionsActive => 'Разрешения предоставлены';

  @override
  String get permissionsRequired => 'Требуются разрешения';

  @override
  String get appCanSendNotif =>
      'Приложение может отправлять системные уведомления';

  @override
  String get requiredForReminders => 'Необходимо для оповещений о напоминаниях';

  @override
  String get unsupportedPlatformCheck =>
      'Проверка разрешений не поддерживается на этой платформе. Проверьте вручную.';

  @override
  String get couldNotVerifyStatus =>
      'Не удалось проверить состояние. Проверьте настройки вручную.';

  @override
  String get testNotificationTitle => 'Тестовое уведомление';

  @override
  String get seconds => 'сек.';

  @override
  String get startTest => 'Начать проверку';

  @override
  String get sendingNotif => 'Отправка…';

  @override
  String get hostIpLabel => 'Имя узла или IP';

  @override
  String get portLabel => 'Порт';

  @override
  String get passwordOptionalLabel => 'Пароль (необязательно)';

  @override
  String get configuredServers => 'Настроенные серверы';

  @override
  String get secureHttps => 'Защищённое (HTTPS)';

  @override
  String get insecureHttp => 'Незащищённое (HTTP)';

  @override
  String get urlCopied => 'URL скопирован';

  @override
  String get serverAddedSuccessfully => 'Сервер добавлен';

  @override
  String get authFailedCheckPassword =>
      'Ошибка аутентификации. Проверьте пароль.';

  @override
  String get addNewServer => 'Добавить сервер';

  @override
  String get autoLoadRemotes => 'Автоподключение удалённых устройств';

  @override
  String get autoLoadRemotesSubtitle =>
      'Автоматически подключаться к настроенным серверам при запуске приложения';

  @override
  String get getRemoCardGitHub => 'Скачать RemoCard на GitHub';

  @override
  String get instructions => 'Инструкция:';

  @override
  String get instruction1 =>
      '1. Установите приложение RemoCard на свои Android-устройства.';

  @override
  String get instruction2 =>
      '2. Запустите сервер в каждом приложении RemoCard.';

  @override
  String get instruction3 => '3. Введите здесь их IP-адреса.';

  @override
  String get instruction4 =>
      '4. Все удалённые слоты SIM появятся в списке устройств.';

  @override
  String get appLogsCopied => 'Журналы скопированы в буфер обмена';

  @override
  String get aramInfoTitle => 'Сведения об ARA-M';

  @override
  String get aramInfoSubtitle => 'Подробности апплета правил доступа';

  @override
  String get whatIsAram => 'Что такое ARA-M?';

  @override
  String get aramDescription =>
      'Access Rule Applet (ARA-M) — механизм в eUICC (eSIM) и SIM-картах, определяющий, каким приложениям разрешено управлять профилями или выполнять низкоуровневые операции. Если хеш приложения отсутствует в списке разрешений ARA-M на карте, система Android заблокирует доступ и выдаст ошибку «Доступ запрещён».';

  @override
  String get appCertHashes => 'Хеши сертификатов приложения';

  @override
  String get aramHashInstruction =>
      'Чтобы предоставить приложению доступ, может потребоваться добавить следующий хеш сертификата SHA-1 в правила ARA-M вашей карты. Этот хеш уникален для сертификата текущей сборки приложения.';

  @override
  String get aramSigningHistoryInstruction =>
      'Для совместимости с разными версиями Android добавьте в правила ARA-M карты все приведённые ниже хеши SHA-1. После смены ключа подписи разные версии Android могут проверять разные сертификаты из истории подписи.';

  @override
  String get certSha1Hash => 'Хеш сертификата SHA-1';

  @override
  String get unavailable => 'Недоступно';

  @override
  String get troubleshooting => 'Устранение неполадок';

  @override
  String get troubleStep1 =>
      'Убедитесь, что используете правильный считыватель карт.';

  @override
  String get troubleStep2 =>
      'Если используется физическая карта, проверьте, тестовая она или промышленная (на промышленных ARA-M часто заблокирован).';

  @override
  String get troubleStep3 =>
      'Приведённые хеши зависят от того, какую сборку вы используете: отладочную, обычную или привилегированную (Magisk).';

  @override
  String get troubleStep4 =>
      'Попробуйте привилегированную сборку (Magisk) — она обходит некоторые ограничения Android API.';

  @override
  String get hashCopied => 'Хеш скопирован в буфер обмена';

  @override
  String get aidCopied => 'AID скопирован в буфер обмена';

  @override
  String get lastSeen => 'Последняя активность';

  @override
  String get unknownProvider => 'Неизвестный оператор';

  @override
  String get unknownProfile => 'Неизвестный профиль';

  @override
  String get tags => 'Метки';

  @override
  String get noTags => 'Нет меток';

  @override
  String records(int count) {
    return 'Записей: $count';
  }

  @override
  String get bytes => 'байт';

  @override
  String get responseCode => 'Код ответа';

  @override
  String get responseBody => 'Тело ответа';

  @override
  String get type => 'Тип';

  @override
  String profileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count профиля',
      many: '$count профилей',
      few: '$count профиля',
      one: '$count профиль',
    );
    return '$_temp0';
  }

  @override
  String get isdrAids => 'AID для ISD-R';

  @override
  String get configureDefaultAids =>
      'Настройка идентификаторов приложений по умолчанию';

  @override
  String get addAidHexHint => 'Добавить AID (hex)';

  @override
  String get notificationProcessing => 'Уведомления';

  @override
  String get manageAutoNotification =>
      'Управление автоматической обработкой уведомлений';

  @override
  String get notificationProcessingHelp =>
      'Обработка уведомлений помогает синхронизировать вашу eUICC с сервером SM-DP+ (оператором). Удаление отправленных уведомлений освобождает память карты.';

  @override
  String get notificationProcessingTimings => 'Моменты обработки';

  @override
  String get notificationProcessingTimingsHelp =>
      'Выберите, когда выполняется автоматическая обработка уведомлений. Некоторые критически важные моменты можно отключить только в режиме разработчика.';

  @override
  String get afterEnablingProfile => 'После включения профиля';

  @override
  String get afterDisablingProfile => 'После отключения профиля';

  @override
  String get afterProfileDownload => 'После загрузки профиля';

  @override
  String get afterProfileDeletion => 'После удаления профиля';

  @override
  String get initialLoad => 'Первая загрузка';

  @override
  String get processNotificationsOnInitialLoad =>
      'Обрабатывать уведомления после завершения загрузки профилей';

  @override
  String get afterSwitchingProfile => 'После переключения профиля';

  @override
  String get processNotificationsAfterSwitchingProfile =>
      'Обрабатывать уведомления после включения или отключения профиля';

  @override
  String get beforeProfileDownload => 'Перед загрузкой профиля';

  @override
  String get processNotificationsBeforeProfileDownload =>
      'Обрабатывать уведомления перед началом загрузки профиля';

  @override
  String get afterProfileInstalled => 'После установки профиля';

  @override
  String get processNotificationsAfterProfileInstalled =>
      'Обрабатывать уведомления после установки профиля';

  @override
  String get processNotificationsAfterProfileDeletion =>
      'Обрабатывать уведомления после удаления профиля';

  @override
  String get developerModeRequiredToDisableTiming =>
      'Чтобы отключить этот момент, включите режим разработчика.';

  @override
  String get sendToServerAutomatically => 'Отправлять на сервер автоматически';

  @override
  String get removeFromCardAfterSending => 'Удалять с карты после отправки';

  @override
  String get removeWithoutSendingCaution =>
      'Используйте с осторожностью: сервер не будет уведомлён';

  @override
  String get reminderSettings => 'Настройки напоминаний';

  @override
  String get appCanSendNotifications =>
      'Приложение может отправлять системные уведомления';

  @override
  String get requiredForReminderAlerts =>
      'Необходимо для оповещений о напоминаниях';

  @override
  String get enable => 'Включить';

  @override
  String get permissionCheckNotSupported =>
      'Проверка разрешений не поддерживается на этой платформе. Проверьте вручную.';

  @override
  String get testNotification => 'Тестовое уведомление';

  @override
  String get notificationsDisabledMessage =>
      'Уведомления отключены. Включите их в системных настройках, чтобы получать напоминания.';

  @override
  String get openSettings => 'Открыть настройки';

  @override
  String get applicationLogs => 'Журналы приложения';

  @override
  String get refreshReload => 'Обновить';

  @override
  String get toggleAutoScroll => 'Автопрокрутка';

  @override
  String get refreshDevices => 'Обновить список устройств';

  @override
  String get scanBluetooth => 'Искать по Bluetooth';

  @override
  String get lessThan1Kb => '< 1 КБ';

  @override
  String get connectionFailed => 'Не удалось подключиться';

  @override
  String get downloadRemoCard => 'Скачать RemoCard';

  @override
  String get remoCardAndroidApp =>
      'Android-приложение для удалённых считывателей';

  @override
  String get resentSuccessfully => 'Отправлено повторно';

  @override
  String get resendFailed => 'Не удалось отправить повторно';

  @override
  String get eid => 'EID';

  @override
  String get seq => '№';

  @override
  String get date => 'Дата';

  @override
  String errorWithDetails(String error) {
    return 'Ошибка: $error';
  }

  @override
  String exportFailed(String error) {
    return 'Не удалось экспортировать базу данных: $error';
  }

  @override
  String get sasAccreditation => 'Аккредитация SAS';

  @override
  String get firmwareVersion => 'Версия прошивки';

  @override
  String get beeSimFirmwareAction => 'Обновить прошивку BeeSIM';

  @override
  String get beeSimFirmwareTitle => 'Обновление прошивки BeeSIM';

  @override
  String get beeSimFirmwareWarning =>
      'Доступно обновление прошивки BeeSIM. До завершения не отключайте питание карты, не разрывайте соединение Bluetooth и не закрывайте приложение. Прерывание обновления может временно вывести карту из строя.';

  @override
  String get beeSimFirmwareConfirm => 'Обновить прошивку';

  @override
  String get platformSupport => 'ПОДДЕРЖКА ПЛАТФОРМЫ';

  @override
  String get rspVersion => 'Версия RSP';

  @override
  String get bppVersion => 'Версия BPP';

  @override
  String get gpVersion => 'Версия GlobalPlatform';

  @override
  String get certInfrastructure => 'ИНФРАСТРУКТУРА СЕРТИФИКАТОВ';

  @override
  String get configuredAddresses => 'НАСТРОЕННЫЕ АДРЕСА';

  @override
  String get defaultSmdpAddress => 'SM-DP+ по умолчанию';

  @override
  String get rootDsAddress => 'Корневой SM-DS';

  @override
  String get euiccSignCi => 'CI подписи eUICC';

  @override
  String get euiccVerifyCi => 'CI проверки eUICC';

  @override
  String get none => 'Нет';

  @override
  String keysCount(int count) {
    return 'Ключей: $count';
  }

  @override
  String get state => 'Состояние';

  @override
  String get profileClass => 'Класс';

  @override
  String get aid => 'AID';

  @override
  String get euiccSpecifications => 'СПЕЦИФИКАЦИИ EUICC';

  @override
  String get sending => 'Отправка…';

  @override
  String get failedToSaveTags => 'Не удалось сохранить метки';

  @override
  String get note => 'Заметка';

  @override
  String get notificationDetails => 'Сведения об уведомлении';

  @override
  String get unknown => 'Неизвестно';

  @override
  String get status => 'Статус';

  @override
  String get sent => 'Отправлено';

  @override
  String get pending => 'Ожидает';

  @override
  String get notifTypeInstall => 'Установка';

  @override
  String get notifTypeDelete => 'Удаление';

  @override
  String get notifTypeEnable => 'Включение';

  @override
  String get notifTypeDisable => 'Отключение';

  @override
  String get notifTypeRpmEnable => 'RPM: включение';

  @override
  String get notifTypeRpmDisable => 'RPM: отключение';

  @override
  String get notifTypeRpmDelete => 'RPM: удаление';

  @override
  String get notifTypeLoadRpm => 'Загрузка RPM';

  @override
  String confirmDeleteNotification(int seq) {
    return 'Удалить уведомление №$seq?';
  }

  @override
  String get notificationRemoved => 'Уведомление удалено';

  @override
  String failedToRemove(String error) {
    return 'Не удалось удалить: $error';
  }

  @override
  String get curlCopied => 'Команда cURL скопирована в буфер обмена';

  @override
  String failedToGenerateCurl(String error) {
    return 'Не удалось сформировать cURL: $error';
  }

  @override
  String get noNotificationAddress => 'Адрес для уведомления недоступен';

  @override
  String get sendingNotification => 'Отправка уведомления…';

  @override
  String get notifSentSuccessfully => 'Уведомление отправлено';

  @override
  String get failedToSendNotification => 'Не удалось отправить уведомление';

  @override
  String errorSendingNotification(String error) {
    return 'Ошибка при отправке уведомления: $error';
  }

  @override
  String pendingCount(int count) {
    return 'Ожидает: $count';
  }

  @override
  String get currentReader => 'Текущий считыватель';

  @override
  String get errorLoadingNotifications => 'Ошибка загрузки уведомлений';

  @override
  String get allCaughtUp => 'Всё обработано';

  @override
  String get sequence => 'Последовательность';

  @override
  String get operation => 'Операция';

  @override
  String get profileNameLabel => 'Имя профиля';

  @override
  String get failedToSend => 'Не удалось отправить';

  @override
  String get onCard => 'На карте';

  @override
  String get sendNotification => 'Отправить уведомление';

  @override
  String get deleteNotification => 'Удалить уведомление';

  @override
  String get noNotifications => 'Нет уведомлений';

  @override
  String get batchDownloadTitle => 'Пакетная загрузка';

  @override
  String get batchDownloadHint =>
      'Вставьте несколько кодов LPA (по одному в строке, не более 20)';

  @override
  String foundLpaCodes(int count) {
    return 'Найдено кодов LPA: $count';
  }

  @override
  String get startBatch => 'Начать пакетную загрузку';

  @override
  String get noLpaCodesFound => 'Корректные коды LPA не найдены';

  @override
  String get insufficientSpaceStoppingBatch =>
      'Недостаточно места. Пакетная загрузка остановлена.';

  @override
  String get exportCsv => 'Экспорт в CSV';

  @override
  String get exportedSuccessfully => 'Экспортировано';

  @override
  String get exportResults => 'Экспорт результатов';

  @override
  String get lpa => 'LPA';

  @override
  String get smdp => 'SM-DP+';

  @override
  String get confirmationCode => 'Код подтверждения';

  @override
  String get size => 'Размер';

  @override
  String get message => 'Сообщение';

  @override
  String get remainingSpace => 'Свободное место';

  @override
  String get stopBatch => 'Остановить';

  @override
  String get stopping => 'Остановка…';

  @override
  String get remove => 'Удалить';

  @override
  String get updateAvailable => 'Доступно обновление';

  @override
  String updateAvailableSubtitle(String appName, String version, String build) {
    return 'Доступна новая версия $appName (v$version b$build). Обновить сейчас?';
  }

  @override
  String get updateAction => 'Обновить';

  @override
  String get later => 'Позже';

  @override
  String get changelog => 'Список изменений';

  @override
  String get sortBy => 'Сортировка';

  @override
  String get sortIccid => 'ICCID';

  @override
  String get sortCountry => 'Страна';

  @override
  String get sortAscending => 'По возрастанию';

  @override
  String get sortDescending => 'По убыванию';

  @override
  String get searchProfiles => 'Поиск профилей…';

  @override
  String get noProfilesMatch => 'Нет профилей, соответствующих запросу.';

  @override
  String get sortDefault => 'По умолчанию';

  @override
  String get sortNickname => 'По имени';

  @override
  String get showProfileSearch => 'Показывать поиск профилей';

  @override
  String get showProfileSearchSubtitle =>
      'Показывать панель поиска и сортировки в списке профилей';

  @override
  String get noReaderFound =>
      'Считыватель не найден. Подключите адаптер eUICC.';

  @override
  String get readyToInstallProfile => 'Профиль готов к установке.';

  @override
  String get downloadHere => 'Загрузить сюда';

  @override
  String get manage => 'Управление';

  @override
  String get buyCard => 'Карта';

  @override
  String get buyData => 'Трафик';

  @override
  String get selectDevice => 'Выбор устройства';

  @override
  String get selectReaderTitle => 'Выбор карты';

  @override
  String get authorizeSigning => 'Разрешить подпись';

  @override
  String get signingDescription =>
      'Веб-сайт запрашивает защищённую подпись у вашей eUICC.';

  @override
  String get smdpAddress => 'Адрес SM-DP+';

  @override
  String get sign => 'Подписать';

  @override
  String profilesInstalled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count профиля установлено',
      many: '$count профилей установлено',
      few: '$count профиля установлено',
      one: '$count профиль установлен',
    );
    return '$_temp0';
  }

  @override
  String get estimatedDownloadSize => 'Предполагаемый размер загрузки';

  @override
  String get phoneFormatInternationalOnly => 'Только E.164';

  @override
  String get phoneFormatInternationalAndMobile => 'Междунар. и мобильные';

  @override
  String get phoneFormatInternationalAndAll => 'Междунар. и национальные';

  @override
  String get phoneFormatOff => 'Выключено';

  @override
  String get settings_item_unit_b => 'Байты';

  @override
  String get settings_item_unit_kb => 'кБ (1000 байт)';

  @override
  String get settings_item_unit_kib => 'КиБ (1024 байта)';

  @override
  String get settings_item_unit_adaptive_si => 'Б / кБ автоматически';

  @override
  String get settings_item_unit_adaptive_bi => 'Б / КиБ автоматически';

  @override
  String get insufficientStorageWarning =>
      'Недостаточно места для установки. Установка может завершиться ошибкой.';

  @override
  String get estimateProfileSize => 'Оценивать размер профиля';

  @override
  String get estimateProfileSizeSubtitle =>
      'Оценивать размер метаданных профиля перед загрузкой';

  @override
  String get customize => 'Настроить';

  @override
  String get customizeDescription =>
      'Задайте новое имя из 6 шестнадцатеричных символов и пароль для вашего считывателя.';

  @override
  String get customizeSuccess =>
      'Считыватель настроен. Выполните сопряжение заново.';

  @override
  String customizeFailed(String error) {
    return 'Не удалось настроить считыватель: $error';
  }

  @override
  String get defaultPasswordWillChangeTitle =>
      'Пароль по умолчанию будет изменён';

  @override
  String defaultPasswordWillChangeMessage(String password) {
    return 'Это устройство подключено со стандартным паролем. После переименования пароль станет $password. Сохраните его перед повторным подключением.';
  }

  @override
  String get savedBleDevices => 'Ранее подключённые BLE-устройства';

  @override
  String get savedBleDevicesSubtitle =>
      'Просмотр имён и паролей устройств, сохранённых на этом устройстве';

  @override
  String get savedBleDevicesDescription =>
      'Каждая запись — локально сохранённый пароль NBLESim. Стандартные пароли также сохраняются.';

  @override
  String get noSavedBleDevices => 'Ранее подключённых BLE-устройств нет.';

  @override
  String get deviceName => 'Имя устройства';

  @override
  String get success => 'Готово';

  @override
  String get devicePasswordHint => '6 шестнадцатеричных символов или пароль';

  @override
  String get sixHexChars => '6 шестнадцатеричных символов';

  @override
  String get database => 'База данных';

  @override
  String exportSuccess(String path) {
    return 'База данных экспортирована в $path';
  }

  @override
  String get importDatabase => 'Импорт базы данных';

  @override
  String get importDatabaseSubtitle =>
      'Объединить записи из другого файла базы данных';

  @override
  String get importDatabaseDialogTitle =>
      'Выберите файл базы данных для импорта';

  @override
  String get importDatabaseTitle => 'Импорт базы данных';

  @override
  String get importDatabaseContent =>
      'Записи из выбранной базы будут объединены с текущей. Существующие записи с такими же ключами будут перезаписаны. Продолжить?';

  @override
  String get import => 'Импортировать';

  @override
  String get importSuccess => 'База данных импортирована';

  @override
  String importFailed(String error) {
    return 'Не удалось импортировать базу данных: $error';
  }

  @override
  String get resetDatabase => 'Сбросить базу данных';

  @override
  String get resetDatabaseSubtitle =>
      'Удалить все данные приложения и перезапустить';

  @override
  String get resetDatabaseTitle => 'Сброс базы данных приложения';

  @override
  String get resetDatabaseContent =>
      'Все локально сохранённые данные, настройки и журналы будут полностью удалены. Приложение закроется. Продолжить?';

  @override
  String get deleteDatabase => 'Удалить базу данных';

  @override
  String resetFailed(String error) {
    return 'Не удалось сбросить базу данных: $error';
  }

  @override
  String get deviceImei => 'TAC устройства';

  @override
  String get deviceImeiSubtitle => 'Используется при загрузке профилей';

  @override
  String get editDeviceImei => 'Изменить TAC устройства';

  @override
  String get editDeviceImeiInfo =>
      'Введите 8-значный TAC или 15-значный IMEI. TAC по умолчанию: 35383741.';

  @override
  String get imeiDigits => 'Цифры TAC или IMEI';

  @override
  String get importAction => 'Импортировать';

  @override
  String get transferTitle => 'Перенос eSIM';

  @override
  String get transferAction => 'Перенести на это устройство';

  @override
  String get transferCheckingEligibility => 'Проверка возможности переноса…';

  @override
  String get transferReadingSource => 'Чтение исходной SIM…';

  @override
  String get transferContactingCarrier => 'Связь с оператором…';

  @override
  String get transferIneligibleReader =>
      'Этот профиль нельзя перенести с помощью данного считывателя. Аутентификация исходной SIM (EAP-AKA) здесь недоступна.';

  @override
  String get transferNoEntitlement =>
      'Для этого профиля не найдена конфигурация переноса оператора. Вы можете указать сервер entitlement вручную.';

  @override
  String transferSourceCarrier(String carrier) {
    return 'Исходный оператор: $carrier';
  }

  @override
  String get transferConfirmTitle => 'Перенести эту подписку?';

  @override
  String get transferConfirmBody =>
      'Оператор перевыпустит эту подписку на данную eUICC. Исходный профиль может быть удалён в процессе переноса.';

  @override
  String get transferStart => 'Начать перенос';

  @override
  String get transferDownloadingProfile => 'Загрузка перенесённого профиля…';

  @override
  String get transferDeleteSourceTitle => 'Удалить исходный профиль';

  @override
  String transferDeleteSourceBody(String iccid) {
    return 'Оператор требует удалить исходный профиль $iccid до активации. Удалить его сейчас?';
  }

  @override
  String get transferDeleteSourceConfirm => 'Удалить и продолжить';

  @override
  String get transferUserInputSubmit => 'Отправить';

  @override
  String get transferAccept => 'Принять';

  @override
  String get transferReject => 'Отклонить';

  @override
  String get transferPendingActivation =>
      'Оператор ещё активирует эту подписку. Это скоро завершится; можно закрыть окно и проверить позже.';

  @override
  String get transferDismissed => 'Оператор отклонил перенос.';

  @override
  String get transferDelayedDownload =>
      'Оператор доставит профиль в ближайшее время. После установки введите ICCID установленного профиля, чтобы завершить перенос.';

  @override
  String get transferInstalledIccid => 'ICCID установленного профиля';

  @override
  String get transferSuccess => 'Перенос завершён';

  @override
  String transferFailed(String error) {
    return 'Не удалось выполнить перенос: $error';
  }

  @override
  String get transferManualServerTitle => 'Сервер entitlement (для опытных)';

  @override
  String get transferManualServerHint => 'https://entitlement.example.com';

  @override
  String get transferEnablingSource => 'Подготовка исходного профиля…';

  @override
  String get transferClose => 'Закрыть';

  @override
  String get transferContinue => 'Продолжить';

  @override
  String get transferSmdsDiscovering => 'Поиск профилей через SM-DS…';

  @override
  String get transferSmdsNoProfiles =>
      'Ожидающих профилей через SM-DS не найдено.';

  @override
  String get transferSelectProfile => 'Выберите профиль для загрузки';

  @override
  String get discoverProfiles => 'Найти профили (SM-DS)';

  @override
  String get discoveringProfiles => 'Поиск профилей…';

  @override
  String get discoveryNoProfiles =>
      'Ожидающих профилей через SM-DS не найдено.';

  @override
  String get transferSmdsServerTitle => 'Сервер SM-DS';

  @override
  String transferProfileOnServer(String eventId, String address) {
    return '$eventId на $address';
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
