// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get addBluetoothReader => 'Add Bluetooth reader';

  @override
  String get bluetoothSetupFailed =>
      'Unable to set up the Bluetooth reader. Check that Bluetooth is on and the reader is nearby, then try again.';

  @override
  String get settingsTitle => '設定';

  @override
  String get displaySettings => '表示設定';

  @override
  String get appearance => '外観';

  @override
  String get appearanceSubtitle => 'テーマ、レイアウト、表示設定を変更します';

  @override
  String get darkMode => 'ダークモード';

  @override
  String get themeStyle => 'テーマスタイル';

  @override
  String get themeStyleSubtitle => 'Nekoko、MD3 のスタイルが選択できます';

  @override
  String get customDesign => 'Nekoko スタイル';

  @override
  String get stockMD3 => '標準的な MD3';

  @override
  String get waterfallLayout => 'ウォーターフォールレイアウト';

  @override
  String get waterfallLayoutSubtitle => 'ワイドスクリーンで Masonry スタイルのレイアウトを使用します';

  @override
  String get system => 'システム';

  @override
  String get light => 'ライト';

  @override
  String get dark => 'ダーク';

  @override
  String get language => '言語';

  @override
  String get systemLanguage => 'システム言語';

  @override
  String get general => '一般';

  @override
  String get ui => 'UI';

  @override
  String get autoLoadProfiles => 'プロファイルを自動で読み込む';

  @override
  String get autoLoadProfilesSubtitle => 'リーダーの選択時にプロファイルを読み込みます';

  @override
  String get loadProfileIcons => 'プロファイルアイコンを読み込む';

  @override
  String get loadProfileIconsSubtitle => 'eUICC からアイコンを取得します (低速)';

  @override
  String get useNekokoIcons => 'Nekoko Cloud からアイコンを取得';

  @override
  String get useNekokoIconsSubtitle => 'Nekoko からキャリアアイコンを取得します';

  @override
  String get forceDeviceDropdown => 'デバイスドロップダウンを強制';

  @override
  String get forceDeviceDropdownSubtitle => 'デバイスの選択で常にドロップダウンを使用します';

  @override
  String get sizeDisplayUnit => 'サイズの表示単位';

  @override
  String get sizeDisplayUnitSubtitle => 'サイズ表示で使用する単位形式を指定します';

  @override
  String get phoneFormat => '電話番号の形式';

  @override
  String get phoneFormatSubtitle => '電話番号の表示形式を指定します';

  @override
  String get notifications => '通知';

  @override
  String get notificationSettings => '通知の設定';

  @override
  String get notificationSettingsSubtitle => '自動処理と削除を設定します';

  @override
  String get notificationHistory => '通知の履歴';

  @override
  String get notificationHistorySubtitle => '送信済みの通知を検索、管理、再送信します';

  @override
  String get tagsAndReminders => 'タグとリマインダー';

  @override
  String get tagManager => 'タグの管理';

  @override
  String get tagManagerSubtitle => 'プロファイルのタグを作成または編集します';

  @override
  String get tagReminders => 'タグのリマインダー';

  @override
  String get tagRemindersSubtitle => '日付のタグに基づいて通知をスケジュールします';

  @override
  String get manageTagsAndReminders => 'タグの管理とリマインダー';

  @override
  String get manageTagsAndRemindersSubtitle => 'タグを構成、テストアラートと通知の権限を確認します';

  @override
  String get viewScheduledReminders => 'スケジュール済みのリマインダーを表示';

  @override
  String get viewScheduledRemindersSubtitle => 'タグベースのリマインダーを管理します';

  @override
  String get connectivity => '接続性';

  @override
  String get remoteReaders => 'リモートリーダー';

  @override
  String get remoteReadersSubtitle => 'RemoCard コンパニオンアプリを構成します';

  @override
  String get enableBle => 'Bluetooth コネクター';

  @override
  String get enableBleSubtitle => 'Bluetooth リーダーのスキャンと接続を有効化します';

  @override
  String get enableCcid => 'USB CCID コネクター';

  @override
  String get enableCcidSubtitle => 'USB スマートカードリーダーを有効化します (CCID)';

  @override
  String get enableOmapi => 'OMAPI コネクター';

  @override
  String get enableOmapiSubtitle =>
      'OMAPI ベースの eUICC 管理のための Open Mobile API 機能を有効化します';

  @override
  String get enableTmapi => 'Telephony API コネクター';

  @override
  String get enableTmapiSubtitle =>
      'Telephony ベースの eUICC 管理のための Open Mobile API 機能を有効化します';

  @override
  String get readerTypes => 'リーダーの種類';

  @override
  String get readerTypesSubtitle => 'リーダーの種類 (CCID、Bluetooth、リモートなど) を管理します';

  @override
  String get enabledReaderTypes => '有効なリーダーの種類';

  @override
  String get enabledReaderTypesSubtitle => 'アプリで利用可能なリーダーの種類を制御します';

  @override
  String get remoteReaderSettings => 'リモートリーダー設定';

  @override
  String get remoteReaderSettingsSubtitle => 'リモートリーダーサーバーと接続を構成';

  @override
  String get ccidReaderTitle => 'CCID (USB/PC/SC)';

  @override
  String get ccidReaderSubtitle => 'USB スマートカードリーダーと PC/SC デバイス';

  @override
  String get bluetoothReaderTitle => 'Bluetooth';

  @override
  String get bluetoothReaderSubtitle => 'Bluetooth LE スマートカードリーダーとライター';

  @override
  String get remoteReadersTitle => 'リモートリーダー';

  @override
  String get remoteReadersConnectorSubtitle => 'ネットワーク接続されたリモートスマートカードリーダー';

  @override
  String get omapiReaderTitle => 'OMAPI';

  @override
  String get omapiReaderSubtitle => 'Open Mobile API 経由の内蔵 SIM カードスロット';

  @override
  String get tmapiReaderTitle => 'Telephony API';

  @override
  String get tmapiReaderSubtitle => 'Telephony API経由の内蔵eSIM';

  @override
  String get remoteServerConfiguration => 'リモートサーバー構成';

  @override
  String get remoteServerConfigurationSubtitle => 'リモートリーダーサーバーと接続設定を管理';

  @override
  String get enableBrowser => 'ブラウザを有効化する';

  @override
  String get enableBrowserSubtitle => 'ストア、購入、ヘルプなどのブラウザタブを追加で表示します';

  @override
  String get transport => '転送';

  @override
  String get disableRefreshFlags => '更新フラグを無効化';

  @override
  String get disableRefreshFlagsSubtitle => '外部リーダーには適用されません';

  @override
  String get apduMaxSegmentSize => 'APDU 最大セグメントのサイズ';

  @override
  String get apduMaxSegmentSizeSubtitle => 'APDU チャンクごとの最大サイズを設定します';

  @override
  String get ensureSingleChannel => '単一チャネルの確保';

  @override
  String get ensureSingleChannelSubtitle => '新しい論理チャネルを開く前に他の論理チャネルを閉じます';

  @override
  String get analytics => '解析とクラウドサービス';

  @override
  String get nekokoCloud => 'Nekoko Cloud';

  @override
  String get nekokoCloudSubtitle => 'インストールデータを解析して予測精度を向上させます';

  @override
  String get developer => '開発者';

  @override
  String get developerMode => '開発者モード';

  @override
  String get developerModeSubtitle => '高度なデバッグ機能を有効化します';

  @override
  String get exportDatabase => 'データベースをエクスポート';

  @override
  String get exportDatabaseSubtitle => 'ローカルデータベースのコピーを保存します';

  @override
  String get openDatabaseFolder => 'データベースフォルダを開く';

  @override
  String get openDatabaseFolderSubtitle => 'データベースファイルを含むフォルダを開きます';

  @override
  String get decodeAsn1 => 'ASN.1 ログのデコード (低速)';

  @override
  String get decodeAsn1Subtitle => 'パフォーマンスが低下する可能性があります';

  @override
  String get viewAppLogs => 'アプリのログを表示';

  @override
  String get viewAppLogsSubtitle => '収集されたアプリのログを表示します';

  @override
  String get about => 'アプリについて';

  @override
  String get version => 'バージョン';

  @override
  String get build => 'ビルド';

  @override
  String get checkUpdates => '更新を確認';

  @override
  String get checkUpdatesSubtitle => '開始時に最新のバージョンを確認';

  @override
  String get licenses => 'オープンソースライセンス';

  @override
  String get licensesSubtitle => '使用されているオープンソースライブラリのライセンス情報です';

  @override
  String get noUpdatesFound => '更新はありません';

  @override
  String get profilesTitle => 'プロファイル';

  @override
  String get switchEstkSlot => 'eSTK スロットを切り替え';

  @override
  String get notificationsButton => '通知';

  @override
  String get downloadProfile => 'プロファイルをダウンロード';

  @override
  String get reconnect => '再接続';

  @override
  String get bluetoothNotConnected => 'Bluetooth が未接続です';

  @override
  String get bluetoothNotConnectedSubtitle =>
      'Bluetooth が有効になっていることと、デバイスが近くにあるか確認してください。「接続」をタップして、デバイスの使用を開始してください。';

  @override
  String get bluetoothConnectionFailed => 'Bluetooth の接続に失敗しました';

  @override
  String bluetoothConnectionFailedSubtitle(Object error) {
    return 'Bluetooth デバイスの接続に失敗しました。\n\n$error';
  }

  @override
  String get removeDevice => 'リモートデバイス';

  @override
  String get retryConnection => '接続';

  @override
  String get remoteConnectionFailed => 'リモートリーダーの接続に失敗しました';

  @override
  String remoteConnectionFailedMessage(Object error) {
    return 'リモートサーバーが実行中であり、アクセスが可能か確認します。\n\n$error';
  }

  @override
  String get errorBluetoothTimeout => 'Bluetooth の操作がタイムアウトしました。やり直してください。';

  @override
  String get errorOmapiSecurity =>
      'セキュリティエラー: カードへのアクセスは、OS または ARA-M のルールによって拒否されました。';

  @override
  String get errorApplicationNotFound =>
      'eUICC 管理アプリ (ISD-R) が見つかりません。このカードは有効な eUICC ではない可能性があります。';

  @override
  String get changeSettings => '設定を変更';

  @override
  String get connectCompatibleReader => '開始するには互換性のあるリーダーを接続してください。';

  @override
  String get connectReaderMessageBle =>
      'Bluetooth 対応の eUICC を持っている場合は、互換性のある Bluetooth デバイスをスキャンすることもできます。';

  @override
  String get connectReaderMessageNoBle => 'CCID リーダーがコンピューターに接続されているか確認してください。';

  @override
  String get downloadSmartCardExtension => 'スマートカードの拡張機能をダウンロード';

  @override
  String get smartCardExtensionMessage =>
      'このブラウザで USB CCID リーダーにアクセスするには拡張機能が必要です。';

  @override
  String get scanForBluetooth => 'Bluetooth でスキャン';

  @override
  String get connectRemote => 'リモートに接続';

  @override
  String get noCardDetected => 'カードが未検出です';

  @override
  String get noCardDetectedMessage => 'このスロットは非対応または有効な eUICC が見つかりません。';

  @override
  String get noDataLoaded => '未接続';

  @override
  String get loadProfiles => '接続';

  @override
  String get disconnect => '切断';

  @override
  String get disconnecting => '切断中...';

  @override
  String get profilesEmpty => 'カード上にプロファイルがありません';

  @override
  String get profilesEmptyMessage => 'この eUICC カードは空です。';

  @override
  String get renameProfile => 'プロファイル名を変更';

  @override
  String get nickname => 'ニックネーム';

  @override
  String get enterProfileNickname => 'プロファイルのニックネームを入力';

  @override
  String get profileNicknameNote => '説明: タグは、「タグの管理」メニューから個別に管理されます。';

  @override
  String get useProfileIcon => 'プロファイルアイコンを使用';

  @override
  String get useProfileIconSubtitle => 'eSIM カードのアイコンを使用します';

  @override
  String get removeCustomIcon => 'カスタムアイコンを削除';

  @override
  String get noRemoteIcon => 'このオペレーターにはリモートアイコンがありません';

  @override
  String get cancel => 'キャンセル';

  @override
  String get ok => 'OK';

  @override
  String get save => '保存';

  @override
  String get delete => '削除';

  @override
  String get refresh => '更新';

  @override
  String get initializing => '初期化中...';

  @override
  String get refreshingProfiles => 'プロファイルを更新中...';

  @override
  String get retrievingEid => 'EID と情報を取得中...';

  @override
  String get updatingProfile => 'プロファイルを更新中...';

  @override
  String get manageIsdR => 'ISD-R AID を管理';

  @override
  String get manageIsdRSubtitle => 'eUICC のデフォルトアプリ ID を構成します';

  @override
  String get transportFailed => '転送が失敗しました';

  @override
  String get remoteTransportFailedMessage =>
      'リモートサーバーに接続しましたが、コマンドが失敗しました。これは通常、リモートデバイスが一時的にビジー状態であるか、カードから切断されていることを意味します。再試行しますか？';

  @override
  String get retry => '再試行';

  @override
  String get scanningForReaders => 'リーダーからスキャン中...';

  @override
  String get switchedEstkSlot => 'eSTK スロットを切り替えました';

  @override
  String get scanningForUnresponsiveDevices => '応答のないデバイスをスキャン中...';

  @override
  String get resettingConnection => '接続を再設定中...';

  @override
  String get connectingToReader => 'リーダーに接続中...';

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
  String get moreOptions => 'その他のオプション';

  @override
  String get retrievingProfiles => 'プロファイルを取得中...';

  @override
  String get savingProfileMetadata => 'プロファイルのメタデータを保存中...';

  @override
  String get enablingProfile => 'プロファイルを有効化中...';

  @override
  String get disablingProfile => 'プロファイルを無効化中...';

  @override
  String get deleteProfile => 'プロファイルを削除';

  @override
  String deleteProfileConfirmation(Object profileName) {
    return '「$profileName」のプロファイルを削除してもよろしいですか？\nこの操作は元に戻せません。';
  }

  @override
  String get deletingProfile => 'プロファイルを削除中...';

  @override
  String get deleting => '削除中...';

  @override
  String get dataUsage => 'データの使用量';

  @override
  String get details => '詳細';

  @override
  String get rename => '名前を変更';

  @override
  String get changeIcon => 'アイコンを変更';

  @override
  String get manageTags => 'タグを管理';

  @override
  String get copyIccid => 'ICCID をコピー';

  @override
  String get notificationProcessingError => '通知の処理中は操作を実行できません';

  @override
  String get operationInProgressError => '作業が進行中です。お待ちください。';

  @override
  String iccidCopied(Object iccid) {
    return 'ICCID をコピーしました: $iccid';
  }

  @override
  String get operationRestricted => '操作の制限';

  @override
  String get notificationProcessingDownloadError =>
      '通知の処理がまだ進行中です。完了するまでお待ち下さい。新しいプロファイルをダウンロードしてください。';

  @override
  String get operational => '運用';

  @override
  String get test => 'テスト';

  @override
  String get provisioning => 'プロビジョニング';

  @override
  String get profileDetails => 'プロファイルの詳細';

  @override
  String get profileDetailsSubtitle => 'プロファイルスロットの eUICC からの情報';

  @override
  String get enabled => '有効化済み';

  @override
  String get disabled => '無効化済み';

  @override
  String get tagsManagedSeparately => '説明: タグは、「タグの管理」メニューから個別に管理されます。';

  @override
  String get changeProfileIcon => 'プロファイルアイコンを変更';

  @override
  String get selectFromGallery => 'ギャラリーから選択';

  @override
  String get nekokoOperatorIcon => 'Nekoko オペレーターのアイコン';

  @override
  String get iconFromEsim => 'eSIM カードのアイコン';

  @override
  String updateIconFailed(Object error) {
    return 'アイコンの更新に失敗しました: $error';
  }

  @override
  String get failedToReadImage => '画像の読み込みに失敗しました';

  @override
  String get failedToProcessImage => '画像の処理に失敗しました';

  @override
  String get customIconSet => 'カスタムアイコンの設定に成功しました';

  @override
  String get noMccMnc => 'このプロファイルは MCC/MNC は使用できません';

  @override
  String get fetchingRemoteIcon => 'リモートアイコンを取得中...';

  @override
  String get remoteIconSaved => 'リモートアイコンをカスタムアイコンとして保存しました';

  @override
  String fetchRemoteIconFailed(Object error) {
    return 'リモートアイコンの取得に失敗しました: $error';
  }

  @override
  String get noProfileIcon => '有効なプロファイルが見つかりません';

  @override
  String get profileIconSaved => 'プロファイルアイコンをカスタムアイコンとして保存しました';

  @override
  String get customIconRemoved => 'カスタムアイコンを削除しました';

  @override
  String get failed => '失敗しました';

  @override
  String euiccError(Object action) {
    return 'プロファイルを$actionしようとしたときに、eUICC がエラーを返しました。';
  }

  @override
  String get dismiss => '破棄';

  @override
  String get dataPlan => 'データプラン';

  @override
  String get used => '使用済み';

  @override
  String get total => '合計';

  @override
  String expires(Object date) {
    return '期限: $date';
  }

  @override
  String get close => '閉じる';

  @override
  String get server => 'サーバー';

  @override
  String get switchFailed => '切り替えに失敗しました';

  @override
  String get deviceRefreshFailed => 'デバイスの更新に失敗しました';

  @override
  String get euiccOptions => 'eUICC のオプション';

  @override
  String get euiccInfo => 'eUICC 情報';

  @override
  String get hideEid => 'EID を非表示';

  @override
  String get showEid => 'EID を表示';

  @override
  String get copyEid => 'EID をコピー';

  @override
  String get eidCopied => 'EID をクリップボードにコピーしました';

  @override
  String get connectRemotes => 'リモートに接続';

  @override
  String get configureRemotes => 'リモートを構成';

  @override
  String get connectingToRemoteReaders => 'バックグラウンドでリモートリーダーに接続中です...';

  @override
  String get noRemoteReadersFound => 'リモートリーダーが見つかりません';

  @override
  String connectedRemoteReaders(Object count) {
    return '$count 個のリモートリーダーに接続しました';
  }

  @override
  String failedToConnectRemoteReaders(Object error) {
    return 'リモートリーダーの接続に失敗しました: $error';
  }

  @override
  String get remoteReaderPassword => 'リモートリーダーのパスワード';

  @override
  String get remoteReaderPasswordSubtitle => 'このリモートリーダーはパスワードが必要です。';

  @override
  String get password => 'パスワード';

  @override
  String get deleteConnection => '接続を削除';

  @override
  String get connect => '接続';

  @override
  String get remoteReaderConnectionFailed => 'リモートリーダーの接続に失敗しました';

  @override
  String remoteReaderConnectionFailedSubtitle(Object error) {
    return 'リモートサーバーが実行中であり、アクセス可能か確認してください。\n\n$error';
  }

  @override
  String get connectReader => '開始するには、互換性のあるリーダーを接続してください。';

  @override
  String get connectReaderSubtitleBle =>
      'Bluetooth 対応の eUICC を持っている場合は、互換性のある Bluetooth デバイスをスキャンすることもできます。';

  @override
  String get connectReaderSubtitleCcid =>
      'CCID リーダーがコンピューターに接続されていることを確認してください。';

  @override
  String get downloadExtension => 'スマートカードの拡張機能をダウンロード';

  @override
  String get downloadExtensionSubtitle =>
      'このブラウザで USB CCID リーダーにアクセスするには拡張機能が必要です。';

  @override
  String get cardUnsupported => 'カードが非対応です';

  @override
  String get cardUnsupportedSubtitle =>
      'このカードは eUICC ではないかリーダーに非対応または、他のリーダー使用されていない可能性があります。';

  @override
  String get omapiWelcome =>
      '良い点は、使用中のデバイスで OMAPI が対応しており、リムーバブルカードと互換性がある可能性が高いことです。';

  @override
  String get supportedDevices => '対応しているデバイス';

  @override
  String get aboutAram => 'ARA-M について';

  @override
  String get accessDenied => 'アクセス拒否';

  @override
  String get accessDeniedSubtitle =>
      'この eUICC にアクセスするには、キャリアの権限が必要です。カードの ARA-M 許可リストがアプリの署名と一致しません。';

  @override
  String get noCardDetectedSubtitle => 'このスロットは非対応、または有効な eUICC が見つかりません。';

  @override
  String get noProfilesInstalled => 'インストール済みのプロファイルはありません';

  @override
  String get noProfilesInstalledSubtitle => 'この eUICC カードは空です。';

  @override
  String get cardRefreshingTitle => 'カードを更新しました';

  @override
  String get cardRefreshingMessage =>
      'カードの状態を更新しています。現時点ではプロファイルの一覧を取得できません。数秒間待った後に再度お試しください。';

  @override
  String get useRemoteIcon => 'リモートアイコンを使用';

  @override
  String get bleDisconnectedTitle => 'Bluetooth が切断されました';

  @override
  String get bleDisconnectedMessage =>
      'カードリーダーとの接続が突然切断されました。カードリーダーが近くにある、または電源が入っているか確認してください。';

  @override
  String get cardStuckRefreshingMessage =>
      'プロファイルの状態を変更中です - 動作しない場合は手動で再接続してください。';

  @override
  String get cardNeedsReplugTitle => 'SIM カードを挿し直してください';

  @override
  String get cardNeedsReplugMessage =>
      'カードが eUICC アプレットを引き渡さないため、現在は管理できません。SIM カードを取り外してから挿し直し、もう一度お試しください。';

  @override
  String get activationCodeTitle => 'アクティベーションコード';

  @override
  String get activationCodeSubtitle =>
      'QR コードをスキャン、または画像を読み込むか LPA の文字列を手動で入力してください。';

  @override
  String get fullActivationCodeLabel => '完全なアクティベーションコード';

  @override
  String get fullActivationCodeHint => 'LPA:1\$smdp.io\$マッチング ID';

  @override
  String get pasteFromClipboardTooltip => 'クリップボードから貼り付け';

  @override
  String get selectFromGalleryTooltip => 'ギャラリーから選択';

  @override
  String get scanQrCodeTooltip => 'QR コードをスキャン';

  @override
  String get smdpAddressLabel => 'SM-DP+ アドレス';

  @override
  String get smdpAddressHint => 'smdp.io';

  @override
  String get matchingIdLabel => 'マッチング ID';

  @override
  String get matchingIdHint => 'ABC-123';

  @override
  String get smdpOidLabel => 'SM-DP+ OID';

  @override
  String get confirmationCodeLabel => '確認コード';

  @override
  String get confirmationCodeHint => '確認コードを入力';

  @override
  String get continueButton => '続行';

  @override
  String get invalidLpaClipboard => 'クリップボードに有効な LPA の文字列が含まれていません。';

  @override
  String get invalidFqdnFormat => '無効な FQDN 形式';

  @override
  String get invalidMatchingIdChars => 'マッチング ID に無効な文字が含まれています';

  @override
  String get invalidOidFormat => '無効な OID 形式 (例: 1.2.840...)';

  @override
  String get activationCodeRequired => 'アクティベーションコードが必要です';

  @override
  String get invalidLpaFormatGeneric => '無効な LPA 形式';

  @override
  String get smdpAddressRequired => 'SM-DP+ が必要です';

  @override
  String get loadingNotifications => '通知を読み込み中...';

  @override
  String get vowifi => 'VoWiFi';

  @override
  String get vowifiSubtitle => 'Wi-Fi 通話を有効化します (Beta)';

  @override
  String get vowifiDisclaimerTitle => '実験的な VoWiFi を有効にしますか？';

  @override
  String get vowifiDisclaimerBody =>
      'VoWiFi は実験的な機能です。お使いの携帯電話事業者と直接通信し、生の APDU に対応した互換性のある外付け SIM/eSIM リーダーでのみ動作します。事業者やリーダーによって互換性は異なります。';

  @override
  String get processing => '処理中...';

  @override
  String get analyzingImage => '画像を解析中...';

  @override
  String get noQrFoundInImage => '画像から QR コードが見つかりません';

  @override
  String get invalidAcInImage => '画像に無効なアクティベーションコードが見つかりました';

  @override
  String get invalidAcFormatDetailed =>
      'アクティベーションコードの形式が無効です。LPA:1\$ で始まっている必要があります...';

  @override
  String get downloadProfileTitle => 'プロファイルをダウンロード';

  @override
  String get connectingToEuicc => 'eUICC に接続中...';

  @override
  String get gettingChallenge => 'eUICC チャレンジを取得中...';

  @override
  String get authenticatingWithSmdp => 'SM-DP+ を認証中...';

  @override
  String get verifyingSignatures => 'SM-DP+ の署名を検証中...';

  @override
  String get retrievingMetadata => 'プロファイルメタデータを取得中...';

  @override
  String get preparingDownload => 'ダウンロードを準備中...';

  @override
  String get preparingEuicc => 'eUICC を準備中...';

  @override
  String get fetchingProfilePackage => 'プロファイルパッケージを取得中...';

  @override
  String installing(Object sent, Object total) {
    return 'インストール中 ($sent / $total バイト)...';
  }

  @override
  String get finalizing => '完了中 (ストレージ情報を更新中)...';

  @override
  String get profileInstalledSuccessfully => 'プロファイルのインストールが成功しました！';

  @override
  String get provider => 'プロバイダー';

  @override
  String get iccid => 'ICCID';

  @override
  String get plmn => 'PLMN';

  @override
  String get storage => 'ストレージ';

  @override
  String get free => '空き容量';

  @override
  String get nvram => 'NVRAM';

  @override
  String get exportCertificates => '証明書をエクスポート';

  @override
  String get euiccCert => 'eUICC 証明書';

  @override
  String get eumCert => 'EUM 証明書';

  @override
  String get enterConfirmationCode => 'キャリアが要求する確認コードを入力してください';

  @override
  String get confirmationCodeRequired => '確認コードが必要です';

  @override
  String get download => 'ダウンロード';

  @override
  String get installationSuccessful => 'インストールが成功しました';

  @override
  String get installationSuccessMessage => 'プロファイルが eUICC にインストールされました。';

  @override
  String get consumed => '消費';

  @override
  String get enableProfileNow => '今すぐにプロファイル有効化';

  @override
  String get done => '完了';

  @override
  String get profileEnabledSuccessfully => 'プロファイルの有効化に成功しました';

  @override
  String get enterNewProfileName => '簡単に識別できるように、プロファイルの新しい名前を入力してください。';

  @override
  String get profileName => 'プロファイル名';

  @override
  String get profileNameHint => '例: 出張';

  @override
  String get profileRenamedSuccessfully => 'プロファイル名の変更が成功しました';

  @override
  String get downloadFailed => 'ダウンロードが失敗しました';

  @override
  String get tryAgain => '再試行';

  @override
  String get savedSuccessfully => '保存に成功しました';

  @override
  String get saveCertificate => '証明書を保存';

  @override
  String get searchingForReaders => 'リーダーを検索中...';

  @override
  String get initializationError => '初期化エラー';

  @override
  String get noReadersFound => 'リーダーが見つかりません';

  @override
  String get noReadersFoundMessage =>
      '互換性のあるリーダーを接続するか、BLE デバイスをスキャンで eSIM プロファイルを管理します。';

  @override
  String get scanBle => 'BLE をスキャン';

  @override
  String get reminderDetails => 'リマインダーの詳細';

  @override
  String get profileNotFound => 'プロファイルが見つかりません';

  @override
  String get resending => '再送信中...';

  @override
  String get noAddressInNotification => '通知データにアドレスがありません';

  @override
  String get sentSuccessfully => '送信が成功しました';

  @override
  String get sendFailed => '送信が失敗しました';

  @override
  String get copiedCurl => 'cURL コマンドをクリップボードにコピーしました';

  @override
  String get noAddressToExport => 'エクスポートするアドレスがありません';

  @override
  String get noHistoryAvailable => '履歴はありません';

  @override
  String get searchByIccid => 'ICCID で検索...';

  @override
  String get resendNotification => '通知を再送信';

  @override
  String get exportAsCurl => 'cURL をエクスポート';

  @override
  String get viewDetails => '詳細を表示';

  @override
  String get deleteEntry => 'エントリを削除';

  @override
  String activeReminders(int count) {
    return '$count 個の有効なリマインダーがあります';
  }

  @override
  String get noScheduledReminders => 'スケジュール済みのリマインダーはありません';

  @override
  String get remindersAppearWhen => 'プロファイルに日付のタグを追加すると、リマインダーが表示されます。';

  @override
  String activeTagsCount(int count) {
    return 'すべてのプロファイルで有効なタグが $count 個あります';
  }

  @override
  String get searchTagsOrProfiles => 'タグまたはプロファイルを検索...';

  @override
  String get noTagsFound => 'タグが見つかりません';

  @override
  String get addTagsFromProfileMenu => 'プロファイル編集メニューからタグを追加することで、ここに表示されます。';

  @override
  String get expired => '期限切れ';

  @override
  String daysLeft(int count) {
    return '残り $count 日';
  }

  @override
  String hoursLeft(int count) {
    return '残り $count 時間';
  }

  @override
  String get expiresSoon => 'まもなく期限切れ';

  @override
  String get soon => '近日';

  @override
  String get activeTags => '有効なタグ';

  @override
  String get addNewTag => '新しいタグを追加';

  @override
  String get noTagsAssigned => 'このプロファイルにはタグが割り当てられていません。';

  @override
  String get textTagHint => 'テキストタグ (例: 仕事、旅行)';

  @override
  String get addDateExpiryTag => '日付/有効期限のタグを追加';

  @override
  String get addNoteOptional => '説明を追加 (任意)';

  @override
  String get add => '追加';

  @override
  String get noteHint => '例: 有効期限、10GB など';

  @override
  String get invalidHexString => '無効な Hex 文字列';

  @override
  String get resetToDefaults => 'デフォルトにリセット';

  @override
  String get resetToDefaultsSuccess => 'デフォルトにリセット';

  @override
  String get addAidHex => 'AID を追加 (Hex)';

  @override
  String get manageAutoNotif => '自動通知処理を管理';

  @override
  String get automaticProcessing => '自動処理';

  @override
  String get notifProcessingInfo =>
      '通知を処理することで、eUICC と SM-DP+ サーバー (キャリア) 間の同期が容易になります。送信済みの通知を削除すると、カードのストレージをクリーンに保つことができます。';

  @override
  String get enabling => '有効化中';

  @override
  String get afterEnabling => 'プロファイルの有効化後';

  @override
  String get disabling => '無効化中';

  @override
  String get afterDisabling => 'プロファイルの無効化後';

  @override
  String get installation => 'インストール';

  @override
  String get afterDownload => 'プロファイルのダウンロード後';

  @override
  String get deletion => '削除';

  @override
  String get afterDeletion => 'プロファイルの削除後';

  @override
  String get autoSend => '自動で送信';

  @override
  String get autoSendSubtitle => 'サーバーに自動で送信します';

  @override
  String get autoRemove => '自動で削除';

  @override
  String get autoRemoveSubtitle => '送信後にカードから削除します';

  @override
  String get removeWithoutSending => '送信をしないで削除';

  @override
  String get removeWithoutSendingSubtitle => '使用上の注意: サーバーに通知されません';

  @override
  String get permissionsActive => '権限が有効';

  @override
  String get permissionsRequired => '権限が必要です';

  @override
  String get appCanSendNotif => 'アプリはシステム通知を送信できます';

  @override
  String get requiredForReminders => 'リマインダーアラートに必要です';

  @override
  String get unsupportedPlatformCheck =>
      'このプラットフォームは権限の確認に対応していません。手動でテストを行ってください。';

  @override
  String get couldNotVerifyStatus => '状態を確認できませんでした。設定を手動で確認してください。';

  @override
  String get testNotificationTitle => 'テスト通知';

  @override
  String get seconds => '秒';

  @override
  String get startTest => 'テストを開始';

  @override
  String get sendingNotif => '送信中...';

  @override
  String get hostIpLabel => 'ホスト名 / IP';

  @override
  String get portLabel => 'ポート';

  @override
  String get passwordOptionalLabel => 'パスワード (任意)';

  @override
  String get configuredServers => '構成済みのサーバー';

  @override
  String get secureHttps => 'セキュア (HTTPS)';

  @override
  String get insecureHttp => '非セキュア (HTTP)';

  @override
  String get urlCopied => 'URL をコピーしました';

  @override
  String get serverAddedSuccessfully => 'サーバーの追加が成功しました';

  @override
  String get authFailedCheckPassword => '認証に失敗しました。パスワードを確認してください。';

  @override
  String get addNewServer => '新しいサーバーを追加';

  @override
  String get autoLoadRemotes => 'リモートデバイスを自動で読み込む';

  @override
  String get autoLoadRemotesSubtitle => 'アプリの起動時に設定されたサーバーに自動で接続します';

  @override
  String get getRemoCardGitHub => 'GitHub から RemoCard を入手';

  @override
  String get instructions => '説明:';

  @override
  String get instruction1 => '1. Android デバイスに RemoCard をインストールします。';

  @override
  String get instruction2 => '2. RemoCard アプリでサーバーを起動します。';

  @override
  String get instruction3 => '3. ここに IP アドレスを入力します。';

  @override
  String get instruction4 => '4. すべてのリモート SIM スロットがデバイスリストに表示されます。';

  @override
  String get appLogsCopied => 'ログをクリップボードにコピーしました';

  @override
  String get aramInfoTitle => 'ARA-M 情報';

  @override
  String get aramInfoSubtitle => 'アクセスルールアプレットの詳細';

  @override
  String get whatIsAram => 'ARA-M とは何ですか？';

  @override
  String get aramDescription =>
      'アクセスルールアプレット (ARA-M) は、eUICC (eSIM) および SIM カード上のメカニズムであり、プロファイルの管理やローレベルの操作の実行を許可するアプリを定義します。アプリのハッシュがカードの ARA-M の許可リストに存在しない場合、Android のシステムはアクセスをブロックして「アクセス拒否」のエラーを返します。';

  @override
  String get appCertHashes => 'アプリ証明書のハッシュ';

  @override
  String get aramHashInstruction =>
      'このアプリにアクセスを許可するには、カードの ARA-M ルールに以下の SHA-1 証明書のハッシュを追加する必要がある場合があります。このハッシュは、現在のアプリビルドの証明書に固有するものです。';

  @override
  String get aramSigningHistoryInstruction =>
      'Android のバージョン間の互換性を保つため、以下のすべての SHA-1 証明書ハッシュをカードの ARA-M ルールに追加してください。アプリの署名鍵を更新した後は、Android のバージョンによって、検証済みの署名履歴のうち異なる証明書が確認される場合があります。';

  @override
  String get certSha1Hash => '証明書の SHA-1 ハッシュ';

  @override
  String get unavailable => '利用不可';

  @override
  String get troubleshooting => 'トラブルシューティング';

  @override
  String get troubleStep1 => '正しいカードリーダーを使用しているか確認してください。';

  @override
  String get troubleStep2 =>
      '物理カードを使用する場合は、それがテストカードか製品版のカードかを確認してください (製品版のカードは ARA-M がロックされていることが多いです)。';

  @override
  String get troubleStep3 =>
      '上記のハッシュはアプリのデバッグバージョン、通常バージョン、特権バージョン (Magisk) のいずれを使用するかによって異なります。';

  @override
  String get troubleStep4 =>
      '一部の Android API 制限を回避可能な、特権バージョン (Magisk) の使用をご検討ください。';

  @override
  String get hashCopied => 'クリップボードにハッシュをコピーしました';

  @override
  String get aidCopied => 'クリップボードに AID をコピーしました';

  @override
  String get lastSeen => '最終確認';

  @override
  String get unknownProvider => '不明なプロバイダー';

  @override
  String get unknownProfile => '不明なプロファイル';

  @override
  String get tags => 'タグ';

  @override
  String get noTags => 'タグなし';

  @override
  String records(int count) {
    return '$count 個のレコードがあります';
  }

  @override
  String get bytes => 'バイト';

  @override
  String get responseCode => 'レスポンスコード';

  @override
  String get responseBody => 'レスポンス本文';

  @override
  String get type => 'タイプ';

  @override
  String profileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個のプロファイル',
      one: '1 個のプロファイル',
    );
    return '$_temp0';
  }

  @override
  String get isdrAids => 'ISD-R AID';

  @override
  String get configureDefaultAids => 'デフォルトのアプリ ID を構成します';

  @override
  String get addAidHexHint => 'AID を追加 (Hex)';

  @override
  String get notificationProcessing => '通知';

  @override
  String get manageAutoNotification => '自動通知処理を管理します';

  @override
  String get notificationProcessingHelp =>
      '通知を処理することで、eUICC と SM-DP+ サーバー (キャリア) 間の同期が容易になります。送信済みの通知を削除すると、カードのストレージをクリーンに保つことができます。';

  @override
  String get notificationProcessingTimings => '処理を行うタイミング';

  @override
  String get notificationProcessingTimingsHelp =>
      '自動通知処理を実行するタイミングを選択してください。一部の安全性で重要なタイミングは、開発者モードが有効化されている場合でのみ無効化できます。';

  @override
  String get afterEnablingProfile => 'プロファイルの有効化後';

  @override
  String get afterDisablingProfile => 'プロファイルの無効化後';

  @override
  String get afterProfileDownload => 'プロファイルのダウンロード後';

  @override
  String get afterProfileDeletion => 'プロファイルの削除後';

  @override
  String get initialLoad => '読み込みをした後';

  @override
  String get processNotificationsOnInitialLoad => 'プロファイルの読み込み完了後に通知を処理します';

  @override
  String get afterSwitchingProfile => 'プロファイルを切り替えた後';

  @override
  String get processNotificationsAfterSwitchingProfile =>
      'プロファイルの有効化または無効化後に通知を処理します';

  @override
  String get beforeProfileDownload => 'プロファイルをインストールする前';

  @override
  String get processNotificationsBeforeProfileDownload =>
      'プロファイルのダウンロードを開始する前に通知を処理します';

  @override
  String get afterProfileInstalled => 'プロファイルをインストールした後';

  @override
  String get processNotificationsAfterProfileInstalled =>
      'プロファイルをインストール後に通知を処理します';

  @override
  String get processNotificationsAfterProfileDeletion => 'プロファイルを削除後に通知を処理します';

  @override
  String get developerModeRequiredToDisableTiming =>
      'このタイミングを無効化するには、開発者モードを有効化してください。';

  @override
  String get sendToServerAutomatically => '自動でサーバーに送信';

  @override
  String get removeFromCardAfterSending => '送信後にカードから削除';

  @override
  String get removeWithoutSendingCaution => '使用上の注意: サーバーに通知されません';

  @override
  String get reminderSettings => 'リマインダーの設定';

  @override
  String get appCanSendNotifications => 'アプリはシステム通知を送信できます';

  @override
  String get requiredForReminderAlerts => 'リマインダーアラートで必要です';

  @override
  String get enable => '有効';

  @override
  String get permissionCheckNotSupported =>
      'このプラットフォームは権限の確認に対応していません。手動でテストを行ってください。';

  @override
  String get testNotification => 'テスト通知';

  @override
  String get notificationsDisabledMessage =>
      '通知が無効になっています。リマインダーを受け取るには、システム設定で通知を有効にしてください。';

  @override
  String get openSettings => '設定を開く';

  @override
  String get applicationLogs => 'アプリのログ';

  @override
  String get refreshReload => '更新/再読み込み';

  @override
  String get toggleAutoScroll => '自動スクロールを切り替え';

  @override
  String get refreshDevices => 'デバイスを更新';

  @override
  String get scanBluetooth => 'Bluetooth をスキャン';

  @override
  String get lessThan1Kb => '< 1 KB';

  @override
  String get connectionFailed => '接続に失敗しました';

  @override
  String get downloadRemoCard => 'RemoCard をダウンロード';

  @override
  String get remoCardAndroidApp => 'リモートコントロール用の Android アプリです';

  @override
  String get resentSuccessfully => '再送信に成功しました';

  @override
  String get resendFailed => '再送信に失敗しました';

  @override
  String get eid => 'EID';

  @override
  String get seq => 'シーケンス';

  @override
  String get date => '日付';

  @override
  String errorWithDetails(String error) {
    return 'エラー: $error';
  }

  @override
  String exportFailed(String error) {
    return 'エクスポートに失敗しました: $error';
  }

  @override
  String get sasAccreditation => 'SAS 認定';

  @override
  String get firmwareVersion => 'ファームウェアバージョン';

  @override
  String get beeSimFirmwareAction => 'BeeSIM ファームウェアを更新';

  @override
  String get beeSimFirmwareTitle => 'BeeSIM ファームウェアを更新';

  @override
  String get beeSimFirmwareWarning =>
      'BeeSIM のファームウェア更新が利用可能です。完了するまで、カードへの給電、Bluetooth の接続、アプリの起動状態を維持してください。更新を中断すると、カードが一時的に使用できなくなる場合があります。';

  @override
  String get beeSimFirmwareConfirm => 'ファームウェアを更新';

  @override
  String get platformSupport => 'プラットフォームの対応';

  @override
  String get rspVersion => 'RSP バージョン';

  @override
  String get bppVersion => 'BPP バージョン';

  @override
  String get gpVersion => 'グローバルプラットフォームのバージョン';

  @override
  String get certInfrastructure => '証明書のインフラストラクチャー';

  @override
  String get configuredAddresses => '設定済みのアドレス';

  @override
  String get defaultSmdpAddress => '既定の SM-DP+';

  @override
  String get rootDsAddress => 'ルート SM-DS';

  @override
  String get euiccSignCi => 'eUICC 署名 CI';

  @override
  String get euiccVerifyCi => 'eUICC 検証 CI';

  @override
  String get none => 'なし';

  @override
  String keysCount(int count) {
    return '$count 個のキー';
  }

  @override
  String get state => '状態';

  @override
  String get profileClass => 'クラス';

  @override
  String get aid => 'AID';

  @override
  String get euiccSpecifications => 'EUICC の仕様';

  @override
  String get sending => '送信中...';

  @override
  String get failedToSaveTags => 'タグの保存に失敗しました';

  @override
  String get note => '説明';

  @override
  String get notificationDetails => 'ダウンロードの詳細';

  @override
  String get unknown => '不明';

  @override
  String get status => '状態';

  @override
  String get sent => '送信';

  @override
  String get pending => '保留中';

  @override
  String get notifTypeInstall => 'インストール';

  @override
  String get notifTypeDelete => '削除';

  @override
  String get notifTypeEnable => '有効';

  @override
  String get notifTypeDisable => '無効';

  @override
  String get notifTypeRpmEnable => 'RPM を有効';

  @override
  String get notifTypeRpmDisable => 'RPM を無効';

  @override
  String get notifTypeRpmDelete => 'RPM を削除';

  @override
  String get notifTypeLoadRpm => 'RPM を読み込み';

  @override
  String confirmDeleteNotification(int seq) {
    return '「#$seq」の通知を削除してもよろしいですか？';
  }

  @override
  String get notificationRemoved => '通知を削除しました';

  @override
  String failedToRemove(String error) {
    return '削除に失敗しました: $error';
  }

  @override
  String get curlCopied => '抽出済みの cURL コマンドをクリップボードにコピーしました';

  @override
  String failedToGenerateCurl(String error) {
    return 'cURL の生成に失敗しました: $error';
  }

  @override
  String get noNotificationAddress => '通知のアドレスがありません';

  @override
  String get sendingNotification => '通知を送信中...';

  @override
  String get notifSentSuccessfully => '通知の送信に成功しました';

  @override
  String get failedToSendNotification => '通知の送信に失敗しました';

  @override
  String errorSendingNotification(String error) {
    return '通知の送信に失敗しました: $error';
  }

  @override
  String pendingCount(int count) {
    return '$count 個が保留中';
  }

  @override
  String get currentReader => '現在のリーダー';

  @override
  String get errorLoadingNotifications => '通知の読み込み中にエラーが発生しました';

  @override
  String get allCaughtUp => '項目は以上です';

  @override
  String get sequence => 'シーケンス';

  @override
  String get operation => '操作';

  @override
  String get profileNameLabel => 'プロファイル名';

  @override
  String get failedToSend => '送信に失敗しました';

  @override
  String get onCard => 'カード上';

  @override
  String get sendNotification => '通知を送信';

  @override
  String get deleteNotification => '通知を削除';

  @override
  String get noNotifications => '通知はありません';

  @override
  String get batchDownloadTitle => '一括ダウンロード';

  @override
  String get batchDownloadHint => '複数の LPA コードをここに貼り付け (1 行につき 1 個、最大 20 個)';

  @override
  String foundLpaCodes(int count) {
    return '$count 個の LPA コードが見つかりました';
  }

  @override
  String get startBatch => '開始';

  @override
  String get noLpaCodesFound => '有効な LPA コードが見つかりません';

  @override
  String get insufficientSpaceStoppingBatch => '空き容量が不足しています。一括ダウンロードを停止します。';

  @override
  String get exportCsv => 'CSV にエクスポート';

  @override
  String get exportedSuccessfully => 'エクスポートが成功しました';

  @override
  String get exportResults => 'エクスポートの結果';

  @override
  String get lpa => 'LPA';

  @override
  String get smdp => 'SM-DP+';

  @override
  String get confirmationCode => '確認コード';

  @override
  String get size => 'サイズ';

  @override
  String get message => 'メッセージ';

  @override
  String get remainingSpace => '残りの空き容量';

  @override
  String get stopBatch => '停止';

  @override
  String get stopping => '停止中...';

  @override
  String get remove => '削除';

  @override
  String get updateAvailable => '更新が利用可能です';

  @override
  String updateAvailableSubtitle(String appName, String version, String build) {
    return '$appName の新しいバージョン (v$version b$build) が利用可能です。今すぐ更新しますか？';
  }

  @override
  String get updateAction => '更新';

  @override
  String get later => '後で';

  @override
  String get changelog => '更新履歴';

  @override
  String get sortBy => '並べ替え';

  @override
  String get sortIccid => 'ICCID';

  @override
  String get sortCountry => '国';

  @override
  String get sortAscending => '昇順';

  @override
  String get sortDescending => '降順';

  @override
  String get searchProfiles => 'プロファイルを検索...';

  @override
  String get noProfilesMatch => '検索に一致するプロファイルはありません。';

  @override
  String get sortDefault => 'デフォルト';

  @override
  String get sortNickname => 'ニックネーム';

  @override
  String get showProfileSearch => 'プロファイルの検索を表示';

  @override
  String get showProfileSearchSubtitle => 'プロファイルリストに検索バーと並べ替えバーを表示します';

  @override
  String get noReaderFound => 'リーダーが見つかりません。eUICC アダプターを接続してください。';

  @override
  String get readyToInstallProfile => 'プロファイルをインストールする準備ができました。';

  @override
  String get downloadHere => 'ダウンロードはこちら';

  @override
  String get manage => '管理';

  @override
  String get buyCard => 'カード';

  @override
  String get buyData => 'データ';

  @override
  String get selectDevice => 'デバイスを選択';

  @override
  String get selectReaderTitle => 'カードを選択';

  @override
  String get authorizeSigning => '署名を承認';

  @override
  String get signingDescription => 'ウェブサイトが eUICC からのセキュアな署名を要求します。';

  @override
  String get smdpAddress => 'SM-DP+ アドレス';

  @override
  String get sign => '署名';

  @override
  String profilesInstalled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個のプロファイルがインストール済み',
      one: '1 個のプロファイルがインストール済み',
    );
    return '$_temp0';
  }

  @override
  String get estimatedDownloadSize => '予想のダウンロードサイズ';

  @override
  String get phoneFormatInternationalOnly => 'E.164 番号のみ';

  @override
  String get phoneFormatInternationalAndMobile => 'E.164 番号とモバイル';

  @override
  String get phoneFormatInternationalAndAll => 'E.164 番号と国際電話';

  @override
  String get phoneFormatOff => 'OFF';

  @override
  String get settings_item_unit_b => 'バイト';

  @override
  String get settings_item_unit_kb => 'KB (1,000 バイト)';

  @override
  String get settings_item_unit_kib => 'KiB (1,024 バイト)';

  @override
  String get settings_item_unit_adaptive_si => 'バイト / KB に適応';

  @override
  String get settings_item_unit_adaptive_bi => 'B / KiB に適応';

  @override
  String get insufficientStorageWarning => '空き容量が不足しているため、インストールに失敗する可能性があります。';

  @override
  String get estimateProfileSize => 'プロファイルサイズの推定';

  @override
  String get estimateProfileSizeSubtitle => 'ダウンロード前にプロファイルのメタデータサイズを推定します';

  @override
  String get customize => 'カスタマイズ';

  @override
  String get customizeDescription => 'ライター用の新しい 6 文字の 16 進数名とパスワードを指定してください。';

  @override
  String get customizeSuccess => 'ライターをカスタマイズしました。デバイスをペアリングし直してください。';

  @override
  String customizeFailed(String error) {
    return 'ライターのカスタマイズに失敗しました: $error';
  }

  @override
  String get defaultPasswordWillChangeTitle => '既定のパスワードが変更されます';

  @override
  String defaultPasswordWillChangeMessage(String password) {
    return 'このデバイスは既定のパスワードで接続されています。名前を変更すると、パスワードは $password に設定されます。再接続する前にこのパスワードを保存してください。';
  }

  @override
  String get savedBleDevices => '以前に接続した BLE デバイス';

  @override
  String get savedBleDevicesSubtitle => 'この端末に保存されているデバイス名とパスワードを表示します';

  @override
  String get savedBleDevicesDescription =>
      '各項目はローカルに保存された NBLESim のパスワードです。既定のパスワードも保存されます。';

  @override
  String get noSavedBleDevices => '以前に接続した BLE デバイスはありません。';

  @override
  String get deviceName => 'デバイス名';

  @override
  String get success => '成功しました';

  @override
  String get devicePasswordHint => '6 文字の 16 進数またはパスワードの文字列';

  @override
  String get sixHexChars => '6 桁の 16 進数';

  @override
  String get database => 'データベース';

  @override
  String exportSuccess(String path) {
    return 'データベースを「$path」にエクスポートしました';
  }

  @override
  String get importDatabase => 'データベースをインポート';

  @override
  String get importDatabaseSubtitle => '別のデータベースファイルから行を統合します';

  @override
  String get importDatabaseDialogTitle => 'データベースファイルを選択してインポートします';

  @override
  String get importDatabaseTitle => 'データベースをインポート';

  @override
  String get importDatabaseContent =>
      '選択したデータベースの行が、現在のデータベースに統合されます。同じキーを持つ既存の行は上書きされます。続行しますか？';

  @override
  String get import => 'インポート';

  @override
  String get importSuccess => 'データベースをインポートしました';

  @override
  String importFailed(String error) {
    return 'データベースのインポートに失敗しました: $error';
  }

  @override
  String get resetDatabase => 'データベースをリセット';

  @override
  String get resetDatabaseSubtitle => 'アプリのデータをすべて消去してリセットします';

  @override
  String get resetDatabaseTitle => 'アプリのデータベースをリセット';

  @override
  String get resetDatabaseContent =>
      'ローカルに保存されているすべてのデータ、設定、ログを完全に削除とアプリを終了します。続行しますか？';

  @override
  String get deleteDatabase => 'データベースを削除';

  @override
  String resetFailed(String error) {
    return 'データベースのリセットに失敗しました: $error';
  }

  @override
  String get deviceImei => 'デバイスの IMEI (TAC)';

  @override
  String get deviceImeiSubtitle => 'プロファイルのダウンロードに使用されます';

  @override
  String get editDeviceImei => 'デバイスの IMEI を編集';

  @override
  String get editDeviceImeiInfo =>
      '16 桁 (8 バイト) を入力してください。標準の IMEI は 35 から始まります。';

  @override
  String get imeiDigits => 'IMEI (数字)';

  @override
  String get importAction => 'インポート';

  @override
  String get transferTitle => 'eSIM を転送';

  @override
  String get transferAction => 'このデバイスに転送';

  @override
  String get transferCheckingEligibility => '資格を確認中…';

  @override
  String get transferReadingSource => 'ソース SIM を読み込み中…';

  @override
  String get transferContactingCarrier => 'キャリアにコンタクト中…';

  @override
  String get transferIneligibleReader =>
      'このプロファイルはリーダーで転送できません。送信元の SIM の認証情報 (EAP-AKA) にアクセスできません。';

  @override
  String get transferNoEntitlement =>
      'このプロファイルのキャリア転送設定が見つかりませんでした。エンタイトルメントサーバーを手動で入力してください。';

  @override
  String transferSourceCarrier(String carrier) {
    return 'ソースキャリア: $carrier';
  }

  @override
  String get transferConfirmTitle => 'このサブスクリプションを転送しますか？';

  @override
  String get transferConfirmBody =>
      'キャリアはサブスクリプションをこの eUICC に再発行します。転送時の一環として元のプロファイルが削除される場合があります。';

  @override
  String get transferStart => '転送を開始';

  @override
  String get transferDownloadingProfile => '転送したプロファイルをダウンロード中…';

  @override
  String get transferDeleteSourceTitle => 'ソースプロファイルを削除';

  @override
  String transferDeleteSourceBody(String iccid) {
    return 'キャリアはプロファイルの有効化前に $iccid のソースプロファイルを削除することを要求しています。今すぐ削除しますか？';
  }

  @override
  String get transferDeleteSourceConfirm => '削除と続行';

  @override
  String get transferUserInputSubmit => '送信';

  @override
  String get transferAccept => '許可';

  @override
  String get transferReject => '拒否';

  @override
  String get transferPendingActivation =>
      '現在、キャリアがこのサブスクリプションの有効化処理を行っています。まもなく完了するため、この画面を閉じて後ほどご確認ください。';

  @override
  String get transferDismissed => 'キャリアが転送を拒否しました。';

  @override
  String get transferDelayedDownload =>
      'キャリアからプロファイルがまもなく配信されます。プロファイルをインストール後にインストール済みの ICCID を入力して完了です。';

  @override
  String get transferInstalledIccid => 'インストール済みの ICCID';

  @override
  String get transferSuccess => '転送が完了しました';

  @override
  String transferFailed(String error) {
    return '転送に失敗しました: $error';
  }

  @override
  String get transferManualServerTitle => 'エンタイトルメントサーバー (高度)';

  @override
  String get transferManualServerHint => 'https://entitlement.example.com';

  @override
  String get transferEnablingSource => 'ソースプロファイルを準備中…';

  @override
  String get transferClose => '閉じる';

  @override
  String get transferContinue => '続行';

  @override
  String get transferSmdsDiscovering => 'SM-DS 経由でプロファイルを検出中…';

  @override
  String get transferSmdsNoProfiles => 'SM-DS による検出では、保留中のプロファイルは見つかりませんでした。';

  @override
  String get transferSelectProfile => 'ダウンロードするプロファイルを選択';

  @override
  String get discoverProfiles => 'プロファイルを探す (SM-DS)';

  @override
  String get discoveringProfiles => 'プロファイルを検出中…';

  @override
  String get discoveryNoProfiles => 'SM-DS による検出では、保留中のプロファイルは見つかりませんでした。';

  @override
  String get transferSmdsServerTitle => 'SM-DS サーバー';

  @override
  String transferProfileOnServer(String eventId, String address) {
    return '$eventId - $address';
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
}
