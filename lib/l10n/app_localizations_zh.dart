// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get settingsTitle => '设置';

  @override
  String get displaySettings => '显示设置';

  @override
  String get appearance => '外观';

  @override
  String get appearanceSubtitle => '自定义主题、布局和显示偏好';

  @override
  String get darkMode => '深色模式';

  @override
  String get themeStyle => '主题样式';

  @override
  String get themeStyleSubtitle => '在自定义和 MD3 样式之间选择';

  @override
  String get customDesign => 'Nekoko 样式';

  @override
  String get stockMD3 => '原生 MD3';

  @override
  String get waterfallLayout => '瀑布流布局';

  @override
  String get waterfallLayoutSubtitle => '在宽屏上使用砖块式布局';

  @override
  String get system => '跟随系统';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get language => '语言';

  @override
  String get systemLanguage => '系统语言';

  @override
  String get general => '通用';

  @override
  String get ui => '用户界面';

  @override
  String get autoLoadProfiles => '自动加载配置';

  @override
  String get autoLoadProfilesSubtitle => '选择读卡器时自动加载卡内配置';

  @override
  String get loadProfileIcons => '加载配置图标';

  @override
  String get loadProfileIconsSubtitle => '从eUICC读取图标（较慢）';

  @override
  String get useNekokoIcons => '使用运营商图标';

  @override
  String get useNekokoIconsSubtitle => '从 operator-icons 获取运营商图标';

  @override
  String get forceDeviceDropdown => '强制从下拉菜单选择设备';

  @override
  String get forceDeviceDropdownSubtitle => '始终使用下拉菜单选择设备';

  @override
  String get sizeDisplayUnit => '容量显示单位';

  @override
  String get sizeDisplayUnitSubtitle => '存储容量的显示格式';

  @override
  String get phoneFormat => '电话号码格式';

  @override
  String get phoneFormatSubtitle => '显示电话号码的格式';

  @override
  String get notifications => '通知';

  @override
  String get notificationSettings => '通知设置';

  @override
  String get notificationSettingsSubtitle => '配置自动处理和清理';

  @override
  String get notificationHistory => '通知历史';

  @override
  String get notificationHistorySubtitle => '查找、管理和重发已发送的通知';

  @override
  String get tagsAndReminders => '标签与提醒';

  @override
  String get tagManager => '标签管理';

  @override
  String get tagManagerSubtitle => '创建和编辑配置标签';

  @override
  String get tagReminders => '标签提醒';

  @override
  String get tagRemindersSubtitle => '基于日期标签的定时通知';

  @override
  String get manageTagsAndReminders => '管理标签与提醒';

  @override
  String get manageTagsAndRemindersSubtitle => '配置标签、权限和测试警报';

  @override
  String get viewScheduledReminders => '查看已安排的提醒';

  @override
  String get viewScheduledRemindersSubtitle => '管理即将到来的标签通知';

  @override
  String get connectivity => '连接';

  @override
  String get remoteReaders => '远程读卡器';

  @override
  String get remoteReadersSubtitle => '配置 RemoCard 配件应用';

  @override
  String get enableBle => '蓝牙连接器';

  @override
  String get enableBleSubtitle => '启用扫描和连接蓝牙读卡器';

  @override
  String get enableCcid => 'USB CCID 连接器';

  @override
  String get enableCcidSubtitle => '启用 USB 智能卡读卡器 (CCID)';

  @override
  String get enableOmapi => 'OMAPI 连接器';

  @override
  String get enableOmapiSubtitle => '通过 OMAPI 启用内置 eUICC 访问';

  @override
  String get enableTmapi => 'Telephony API 连接器';

  @override
  String get enableTmapiSubtitle => '通过 Telephony API API 启用特权访问';

  @override
  String get readerTypes => '读卡器类型';

  @override
  String get readerTypesSubtitle => '管理已启用的读卡器类型（CCID、蓝牙、远程等）';

  @override
  String get enabledReaderTypes => '已启用的读卡器类型';

  @override
  String get enabledReaderTypesSubtitle => '控制应用中可用的读卡器类型';

  @override
  String get remoteReaderSettings => '远程读卡器设置';

  @override
  String get remoteReaderSettingsSubtitle => '配置远程读卡器服务器和连接';

  @override
  String get ccidReaderTitle => 'CCID（USB/PC/SC）';

  @override
  String get ccidReaderSubtitle => 'USB智能卡读卡器和PC/SC设备';

  @override
  String get bluetoothReaderTitle => '蓝牙';

  @override
  String get bluetoothReaderSubtitle => '蓝牙LE智能卡读卡器和写卡器';

  @override
  String get remoteReadersTitle => '远程读卡器';

  @override
  String get remoteReadersConnectorSubtitle => '网络连接的远程智能卡读卡器';

  @override
  String get omapiReaderTitle => 'OMAPI';

  @override
  String get omapiReaderSubtitle => '通过Open Mobile API的内置SIM卡槽';

  @override
  String get tmapiReaderTitle => 'Telephony API';

  @override
  String get tmapiReaderSubtitle => '通过Telephony API的内置eSIM';

  @override
  String get remoteServerConfiguration => '远程服务器配置';

  @override
  String get remoteServerConfigurationSubtitle => '管理远程读卡器服务器和连接设置';

  @override
  String get enableBrowser => '启用浏览器';

  @override
  String get enableBrowserSubtitle => '在主屏幕显示商店、购买或帮助等额外标签';

  @override
  String get transport => '传输';

  @override
  String get disableRefreshFlags => '禁用刷新标志';

  @override
  String get disableRefreshFlagsSubtitle => '不适用于外部读卡器';

  @override
  String get apduMaxSegmentSize => 'APDU 最大分段大小';

  @override
  String get apduMaxSegmentSizeSubtitle => '每个 APDU 数据块的最大大小';

  @override
  String get ensureSingleChannel => '确保单通道';

  @override
  String get ensureSingleChannelSubtitle => '在打开新逻辑通道前关闭其他通道';

  @override
  String get analytics => '分析与云服务';

  @override
  String get nekokoCloud => 'Nekoko 云';

  @override
  String get nekokoCloudSubtitle => '分析安装数据以改进预测';

  @override
  String get developer => '开发者';

  @override
  String get developerMode => '开发者模式';

  @override
  String get developerModeSubtitle => '启用高级调试功能';

  @override
  String get exportDatabase => '导出数据库';

  @override
  String get exportDatabaseSubtitle => '保存本地数据库副本';

  @override
  String get openDatabaseFolder => '打开数据库文件夹';

  @override
  String get openDatabaseFolderSubtitle => '打开包含数据库文件的文件夹';

  @override
  String get decodeAsn1 => '解码 ASN.1 日志 (慢)';

  @override
  String get decodeAsn1Subtitle => '严重影响性能';

  @override
  String get viewAppLogs => '查看应用日志';

  @override
  String get viewAppLogsSubtitle => '查看收集的应用程序日志';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get build => '构建';

  @override
  String get checkUpdates => '检查更新';

  @override
  String get checkUpdatesSubtitle => '启动时自动检查新版本';

  @override
  String get licenses => '开源许可';

  @override
  String get licensesSubtitle => '所使用的开源库的许可信息';

  @override
  String get noUpdatesFound => '未发现更新';

  @override
  String get profilesTitle => '配置列表';

  @override
  String get switchEstkSlot => '切换 eSTK 插槽';

  @override
  String get notificationsButton => '通知';

  @override
  String get downloadProfile => '下载配置';

  @override
  String get reconnect => '重新连接';

  @override
  String get bluetoothNotConnected => '蓝牙未连接';

  @override
  String get bluetoothNotConnectedSubtitle => '请确保蓝牙已开启且设备在附近。点击连接以开始使用此设备。';

  @override
  String get bluetoothConnectionFailed => '蓝牙连接失败';

  @override
  String bluetoothConnectionFailedSubtitle(Object error) {
    return '无法连接到蓝牙设备。\n\n$error';
  }

  @override
  String get removeDevice => '移除设备';

  @override
  String get retryConnection => '连接';

  @override
  String get remoteConnectionFailed => '远程读卡器连接失败';

  @override
  String remoteConnectionFailedMessage(Object error) {
    return '确保远程服务器正在运行且可访问。\n\n$error';
  }

  @override
  String get errorBluetoothTimeout => '蓝牙操作超时。请再试一次。';

  @override
  String get errorOmapiSecurity => '安全错误：操作系统或 ARA-M 规则拒绝访问该卡片。';

  @override
  String get errorApplicationNotFound =>
      '找不到 eUICC 管理应用程序 (ISD-R) 。此卡可能不是有效的 eUICC。';

  @override
  String get changeSettings => '更改设置';

  @override
  String get connectCompatibleReader => '请连接兼容的读卡器以开始。';

  @override
  String get connectReaderMessageBle => '如果您有支持蓝牙的 eUICC，也可以扫描蓝牙设备。';

  @override
  String get connectReaderMessageNoBle => '请确保您的 CCID 读卡器已连接到电脑。';

  @override
  String get downloadSmartCardExtension => '下载智能卡扩展';

  @override
  String get smartCardExtensionMessage => '此浏览器需要扩展程序才能访问 USB CCID 读卡器。';

  @override
  String get scanForBluetooth => '扫描蓝牙设备';

  @override
  String get connectRemote => '连接远程设备';

  @override
  String get noCardDetected => '未检测到卡片';

  @override
  String get noCardDetectedMessage => '在此插槽中未找到可用或活动的 eUICC。';

  @override
  String get noDataLoaded => '未连接';

  @override
  String get loadProfiles => '连接';

  @override
  String get disconnect => '断开连接';

  @override
  String get disconnecting => '正在断开连接...';

  @override
  String get profilesEmpty => '卡内无配置';

  @override
  String get profilesEmptyMessage => '此 eUICC 卡是空的。';

  @override
  String get renameProfile => '重命名配置文件';

  @override
  String get nickname => '昵称';

  @override
  String get enterProfileNickname => '输入配置昵称';

  @override
  String get profileNicknameNote => '注意：标签通过“标签管理”菜单单独管理。';

  @override
  String get useProfileIcon => '使用配置图标';

  @override
  String get useProfileIconSubtitle => 'eSIM 卡自带图标';

  @override
  String get removeCustomIcon => '移除自定义图标';

  @override
  String get noRemoteIcon => '该运营商无远程图标';

  @override
  String get cancel => '取消';

  @override
  String get ok => '确定';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get refresh => '刷新';

  @override
  String get initializing => '初始化中...';

  @override
  String get refreshingProfiles => '刷新配置中...';

  @override
  String get retrievingEid => '正在获取 EID 和信息...';

  @override
  String get updatingProfile => '正在更新配置...';

  @override
  String get manageIsdR => '管理 ISD-R AID';

  @override
  String get manageIsdRSubtitle => '配置 eUICC 的默认应用 ID';

  @override
  String get transportFailed => '传输失败';

  @override
  String get remoteTransportFailedMessage =>
      '已连接到远程服务器，但命令执行失败。这通常意味着远程设备暂时正忙或与卡断开连接。是否重试？';

  @override
  String get retry => '重试';

  @override
  String get scanningForReaders => '正在扫描读卡器...';

  @override
  String get switchedEstkSlot => '已切换 eSTK 插槽';

  @override
  String get scanningForUnresponsiveDevices => '正在扫描无响应设备...';

  @override
  String get resettingConnection => '正在重置连接...';

  @override
  String get connectingToReader => '正在连接到读卡器...';

  @override
  String get moreOptions => '更多选项';

  @override
  String get retrievingProfiles => '正在获取配置列表...';

  @override
  String get savingProfileMetadata => '正在保存配置元数据...';

  @override
  String get enablingProfile => '正在启用配置...';

  @override
  String get disablingProfile => '正在禁用配置...';

  @override
  String get deleteProfile => '删除配置';

  @override
  String deleteProfileConfirmation(Object profileName) {
    return '确定要删除配置 $profileName 吗？\n此操作无法撤销。';
  }

  @override
  String get deletingProfile => '正在删除配置...';

  @override
  String get deleting => 'Deleting...';

  @override
  String get dataUsage => '流量消耗';

  @override
  String get details => '详情';

  @override
  String get rename => '重命名';

  @override
  String get changeIcon => '更改图标';

  @override
  String get manageTags => '管理标签';

  @override
  String get copyIccid => '复制 ICCID';

  @override
  String get notificationProcessingError => '通知正在处理中，无法执行操作';

  @override
  String get operationInProgressError => 'Operation in progress, please wait';

  @override
  String iccidCopied(Object iccid) {
    return 'ICCID 已复制: $iccid';
  }

  @override
  String get operationRestricted => '操作受限';

  @override
  String get notificationProcessingDownloadError => '通知仍在处理中。请在下载新配置前等待处理完成。';

  @override
  String get operational => '运营级';

  @override
  String get test => '测试级';

  @override
  String get provisioning => '预置级';

  @override
  String get profileDetails => '配置详情';

  @override
  String get profileDetailsSubtitle => '来自 eUICC 该配置插槽的信息。';

  @override
  String get enabled => '已启用';

  @override
  String get disabled => '已禁用';

  @override
  String get tagsManagedSeparately => '注意：标签通过“管理标签”菜单独立管理。';

  @override
  String get changeProfileIcon => '更改配置图标';

  @override
  String get selectFromGallery => '从相册选择';

  @override
  String get nekokoOperatorIcon => '运营商图标';

  @override
  String get iconFromEsim => '来自 eSIM 卡的图标';

  @override
  String updateIconFailed(Object error) {
    return '更新图标失败: $error';
  }

  @override
  String get failedToReadImage => '无法读取图片文件';

  @override
  String get failedToProcessImage => '无法处理图片';

  @override
  String get customIconSet => '自定义图标设置成功';

  @override
  String get noMccMnc => '此配置没有可用的 MCC/MNC';

  @override
  String get fetchingRemoteIcon => '正在获取远程图标...';

  @override
  String get remoteIconSaved => '远程图标已保存为自定义图标';

  @override
  String fetchRemoteIconFailed(Object error) {
    return '获取远程图标失败: $error';
  }

  @override
  String get noProfileIcon => '没有可用的配置图标';

  @override
  String get profileIconSaved => '配置图标已保存为自定义图标';

  @override
  String get customIconRemoved => '自定义图标已移除';

  @override
  String get failed => '失败';

  @override
  String euiccError(Object action) {
    return 'eUICC 在尝试 $action 配置时返回错误。';
  }

  @override
  String get dismiss => '忽略';

  @override
  String get dataPlan => '流量套餐';

  @override
  String get used => '已用';

  @override
  String get total => '总量';

  @override
  String expires(Object date) {
    return '过期时间: $date';
  }

  @override
  String get close => '关闭';

  @override
  String get server => '服务器';

  @override
  String get switchFailed => '切换失败';

  @override
  String get deviceRefreshFailed => '设备刷新失败';

  @override
  String get euiccOptions => 'eUICC 选项';

  @override
  String get euiccInfo => 'eUICC 信息';

  @override
  String get hideEid => '隐藏 EID';

  @override
  String get showEid => '显示 EID';

  @override
  String get copyEid => '复制 EID';

  @override
  String get eidCopied => 'EID 已复制到剪贴板';

  @override
  String get connectRemotes => '连接远程';

  @override
  String get configureRemotes => '配置远程';

  @override
  String get connectingToRemoteReaders => '正在后台连接远程读卡器...';

  @override
  String get noRemoteReadersFound => '未找到远程读卡器';

  @override
  String connectedRemoteReaders(Object count) {
    return '已连接 $count 个远程读卡器';
  }

  @override
  String failedToConnectRemoteReaders(Object error) {
    return '连接远程读卡器失败: $error';
  }

  @override
  String get remoteReaderPassword => '远程读卡器密码';

  @override
  String get remoteReaderPasswordSubtitle => '此远程读卡器需要密码。';

  @override
  String get password => '密码';

  @override
  String get deleteConnection => '删除连接';

  @override
  String get connect => '连接';

  @override
  String get remoteReaderConnectionFailed => '远程读卡器连接失败';

  @override
  String remoteReaderConnectionFailedSubtitle(Object error) {
    return '请确保远程服务器正在运行且可访问。\n\n$error';
  }

  @override
  String get connectReader => '连接兼容的读卡器以开始。';

  @override
  String get connectReaderSubtitleBle => '如果您有支持蓝牙的 eUICC，也可以扫描兼容的蓝牙设备。';

  @override
  String get connectReaderSubtitleCcid => '请确保您的 CCID 读卡器已连接到电脑。';

  @override
  String get downloadExtension => '下载智能卡扩展';

  @override
  String get downloadExtensionSubtitle => '在此浏览器中访问 USB CCID 读卡器需要该扩展。';

  @override
  String get cardUnsupported => '不支持该卡';

  @override
  String get cardUnsupportedSubtitle => '此卡可能不是 eUICC，或者该读卡器不支持此卡，或者正在被其他程序占用。';

  @override
  String get omapiWelcome => '好消息 — 您的设备支持 OMAPI，极有可能兼容可拆卸 eUICC 卡！';

  @override
  String get supportedDevices => '支持的设备';

  @override
  String get aboutAram => '关于 ARA-M';

  @override
  String get accessDenied => '访问被拒绝';

  @override
  String get accessDeniedSubtitle =>
      '访问此 eUICC 需要运营商权限。该卡的 ARA-M 允许列表与此应用的签名不匹配。';

  @override
  String get noCardDetectedSubtitle => '在此插槽中未找到不支持或活动的 eUICC。';

  @override
  String get noProfilesInstalled => '未安装任何配置';

  @override
  String get noProfilesInstalledSubtitle => '此 eUICC 卡是空的。';

  @override
  String get cardRefreshingTitle => '正在刷新卡片';

  @override
  String get cardRefreshingMessage => '卡片正在更新状态。此时无法检索个人资料列表。请等待几秒钟，然后重试。';

  @override
  String get useRemoteIcon => '使用远程图标';

  @override
  String get bleDisconnectedTitle => '蓝牙连接丢失';

  @override
  String get bleDisconnectedMessage => '与卡片阅读器的连接突然丢失。请确保它在附近并已开启。';

  @override
  String get cardStuckRefreshingMessage => '配置文件状态正在更改——如果卡住，请手动将SIM卡重新插入。';

  @override
  String get activationCodeTitle => '激活码';

  @override
  String get activationCodeSubtitle => '扫描二维码、拖拽图片或手动输入 LPA 字符串。';

  @override
  String get fullActivationCodeLabel => '完整激活码';

  @override
  String get fullActivationCodeHint => 'LPA:1\$smdp.io\$MATCHING-ID';

  @override
  String get pasteFromClipboardTooltip => '从剪贴板粘贴';

  @override
  String get selectFromGalleryTooltip => '从相册选择';

  @override
  String get scanQrCodeTooltip => '扫描二维码';

  @override
  String get smdpAddressLabel => 'SM-DP+ 地址';

  @override
  String get smdpAddressHint => 'smdp.io';

  @override
  String get matchingIdLabel => '匹配 ID';

  @override
  String get matchingIdHint => 'ABC-123';

  @override
  String get smdpOidLabel => 'SM-DP+ OID';

  @override
  String get confirmationCodeLabel => '确认码';

  @override
  String get confirmationCodeHint => '输入确认码';

  @override
  String get continueButton => '继续';

  @override
  String get invalidLpaClipboard => '剪贴板不包含有效的 LPA 字符串。';

  @override
  String get invalidFqdnFormat => 'FQDN 格式无效';

  @override
  String get invalidMatchingIdChars => '匹配 ID 包含非法字符';

  @override
  String get invalidOidFormat => 'OID 格式无效 (例如 1.2.840...)';

  @override
  String get activationCodeRequired => '必须输入激活码';

  @override
  String get invalidLpaFormatGeneric => 'LPA 格式无效';

  @override
  String get smdpAddressRequired => '必须输入 SM-DP+ 地址';

  @override
  String get loadingNotifications => '正在加载通知...';

  @override
  String get processing => '处理中...';

  @override
  String get analyzingImage => '正在分析图片...';

  @override
  String get noQrFoundInImage => '图片中未找到二维码';

  @override
  String get invalidAcInImage => '图片中包含无效的激活码';

  @override
  String get invalidAcFormatDetailed => '激活码格式无效。必须以 LPA:1\$ 开头...';

  @override
  String get downloadProfileTitle => '下载配置文件';

  @override
  String get connectingToEuicc => '正在连接 eUICC...';

  @override
  String get gettingChallenge => '正在获取 eUICC 挑战值...';

  @override
  String get authenticatingWithSmdp => '正在进行 SM-DP+ 认证...';

  @override
  String get verifyingSignatures => '正在验证 SM-DP+ 签名...';

  @override
  String get retrievingMetadata => '正在获取配置文件元数据...';

  @override
  String get preparingDownload => '正在准备下载...';

  @override
  String get preparingEuicc => '正在准备 eUICC...';

  @override
  String get fetchingProfilePackage => '正在获取配置文件包...';

  @override
  String installing(Object sent, Object total) {
    return '正在安装 ($sent / $total 字节)...';
  }

  @override
  String get finalizing => '正在完成 (更新存储信息)...';

  @override
  String get profileInstalledSuccessfully => '配置文件安装成功！';

  @override
  String get provider => '运营商';

  @override
  String get iccid => 'ICCID';

  @override
  String get plmn => 'PLMN';

  @override
  String get storage => '存储';

  @override
  String get free => '剩余';

  @override
  String get nvram => 'NVRAM';

  @override
  String get exportCertificates => '导出证书';

  @override
  String get euiccCert => 'eUICC 证书';

  @override
  String get eumCert => 'EUM 证书';

  @override
  String get enterConfirmationCode => '请输入运营商要求的确认码';

  @override
  String get confirmationCodeRequired => '确认码是必填项';

  @override
  String get download => '下载';

  @override
  String get installationSuccessful => '安装成功';

  @override
  String get installationSuccessMessage => '配置文件已成功安装到您的 eUICC。';

  @override
  String get consumed => '已用';

  @override
  String get enableProfileNow => '立即启用配置文件';

  @override
  String get done => '完成';

  @override
  String get profileEnabledSuccessfully => '配置文件启用成功';

  @override
  String get enterNewProfileName => '输入该配置文件的新名称，以便您更轻松地识别它。';

  @override
  String get profileName => '配置文件名称';

  @override
  String get profileNameHint => '例如：工作出差';

  @override
  String get profileRenamedSuccessfully => '配置文件重命名成功';

  @override
  String get downloadFailed => '下载失败';

  @override
  String get tryAgain => '重试';

  @override
  String get savedSuccessfully => '保存成功';

  @override
  String get saveCertificate => '保存证书';

  @override
  String get searchingForReaders => '正在搜索读卡器...';

  @override
  String get initializationError => '初始化错误';

  @override
  String get noReadersFound => '未找到读取器';

  @override
  String get noReadersFoundMessage => '插入兼容的读取器或扫描蓝牙设备以管理您的 eSIM 配置。';

  @override
  String get scanBle => '扫描蓝牙';

  @override
  String get reminderDetails => '提醒详情';

  @override
  String get profileNotFound => '未找到配置';

  @override
  String get resending => '正在重发...';

  @override
  String get noAddressInNotification => '通知数据中没有地址';

  @override
  String get sentSuccessfully => '发送成功';

  @override
  String get sendFailed => '发送失败';

  @override
  String get copiedCurl => 'cURL 命令已复制到剪贴板';

  @override
  String get noAddressToExport => '没有要导出的地址';

  @override
  String get noHistoryAvailable => '没有历史记录';

  @override
  String get searchByIccid => '搜索 ICCID...';

  @override
  String get resendNotification => '重发通知';

  @override
  String get exportAsCurl => '导出为 cURL';

  @override
  String get viewDetails => '查看详情';

  @override
  String get deleteEntry => '删除条目';

  @override
  String activeReminders(int count) {
    return '$count 个活动的提醒';
  }

  @override
  String get noScheduledReminders => '没有已安排的提醒';

  @override
  String get remindersAppearWhen => '当您为配置添加日期标签时，提醒会出现在这里。';

  @override
  String activeTagsCount(int count) {
    return '所有配置中共 $count 个活动标签';
  }

  @override
  String get searchTagsOrProfiles => '搜索标签或配置...';

  @override
  String get noTagsFound => '未找到标签';

  @override
  String get addTagsFromProfileMenu => '从配置编辑菜单添加标签即可在此处查看。';

  @override
  String get expired => '已过期';

  @override
  String daysLeft(int count) {
    return '剩余 $count 天';
  }

  @override
  String hoursLeft(int count) {
    return '剩余 $count 小时';
  }

  @override
  String get expiresSoon => '即将过期';

  @override
  String get soon => '即将';

  @override
  String get activeTags => '有效标签';

  @override
  String get addNewTag => '添加新标签';

  @override
  String get noTagsAssigned => '此配置未分配标签';

  @override
  String get textTagHint => '文本标签 (如: 工作, 旅行)';

  @override
  String get addDateExpiryTag => '添加日期/到期标签';

  @override
  String get addNoteOptional => '添加备注 (可选)';

  @override
  String get add => '添加';

  @override
  String get noteHint => '如: 到期时间, 10GB 等';

  @override
  String get invalidHexString => '无效的十六进制字符串';

  @override
  String get resetToDefaults => '重置为默认值';

  @override
  String get resetToDefaultsSuccess => '已重置为默认值';

  @override
  String get addAidHex => '添加 AID (十六进制)';

  @override
  String get manageAutoNotif => '管理自动通知处理';

  @override
  String get automaticProcessing => '自动处理';

  @override
  String get notifProcessingInfo =>
      '处理通知有助于同步 eUICC 与 SM-DP+ 服务器（运营商）。删除已发送的通知可保持卡片存储空间整洁。';

  @override
  String get enabling => '启用时';

  @override
  String get afterEnabling => '启用配置后';

  @override
  String get disabling => '禁用时';

  @override
  String get afterDisabling => '禁用配置后';

  @override
  String get installation => '安装时';

  @override
  String get afterDownload => '下载配置后';

  @override
  String get deletion => '删除时';

  @override
  String get afterDeletion => '删除配置后';

  @override
  String get autoSend => '自动发送';

  @override
  String get autoSendSubtitle => '自动发送到服务器';

  @override
  String get autoRemove => '自动删除';

  @override
  String get autoRemoveSubtitle => '发送后从卡片中删除';

  @override
  String get removeWithoutSending => '不发送直接删除';

  @override
  String get removeWithoutSendingSubtitle => '谨慎使用：服务器不会收到通知';

  @override
  String get permissionsActive => '权限已激活';

  @override
  String get permissionsRequired => '需要权限';

  @override
  String get appCanSendNotif => '应用可以发送系统通知';

  @override
  String get requiredForReminders => '提醒警报需要此权限';

  @override
  String get unsupportedPlatformCheck => '此平台不支持权限检查。请进行手动测试。';

  @override
  String get couldNotVerifyStatus => '无法验证状态。请手动检查设置。';

  @override
  String get testNotificationTitle => '测试通知';

  @override
  String get seconds => '秒';

  @override
  String get startTest => '开始测试';

  @override
  String get sendingNotif => '正在发送...';

  @override
  String get hostIpLabel => '主机名 / IP';

  @override
  String get portLabel => '端口';

  @override
  String get passwordOptionalLabel => '密码（可选）';

  @override
  String get configuredServers => '已配置的服务器';

  @override
  String get secureHttps => '安全 (HTTPS)';

  @override
  String get insecureHttp => '不安全 (HTTP)';

  @override
  String get urlCopied => 'URL 已复制';

  @override
  String get serverAddedSuccessfully => '服务器添加成功';

  @override
  String get authFailedCheckPassword => '身份验证失败。请检查密码。';

  @override
  String get addNewServer => '添加新服务器';

  @override
  String get autoLoadRemotes => '自动加载远程设备';

  @override
  String get autoLoadRemotesSubtitle => '应用启动时自动连接到已配置的服务器';

  @override
  String get getRemoCardGitHub => '从 GitHub 获取 RemoCard';

  @override
  String get instructions => '说明：';

  @override
  String get instruction1 => '1. 在您的安卓设备上安装 RemoCard 应用。';

  @override
  String get instruction2 => '2. 在每个 RemoCard 应用中启动服务器。';

  @override
  String get instruction3 => '3. 在此处输入 IP 地址。';

  @override
  String get instruction4 => '4. 所有远程 SIM 插槽将出现在设备列表中。';

  @override
  String get appLogsCopied => '日志已复制到剪贴板';

  @override
  String get aramInfoTitle => 'ARA-M 信息';

  @override
  String get aramInfoSubtitle => '访问规则小应用详情';

  @override
  String get whatIsAram => '什么是 ARA-M？';

  @override
  String get aramDescription =>
      '访问规则小应用 (ARA-M) 是 eUICC (eSIM) 和 SIM 卡上的一种机制，它定义了哪些应用程序被允许管理配置或执行低级操作。如果应用的哈希值不在卡片的 ARA-M 允许列表中，安卓系统将阻止访问，导致“访问被拒绝”错误。';

  @override
  String get appCertHashes => '应用证书哈希';

  @override
  String get aramHashInstruction =>
      '为兼容不同 Android 版本，请将下方所有 SHA-1 证书哈希添加到卡片的 ARA-M 规则中。应用签名密钥升级后，不同 Android 版本可能会检查已验证签名历史中的不同证书。';

  @override
  String get aramSigningHistoryInstruction =>
      'For compatibility across Android versions, add all SHA-1 certificate hashes below to your card\'s ARA-M rules. After an app signing key upgrade, different Android versions may check different certificates from the verified signing history.';

  @override
  String get certSha1Hash => '证书 SHA-1 哈希';

  @override
  String get unavailable => '不可用';

  @override
  String get troubleshooting => '故障排除';

  @override
  String get troubleStep1 => '确保您使用了正确的读卡器。';

  @override
  String get troubleStep2 => '如果使用实体卡，请检查它是测试卡还是生产卡（生产卡通常锁定 ARA-M）。';

  @override
  String get troubleStep3 => '上述哈希值取决于您使用的是应用的调试版、正式版还是特权 (Magisk) 版。';

  @override
  String get troubleStep4 => '考虑使用可以绕过某些安卓 API 限制的特权 (Magisk) 构建版。';

  @override
  String get hashCopied => '哈希已复制到剪贴板';

  @override
  String get aidCopied => 'AID 已复制到剪贴板';

  @override
  String get lastSeen => '最后出现';

  @override
  String get unknownProvider => '未知运营商';

  @override
  String get unknownProfile => '未知配置';

  @override
  String get tags => '标签';

  @override
  String get noTags => '无标签';

  @override
  String records(int count) {
    return '$count 条记录';
  }

  @override
  String get bytes => '字节';

  @override
  String get responseCode => '响应代码';

  @override
  String get responseBody => '响应体';

  @override
  String get type => '类型';

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
  String get isdrAids => 'ISD-R AID';

  @override
  String get configureDefaultAids => '配置默认应用 ID';

  @override
  String get addAidHexHint => '添加 AID (十六进制)';

  @override
  String get notificationProcessing => '通知设置';

  @override
  String get manageAutoNotification => '管理自动通知处理';

  @override
  String get notificationProcessingHelp =>
      '处理通知有助于您的 eUICC 与 SM-DP+ 服务器（运营商）之间的同步。删除已发送的通知可以保持卡存储清洁。';

  @override
  String get notificationProcessingTimings => 'Processing timings';

  @override
  String get notificationProcessingTimingsHelp =>
      'Choose when automatic notification processing runs. Some safety-critical timings can only be disabled while Developer Mode is enabled.';

  @override
  String get afterEnablingProfile => '启用配置后';

  @override
  String get afterDisablingProfile => '禁用配置后';

  @override
  String get afterProfileDownload => '下载配置后';

  @override
  String get afterProfileDeletion => '删除配置后';

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
  String get sendToServerAutomatically => '自动发送到服务器';

  @override
  String get removeFromCardAfterSending => '发送后从卡中删除';

  @override
  String get removeWithoutSendingCaution => '请谨慎使用：服务器将不会收到通知';

  @override
  String get reminderSettings => '提醒设置';

  @override
  String get appCanSendNotifications => '应用可以发送系统通知';

  @override
  String get requiredForReminderAlerts => '接收提醒通知所需';

  @override
  String get enable => '启用';

  @override
  String get permissionCheckNotSupported => '此平台不支持权限检查。请进行手动测试。';

  @override
  String get testNotification => '测试通知';

  @override
  String get notificationsDisabledMessage => '通知已禁用。请在系统设置中启用它们以接收提醒。';

  @override
  String get openSettings => '打开设置';

  @override
  String get applicationLogs => '应用日志';

  @override
  String get refreshReload => '刷新/重新加载';

  @override
  String get toggleAutoScroll => '切换自动滚动';

  @override
  String get refreshDevices => '刷新设备';

  @override
  String get scanBluetooth => '扫描蓝牙';

  @override
  String get lessThan1Kb => '< 1 KB';

  @override
  String get connectionFailed => '连接失败';

  @override
  String get downloadRemoCard => '下载 RemoCard';

  @override
  String get remoCardAndroidApp => 'Android 远程控制器应用';

  @override
  String get resentSuccessfully => '重发成功';

  @override
  String get resendFailed => '重发失败';

  @override
  String get eid => 'EID';

  @override
  String get seq => '序列号';

  @override
  String get date => '日期';

  @override
  String errorWithDetails(String error) {
    return '错误: $error';
  }

  @override
  String exportFailed(String error) {
    return '导出失败: $error';
  }

  @override
  String get sasAccreditation => 'SAS 认证';

  @override
  String get firmwareVersion => '固件版本';

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
  String get platformSupport => '平台支持';

  @override
  String get rspVersion => 'RSP 版本';

  @override
  String get bppVersion => 'BPP 版本';

  @override
  String get gpVersion => 'GlobalPlatform 版本';

  @override
  String get certInfrastructure => '证书基础结构';

  @override
  String get euiccSignCi => 'eUICC 签名 CI';

  @override
  String get euiccVerifyCi => 'eUICC 验证 CI';

  @override
  String get none => '无';

  @override
  String keysCount(int count) {
    return '$count 个密钥';
  }

  @override
  String get state => '状态';

  @override
  String get profileClass => '类别';

  @override
  String get aid => 'AID';

  @override
  String get euiccSpecifications => 'eUICC 规格';

  @override
  String get sending => '正在发送...';

  @override
  String get failedToSaveTags => '保存标签失败';

  @override
  String get note => '备注';

  @override
  String get notificationDetails => '通知详情';

  @override
  String get unknown => '未知';

  @override
  String get status => '状态';

  @override
  String get sent => '已发送';

  @override
  String get pending => '待处理';

  @override
  String get notifTypeInstall => '安装';

  @override
  String get notifTypeDelete => '删除';

  @override
  String get notifTypeEnable => '启用';

  @override
  String get notifTypeDisable => '禁用';

  @override
  String get notifTypeRpmEnable => 'RPM 启用';

  @override
  String get notifTypeRpmDisable => 'RPM 禁用';

  @override
  String get notifTypeRpmDelete => 'RPM 删除';

  @override
  String get notifTypeLoadRpm => '加载 RPM';

  @override
  String confirmDeleteNotification(int seq) {
    return '您确定要删除通知 #$seq 吗？';
  }

  @override
  String get notificationRemoved => '通知已移除';

  @override
  String failedToRemove(String error) {
    return '移除失败: $error';
  }

  @override
  String get curlCopied => 'cURL 命令已提取到剪贴板';

  @override
  String failedToGenerateCurl(String error) {
    return '生成 cURL 失败: $error';
  }

  @override
  String get noNotificationAddress => '无可用通知地址';

  @override
  String get sendingNotification => '正在发送通知...';

  @override
  String get notifSentSuccessfully => '通知发送成功';

  @override
  String get failedToSendNotification => '发送通知失败';

  @override
  String errorSendingNotification(String error) {
    return '发送通知时出错: $error';
  }

  @override
  String pendingCount(int count) {
    return '$count 条待处理';
  }

  @override
  String get currentReader => '当前读取器';

  @override
  String get errorLoadingNotifications => '加载通知时出错';

  @override
  String get allCaughtUp => '您已处理完所有内容';

  @override
  String get sequence => '序列号';

  @override
  String get operation => '操作';

  @override
  String get profileNameLabel => '配置名称';

  @override
  String get failedToSend => '发送失败';

  @override
  String get onCard => '卡内';

  @override
  String get sendNotification => '发送通知';

  @override
  String get deleteNotification => '删除通知';

  @override
  String get noNotifications => '无通知';

  @override
  String get batchDownloadTitle => '批量下载';

  @override
  String get batchDownloadHint => '在此粘贴多个 LPA 代码（每行一个，最多 20 个）';

  @override
  String foundLpaCodes(int count) {
    return '找到 $count 个 LPA 代码';
  }

  @override
  String get startBatch => '开始批量任务';

  @override
  String get noLpaCodesFound => '未找到有效的 LPA 代码';

  @override
  String get insufficientSpaceStoppingBatch => '空间不足。正在停止批量下载。';

  @override
  String get exportCsv => '导出为 CSV';

  @override
  String get exportedSuccessfully => '导出成功';

  @override
  String get exportResults => '导出结果';

  @override
  String get lpa => 'LPA';

  @override
  String get smdp => 'SM-DP+';

  @override
  String get confirmationCode => '确认码';

  @override
  String get size => '大小';

  @override
  String get message => '内容';

  @override
  String get remainingSpace => '剩余空间';

  @override
  String get stopBatch => '停止批量';

  @override
  String get stopping => '正在停止...';

  @override
  String get remove => '移除';

  @override
  String get updateAvailable => '发现更新';

  @override
  String updateAvailableSubtitle(String appName, String version, String build) {
    return '$appName 的新版本已发布 (v$version b$build)。现在更新吗？';
  }

  @override
  String get updateAction => '更新';

  @override
  String get later => '稍后';

  @override
  String get changelog => '更新日志';

  @override
  String get sortBy => '排序方式';

  @override
  String get sortIccid => 'ICCID';

  @override
  String get sortCountry => '国家/地区';

  @override
  String get sortAscending => '升序';

  @override
  String get sortDescending => '降序';

  @override
  String get searchProfiles => '搜索配置...';

  @override
  String get noProfilesMatch => '没有符合搜索条件的配置。';

  @override
  String get sortDefault => '默认';

  @override
  String get sortNickname => '昵称';

  @override
  String get showProfileSearch => '显示配置搜索';

  @override
  String get showProfileSearchSubtitle => '在配置列表中显示搜索和排序栏';

  @override
  String get noReaderFound => '未找到读取器。请连接您的 eUICC 适配器。';

  @override
  String get readyToInstallProfile => '准备安装配置。';

  @override
  String get downloadHere => '在此下载';

  @override
  String get manage => '管理';

  @override
  String get buyCard => '卡片';

  @override
  String get buyData => '数据';

  @override
  String get selectDevice => '选择设备';

  @override
  String get selectReaderTitle => '选择卡片';

  @override
  String get authorizeSigning => '授权签名';

  @override
  String get signingDescription => '网站正在请求您的 eUICC 进行安全签名。';

  @override
  String get smdpAddress => 'SM-DP+ 地址';

  @override
  String get sign => '签名';

  @override
  String profilesInstalled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 配置文件已安装',
      one: '已安装1个配置文件',
    );
    return '$_temp0';
  }

  @override
  String get estimatedDownloadSize => '预估下载大小';

  @override
  String get phoneFormatInternationalOnly => 'E.164 Int\'l Only';

  @override
  String get phoneFormatInternationalAndMobile => 'Int\'l & Mobile';

  @override
  String get phoneFormatInternationalAndAll => 'Int\'l & National';

  @override
  String get phoneFormatOff => '关闭';

  @override
  String get settings_item_unit_b => '字节';

  @override
  String get settings_item_unit_kb => 'kB (1,000 Bytes)';

  @override
  String get settings_item_unit_kib => 'kiB (1,024 Bytes)';

  @override
  String get settings_item_unit_adaptive_si => 'B / kB Adaptive';

  @override
  String get settings_item_unit_adaptive_bi => 'B / kiB Adaptive';

  @override
  String get insufficientStorageWarning => '可用空间不足，安装可能会失败。';

  @override
  String get estimateProfileSize => '估计配置文件大小';

  @override
  String get estimateProfileSizeSubtitle => '在下载前估计配置文件元数据的大小';

  @override
  String get customize => '自定义';

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
  String get deviceName => '设备名称';

  @override
  String get success => '成功';

  @override
  String get devicePasswordHint => '6 个十六进制字符或密码字符串';

  @override
  String get sixHexChars => '6 个十六进制字符';

  @override
  String get database => '数据库';

  @override
  String exportSuccess(String path) {
    return '数据库已导出到: $path';
  }

  @override
  String get importDatabase => '导入数据库';

  @override
  String get importDatabaseSubtitle => '从另一个数据库文件合并行';

  @override
  String get importDatabaseDialogTitle => '选择要导入的数据库文件';

  @override
  String get importDatabaseTitle => '导入数据库';

  @override
  String get importDatabaseContent =>
      '这将把所选数据库中的行合并到您当前的数据库。使用相同键的现有行将被覆盖。是否继续？';

  @override
  String get import => '导入';

  @override
  String get importSuccess => '数据库导入成功';

  @override
  String importFailed(String error) {
    return '导出数据库失败: $error';
  }

  @override
  String get resetDatabase => '重置数据库';

  @override
  String get resetDatabaseSubtitle => '清除所有应用数据并重启';

  @override
  String get resetDatabaseTitle => '重置应用数据库';

  @override
  String get resetDatabaseContent => '这将完全删除所有本地存储的数据、配置和日志。应用程序将关闭。您确定要继续吗？';

  @override
  String get deleteDatabase => '删除数据库';

  @override
  String resetFailed(String error) {
    return '重置数据库失败: $error';
  }

  @override
  String get deviceImei => '设备 TAC';

  @override
  String get deviceImeiSubtitle => '用于配置下载';

  @override
  String get editDeviceImei => '编辑设备 TAC';

  @override
  String get editDeviceImeiInfo => '输入 8 位 TAC，或 15 位 IMEI。默认 TAC：35383741。';

  @override
  String get imeiDigits => 'TAC 或 IMEI 数字';

  @override
  String get importAction => '导入';

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

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get settingsTitle => '設定';

  @override
  String get displaySettings => '顯示設定';

  @override
  String get appearance => '外觀';

  @override
  String get appearanceSubtitle => '自定義主題、布局和顯示偏好';

  @override
  String get darkMode => '深色模式';

  @override
  String get themeStyle => '主題樣式';

  @override
  String get themeStyleSubtitle => '在自定義和 MD3 樣式之間選擇';

  @override
  String get customDesign => 'Nekoko 樣式';

  @override
  String get stockMD3 => '原生 MD3';

  @override
  String get waterfallLayout => '瀑布流布局';

  @override
  String get waterfallLayoutSubtitle => '在寬屏上使用磚塊式布局';

  @override
  String get system => '跟隨系統';

  @override
  String get light => '淺色';

  @override
  String get dark => '深色';

  @override
  String get language => '語言';

  @override
  String get systemLanguage => '系統語言';

  @override
  String get general => '一般';

  @override
  String get ui => '使用者介面';

  @override
  String get autoLoadProfiles => '自動載入設定檔';

  @override
  String get autoLoadProfilesSubtitle => '選擇讀卡機時自動載入卡片設定';

  @override
  String get loadProfileIcons => '載入設定檔圖示';

  @override
  String get loadProfileIconsSubtitle => '從eUICC讀取圖示（較慢）';

  @override
  String get useNekokoIcons => '使用電信商圖示';

  @override
  String get useNekokoIconsSubtitle => '從 operator-icons 獲取電信商圖示';

  @override
  String get forceDeviceDropdown => '強制從下拉選單選擇裝置';

  @override
  String get forceDeviceDropdownSubtitle => '始終使用下拉選單選擇裝置';

  @override
  String get sizeDisplayUnit => '容量顯示單位';

  @override
  String get sizeDisplayUnitSubtitle => '儲存容量的顯示格式';

  @override
  String get phoneFormat => '電話號碼格式';

  @override
  String get phoneFormatSubtitle => '顯示電話號碼的格式';

  @override
  String get notifications => '通知';

  @override
  String get notificationSettings => '通知設定';

  @override
  String get notificationSettingsSubtitle => '設定自動處理和清理';

  @override
  String get notificationHistory => '通知記錄';

  @override
  String get notificationHistorySubtitle => '搜尋、管理和重發已發送的通知';

  @override
  String get tagsAndReminders => '標籤與提醒';

  @override
  String get tagManager => '標籤管理';

  @override
  String get tagManagerSubtitle => '建立和編輯設定檔標籤';

  @override
  String get tagReminders => '標籤提醒';

  @override
  String get tagRemindersSubtitle => '基於日期標籤的排程通知';

  @override
  String get manageTagsAndReminders => '管理標籤與提醒';

  @override
  String get manageTagsAndRemindersSubtitle => '設定標籤、權限和測試警報';

  @override
  String get viewScheduledReminders => '檢視已排程的提醒';

  @override
  String get viewScheduledRemindersSubtitle => '管理即將到來的標籤通知';

  @override
  String get connectivity => '連線';

  @override
  String get remoteReaders => '遠端讀卡機';

  @override
  String get remoteReadersSubtitle => '配置 RemoCard 配件應用';

  @override
  String get enableBle => '藍牙連接器';

  @override
  String get enableBleSubtitle => '啟用掃描和連接藍牙讀卡器';

  @override
  String get enableCcid => 'USB CCID 連接器';

  @override
  String get enableCcidSubtitle => '啟用 USB 智能卡讀卡器 (CCID)';

  @override
  String get enableOmapi => 'OMAPI 連接器';

  @override
  String get enableOmapiSubtitle => '通過 OMAPI 啟用內建 eUICC 存取';

  @override
  String get enableTmapi => 'Telephony API 連接器';

  @override
  String get enableTmapiSubtitle => '通過 Telephony API API 啟用特權存取';

  @override
  String get readerTypes => '讀卡機類型';

  @override
  String get readerTypesSubtitle => '管理已啟用的讀卡機類型（CCID、藍牙、遠端等）';

  @override
  String get enabledReaderTypes => '已啟用的讀卡機類型';

  @override
  String get enabledReaderTypesSubtitle => '控制應用程式中可用的讀卡機類型';

  @override
  String get remoteReaderSettings => '遠端讀卡機設定';

  @override
  String get remoteReaderSettingsSubtitle => '設定遠端讀卡機伺服器和連線';

  @override
  String get ccidReaderTitle => 'CCID（USB/PC/SC）';

  @override
  String get ccidReaderSubtitle => 'USB智慧卡讀卡機和PC/SC裝置';

  @override
  String get bluetoothReaderTitle => '藍牙';

  @override
  String get bluetoothReaderSubtitle => '藍牙LE智慧卡讀卡機和寫卡機';

  @override
  String get remoteReadersTitle => '遠端讀卡機';

  @override
  String get remoteReadersConnectorSubtitle => '網路連接的遠端智慧卡讀卡機';

  @override
  String get omapiReaderTitle => 'OMAPI';

  @override
  String get omapiReaderSubtitle => '透過Open Mobile API的內建SIM卡槽';

  @override
  String get tmapiReaderTitle => 'Telephony API';

  @override
  String get tmapiReaderSubtitle => '透過Telephony API的內建eSIM';

  @override
  String get remoteServerConfiguration => '遠端伺服器設定';

  @override
  String get remoteServerConfigurationSubtitle => '管理遠端讀卡機伺服器和連線設定';

  @override
  String get enableBrowser => '啟用瀏覽器';

  @override
  String get enableBrowserSubtitle => '在主畫面顯示商店、購買或幫助等額外標籤';

  @override
  String get transport => '傳輸';

  @override
  String get disableRefreshFlags => '禁用重新整理標誌';

  @override
  String get disableRefreshFlagsSubtitle => '不適用於外部讀卡機';

  @override
  String get apduMaxSegmentSize => 'APDU 最大分段大小';

  @override
  String get apduMaxSegmentSizeSubtitle => '每個 APDU 資料塊的最大大小';

  @override
  String get ensureSingleChannel => 'Ensure Single Channel';

  @override
  String get ensureSingleChannelSubtitle =>
      'Close other logical channels before opening a new one';

  @override
  String get analytics => '分析與雲端服務';

  @override
  String get nekokoCloud => 'Nekoko Cloud';

  @override
  String get nekokoCloudSubtitle => '分析安裝數據以改進預測';

  @override
  String get developer => '開發者';

  @override
  String get developerMode => '開發者模式';

  @override
  String get developerModeSubtitle => '啟用進階偵錯功能';

  @override
  String get exportDatabase => '匯出資料庫';

  @override
  String get exportDatabaseSubtitle => '儲存本機資料庫副本';

  @override
  String get openDatabaseFolder => '開啟資料庫資料夾';

  @override
  String get openDatabaseFolderSubtitle => '開啟包含資料庫檔案的資料夾';

  @override
  String get decodeAsn1 => '解碼 ASN.1 記錄 (慢)';

  @override
  String get decodeAsn1Subtitle => '嚴重影響效能';

  @override
  String get viewAppLogs => '檢視應用程式記錄';

  @override
  String get viewAppLogsSubtitle => '檢視收集的應用程式記錄';

  @override
  String get about => '關於';

  @override
  String get version => '版本';

  @override
  String get build => '組建';

  @override
  String get checkUpdates => '檢查更新';

  @override
  String get checkUpdatesSubtitle => '啟動時自動檢查新版本';

  @override
  String get licenses => 'Open Source Licenses';

  @override
  String get licensesSubtitle =>
      'License information for open source libraries used';

  @override
  String get noUpdatesFound => 'No updates found';

  @override
  String get profilesTitle => '設定檔列表';

  @override
  String get switchEstkSlot => '切換 eSTK 插槽';

  @override
  String get notificationsButton => '通知';

  @override
  String get downloadProfile => '下載設定檔';

  @override
  String get reconnect => '重新連線';

  @override
  String get bluetoothNotConnected => '藍牙未連接';

  @override
  String get bluetoothNotConnectedSubtitle => '請確保藍牙已開啟且設備在附近。點擊連接以開始使用此設備。';

  @override
  String get bluetoothConnectionFailed => '藍牙連接失敗';

  @override
  String bluetoothConnectionFailedSubtitle(Object error) {
    return '無法連接到藍牙設備。\n\n$error';
  }

  @override
  String get removeDevice => '移除設備';

  @override
  String get retryConnection => '連接';

  @override
  String get remoteConnectionFailed => '遠端讀卡機連線失敗';

  @override
  String remoteConnectionFailedMessage(Object error) {
    return '確保遠端伺服器正在執行且可存取。\n\n$error';
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
  String get changeSettings => '更改設定';

  @override
  String get connectCompatibleReader => '請連接相容的讀卡機以開始。';

  @override
  String get connectReaderMessageBle => '如果您有支援藍牙的 eUICC，也可以掃描藍牙裝置。';

  @override
  String get connectReaderMessageNoBle => '請確保您的 CCID 讀卡機已連接到電腦。';

  @override
  String get downloadSmartCardExtension => '下載智慧卡擴充功能';

  @override
  String get smartCardExtensionMessage => '此瀏覽器需要擴充功能才能存取 USB CCID 讀卡機。';

  @override
  String get scanForBluetooth => '掃描藍牙裝置';

  @override
  String get connectRemote => '連接遠端裝置';

  @override
  String get noCardDetected => '未偵測到卡片';

  @override
  String get noCardDetectedMessage => '在此插槽中未找到可用或活動的 eUICC。';

  @override
  String get noDataLoaded => '未連接';

  @override
  String get loadProfiles => '連接';

  @override
  String get disconnect => '斷開連接';

  @override
  String get disconnecting => 'Disconnecting...';

  @override
  String get profilesEmpty => '卡內無設定檔';

  @override
  String get profilesEmptyMessage => '此 eUICC 卡是空的。';

  @override
  String get renameProfile => '重命名設定檔';

  @override
  String get nickname => '暱稱';

  @override
  String get enterProfileNickname => '輸入設定檔暱稱';

  @override
  String get profileNicknameNote => '注意：標籤透過「標籤管理」選單單獨管理。';

  @override
  String get useProfileIcon => '使用設定檔圖示';

  @override
  String get useProfileIconSubtitle => 'eSIM 卡自帶圖示';

  @override
  String get removeCustomIcon => '移除自訂圖示';

  @override
  String get noRemoteIcon => '該電信商無遠端圖示';

  @override
  String get cancel => '取消';

  @override
  String get ok => '確定';

  @override
  String get save => '儲存';

  @override
  String get delete => '刪除';

  @override
  String get refresh => '重新整理';

  @override
  String get initializing => '正在初始化...';

  @override
  String get refreshingProfiles => '正在重新整理設定檔...';

  @override
  String get retrievingEid => '正在獲取 EID 和資訊...';

  @override
  String get updatingProfile => '正在更新設定檔...';

  @override
  String get manageIsdR => '管理 ISD-R AID';

  @override
  String get manageIsdRSubtitle => '設定 eUICC 的預設應用程式 ID';

  @override
  String get transportFailed => '傳輸失敗';

  @override
  String get remoteTransportFailedMessage =>
      '已連接到遠端伺服器，但命令執行失敗。這通常意味著遠端設備暫時忙碌或與卡片中斷連接。是否重試？';

  @override
  String get retry => '重試';

  @override
  String get scanningForReaders => '正在掃描讀卡機...';

  @override
  String get switchedEstkSlot => '已切換 eSTK 插槽';

  @override
  String get scanningForUnresponsiveDevices => '正在掃描無回應設備...';

  @override
  String get resettingConnection => '正在重設連接...';

  @override
  String get connectingToReader => '正在連接到讀卡機...';

  @override
  String get moreOptions => '更多選項';

  @override
  String get retrievingProfiles => '正在獲取設定檔列表...';

  @override
  String get savingProfileMetadata => '正在儲存設定檔元資料...';

  @override
  String get enablingProfile => '正在啟用設定檔...';

  @override
  String get disablingProfile => '正在停用設定檔...';

  @override
  String get deleteProfile => '刪除設定檔';

  @override
  String deleteProfileConfirmation(Object profileName) {
    return '確定要刪除設定檔 $profileName 嗎？\n此操作無法復原。';
  }

  @override
  String get deletingProfile => '正在刪除設定檔...';

  @override
  String get deleting => 'Deleting...';

  @override
  String get dataUsage => '流量消耗';

  @override
  String get details => '詳情';

  @override
  String get rename => '重新命名';

  @override
  String get changeIcon => '變更圖示';

  @override
  String get manageTags => '管理標籤';

  @override
  String get copyIccid => '複製 ICCID';

  @override
  String get notificationProcessingError => '通知正在處理中，無法執行操作';

  @override
  String get operationInProgressError => 'Operation in progress, please wait';

  @override
  String iccidCopied(Object iccid) {
    return 'ICCID 已複製: $iccid';
  }

  @override
  String get operationRestricted => '操作受限';

  @override
  String get notificationProcessingDownloadError => '通知仍在處理中。請在下載新設定檔前等待處理完成。';

  @override
  String get operational => '營運級';

  @override
  String get test => '測試級';

  @override
  String get provisioning => '預置級';

  @override
  String get profileDetails => '設定檔詳情';

  @override
  String get profileDetailsSubtitle => '來自 eUICC 該設定檔插槽的資訊。';

  @override
  String get enabled => '已啟用';

  @override
  String get disabled => '已停用';

  @override
  String get tagsManagedSeparately => '注意：標籤透過「管理標籤」選單獨立管理。';

  @override
  String get changeProfileIcon => '變更設定檔圖示';

  @override
  String get selectFromGallery => '從相簿選擇';

  @override
  String get nekokoOperatorIcon => '電信商圖示';

  @override
  String get iconFromEsim => '來自 eSIM 卡的圖示';

  @override
  String updateIconFailed(Object error) {
    return '更新圖示失敗: $error';
  }

  @override
  String get failedToReadImage => '無法讀取圖片檔案';

  @override
  String get failedToProcessImage => '無法處理圖片';

  @override
  String get customIconSet => '自定義圖示設定成功';

  @override
  String get noMccMnc => '此設定檔沒有可用的 MCC/MNC';

  @override
  String get fetchingRemoteIcon => '正在獲取遠端圖示...';

  @override
  String get remoteIconSaved => '遠端圖示已儲存為自定義圖示';

  @override
  String fetchRemoteIconFailed(Object error) {
    return '獲取遠端圖示失敗: $error';
  }

  @override
  String get noProfileIcon => '沒有可用的設定檔圖示';

  @override
  String get profileIconSaved => '設定檔圖示已儲存為自定義圖示';

  @override
  String get customIconRemoved => '自定義圖示已移除';

  @override
  String get failed => '失敗';

  @override
  String euiccError(Object action) {
    return 'eUICC 在嘗試 $action 設定檔時傳回錯誤。';
  }

  @override
  String get dismiss => '忽略';

  @override
  String get dataPlan => '流量方案';

  @override
  String get used => '已用';

  @override
  String get total => '總量';

  @override
  String expires(Object date) {
    return '到期時間: $date';
  }

  @override
  String get close => '關閉';

  @override
  String get server => '伺服器';

  @override
  String get switchFailed => '切換失敗';

  @override
  String get deviceRefreshFailed => '設備刷新失敗';

  @override
  String get euiccOptions => 'eUICC 選項';

  @override
  String get euiccInfo => 'eUICC 資訊';

  @override
  String get hideEid => '隱藏 EID';

  @override
  String get showEid => '顯示 EID';

  @override
  String get copyEid => '複製 EID';

  @override
  String get eidCopied => 'EID 已複製到剪貼簿';

  @override
  String get connectRemotes => '連接遠端';

  @override
  String get configureRemotes => '設定遠端';

  @override
  String get connectingToRemoteReaders => '正在背景連接遠端讀卡機...';

  @override
  String get noRemoteReadersFound => '未找到遠端讀卡機';

  @override
  String connectedRemoteReaders(Object count) {
    return '已連接 $count 個遠端讀卡機';
  }

  @override
  String failedToConnectRemoteReaders(Object error) {
    return '連接遠端讀卡機失敗: $error';
  }

  @override
  String get remoteReaderPassword => '遠端讀卡機密碼';

  @override
  String get remoteReaderPasswordSubtitle => '此遠端讀卡機需要密碼。';

  @override
  String get password => '密碼';

  @override
  String get deleteConnection => '移除連線';

  @override
  String get connect => '連接';

  @override
  String get remoteReaderConnectionFailed => '遠端讀卡機連接失敗';

  @override
  String remoteReaderConnectionFailedSubtitle(Object error) {
    return '請確保遠端伺服器正在執行且可存取。\n\n$error';
  }

  @override
  String get connectReader => '連接相容的讀卡機以開始。';

  @override
  String get connectReaderSubtitleBle => '如果您有支援藍牙的 eUICC，也可以掃描相容的藍牙設備。';

  @override
  String get connectReaderSubtitleCcid => '請確保您的 CCID 讀卡機已連接到電腦。';

  @override
  String get downloadExtension => '下載智慧卡擴充功能';

  @override
  String get downloadExtensionSubtitle => '在此瀏覽器中存取 USB CCID 讀卡機需要該擴充功能。';

  @override
  String get cardUnsupported => '不支援該卡片';

  @override
  String get cardUnsupportedSubtitle =>
      '此卡片可能不是 eUICC，或者該讀卡機不支援此卡片，或者正在被其他程式佔用。';

  @override
  String get omapiWelcome => '好消息 — 您的設備支援 OMAPI，極有可能相容可拆卸 eUICC 卡片！';

  @override
  String get supportedDevices => '支援的設備';

  @override
  String get aboutAram => '關於 ARA-M';

  @override
  String get accessDenied => '存取被拒絕';

  @override
  String get accessDeniedSubtitle =>
      '存取此 eUICC 需要營運商權限。該卡片的 ARA-M 允許列表與此應用程式的簽章不符。';

  @override
  String get noCardDetectedSubtitle => '在此插槽中未找到不支援或活動的 eUICC。';

  @override
  String get noProfilesInstalled => '未安裝任何設定檔';

  @override
  String get noProfilesInstalledSubtitle => '此 eUICC 卡片是空的。';

  @override
  String get cardRefreshingTitle => 'Card is Refreshing';

  @override
  String get cardRefreshingMessage =>
      'The card is currently updating its state. Profile list cannot be retrieved at this moment. Please wait a few seconds and then try again.';

  @override
  String get useRemoteIcon => '使用遠端圖示';

  @override
  String get bleDisconnectedTitle => 'Bluetooth Connection Lost';

  @override
  String get bleDisconnectedMessage =>
      'The connection to the card reader was suddenly lost. Please ensure it is nearby and turned on.';

  @override
  String get cardStuckRefreshingMessage =>
      'Profile state change ongoing - try manually re-plug the SIM card if it stucks.';

  @override
  String get activationCodeTitle => '激活碼';

  @override
  String get activationCodeSubtitle => '掃描二維碼、拖拽圖片或手動輸入 LPA 字串。';

  @override
  String get fullActivationCodeLabel => '完整激活碼';

  @override
  String get fullActivationCodeHint => 'LPA:1\$smdp.io\$MATCHING-ID';

  @override
  String get pasteFromClipboardTooltip => '從剪貼板粘貼';

  @override
  String get selectFromGalleryTooltip => '從相冊選擇';

  @override
  String get scanQrCodeTooltip => '掃描二維碼';

  @override
  String get smdpAddressLabel => 'SM-DP+ 地址';

  @override
  String get smdpAddressHint => 'smdp.io';

  @override
  String get matchingIdLabel => '匹配 ID';

  @override
  String get matchingIdHint => 'ABC-123';

  @override
  String get smdpOidLabel => 'SM-DP+ OID';

  @override
  String get confirmationCodeLabel => '確認碼';

  @override
  String get confirmationCodeHint => '輸入確認碼';

  @override
  String get continueButton => '繼續';

  @override
  String get invalidLpaClipboard => '剪貼板不包含有效的 LPA 字串。';

  @override
  String get invalidFqdnFormat => 'FQDN 格式無效';

  @override
  String get invalidMatchingIdChars => '匹配 ID 包含非法字符';

  @override
  String get invalidOidFormat => 'OID 格式無效 (例如 1.2.840...)';

  @override
  String get activationCodeRequired => '必須輸入激活碼';

  @override
  String get invalidLpaFormatGeneric => 'LPA 格式無效';

  @override
  String get smdpAddressRequired => '必須輸入 SM-DP+ 地址';

  @override
  String get loadingNotifications => '正在加載通知...';

  @override
  String get processing => '處理中...';

  @override
  String get analyzingImage => '正在分析圖片...';

  @override
  String get noQrFoundInImage => '圖片中未找到二維碼';

  @override
  String get invalidAcInImage => '圖片中包含無效的激活碼';

  @override
  String get invalidAcFormatDetailed => '啟動碼格式無效。必須以 LPA:1\$ 開頭...';

  @override
  String get downloadProfileTitle => '下載設定檔';

  @override
  String get connectingToEuicc => '正在連接 eUICC...';

  @override
  String get gettingChallenge => '正在獲取 eUICC 挑戰值...';

  @override
  String get authenticatingWithSmdp => '正在進行 SM-DP+ 認證...';

  @override
  String get verifyingSignatures => '正在驗證 SM-DP+ 簽名...';

  @override
  String get retrievingMetadata => '正在獲取設定檔元數據...';

  @override
  String get preparingDownload => '正在準備下載...';

  @override
  String get preparingEuicc => '正在準備 eUICC...';

  @override
  String get fetchingProfilePackage => '正在獲取設定檔包...';

  @override
  String installing(Object sent, Object total) {
    return '正在安裝 ($sent / $total 位元組)...';
  }

  @override
  String get finalizing => '正在完成 (更新存儲資訊)...';

  @override
  String get profileInstalledSuccessfully => '設定檔安裝成功！';

  @override
  String get provider => '運營商';

  @override
  String get iccid => 'ICCID';

  @override
  String get plmn => 'PLMN';

  @override
  String get storage => '存儲';

  @override
  String get free => '剩餘';

  @override
  String get nvram => 'NVRAM';

  @override
  String get exportCertificates => '導出證書';

  @override
  String get euiccCert => 'eUICC 證書';

  @override
  String get eumCert => 'EUM 證書';

  @override
  String get enterConfirmationCode => '請輸入運營商要求的確認碼';

  @override
  String get confirmationCodeRequired => '確認碼是必填項';

  @override
  String get download => '下載';

  @override
  String get installationSuccessful => '安裝成功';

  @override
  String get installationSuccessMessage => '設定檔已成功安裝到您的 eUICC。';

  @override
  String get consumed => '已用';

  @override
  String get enableProfileNow => '立即啟用設定檔';

  @override
  String get done => '完成';

  @override
  String get profileEnabledSuccessfully => '設定檔啟用成功';

  @override
  String get enterNewProfileName => '輸入該設定檔的新名稱，以便您更輕鬆地識別它。';

  @override
  String get profileName => '設定檔名稱';

  @override
  String get profileNameHint => '例如：工作出差';

  @override
  String get profileRenamedSuccessfully => '設定檔重命名成功';

  @override
  String get downloadFailed => '下載失敗';

  @override
  String get tryAgain => '重試';

  @override
  String get savedSuccessfully => '保存成功';

  @override
  String get saveCertificate => '保存證書';

  @override
  String get searchingForReaders => '正在搜尋讀卡機...';

  @override
  String get initializationError => '初始化錯誤';

  @override
  String get noReadersFound => '未找到讀取器';

  @override
  String get noReadersFoundMessage => '插入兼容的讀取器或掃描藍牙設備以管理您的 eSIM 配置。';

  @override
  String get scanBle => '掃描藍牙';

  @override
  String get reminderDetails => '提醒詳情';

  @override
  String get profileNotFound => '未找到設定檔';

  @override
  String get resending => '正在重發...';

  @override
  String get noAddressInNotification => '通知數據中沒有地址';

  @override
  String get sentSuccessfully => '發送成功';

  @override
  String get sendFailed => '發送失敗';

  @override
  String get copiedCurl => 'cURL 指令已複製到剪貼簿';

  @override
  String get noAddressToExport => '沒有要匯出的地址';

  @override
  String get noHistoryAvailable => '沒有歷史記錄';

  @override
  String get searchByIccid => '搜尋 ICCID...';

  @override
  String get resendNotification => '重發通知';

  @override
  String get exportAsCurl => '匯出為 cURL';

  @override
  String get viewDetails => '檢視詳情';

  @override
  String get deleteEntry => '刪除條目';

  @override
  String activeReminders(int count) {
    return '$count 個活動的提醒';
  }

  @override
  String get noScheduledReminders => '沒有已排程的提醒';

  @override
  String get remindersAppearWhen => '當您為設定檔添加日期標籤時，提醒會出現在這裡。';

  @override
  String activeTagsCount(int count) {
    return '所有設定檔中共 $count 個活動標籤';
  }

  @override
  String get searchTagsOrProfiles => '搜尋標籤或設定檔...';

  @override
  String get noTagsFound => '未找到標籤';

  @override
  String get addTagsFromProfileMenu => '從設定檔編輯選單添加標籤即可在此處檢視。';

  @override
  String get expired => '已過期';

  @override
  String daysLeft(int count) {
    return '剩餘 $count 天';
  }

  @override
  String hoursLeft(int count) {
    return '剩餘 $count 小時';
  }

  @override
  String get expiresSoon => '即將過期';

  @override
  String get soon => '即將';

  @override
  String get activeTags => '有效標籤';

  @override
  String get addNewTag => '添加新標籤';

  @override
  String get noTagsAssigned => '此配置未分配標籤';

  @override
  String get textTagHint => '文本標籤 (如: 工作, 旅行)';

  @override
  String get addDateExpiryTag => '添加日期/到期標籤';

  @override
  String get addNoteOptional => '添加備註 (可選)';

  @override
  String get add => '添加';

  @override
  String get noteHint => '如: 到期時間, 10GB 等';

  @override
  String get invalidHexString => '無效的十六進制字符串';

  @override
  String get resetToDefaults => '重置為默認值';

  @override
  String get resetToDefaultsSuccess => '已重置為默認值';

  @override
  String get addAidHex => '添加 AID (十六進位)';

  @override
  String get manageAutoNotif => '管理自動通知處理';

  @override
  String get automaticProcessing => '自動處理';

  @override
  String get notifProcessingInfo =>
      '處理通知有助於同步 eUICC 與 SM-DP+ 伺服器（電信商）。刪除已發送的通知可保持卡片存儲空間整潔。';

  @override
  String get enabling => '啟用時';

  @override
  String get afterEnabling => '啟用設定檔後';

  @override
  String get disabling => '禁用時';

  @override
  String get afterDisabling => '禁用設定檔後';

  @override
  String get installation => '安裝時';

  @override
  String get afterDownload => '下載設定檔後';

  @override
  String get deletion => '刪除時';

  @override
  String get afterDeletion => '刪除設定檔後';

  @override
  String get autoSend => '自動發送';

  @override
  String get autoSendSubtitle => '自動發送到伺服器';

  @override
  String get autoRemove => '自動刪除';

  @override
  String get autoRemoveSubtitle => '發送後從卡片中刪除';

  @override
  String get removeWithoutSending => '不發送直接刪除';

  @override
  String get removeWithoutSendingSubtitle => '謹慎使用：伺服器不會收到通知';

  @override
  String get permissionsActive => '權限已激活';

  @override
  String get permissionsRequired => '需要權限';

  @override
  String get appCanSendNotif => '應用程式可以發送系統通知';

  @override
  String get requiredForReminders => '提醒警報需要此權限';

  @override
  String get unsupportedPlatformCheck => '此平台不支援權限檢查。請進行手動測試。';

  @override
  String get couldNotVerifyStatus => '無法驗證狀態。請手動檢查設置。';

  @override
  String get testNotificationTitle => '測試通知';

  @override
  String get seconds => '秒';

  @override
  String get startTest => '開始測試';

  @override
  String get sendingNotif => '正在發送...';

  @override
  String get hostIpLabel => '主機名 / IP';

  @override
  String get portLabel => '連接埠';

  @override
  String get passwordOptionalLabel => '密碼（可選）';

  @override
  String get configuredServers => '已設定的伺服器';

  @override
  String get secureHttps => '安全 (HTTPS)';

  @override
  String get insecureHttp => '不安全 (HTTP)';

  @override
  String get urlCopied => 'URL 已複製';

  @override
  String get serverAddedSuccessfully => '伺服器添加成功';

  @override
  String get authFailedCheckPassword => '身份驗證失敗。請檢查密碼。';

  @override
  String get addNewServer => '添加新伺服器';

  @override
  String get autoLoadRemotes => '自動載入遠端裝置';

  @override
  String get autoLoadRemotesSubtitle => '應用程式啟動時自動連接到已設定的伺服器';

  @override
  String get getRemoCardGitHub => '從 GitHub 獲取 RemoCard';

  @override
  String get instructions => '說明：';

  @override
  String get instruction1 => '1. 在您的安卓裝置上安裝 RemoCard 應用程式。';

  @override
  String get instruction2 => '2. 在每個 RemoCard 應用程式中啟動伺服器。';

  @override
  String get instruction3 => '3. 在此處輸入 IP 地址。';

  @override
  String get instruction4 => '4. 所有遠端 SIM 插槽將出現在裝置列表中。';

  @override
  String get appLogsCopied => '日誌已複製到剪貼簿';

  @override
  String get aramInfoTitle => 'ARA-M 資訊';

  @override
  String get aramInfoSubtitle => '存取規則小應用詳情';

  @override
  String get whatIsAram => '什麼是 ARA-M？';

  @override
  String get aramDescription =>
      '存取規則小應用 (ARA-M) 是 eUICC (eSIM) 和 SIM 卡上的一種機制，它定義了哪些應用程式被允許管理設定檔或執行低級操作。如果應用程式的哈希值不在卡片的 ARA-M 允許列表中，安卓系統將阻止存取，導致「存取被拒絕」錯誤。';

  @override
  String get appCertHashes => '應用程式證書哈希';

  @override
  String get aramHashInstruction =>
      '為相容不同 Android 版本，請將下方所有 SHA-1 憑證雜湊新增到卡片的 ARA-M 規則中。應用程式簽署金鑰升級後，不同 Android 版本可能會檢查已驗證簽署記錄中的不同憑證。';

  @override
  String get certSha1Hash => '證書 SHA-1 哈希';

  @override
  String get unavailable => '不可用';

  @override
  String get troubleshooting => '故障排除';

  @override
  String get troubleStep1 => '確保您使用了正確的讀卡機。';

  @override
  String get troubleStep2 => '如果使用實體卡，請檢查它是測試卡還是生產卡（生產卡通常鎖定 ARA-M）。';

  @override
  String get troubleStep3 => '上述哈希值取決於您使用的是應用程式的偵錯版、正式版還是特權 (Magisk) 版。';

  @override
  String get troubleStep4 => '考慮使用可以繞過某些安卓 API 限制的特權 (Magisk) 組建版。';

  @override
  String get hashCopied => '哈希已複製到剪貼簿';

  @override
  String get aidCopied => 'AID 已複製到剪貼簿';

  @override
  String get lastSeen => '最後出現';

  @override
  String get unknownProvider => '未知運營商';

  @override
  String get unknownProfile => '未知配置';

  @override
  String get tags => '標籤';

  @override
  String get noTags => '無標籤';

  @override
  String records(int count) {
    return '$count 條記錄';
  }

  @override
  String get bytes => '位元組';

  @override
  String get responseCode => '響應代碼';

  @override
  String get responseBody => '響應體';

  @override
  String get type => '類型';

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
  String get isdrAids => 'ISD-R AID';

  @override
  String get configureDefaultAids => '配置默認應用 ID';

  @override
  String get addAidHexHint => '添加 AID (十六進制)';

  @override
  String get notificationProcessing => '通知設置';

  @override
  String get manageAutoNotification => '管理自動通知處理';

  @override
  String get notificationProcessingHelp =>
      '處理通知有助於您的 eUICC 與 SM-DP+ 服務器（運營商）之間的同步。刪除已發送的通知可以保持卡存儲清潔。';

  @override
  String get notificationProcessingTimings => 'Processing timings';

  @override
  String get notificationProcessingTimingsHelp =>
      'Choose when automatic notification processing runs. Some safety-critical timings can only be disabled while Developer Mode is enabled.';

  @override
  String get afterEnablingProfile => '啟用配置後';

  @override
  String get afterDisablingProfile => '禁用配置後';

  @override
  String get afterProfileDownload => '下載配置後';

  @override
  String get afterProfileDeletion => '刪除配置後';

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
  String get sendToServerAutomatically => '自動發送到服務器';

  @override
  String get removeFromCardAfterSending => '發送後從卡中刪除';

  @override
  String get removeWithoutSendingCaution => '請謹慎使用：服務器將不會收到通知';

  @override
  String get reminderSettings => '提醒設置';

  @override
  String get appCanSendNotifications => '應用可以發送系統通知';

  @override
  String get requiredForReminderAlerts => '接收提醒通知所需';

  @override
  String get enable => '啟用';

  @override
  String get permissionCheckNotSupported => '此平臺不支持權限檢查。請進行手動測試。';

  @override
  String get testNotification => '測試通知';

  @override
  String get notificationsDisabledMessage => '通知已禁用。請在系統設置中啟用它們以接收提醒。';

  @override
  String get openSettings => '打開設置';

  @override
  String get applicationLogs => '應用日誌';

  @override
  String get refreshReload => '刷新/重新加載';

  @override
  String get toggleAutoScroll => '切換自動滾動';

  @override
  String get refreshDevices => '刷新設備';

  @override
  String get scanBluetooth => '掃描藍牙';

  @override
  String get lessThan1Kb => '< 1 KB';

  @override
  String get connectionFailed => '連接失敗';

  @override
  String get downloadRemoCard => '下載 RemoCard';

  @override
  String get remoCardAndroidApp => 'Android 遠程控制器應用';

  @override
  String get resentSuccessfully => '重發成功';

  @override
  String get resendFailed => '重發失敗';

  @override
  String get eid => 'EID';

  @override
  String get seq => '序列號';

  @override
  String get date => '日期';

  @override
  String errorWithDetails(String error) {
    return '錯誤: $error';
  }

  @override
  String exportFailed(String error) {
    return '導出失敗: $error';
  }

  @override
  String get sasAccreditation => 'SAS 認證';

  @override
  String get firmwareVersion => '韌體版本';

  @override
  String get platformSupport => '平台支持';

  @override
  String get rspVersion => 'RSP 版本';

  @override
  String get bppVersion => 'BPP 版本';

  @override
  String get gpVersion => 'GlobalPlatform 版本';

  @override
  String get certInfrastructure => '證書基礎結構';

  @override
  String get euiccSignCi => 'eUICC 簽名 CI';

  @override
  String get euiccVerifyCi => 'eUICC 驗證 CI';

  @override
  String get none => '無';

  @override
  String keysCount(int count) {
    return '$count 個金鑰';
  }

  @override
  String get state => '狀態';

  @override
  String get profileClass => '類別';

  @override
  String get aid => 'AID';

  @override
  String get euiccSpecifications => 'eUICC 規格';

  @override
  String get sending => '正在發送...';

  @override
  String get failedToSaveTags => '儲存標籤失敗';

  @override
  String get note => '備註';

  @override
  String get notificationDetails => '通知詳情';

  @override
  String get unknown => '未知';

  @override
  String get status => '狀態';

  @override
  String get sent => '已發送';

  @override
  String get pending => '待處理';

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
  String get manage => '管理';

  @override
  String get buyCard => '卡片';

  @override
  String get buyData => '數據';

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
  String get estimatedDownloadSize => '預估下載大小';

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
  String get insufficientStorageWarning => '可用空間不足，安裝可能會失敗。';

  @override
  String get estimateProfileSize => '估計配置文件大小';

  @override
  String get estimateProfileSizeSubtitle => '在下載前估計配置文件元數據的大小';

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
}
