// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get settingsTitle => '設定';

  @override
  String get displaySettings => '表示設定';

  @override
  String get appearance => '外観';

  @override
  String get appearanceSubtitle => 'テーマ、レイアウト、表示設定をカスタマイズ';

  @override
  String get darkMode => 'ダークモード';

  @override
  String get themeStyle => 'テーマスタイル';

  @override
  String get themeStyleSubtitle => 'カスタムまたは MD3 スタイルを選択';

  @override
  String get customDesign => 'Nekoko スタイル';

  @override
  String get stockMD3 => '標準 MD3';

  @override
  String get waterfallLayout => 'ウォーターフォールレイアウト';

  @override
  String get waterfallLayoutSubtitle => 'ワイドスクリーンでメイソンリースタイルのレイアウトを使用';

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
  String get useNekokoIcons => 'オペレーターアイコンを使用';

  @override
  String get useNekokoIconsSubtitle => 'operator-icons からキャリアアイコンを取得します';

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
  String get readerTypes => 'リーダータイプ';

  @override
  String get readerTypesSubtitle => '有効なリーダータイプを管理（CCID、Bluetooth、リモートなど）';

  @override
  String get enabledReaderTypes => '有効なリーダータイプ';

  @override
  String get enabledReaderTypesSubtitle => 'アプリで利用可能なリーダータイプを制御';

  @override
  String get remoteReaderSettings => 'リモートリーダー設定';

  @override
  String get remoteReaderSettingsSubtitle => 'リモートリーダーサーバーと接続を構成';

  @override
  String get ccidReaderTitle => 'CCID（USB/PC/SC）';

  @override
  String get ccidReaderSubtitle => 'USBスマートカードリーダーとPC/SCデバイス';

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
  String get omapiReaderSubtitle => 'Open Mobile API経由の内蔵SIMカードスロット';

  @override
  String get tmapiReaderTitle => 'Telephony API';

  @override
  String get tmapiReaderSubtitle => 'Telephony API経由の内蔵eSIM';

  @override
  String get remoteServerConfiguration => 'リモートサーバー構成';

  @override
  String get remoteServerConfigurationSubtitle => 'リモートリーダーサーバーと接続設定を管理';

  @override
  String get enableBrowser => 'ブラウザを有効にする';

  @override
  String get enableBrowserSubtitle => 'ストア、購入、ヘルプなどの追加のブラウザタブを表示する';

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
  String get decodeAsn1Subtitle => 'パフォーマンスに大きな影響を与えます';

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
  String get nekokoOperatorIcon => 'オペレーターアイコン';

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
      'Android バージョン間の互換性を確保するため、以下のすべての SHA-1 証明書ハッシュをカードの ARA-M ルールに追加してください。アプリ署名鍵のアップグレード後は、Android のバージョンによって検証済み署名履歴内の異なる証明書が確認される場合があります。';

  @override
  String get aramSigningHistoryInstruction =>
      'For compatibility across Android versions, add all SHA-1 certificate hashes below to your card\'s ARA-M rules. After an app signing key upgrade, different Android versions may check different certificates from the verified signing history.';

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
  String get notificationProcessingTimings => 'Processing timings';

  @override
  String get notificationProcessingTimingsHelp =>
      'Choose when automatic notification processing runs. Some safety-critical timings can only be disabled while Developer Mode is enabled.';

  @override
  String get afterEnablingProfile => 'プロファイルの有効化後';

  @override
  String get afterDisablingProfile => 'プロファイルの無効化後';

  @override
  String get afterProfileDownload => 'プロファイルのダウンロード後';

  @override
  String get afterProfileDeletion => 'プロファイルの削除後';

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
  String get beeSimFirmwareAction => 'Update BeeSIM firmware';

  @override
  String get beeSimFirmwareTitle => 'BeeSIM firmware update';

  @override
  String get beeSimFirmwareWarning =>
      'A BeeSIM firmware update is available. Keep the card powered, Bluetooth connected, and the app open until it finishes. Interrupting the update may leave the card temporarily unusable.';

  @override
  String get beeSimFirmwareConfirm => 'Update firmware';

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
  String get deviceImei => 'デバイス TAC';

  @override
  String get deviceImeiSubtitle => 'プロファイルのダウンロードに使用されます';

  @override
  String get editDeviceImei => 'デバイス TAC を編集';

  @override
  String get editDeviceImeiInfo =>
      '8 桁の TAC、または 15 桁の IMEI を入力してください。既定の TAC: 35383741。';

  @override
  String get imeiDigits => 'TAC または IMEI の数字';

  @override
  String get importAction => 'インポート';

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
