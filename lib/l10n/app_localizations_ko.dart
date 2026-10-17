// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get settingsTitle => '설정';

  @override
  String get displaySettings => 'Display Settings';

  @override
  String get appearance => '외관';

  @override
  String get appearanceSubtitle =>
      'Customize theme, layout, and display preferences';

  @override
  String get darkMode => '다크 모드';

  @override
  String get themeStyle => 'Theme Style';

  @override
  String get themeStyleSubtitle => 'Choose between Custom and MD3 style';

  @override
  String get customDesign => 'Nekoko Style';

  @override
  String get stockMD3 => 'Stock MD3';

  @override
  String get waterfallLayout => 'Waterfall Layout';

  @override
  String get waterfallLayoutSubtitle =>
      'Use Masonry style layout on wide screens';

  @override
  String get system => '시스템';

  @override
  String get light => '라이트';

  @override
  String get dark => '다크';

  @override
  String get language => '언어';

  @override
  String get systemLanguage => '시스템 언어';

  @override
  String get general => '일반';

  @override
  String get ui => 'UI';

  @override
  String get autoLoadProfiles => '프로파일 자동 로드';

  @override
  String get autoLoadProfilesSubtitle => '리더 선택 시 프로파일을 불러옵니다';

  @override
  String get loadProfileIcons => '프로파일 아이콘 로드';

  @override
  String get loadProfileIconsSubtitle => 'eUICC에서 아이콘을 가져옵니다 (느림)';

  @override
  String get useNekokoIcons => '통신사 아이콘 사용';

  @override
  String get useNekokoIconsSubtitle => 'operator-icons에서 통신사 아이콘을 가져옵니다';

  @override
  String get forceDeviceDropdown => '기기 드롭다운 강제 사용';

  @override
  String get forceDeviceDropdownSubtitle => '기기 선택 시 항상 드롭다운을 사용합니다';

  @override
  String get sizeDisplayUnit => '크기 표시 단위';

  @override
  String get sizeDisplayUnitSubtitle => '크기 표시에 사용할 단위 형식을 지정합니다';

  @override
  String get phoneFormat => '전화번호 형식';

  @override
  String get phoneFormatSubtitle => '전화번호 표시 형식을 지정합니다';

  @override
  String get notifications => '알림';

  @override
  String get notificationSettings => '알림 설정';

  @override
  String get notificationSettingsSubtitle => '자동 처리 및 삭제를 설정합니다';

  @override
  String get notificationHistory => '알림 내역';

  @override
  String get notificationHistorySubtitle => '전송된 알림 검색, 관리 및 재전송';

  @override
  String get tagsAndReminders => '태그 및 리마인더';

  @override
  String get tagManager => '태그 관리';

  @override
  String get tagManagerSubtitle => '프로파일 태그 생성 또는 편집';

  @override
  String get tagReminders => '태그 리마인더';

  @override
  String get tagRemindersSubtitle => '날짜 태그를 기반으로 알림 예약';

  @override
  String get manageTagsAndReminders => '태그 및 리마인더 관리';

  @override
  String get manageTagsAndRemindersSubtitle => '태그 구성, 테스트 알림 및 권한 확인';

  @override
  String get viewScheduledReminders => '예약된 리마인더 보기';

  @override
  String get viewScheduledRemindersSubtitle => '태그 기반 리마인더 관리';

  @override
  String get connectivity => '연결';

  @override
  String get remoteReaders => '원격 리더';

  @override
  String get remoteReadersSubtitle => 'RemoCard 컴패니언 앱 구성';

  @override
  String get enableBle => '블루투스 커넥터';

  @override
  String get enableBleSubtitle => '블루투스 리더 스캔 및 연결 활성화';

  @override
  String get enableCcid => 'USB CCID 커넥터';

  @override
  String get enableCcidSubtitle => 'USB 스마트 카드 리더 활성화 (CCID)';

  @override
  String get enableOmapi => '안드로이드 OMAPI 커넥터';

  @override
  String get enableOmapiSubtitle =>
      'OMAPI 기반 eUICC 관리를 위한 Open Mobile API 기능 활성화';

  @override
  String get enableTmapi => '안드로이드 Telephony 커넥터';

  @override
  String get enableTmapiSubtitle =>
      'Telephony 기반 eUICC 관리를 위한 Open Mobile API 기능 활성화';

  @override
  String get readerTypes => '리더 유형';

  @override
  String get readerTypesSubtitle => '활성화된 리더 유형 관리 (CCID, Bluetooth, 원격 등)';

  @override
  String get enabledReaderTypes => '활성화된 리더 유형';

  @override
  String get enabledReaderTypesSubtitle => '앱에서 사용 가능한 리더 유형 제어';

  @override
  String get remoteReaderSettings => '원격 리더 설정';

  @override
  String get remoteReaderSettingsSubtitle => '원격 리더 서버 및 연결 구성';

  @override
  String get ccidReaderTitle => 'CCID (USB/PC/SC)';

  @override
  String get ccidReaderSubtitle => 'USB 스마트 카드 리더 및 PC/SC 장치';

  @override
  String get bluetoothReaderTitle => 'Bluetooth';

  @override
  String get bluetoothReaderSubtitle => 'Bluetooth LE 스마트 카드 리더 및 라이터';

  @override
  String get remoteReadersTitle => '원격 리더';

  @override
  String get remoteReadersConnectorSubtitle => '네트워크 연결 원격 스마트 카드 리더';

  @override
  String get omapiReaderTitle => 'OMAPI';

  @override
  String get omapiReaderSubtitle => 'Open Mobile API를 통한 내장 SIM 카드 슬롯';

  @override
  String get tmapiReaderTitle => 'Telephony API';

  @override
  String get tmapiReaderSubtitle => 'Telephony API를 통한 내장 eSIM';

  @override
  String get remoteServerConfiguration => '원격 서버 구성';

  @override
  String get remoteServerConfigurationSubtitle => '원격 리더 서버 및 연결 설정 관리';

  @override
  String get enableBrowser => '브라우저 활성화';

  @override
  String get enableBrowserSubtitle => '스토어, 구매 또는 도움말과 같은 추가 브라우저 탭 표시';

  @override
  String get transport => '전송';

  @override
  String get disableRefreshFlags => '새로고침 플래그 비활성화';

  @override
  String get disableRefreshFlagsSubtitle => '외부 리더에는 적용되지 않습니다';

  @override
  String get apduMaxSegmentSize => 'APDU 최대 세그먼트 크기';

  @override
  String get apduMaxSegmentSizeSubtitle => 'APDU 청크당 최대 크기 설정';

  @override
  String get ensureSingleChannel => '단일 채널 보장';

  @override
  String get ensureSingleChannelSubtitle => '새 논리 채널을 열기 전에 다른 논리 채널을 닫습니다';

  @override
  String get analytics => '분석 및 클라우드 서비스';

  @override
  String get nekokoCloud => 'Nekoko Cloud';

  @override
  String get nekokoCloudSubtitle => '설치 데이터를 분석하여 예측 정확도 향상';

  @override
  String get developer => '개발자';

  @override
  String get developerMode => '개발자 모드';

  @override
  String get developerModeSubtitle => '고급 디버깅 기능 활성화';

  @override
  String get exportDatabase => '데이터베이스 내보내기';

  @override
  String get exportDatabaseSubtitle => '로컬 데이터베이스 사본 저장';

  @override
  String get openDatabaseFolder => '데이터베이스 폴더 열기';

  @override
  String get openDatabaseFolderSubtitle => '데이터베이스 파일이 포함된 폴더 열기';

  @override
  String get decodeAsn1 => 'ASN.1 로그 디코드 (느림)';

  @override
  String get decodeAsn1Subtitle => '성능에 큰 영향을 미칩니다';

  @override
  String get viewAppLogs => '앱 로그 보기';

  @override
  String get viewAppLogsSubtitle => '수집된 앱 로그를 표시합니다';

  @override
  String get about => '정보';

  @override
  String get version => '버전';

  @override
  String get build => '빌드';

  @override
  String get checkUpdates => '업데이트 확인';

  @override
  String get checkUpdatesSubtitle => '시작 시 최신 버전 확인';

  @override
  String get licenses => '오픈소스 라이선스';

  @override
  String get licensesSubtitle => '사용된 오픈소스 라이브러리의 라이선스 정보';

  @override
  String get noUpdatesFound => '업데이트가 없습니다';

  @override
  String get profilesTitle => '프로파일';

  @override
  String get switchEstkSlot => 'eSTK 슬롯 전환';

  @override
  String get notificationsButton => '알림';

  @override
  String get downloadProfile => '프로파일 다운로드';

  @override
  String get reconnect => '재연결';

  @override
  String get bluetoothNotConnected => '블루투스가 연결되지 않았습니다';

  @override
  String get bluetoothNotConnectedSubtitle =>
      '블루투스가 활성화되어 있고 기기가 근처에 있는지 확인하세요. \'연결\'을 탭하여 기기 사용을 시작하세요.';

  @override
  String get bluetoothConnectionFailed => '블루투스 연결에 실패했습니다';

  @override
  String bluetoothConnectionFailedSubtitle(Object error) {
    return '블루투스 기기 연결에 실패했습니다.\n\n$error';
  }

  @override
  String get removeDevice => '원격 기기';

  @override
  String get retryConnection => '연결';

  @override
  String get remoteConnectionFailed => '원격 리더 연결에 실패했습니다';

  @override
  String remoteConnectionFailedMessage(Object error) {
    return '원격 서버가 실행 중이며 액세스 가능한지 확인하세요.\n\n$error';
  }

  @override
  String get errorBluetoothTimeout => '블루투스 작업 시간이 초과되었습니다. 다시 시도해 주세요.';

  @override
  String get errorOmapiSecurity => '보안 오류: OS 또는 ARA-M 규칙에 의해 카드 액세스가 거부되었습니다.';

  @override
  String get errorApplicationNotFound =>
      'eUICC 관리 애플리케이션(ISD-R)을 찾을 수 없습니다. 이 카드는 유효한 eUICC가 아닐 수 있습니다.';

  @override
  String get changeSettings => '설정 변경';

  @override
  String get connectCompatibleReader => '시작하려면 호환되는 리더를 연결하세요.';

  @override
  String get connectReaderMessageBle =>
      '블루투스 지원 eUICC가 있는 경우 호환되는 블루투스 기기를 스캔할 수도 있습니다.';

  @override
  String get connectReaderMessageNoBle => 'CCID 리더가 컴퓨터에 연결되어 있는지 확인하세요.';

  @override
  String get downloadSmartCardExtension => '스마트 카드 확장 프로그램 다운로드';

  @override
  String get smartCardExtensionMessage =>
      '이 브라우저에서 USB CCID 리더에 액세스하려면 확장 프로그램이 필요합니다.';

  @override
  String get scanForBluetooth => '블루투스 스캔';

  @override
  String get connectRemote => '원격 연결';

  @override
  String get noCardDetected => '카드가 감지되지 않았습니다';

  @override
  String get noCardDetectedMessage => '이 슬롯은 지원되지 않거나 유효한 eUICC를 찾을 수 없습니다.';

  @override
  String get noDataLoaded => '연결되지 않음';

  @override
  String get loadProfiles => '연결';

  @override
  String get disconnect => '연결 해제';

  @override
  String get disconnecting => '연결 해제 중...';

  @override
  String get profilesEmpty => '카드에 프로파일이 없습니다';

  @override
  String get profilesEmptyMessage => '이 eUICC 카드는 비어 있습니다.';

  @override
  String get renameProfile => '프로파일 이름 변경';

  @override
  String get nickname => '닉네임';

  @override
  String get enterProfileNickname => '프로파일 닉네임 입력';

  @override
  String get profileNicknameNote => '참고: 태그는 \'태그 관리\' 메뉴에서 개별적으로 관리됩니다.';

  @override
  String get useProfileIcon => '프로파일 아이콘 사용';

  @override
  String get useProfileIconSubtitle => 'eSIM 카드 아이콘을 사용합니다';

  @override
  String get removeCustomIcon => '사용자 지정 아이콘 제거';

  @override
  String get noRemoteIcon => '이 통신사에는 원격 아이콘이 없습니다';

  @override
  String get cancel => '취소';

  @override
  String get ok => '확인';

  @override
  String get save => '저장';

  @override
  String get delete => '삭제';

  @override
  String get refresh => '새로고침';

  @override
  String get initializing => '초기화 중...';

  @override
  String get refreshingProfiles => '프로파일 새로고침 중...';

  @override
  String get retrievingEid => 'EID 및 정보 검색 중...';

  @override
  String get updatingProfile => '프로파일 업데이트 중...';

  @override
  String get manageIsdR => 'ISD-R AID 관리';

  @override
  String get manageIsdRSubtitle => 'eUICC 기본 앱 ID 구성';

  @override
  String get transportFailed => '전송 실패';

  @override
  String get remoteTransportFailedMessage =>
      '원격 서버에 연결되었지만 명령이 실패했습니다. 이는 일반적으로 원격 기기가 일시적으로 사용 중이거나 카드에서 연결이 끊어졌음을 의미합니다. 다시 시도하시겠습니까?';

  @override
  String get retry => '다시 시도';

  @override
  String get scanningForReaders => '리더 스캔 중...';

  @override
  String get switchedEstkSlot => 'eSTK 슬롯을 전환했습니다';

  @override
  String get scanningForUnresponsiveDevices => '응답 없는 기기 스캔 중...';

  @override
  String get resettingConnection => '연결 재설정 중...';

  @override
  String get connectingToReader => '리더에 연결 중...';

  @override
  String get moreOptions => '추가 옵션';

  @override
  String get retrievingProfiles => '프로파일 검색 중...';

  @override
  String get savingProfileMetadata => '프로파일 메타데이터 저장 중...';

  @override
  String get enablingProfile => '프로파일 활성화 중...';

  @override
  String get disablingProfile => '프로파일 비활성화 중...';

  @override
  String get deleteProfile => '프로파일 삭제';

  @override
  String deleteProfileConfirmation(Object profileName) {
    return '\'$profileName\' 프로파일을 삭제하시겠습니까?\n이 작업은 취소할 수 없습니다.';
  }

  @override
  String get deletingProfile => '프로파일 삭제 중...';

  @override
  String get deleting => 'Deleting...';

  @override
  String get dataUsage => '데이터 사용량';

  @override
  String get details => '세부 정보';

  @override
  String get rename => '이름 변경';

  @override
  String get changeIcon => '아이콘 변경';

  @override
  String get manageTags => '태그 관리';

  @override
  String get copyIccid => 'ICCID 복사';

  @override
  String get notificationProcessingError => '알림 처리 중에는 작업을 수행할 수 없습니다';

  @override
  String get operationInProgressError => 'Operation in progress, please wait';

  @override
  String iccidCopied(Object iccid) {
    return 'ICCID 복사됨: $iccid';
  }

  @override
  String get operationRestricted => '작업 제한됨';

  @override
  String get notificationProcessingDownloadError =>
      '알림 처리가 아직 진행 중입니다. 완료될 때까지 기다렸다가 새 프로파일을 다운로드하세요.';

  @override
  String get operational => '운영';

  @override
  String get test => '테스트';

  @override
  String get provisioning => '프로비저닝';

  @override
  String get profileDetails => '프로파일 세부 정보';

  @override
  String get profileDetailsSubtitle => '프로파일 슬롯의 eUICC 정보';

  @override
  String get enabled => '활성화됨';

  @override
  String get disabled => '비활성화됨';

  @override
  String get tagsManagedSeparately => '참고: 태그는 \'태그 관리\' 메뉴에서 개별적으로 관리됩니다.';

  @override
  String get changeProfileIcon => '프로파일 아이콘 변경';

  @override
  String get selectFromGallery => '갤러리에서 선택';

  @override
  String get nekokoOperatorIcon => '통신사 아이콘';

  @override
  String get iconFromEsim => 'eSIM 카드 아이콘';

  @override
  String updateIconFailed(Object error) {
    return '아이콘 업데이트 실패: $error';
  }

  @override
  String get failedToReadImage => '이미지 읽기 실패';

  @override
  String get failedToProcessImage => '이미지 처리 실패';

  @override
  String get customIconSet => '사용자 지정 아이콘이 설정되었습니다';

  @override
  String get noMccMnc => '이 프로파일은 MCC/MNC를 사용할 수 없습니다';

  @override
  String get fetchingRemoteIcon => '원격 아이콘 가져오는 중...';

  @override
  String get remoteIconSaved => '원격 아이콘을 사용자 지정 아이콘으로 저장했습니다';

  @override
  String fetchRemoteIconFailed(Object error) {
    return '원격 아이콘 가져오기 실패: $error';
  }

  @override
  String get noProfileIcon => '유효한 프로파일 아이콘을 찾을 수 없습니다';

  @override
  String get profileIconSaved => '프로파일 아이콘을 사용자 지정 아이콘으로 저장했습니다';

  @override
  String get customIconRemoved => '사용자 지정 아이콘이 제거되었습니다';

  @override
  String get failed => '실패';

  @override
  String euiccError(Object action) {
    return '프로파일을 $action하려고 할 때 eUICC에서 오류를 반환했습니다.';
  }

  @override
  String get dismiss => '닫기';

  @override
  String get dataPlan => '데이터 요금제';

  @override
  String get used => '사용됨';

  @override
  String get total => '총';

  @override
  String expires(Object date) {
    return '만료일: $date';
  }

  @override
  String get close => '닫기';

  @override
  String get server => '서버';

  @override
  String get switchFailed => '전환 실패';

  @override
  String get deviceRefreshFailed => '기기 새로고침 실패';

  @override
  String get euiccOptions => 'eUICC 옵션';

  @override
  String get euiccInfo => 'eUICC 정보';

  @override
  String get hideEid => 'EID 숨기기';

  @override
  String get showEid => 'EID 표시';

  @override
  String get copyEid => 'EID 복사';

  @override
  String get eidCopied => 'EID가 클립보드에 복사되었습니다';

  @override
  String get connectRemotes => '원격 연결';

  @override
  String get configureRemotes => '원격 구성';

  @override
  String get connectingToRemoteReaders => '백그라운드에서 원격 리더에 연결 중...';

  @override
  String get noRemoteReadersFound => '원격 리더를 찾을 수 없습니다';

  @override
  String connectedRemoteReaders(Object count) {
    return '$count개의 원격 리더에 연결되었습니다';
  }

  @override
  String failedToConnectRemoteReaders(Object error) {
    return '원격 리더 연결 실패: $error';
  }

  @override
  String get remoteReaderPassword => '원격 리더 비밀번호';

  @override
  String get remoteReaderPasswordSubtitle => '이 원격 리더에는 비밀번호가 필요합니다.';

  @override
  String get password => '비밀번호';

  @override
  String get deleteConnection => '연결 삭제';

  @override
  String get connect => '연결';

  @override
  String get remoteReaderConnectionFailed => '원격 리더 연결 실패';

  @override
  String remoteReaderConnectionFailedSubtitle(Object error) {
    return '원격 서버가 실행 중이며 액세스 가능한지 확인하세요.\n\n$error';
  }

  @override
  String get connectReader => '시작하려면 호환되는 리더를 연결하세요.';

  @override
  String get connectReaderSubtitleBle =>
      '블루투스 지원 eUICC가 있는 경우 호환되는 블루투스 기기를 스캔할 수도 있습니다.';

  @override
  String get connectReaderSubtitleCcid => 'CCID 리더가 컴퓨터에 연결되어 있는지 확인하세요.';

  @override
  String get downloadExtension => '스마트 카드 확장 프로그램 다운로드';

  @override
  String get downloadExtensionSubtitle =>
      '이 브라우저에서 USB CCID 리더에 액세스하려면 확장 프로그램이 필요합니다.';

  @override
  String get cardUnsupported => '지원되지 않는 카드';

  @override
  String get cardUnsupportedSubtitle =>
      '이 카드는 eUICC가 아니거나, 리더에서 지원하지 않거나, 다른 리더에서 사용 중일 수 있습니다.';

  @override
  String get omapiWelcome =>
      '좋은 소식은 사용 중인 기기에서 OMAPI를 지원하며, 이동식 카드와 호환될 가능성이 높다는 것입니다.';

  @override
  String get supportedDevices => '지원되는 기기';

  @override
  String get aboutAram => 'ARA-M 정보';

  @override
  String get accessDenied => '액세스 거부됨';

  @override
  String get accessDeniedSubtitle =>
      '이 eUICC에 액세스하려면 통신사 권한이 필요합니다. 카드의 ARA-M 허용 목록이 앱 서명과 일치하지 않습니다.';

  @override
  String get noCardDetectedSubtitle => '이 슬롯은 지원되지 않거나 유효한 eUICC를 찾을 수 없습니다.';

  @override
  String get noProfilesInstalled => '설치된 프로파일 없음';

  @override
  String get noProfilesInstalledSubtitle => '이 eUICC 카드는 비어 있습니다.';

  @override
  String get cardRefreshingTitle => 'Card is Refreshing';

  @override
  String get cardRefreshingMessage =>
      'The card is currently updating its state. Profile list cannot be retrieved at this moment. Please wait a few seconds and then try again.';

  @override
  String get useRemoteIcon => '원격 아이콘 사용';

  @override
  String get bleDisconnectedTitle => 'Bluetooth Connection Lost';

  @override
  String get bleDisconnectedMessage =>
      'The connection to the card reader was suddenly lost. Please ensure it is nearby and turned on.';

  @override
  String get cardStuckRefreshingMessage =>
      'Profile state change ongoing - try manually re-plug the SIM card if it stucks.';

  @override
  String get activationCodeTitle => '활성화 코드';

  @override
  String get activationCodeSubtitle =>
      'QR 코드를 스캔하거나 이미지를 불러오거나 LPA 문자열을 수동으로 입력하세요.';

  @override
  String get fullActivationCodeLabel => '전체 활성화 코드';

  @override
  String get fullActivationCodeHint => 'LPA:1\$smdp.io\$매칭_ID';

  @override
  String get pasteFromClipboardTooltip => '클립보드에서 붙여넣기';

  @override
  String get selectFromGalleryTooltip => '갤러리에서 선택';

  @override
  String get scanQrCodeTooltip => 'QR 코드 스캔';

  @override
  String get smdpAddressLabel => 'SM-DP+ 주소';

  @override
  String get smdpAddressHint => 'smdp.io';

  @override
  String get matchingIdLabel => '매칭 ID';

  @override
  String get matchingIdHint => 'ABC-123';

  @override
  String get smdpOidLabel => 'SM-DP+ OID';

  @override
  String get confirmationCodeLabel => '확인 코드';

  @override
  String get confirmationCodeHint => '확인 코드 입력';

  @override
  String get continueButton => '계속';

  @override
  String get invalidLpaClipboard => '클립보드에 유효한 LPA 문자열이 없습니다.';

  @override
  String get invalidFqdnFormat => '잘못된 FQDN 형식';

  @override
  String get invalidMatchingIdChars => '매칭 ID에 잘못된 문자가 포함되어 있습니다';

  @override
  String get invalidOidFormat => '잘못된 OID 형식 (예: 1.2.840...)';

  @override
  String get activationCodeRequired => '활성화 코드가 필요합니다';

  @override
  String get invalidLpaFormatGeneric => '잘못된 LPA 형식';

  @override
  String get smdpAddressRequired => 'SM-DP+ 주소가 필요합니다';

  @override
  String get loadingNotifications => '알림 로드 중...';

  @override
  String get processing => '처리 중...';

  @override
  String get analyzingImage => '이미지 분석 중...';

  @override
  String get noQrFoundInImage => '이미지에서 QR 코드를 찾을 수 없습니다';

  @override
  String get invalidAcInImage => '이미지에서 유효하지 않은 활성화 코드가 발견되었습니다';

  @override
  String get invalidAcFormatDetailed =>
      '활성화 코드 형식이 잘못되었습니다. LPA:1\$로 시작해야 합니다...';

  @override
  String get downloadProfileTitle => '프로파일 다운로드';

  @override
  String get connectingToEuicc => 'eUICC에 연결 중...';

  @override
  String get gettingChallenge => 'eUICC 챌린지 가져오는 중...';

  @override
  String get authenticatingWithSmdp => 'SM-DP+ 인증 중...';

  @override
  String get verifyingSignatures => 'SM-DP+ 서명 확인 중...';

  @override
  String get retrievingMetadata => '프로파일 메타데이터 검색 중...';

  @override
  String get preparingDownload => '다운로드 준비 중...';

  @override
  String get preparingEuicc => 'eUICC 준비 중...';

  @override
  String get fetchingProfilePackage => '프로파일 패키지 가져오는 중...';

  @override
  String installing(Object sent, Object total) {
    return '설치 중 ($sent / $total 바이트)...';
  }

  @override
  String get finalizing => '마무리 중 (저장소 정보 업데이트 중)...';

  @override
  String get profileInstalledSuccessfully => '프로파일이 성공적으로 설치되었습니다!';

  @override
  String get provider => '공급자';

  @override
  String get iccid => 'ICCID';

  @override
  String get plmn => 'PLMN';

  @override
  String get storage => '저장소';

  @override
  String get free => '여유 공간';

  @override
  String get nvram => 'NVRAM';

  @override
  String get exportCertificates => '인증서 내보내기';

  @override
  String get euiccCert => 'eUICC 인증서';

  @override
  String get eumCert => 'EUM 인증서';

  @override
  String get enterConfirmationCode => '통신사에서 요구하는 확인 코드를 입력하세요';

  @override
  String get confirmationCodeRequired => '확인 코드가 필요합니다';

  @override
  String get download => '다운로드';

  @override
  String get installationSuccessful => '설치 성공';

  @override
  String get installationSuccessMessage => '프로파일이 eUICC에 설치되었습니다.';

  @override
  String get consumed => '소비됨';

  @override
  String get enableProfileNow => '지금 프로파일 활성화';

  @override
  String get done => '완료';

  @override
  String get profileEnabledSuccessfully => '프로파일이 성공적으로 활성화되었습니다';

  @override
  String get enterNewProfileName => '쉽게 식별할 수 있도록 프로파일의 새 이름을 입력하세요.';

  @override
  String get profileName => '프로파일 이름';

  @override
  String get profileNameHint => '예: 출장';

  @override
  String get profileRenamedSuccessfully => '프로파일 이름이 성공적으로 변경되었습니다';

  @override
  String get downloadFailed => '다운로드 실패';

  @override
  String get tryAgain => '다시 시도';

  @override
  String get savedSuccessfully => '성공적으로 저장되었습니다';

  @override
  String get saveCertificate => '인증서 저장';

  @override
  String get searchingForReaders => '리더 검색 중...';

  @override
  String get initializationError => '초기화 오류';

  @override
  String get noReadersFound => '리더를 찾을 수 없습니다';

  @override
  String get noReadersFoundMessage =>
      '호환되는 리더를 연결하거나 BLE 기기를 스캔하여 eSIM 프로파일을 관리하세요.';

  @override
  String get scanBle => 'BLE 스캔';

  @override
  String get reminderDetails => '리마인더 세부 정보';

  @override
  String get profileNotFound => '프로파일을 찾을 수 없습니다';

  @override
  String get resending => '재전송 중...';

  @override
  String get noAddressInNotification => '알림 데이터에 주소가 없습니다';

  @override
  String get sentSuccessfully => '성공적으로 전송되었습니다';

  @override
  String get sendFailed => '전송 실패';

  @override
  String get copiedCurl => 'cURL 명령이 클립보드에 복사되었습니다';

  @override
  String get noAddressToExport => '내보낼 주소가 없습니다';

  @override
  String get noHistoryAvailable => '사용 가능한 내역이 없습니다';

  @override
  String get searchByIccid => 'ICCID로 검색...';

  @override
  String get resendNotification => '알림 재전송';

  @override
  String get exportAsCurl => 'cURL로 내보내기';

  @override
  String get viewDetails => '세부 정보 보기';

  @override
  String get deleteEntry => '항목 삭제';

  @override
  String activeReminders(int count) {
    return '$count개의 활성 리마인더가 있습니다';
  }

  @override
  String get noScheduledReminders => '예약된 리마인더 없음';

  @override
  String get remindersAppearWhen => '프로파일에 날짜 태그를 추가하면 여기에 리마인더가 표시됩니다.';

  @override
  String activeTagsCount(int count) {
    return '모든 프로파일에 걸쳐 $count개의 활성 태그가 있습니다';
  }

  @override
  String get searchTagsOrProfiles => '태그 또는 프로파일 검색...';

  @override
  String get noTagsFound => '태그를 찾을 수 없습니다';

  @override
  String get addTagsFromProfileMenu => '프로파일 편집 메뉴에서 태그를 추가하면 여기에 표시됩니다.';

  @override
  String get expired => '만료됨';

  @override
  String daysLeft(int count) {
    return '$count일 남음';
  }

  @override
  String hoursLeft(int count) {
    return '$count시간 남음';
  }

  @override
  String get expiresSoon => '곧 만료됨';

  @override
  String get soon => '곧';

  @override
  String get activeTags => '활성 태그';

  @override
  String get addNewTag => '새 태그 추가';

  @override
  String get noTagsAssigned => '이 프로파일에 할당된 태그가 없습니다.';

  @override
  String get textTagHint => '텍스트 태그 (예: 업무, 여행)';

  @override
  String get addDateExpiryTag => '날짜/만료 태그 추가';

  @override
  String get addNoteOptional => '메모 추가 (선택 사항)';

  @override
  String get add => '추가';

  @override
  String get noteHint => '예: 만료일, 10GB 등';

  @override
  String get invalidHexString => '잘못된 Hex 문자열';

  @override
  String get resetToDefaults => '기본값으로 재설정';

  @override
  String get resetToDefaultsSuccess => '기본값으로 재설정됨';

  @override
  String get addAidHex => 'AID 추가 (Hex)';

  @override
  String get manageAutoNotif => '자동 알림 처리 관리';

  @override
  String get automaticProcessing => '자동 처리';

  @override
  String get notifProcessingInfo =>
      '알림을 처리하면 eUICC와 SM-DP+ 서버(통신사) 간의 동기화가 용이해집니다. 전송된 알림을 삭제하면 카드의 저장 공간을 깔끔하게 유지할 수 있습니다.';

  @override
  String get enabling => '활성화';

  @override
  String get afterEnabling => '프로파일 활성화 후';

  @override
  String get disabling => '비활성화';

  @override
  String get afterDisabling => '프로파일 비활성화 후';

  @override
  String get installation => '설치';

  @override
  String get afterDownload => '프로파일 다운로드 후';

  @override
  String get deletion => '삭제';

  @override
  String get afterDeletion => '프로파일 삭제 후';

  @override
  String get autoSend => '자동 전송';

  @override
  String get autoSendSubtitle => '서버에 자동으로 전송합니다';

  @override
  String get autoRemove => '자동 삭제';

  @override
  String get autoRemoveSubtitle => '전송 후 카드에서 삭제합니다';

  @override
  String get removeWithoutSending => '전송하지 않고 삭제';

  @override
  String get removeWithoutSendingSubtitle => '주의: 서버에 알리지 않습니다';

  @override
  String get permissionsActive => '권한 활성화됨';

  @override
  String get permissionsRequired => '권한 필요';

  @override
  String get appCanSendNotif => '앱에서 시스템 알림을 보낼 수 있습니다';

  @override
  String get requiredForReminders => '리마인더 알림에 필요합니다';

  @override
  String get unsupportedPlatformCheck =>
      '이 플랫폼은 권한 확인을 지원하지 않습니다. 수동으로 테스트하십시오.';

  @override
  String get couldNotVerifyStatus => '상태를 확인할 수 없습니다. 설정을 수동으로 확인하십시오.';

  @override
  String get testNotificationTitle => '테스트 알림';

  @override
  String get seconds => '초';

  @override
  String get startTest => '테스트 시작';

  @override
  String get sendingNotif => '보내는 중...';

  @override
  String get hostIpLabel => '호스트 이름 / IP';

  @override
  String get portLabel => '포트';

  @override
  String get passwordOptionalLabel => '비밀번호 (선택 사항)';

  @override
  String get configuredServers => '구성된 서버';

  @override
  String get secureHttps => '보안 (HTTPS)';

  @override
  String get insecureHttp => '비보안 (HTTP)';

  @override
  String get urlCopied => 'URL 복사됨';

  @override
  String get serverAddedSuccessfully => '서버가 성공적으로 추가되었습니다';

  @override
  String get authFailedCheckPassword => '인증 실패. 비밀번호를 확인하십시오.';

  @override
  String get addNewServer => '새 서버 추가';

  @override
  String get autoLoadRemotes => '원격 기기 자동 로드';

  @override
  String get autoLoadRemotesSubtitle => '앱 시작 시 구성된 서버에 자동 연결';

  @override
  String get getRemoCardGitHub => 'GitHub에서 RemoCard 받기';

  @override
  String get instructions => '설명:';

  @override
  String get instruction1 => '1. 안드로이드 기기에 RemoCard를 설치합니다.';

  @override
  String get instruction2 => '2. RemoCard 앱에서 서버를 시작합니다.';

  @override
  String get instruction3 => '3. 여기에 IP 주소를 입력합니다.';

  @override
  String get instruction4 => '4. 모든 원격 SIM 슬롯이 기기 목록에 표시됩니다.';

  @override
  String get appLogsCopied => '로그가 클립보드에 복사되었습니다';

  @override
  String get aramInfoTitle => 'ARA-M 정보';

  @override
  String get aramInfoSubtitle => '액세스 규칙 애플릿 세부 정보';

  @override
  String get whatIsAram => 'ARA-M이란 무엇입니까?';

  @override
  String get aramDescription =>
      '액세스 규칙 애플릿(ARA-M)은 eUICC(eSIM) 및 SIM 카드에 있는 메커니즘으로, 프로파일 관리 및 하위 수준 작업을 수행할 수 있는 앱을 정의합니다. 앱의 해시가 카드의 ARA-M 허용 목록에 없으면 안드로이드 시스템은 액세스를 차단하고 \'액세스 거부됨\' 오류를 반환합니다.';

  @override
  String get appCertHashes => '앱 인증서 해시';

  @override
  String get aramHashInstruction =>
      'Android 버전 간 호환성을 위해 아래의 모든 SHA-1 인증서 해시를 카드의 ARA-M 규칙에 추가하세요. 앱 서명 키를 업그레이드한 후에는 Android 버전에 따라 검증된 서명 기록의 서로 다른 인증서를 확인할 수 있습니다.';

  @override
  String get aramSigningHistoryInstruction =>
      'For compatibility across Android versions, add all SHA-1 certificate hashes below to your card\'s ARA-M rules. After an app signing key upgrade, different Android versions may check different certificates from the verified signing history.';

  @override
  String get certSha1Hash => '인증서 SHA-1 해시';

  @override
  String get unavailable => '사용할 수 없음';

  @override
  String get troubleshooting => '문제 해결';

  @override
  String get troubleStep1 => '올바른 카드 리더기를 사용하고 있는지 확인하십시오.';

  @override
  String get troubleStep2 =>
      '물리적 카드를 사용하는 경우 테스트 카드인지 상용 카드인지 확인하십시오(상용 카드는 종종 ARA-M이 잠겨 있습니다).';

  @override
  String get troubleStep3 =>
      '위의 해시는 앱의 디버그, 일반, 특권(Magisk) 버전 중 어떤 것을 사용하는지에 따라 다릅니다.';

  @override
  String get troubleStep4 =>
      '일부 안드로이드 API 제한을 우회할 수 있는 특권 버전(Magisk) 사용을 고려하십시오.';

  @override
  String get hashCopied => '해시가 클립보드에 복사되었습니다';

  @override
  String get aidCopied => 'AID가 클립보드에 복사되었습니다';

  @override
  String get lastSeen => '마지막 확인';

  @override
  String get unknownProvider => '알 수 없는 공급자';

  @override
  String get unknownProfile => '알 수 없는 프로파일';

  @override
  String get tags => '태그';

  @override
  String get noTags => '태그 없음';

  @override
  String records(int count) {
    return '$count개의 레코드가 있습니다';
  }

  @override
  String get bytes => '바이트';

  @override
  String get responseCode => '응답 코드';

  @override
  String get responseBody => '응답 본문';

  @override
  String get type => '유형';

  @override
  String profileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개의 프로파일',
      one: '1개의 프로파일',
    );
    return '$_temp0';
  }

  @override
  String get isdrAids => 'ISD-R AID';

  @override
  String get configureDefaultAids => '기본 앱 ID 구성';

  @override
  String get addAidHexHint => 'AID 추가 (Hex)';

  @override
  String get notificationProcessing => '알림 처리';

  @override
  String get manageAutoNotification => '자동 알림 처리를 관리합니다';

  @override
  String get notificationProcessingHelp =>
      '알림을 처리하면 eUICC와 SM-DP+ 서버(통신사) 간의 동기화가 용이해집니다. 전송된 알림을 삭제하면 카드의 저장 공간을 깔끔하게 유지할 수 있습니다.';

  @override
  String get notificationProcessingTimings => 'Processing timings';

  @override
  String get notificationProcessingTimingsHelp =>
      'Choose when automatic notification processing runs. Some safety-critical timings can only be disabled while Developer Mode is enabled.';

  @override
  String get afterEnablingProfile => '프로파일 활성화 후';

  @override
  String get afterDisablingProfile => '프로파일 비활성화 후';

  @override
  String get afterProfileDownload => '프로파일 다운로드 후';

  @override
  String get afterProfileDeletion => '프로파일 삭제 후';

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
  String get sendToServerAutomatically => '서버에 자동으로 전송';

  @override
  String get removeFromCardAfterSending => '전송 후 카드에서 삭제';

  @override
  String get removeWithoutSendingCaution => '주의: 서버에 알리지 않고 삭제';

  @override
  String get reminderSettings => '리마인더 설정';

  @override
  String get appCanSendNotifications => '앱에서 시스템 알림을 보낼 수 있습니다';

  @override
  String get requiredForReminderAlerts => '리마인더 알림에 필요합니다';

  @override
  String get enable => '활성화';

  @override
  String get permissionCheckNotSupported =>
      '이 플랫폼은 권한 확인을 지원하지 않습니다. 수동으로 테스트하십시오.';

  @override
  String get testNotification => '테스트 알림';

  @override
  String get notificationsDisabledMessage =>
      '알림이 비활성화되었습니다. 리마인더를 받으려면 시스템 설정에서 알림을 켜주세요.';

  @override
  String get openSettings => '설정 열기';

  @override
  String get applicationLogs => '앱 로그';

  @override
  String get refreshReload => '새로고침/다시 로드';

  @override
  String get toggleAutoScroll => '자동 스크롤 전환';

  @override
  String get refreshDevices => '기기 새로고침';

  @override
  String get scanBluetooth => '블루투스 스캔';

  @override
  String get lessThan1Kb => '< 1 KB';

  @override
  String get connectionFailed => '연결 실패';

  @override
  String get downloadRemoCard => 'RemoCard 다운로드';

  @override
  String get remoCardAndroidApp => '원격 제어용 안드로이드 앱';

  @override
  String get resentSuccessfully => '성공적으로 재전송되었습니다';

  @override
  String get resendFailed => '재전송 실패';

  @override
  String get eid => 'EID';

  @override
  String get seq => '순서';

  @override
  String get date => '날짜';

  @override
  String errorWithDetails(String error) {
    return '오류: $error';
  }

  @override
  String exportFailed(String error) {
    return '내보내기 실패: $error';
  }

  @override
  String get sasAccreditation => 'SAS 인증';

  @override
  String get firmwareVersion => '펌웨어 버전';

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
  String get platformSupport => '플랫폼 지원';

  @override
  String get rspVersion => 'RSP 버전';

  @override
  String get bppVersion => 'BPP 버전';

  @override
  String get gpVersion => '글로벌 플랫폼 버전';

  @override
  String get certInfrastructure => '인증서 인프라';

  @override
  String get euiccSignCi => 'eUICC 서명 CI';

  @override
  String get euiccVerifyCi => 'eUICC 검증 CI';

  @override
  String get none => '없음';

  @override
  String keysCount(int count) {
    return '$count개의 키';
  }

  @override
  String get state => '상태';

  @override
  String get profileClass => '클래스';

  @override
  String get aid => 'AID';

  @override
  String get euiccSpecifications => 'EUICC 사양';

  @override
  String get sending => '보내는 중...';

  @override
  String get failedToSaveTags => '태그 저장 실패';

  @override
  String get note => '메모';

  @override
  String get notificationDetails => '다운로드 세부 정보';

  @override
  String get unknown => '알 수 없음';

  @override
  String get status => '상태';

  @override
  String get sent => '전송됨';

  @override
  String get pending => '대기 중';

  @override
  String get notifTypeInstall => '설치';

  @override
  String get notifTypeDelete => '삭제';

  @override
  String get notifTypeEnable => '활성화';

  @override
  String get notifTypeDisable => '비활성화';

  @override
  String get notifTypeRpmEnable => 'RPM 활성화';

  @override
  String get notifTypeRpmDisable => 'RPM 비활성화';

  @override
  String get notifTypeRpmDelete => 'RPM 삭제';

  @override
  String get notifTypeLoadRpm => 'RPM 로드';

  @override
  String confirmDeleteNotification(int seq) {
    return '알림 \'#$seq\'을(를) 삭제하시겠습니까?';
  }

  @override
  String get notificationRemoved => '알림이 삭제되었습니다';

  @override
  String failedToRemove(String error) {
    return '삭제 실패: $error';
  }

  @override
  String get curlCopied => '추출된 cURL 명령이 클립보드에 복사되었습니다';

  @override
  String failedToGenerateCurl(String error) {
    return 'cURL 생성 실패: $error';
  }

  @override
  String get noNotificationAddress => '알림 주소가 없습니다';

  @override
  String get sendingNotification => '알림 전송 중...';

  @override
  String get notifSentSuccessfully => '알림이 성공적으로 전송되었습니다';

  @override
  String get failedToSendNotification => '알림 전송 실패';

  @override
  String errorSendingNotification(String error) {
    return '알림 전송 중 오류 발생: $error';
  }

  @override
  String pendingCount(int count) {
    return '$count개 대기 중';
  }

  @override
  String get currentReader => '현재 리더';

  @override
  String get errorLoadingNotifications => '알림을 로드하는 중 오류가 발생했습니다';

  @override
  String get allCaughtUp => '모든 항목을 확인했습니다';

  @override
  String get sequence => '순서';

  @override
  String get operation => '작업';

  @override
  String get profileNameLabel => '프로파일 이름';

  @override
  String get failedToSend => '전송 실패';

  @override
  String get onCard => '카드에 있음';

  @override
  String get sendNotification => '알림 전송';

  @override
  String get deleteNotification => '알림 삭제';

  @override
  String get noNotifications => '알림 없음';

  @override
  String get batchDownloadTitle => '일괄 다운로드';

  @override
  String get batchDownloadHint => '여러 LPA 코드를 여기에 붙여넣으세요 (한 줄에 1개씩, 최대 20개)';

  @override
  String foundLpaCodes(int count) {
    return '$count개의 LPA 코드를 찾았습니다';
  }

  @override
  String get startBatch => '시작';

  @override
  String get noLpaCodesFound => '유효한 LPA 코드를 찾을 수 없습니다';

  @override
  String get insufficientSpaceStoppingBatch => '공간이 부족합니다. 일괄 다운로드를 중지합니다.';

  @override
  String get exportCsv => 'CSV로 내보내기';

  @override
  String get exportedSuccessfully => '성공적으로 내보냈습니다';

  @override
  String get exportResults => '내보내기 결과';

  @override
  String get lpa => 'LPA';

  @override
  String get smdp => 'SM-DP+';

  @override
  String get confirmationCode => '확인 코드';

  @override
  String get size => '크기';

  @override
  String get message => '메시지';

  @override
  String get remainingSpace => '남은 공간';

  @override
  String get stopBatch => '중지';

  @override
  String get stopping => '중지 중...';

  @override
  String get remove => '제거';

  @override
  String get updateAvailable => '업데이트 가능';

  @override
  String updateAvailableSubtitle(String appName, String version, String build) {
    return '$appName의 새 버전(v$version b$build)을 사용할 수 있습니다. 지금 업데이트하시겠습니까?';
  }

  @override
  String get updateAction => '업데이트';

  @override
  String get later => '나중에';

  @override
  String get changelog => '변경 내역';

  @override
  String get sortBy => '정렬 기준';

  @override
  String get sortIccid => 'ICCID';

  @override
  String get sortCountry => '국가';

  @override
  String get sortAscending => '오름차순';

  @override
  String get sortDescending => '내림차순';

  @override
  String get searchProfiles => '프로파일 검색...';

  @override
  String get noProfilesMatch => '검색어와 일치하는 프로파일이 없습니다.';

  @override
  String get sortDefault => '기본값';

  @override
  String get sortNickname => '닉네임';

  @override
  String get showProfileSearch => '프로파일 검색 표시';

  @override
  String get showProfileSearchSubtitle => '프로파일 목록에 검색 및 정렬 표시줄을 표시합니다';

  @override
  String get noReaderFound => '리더를 찾을 수 없습니다. eUICC 어댑터를 연결하세요.';

  @override
  String get readyToInstallProfile => '프로파일을 설치할 준비가 되었습니다.';

  @override
  String get downloadHere => '여기에서 다운로드';

  @override
  String get manage => '관리';

  @override
  String get buyCard => '카드 구매';

  @override
  String get buyData => '데이터 구매';

  @override
  String get selectDevice => '기기 선택';

  @override
  String get selectReaderTitle => '카드 선택';

  @override
  String get authorizeSigning => '서명 승인';

  @override
  String get signingDescription => '웹사이트가 eUICC의 안전한 서명을 요구합니다.';

  @override
  String get smdpAddress => 'SM-DP+ 주소';

  @override
  String get sign => '서명';

  @override
  String profilesInstalled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개의 프로파일이 설치됨',
      one: '1개의 프로파일이 설치됨',
    );
    return '$_temp0';
  }

  @override
  String get estimatedDownloadSize => '예상 다운로드 크기';

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
  String get insufficientStorageWarning => '저장 공간이 부족하여 설치가 실패할 수 있습니다.';

  @override
  String get estimateProfileSize => '프로파일 크기 예측';

  @override
  String get estimateProfileSizeSubtitle => '다운로드 전 프로파일 메타데이터 크기 예측';

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
