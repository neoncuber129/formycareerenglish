// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'FormyCareer';

  @override
  String get navDesktop => '데스크톱';

  @override
  String get navDashboard => '대시보드';

  @override
  String get navCapture => '수집';

  @override
  String get navReview => '복습';

  @override
  String get navVocabulary => '단어장';

  @override
  String get navGuides => '가이드';

  @override
  String get navSettings => '설정';

  @override
  String get navAbout => '정보';

  @override
  String get navWords => '단어';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsSubtitle => '언어 및 로컬 환경설정';

  @override
  String get uiLanguageSectionTitle => '인터페이스 언어';

  @override
  String get uiLanguageLabel => '앱 언어';

  @override
  String get uiLanguageDescription =>
      '메뉴와 설정 화면의 글자를 바꿉니다. 번역 설명은 아래 ‘모국어’ 설정을 따릅니다.';

  @override
  String get uiLocaleSystem => '시스템 따라가기';

  @override
  String get uiLocaleEnglish => 'English';

  @override
  String get uiLocaleVietnamese => 'Tiếng Việt';

  @override
  String get uiLocaleJapanese => '日本語';

  @override
  String get uiLocaleChinese => '中文（简体）';

  @override
  String get uiLocaleKorean => '한국어';

  @override
  String get settingsTextScaleSectionTitle => '글자 크기';

  @override
  String get settingsTextScaleLabel => '인터페이스 글자 크기';

  @override
  String get settingsTextScaleDescription =>
      '데스크톱 창과 수집 팝업 글자 크기입니다. Windows 디스플레이 배율과 함께 적용됩니다.';

  @override
  String settingsTextScalePercent(int percent) {
    return '$percent%';
  }

  @override
  String get backupSectionTitle => '로컬 백업 및 복원';

  @override
  String get backupSectionIntro => '데이터를 이 컴퓨터에서 백업하고 복원합니다.';

  @override
  String get defaultBackupFolderTitle => '기본 백업 폴더';

  @override
  String get defaultBackupFolderDescription =>
      '예약 자동 백업에 사용됩니다. 기본값은 문서 폴더 아래입니다. 아래 ‘지금 백업’에서는 다른 폴더를 선택할 수 있습니다.';

  @override
  String get resolvingPath => '경로 확인 중…';

  @override
  String currentPathPrefix(String path) {
    return '현재: $path';
  }

  @override
  String get confirmUseFolder => '이 폴더 사용';

  @override
  String get changeDefaultFolder => '기본 폴더 변경';

  @override
  String get useAppDefaultFolder => '앱 기본 폴더 사용';

  @override
  String couldNotUseFolder(String error) {
    return '이 폴더를 사용할 수 없습니다: $error';
  }

  @override
  String defaultBackupFolderSet(String path) {
    return '기본 백업 폴더: $path';
  }

  @override
  String get usingAppDefaultAgain => '앱 기본 폴더를 다시 사용합니다.';

  @override
  String get automaticBackupTitle => '자동 백업';

  @override
  String get automaticBackupDescription => '위의 기본 폴더에 일정에 따라 라이브러리 사본을 저장합니다.';

  @override
  String get repeatEveryLabel => '반복 주기';

  @override
  String get backupNow => '지금 백업';

  @override
  String get restoreFromFile => '파일에서 복원';

  @override
  String get saveBackupHere => '여기에 저장';

  @override
  String get restoreFromThisFile => '이 파일에서 복원';

  @override
  String get backupFilesFilter => '백업 파일';

  @override
  String backupCreated(String path) {
    return '백업 생성됨: $path';
  }

  @override
  String restoredFrom(String restored) {
    return '복원 출처: $restored';
  }

  @override
  String get backupFooterNote =>
      '‘지금 백업’에서는 원하는 폴더를 고를 수 있습니다. 자동 백업은 항상 위 기본 폴더를 사용합니다. 복원 시 .db 또는 .json 파일을 선택하세요.';

  @override
  String get backupIntervalHourly => '매시간';

  @override
  String get backupInterval6h => '6시간마다';

  @override
  String get backupInterval12h => '12시간마다';

  @override
  String get backupIntervalDaily => '매일';

  @override
  String get backupInterval2days => '이틀마다';

  @override
  String get backupIntervalWeekly => '매주';

  @override
  String backupIntervalEveryHours(int hours) {
    return '$hours시간마다';
  }

  @override
  String get translationSectionTitle => '번역';

  @override
  String get nativeLanguageLabel => '모국어';

  @override
  String get translationNativeHelp => '번역과 설명은 이 언어로 표시됩니다.';

  @override
  String get translationEngineHelp => '가장 빠른 응답을 위해 번역 엔진이 자동으로 선택됩니다.';

  @override
  String get backupErrNoBackupFile => '복원할 백업 파일이 없습니다.';

  @override
  String get backupErrSqliteMissing => 'SQLite 백업 파일을 찾을 수 없습니다.';

  @override
  String get backupErrFileMissing => '선택한 백업 파일을 찾을 수 없습니다.';

  @override
  String get backupErrUnsupportedFormat =>
      '지원하지 않는 형식입니다. .db 또는 .json 파일을 선택하세요.';

  @override
  String get backupErrInvalidCorrupt => '백업 파일이 잘못되었거나 손상되었습니다.';

  @override
  String backupErrGeneric(String error) {
    return '백업 또는 복원에 실패했습니다. 세부 정보: $error';
  }

  @override
  String get commonCancel => '취소';

  @override
  String get commonClose => '닫기';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonSave => '저장';

  @override
  String get commonBack => '뒤로';

  @override
  String get commonOk => '확인';

  @override
  String get commonRefresh => '새로 고침';

  @override
  String get commonTips => '팁';

  @override
  String get commonGranted => '허용됨';

  @override
  String get commonMissing => '없음';

  @override
  String get commonChecking => '확인 중…';

  @override
  String get commonLoading => '로드 중…';

  @override
  String get commonStudy => '학습';

  @override
  String get commonTag => '태그';

  @override
  String get commonArchive => '보관';

  @override
  String get commonResetSrs => 'SRS 초기화';

  @override
  String get commonActivate => '활성화';

  @override
  String get cmdCancelEsc => '취소 (Esc)';

  @override
  String get cmdOneItemSelected => '1개 선택됨';

  @override
  String cmdManyItemsSelected(int count) {
    return '$count개 선택됨';
  }

  @override
  String get dashSubtitle => '학습 요약 및 빠른 이동';

  @override
  String dashCouldNotLoadVocab(String error) {
    return '단어장을 불러올 수 없습니다: $error';
  }

  @override
  String get dashHeroTitle => '내 학습 허브';

  @override
  String dashHeroStatsLine(int dueNow, int active, int newCount) {
    return '지금 $dueNow개 · 활성 덱 $active장 · 새 카드 $newCount';
  }

  @override
  String get dashHeroShareCaption => '활성 덱 중 복습 비율';

  @override
  String dashHeroPercentDue(int percent) {
    return '활성 카드의 $percent% 만료';
  }

  @override
  String get dashStatDueNowTitle => '지금 만료';

  @override
  String get dashStatDueNowSubtitle => 'SRS 복습 가능';

  @override
  String get dashStatActiveTitle => '활성 덱';

  @override
  String get dashStatActiveSubtitle => '보관 안 함';

  @override
  String get dashStatNewTitle => '신규';

  @override
  String get dashStatNewSubtitle => '복습 안 함';

  @override
  String get dashStatArchivedTitle => '보관됨';

  @override
  String get dashStatArchivedSubtitle => '대기열 제외';

  @override
  String get dashInsightUpcoming => '예정 복습';

  @override
  String get dashInsightDeckComposition => '덱 구성';

  @override
  String get dashInsightByLanguage => '언어별';

  @override
  String get dashInsightPopularTags => '인기 태그';

  @override
  String get dashEmptyLangPairs => '언어 쌍이 없습니다.';

  @override
  String get dashEmptyTags => '태그 없음 — 수집 시 추가하세요.';

  @override
  String get dashDeckCompositionEmpty => '단어를 추가하면 구성이 표시됩니다.';

  @override
  String dashLegendNewCount(int count) {
    return '신규 · $count';
  }

  @override
  String dashLegendLearningCount(int count) {
    return '학습 중(1–6회) · $count';
  }

  @override
  String dashLegendEstablishedCount(int count) {
    return '안정(>6회) · $count';
  }

  @override
  String get dashDueNowRow => '만료 또는 지각';

  @override
  String get dashDueWeekRow => '향후 7일 이내(오늘 제외)';

  @override
  String get dashDueLaterRow => '그 이후';

  @override
  String get dashQuickActions => '빠른 작업';

  @override
  String get dashStartReview => '복습 시작';

  @override
  String get dashOpenVocabulary => '단어장 열기';

  @override
  String get dashCapture => '수집';

  @override
  String get dashNothingDueHint => '만료 카드 없음. 복습 탭에서 미리 할 수 있습니다.';

  @override
  String get mobileDashSubtitle => '학습 스냅샷';

  @override
  String mobileDashLoadFailed(String error) {
    return '단어장을 불러올 수 없습니다.\\n$error';
  }

  @override
  String get mobileStatDueSubtitle => 'SRS 대기열';

  @override
  String get mobileStatActiveSubtitle => '덱 안';

  @override
  String get mobileStatNewSubtitle => '미복습';

  @override
  String get mobileStatArchivedSubtitle => '일시중지';

  @override
  String get mobileGoReview => '복습으로';

  @override
  String get mobileGoWords => '단어로';

  @override
  String get guidesPageSubtitle => '캡처·복습·단어·일상 사용 팁.';

  @override
  String get guidesIntroTitle => '탭 안내';

  @override
  String get guidesIntroBody => '왼쪽 탭: 대시보드·수집·복습·단어·이 안내·설정·정보.';

  @override
  String get guidesCaptureTitle => '수집';

  @override
  String get guidesCaptureBody =>
      '단축키는 캡처 탭 참고. 자동 수집으로 다른 앱 선택 추적. 팝업에서 원문 일부 드래그해 번역.';

  @override
  String get guidesReviewTitle => '복습(SRS)';

  @override
  String get guidesReviewBody => '복습 탭에서 SRS. Pro는 혼합 복습.';

  @override
  String get guidesVocabTitle => '단어장';

  @override
  String get guidesVocabBody => '단어 탭에서 검색·태그·보관. 동기화는 설정 따름.';

  @override
  String get guidesSettingsTitle => '설정 및 백업';

  @override
  String get guidesSettingsBody => '모국어·글자 크기·단축키·백업 폴더 설정.';

  @override
  String get guidesProTitle => '무료 및 Pro';

  @override
  String get guidesProBody =>
      '무료는 일일 한도 있을 수 있음. Pro는 배너 제거·혼합 복습·무제한 등. 정보 탭에서 구매.';

  @override
  String get aboutPageSubtitle => '앱 정보 및 라이선스';

  @override
  String get aboutTagline => '캡처·복습·단어 관리를 위한 학습 공간입니다.';

  @override
  String aboutVersionPrefix(String version) {
    return '버전 $version';
  }

  @override
  String get aboutUpdatesSection => '업데이트 및 Pro';

  @override
  String aboutLatestVersionLabel(String version) {
    return '최신 버전: $version';
  }

  @override
  String get aboutUpdateAvailable => '업데이트가 있습니다.';

  @override
  String get aboutUsingLatest => '최신 버전을 사용 중입니다.';

  @override
  String aboutReleaseNotesPrefix(String notes) {
    return '릴리스 노트: $notes';
  }

  @override
  String get aboutMinVersionWarning => '지원 최소 버전 미만입니다.';

  @override
  String get aboutPlanPro => '현재 플랜: Pro';

  @override
  String get aboutPlanFree => '현재 플랜: 무료';

  @override
  String get aboutProKeyInstructions => 'Lemon Squeezy 라이선스 키를 입력하세요.';

  @override
  String get aboutCheckUpdates => '업데이트 확인';

  @override
  String get aboutCheckingUpdates => '확인 중…';

  @override
  String get aboutDownloadLatest => '최신 다운로드';

  @override
  String get aboutVisitProWebsite => '웹사이트에서 Pro 구매';

  @override
  String get aboutActivating => '활성화 중…';

  @override
  String get aboutActivatePro => 'Pro 활성화';

  @override
  String get aboutActivateProTitle => 'Pro 활성화';

  @override
  String get aboutActivateProPlaceholder => '이메일의 라이선스 키 붙여넣기';

  @override
  String get aboutUpdateCheckDone => '업데이트 확인 완료';

  @override
  String get aboutWhatProUnlocks => 'Pro 혜택';

  @override
  String get aboutOneLicense => '라이선스 하나로 데스크톱·모바일 Pro.';

  @override
  String get aboutProBenefit1 => 'Pro 시 데스크톱 배너 광고 없음.';

  @override
  String get aboutProBenefit2 => '혼합 복습 모드.';

  @override
  String get aboutProBenefit3 => 'SRS 일일 채점 무제한(무료 100회).';

  @override
  String get aboutProBenefit4 => '데스크톱 캡처에서 저장하는 새 단어가 일일 무제한(무료는 일일 한도).';

  @override
  String get aboutProBenefit5 =>
      '데스크톱 캡처 팝업 번역 요청 일일 무제한. 캐시 적중은 한도에 포함 안 됨(무료는 일일 한도).';

  @override
  String get aboutSupportLegal => '지원 및 법적 정보';

  @override
  String aboutSupportEmailPrefix(String email) {
    return '지원 이메일: $email';
  }

  @override
  String get aboutCopySupportEmail => '지원 메일 복사';

  @override
  String get aboutOpenSourceLicenses => '오픈소스 라이선스';

  @override
  String get aboutPrivacyPolicy => '개인정보 처리방침';

  @override
  String get aboutTermsOfService => '서비스 약관';

  @override
  String get aboutSupportEmailCopied => '복사함';

  @override
  String get capturePageSubtitle => '자동 수집·단축키·동기화';

  @override
  String get captureAutoCaptureTitle => '자동 수집';

  @override
  String get captureAutoCaptureBody => '켜면 다른 앱 선택 추적. 끄면 Ctrl+Shift+D만.';

  @override
  String captureAutoToggleShortcutLine(String shortcut) {
    return '$shortcut(으)로 전환.';
  }

  @override
  String get captureHotkeyToggleLabel => '자동 수집 전환 단축키';

  @override
  String get capturePressNewShortcut => '새 단축키 입력';

  @override
  String get captureAutoStatusOn => '켜짐';

  @override
  String get captureAutoStatusOff => '꺼짐';

  @override
  String captureAutoToast(String status, String hotkey) {
    return '자동 수집: $status ($hotkey)';
  }

  @override
  String captureHotkeySetToast(String key) {
    return '자동 수집 단축키 Ctrl+Shift+$key';
  }

  @override
  String get captureVisualGuidesCardTitle => '시각 안내';

  @override
  String get captureVisualGuidesAutoHeading => '자동 수집 흐름';

  @override
  String get captureVisualGuidesOcrHeading => '화면 영역 OCR';

  @override
  String get captureVisualGuidesPopupRefineHint =>
      '팁: 수집 팝업에서 원문 일부를 드래그하면 그 구만 번역합니다. 닫지 않고 여러 번 바꿀 수 있습니다.';

  @override
  String get captureAutoFlowSelectLabel => '선택';

  @override
  String get captureAutoFlowPauseLabel => '대기';

  @override
  String get captureAutoFlowPopupLabel => '조회';

  @override
  String get captureAutoFlowCaption => '켜짐 시 3단계(다른 앱).';

  @override
  String get captureAutoVisualGuideLink => '단계별 안내…';

  @override
  String get captureDlgAutoCaptureTitle => '자동 수집 작동 방식';

  @override
  String get captureDlgAutoCaptureIntro =>
      '켜면 Formycareer가 다른 앱의 마우스 선택을 감지합니다(Formycareer 창 안은 제외).\\n\\n아래는 흐름 도식입니다.';

  @override
  String get captureDlgAutoCaptureStep1Title => '1. 다른 앱에서 선택';

  @override
  String get captureDlgAutoCaptureStep1Body => '브라우저·PDF 등에서 드래그 또는 단어 더블클릭.';

  @override
  String get captureDlgAutoCaptureStep2Title => '2. 놓고 잠시 대기';

  @override
  String get captureDlgAutoCaptureStep2Body => '선택이 안정된 뒤 읽습니다.';

  @override
  String get captureDlgAutoCaptureStep3Title => '3. 팝업 표시';

  @override
  String get captureDlgAutoCaptureStep3Body =>
      '팝업에서 문단을 열어 번역·저장 — 원문 영역에서 드래그하면 그 구만 번역합니다.';

  @override
  String get captureDlgAutoCaptureStep4Title => '4. 원문에서 다른 구간 더 선택';

  @override
  String get captureDlgAutoCaptureStep4Body =>
      '팝업의 원문 영역에서 필요할 때마다 다른 구간을 드래그 선택하면 그 부분만 번역되며, 창을 닫지 않고 반복할 수 있습니다.';

  @override
  String get captureDlgAutoCaptureSchemeCaption => '개념도(실제 UI 아님)';

  @override
  String get captureOcrFlowHotkeyLabel => '단축키';

  @override
  String get captureOcrFlowRegionLabel => '영역 지정';

  @override
  String get captureOcrFlowResultLabel => 'OCR 텍스트';

  @override
  String get captureOcrFlowCaption => 'Ctrl+Shift+X 후 영역을 드래그하세요.';

  @override
  String get captureOcrVisualGuideLink => 'OCR 단계 안내…';

  @override
  String get captureDlgOcrGuideTitle => '영역 OCR 방법';

  @override
  String get captureDlgOcrGuideIntro =>
      '영역 OCR은 선택한 화면에서 글자를 읽습니다. 자동 수집과 무관합니다.\\n\\n아래는 단계입니다.';

  @override
  String get captureDlgOcrStep1Title => '1. 영역 캡처 시작';

  @override
  String get captureDlgOcrStep1Body => '다른 앱에서 Ctrl+Shift+X 또는 이 창 포커스 시 단축키.';

  @override
  String get captureDlgOcrStep2Title => '2. 사각형 드래그';

  @override
  String get captureDlgOcrStep2Body => '화면이 어두워지면 드래그로 영역 지정.';

  @override
  String get captureDlgOcrStep3Title => '3. 확인 후 결과 보기';

  @override
  String get captureDlgOcrStep3Body => '확인 후 OCR 결과가 팝업에서 열려 번역하거나 저장할 수 있습니다.';

  @override
  String get captureDlgOcrStep4Title => '4. 원문에서 다른 구간 더 선택';

  @override
  String get captureDlgOcrStep4Body =>
      '팝업의 원문 영역에서 필요할 때마다 다른 구간을 드래그 선택하면 그 부분만 번역되며, 창을 닫지 않고 반복할 수 있습니다.';

  @override
  String get captureDlgOcrSchemeCaption => '개념도(실제 UI 아님)';

  @override
  String get captureActiveBehaviorNote => '선택 후 잠시 뒤 읽음 — 클립보드가 바뀔 수 있음.';

  @override
  String get captureShortcutsSectionTitle => '수집';

  @override
  String get captureShortcutsSectionBody =>
      'Ctrl+Shift+D(텍스트), Ctrl+Shift+X(영역).';

  @override
  String get captureTextFromSelection => '선택 영역 텍스트';

  @override
  String get captureImageRegionOcr => '이미지/영역 OCR';

  @override
  String get capturePermissionsTitle => '권한';

  @override
  String captureAccessibilityGrantedLine(String state) {
    return '손쉬운 사용: $state';
  }

  @override
  String captureScreenRecordingGrantedLine(String state) {
    return '화면 녹화: $state';
  }

  @override
  String get capturePermRefresh => '새로 고침';

  @override
  String get capturePermRequest => '누락 권한 요청';

  @override
  String get capturePermChecking => '확인 중…';

  @override
  String get capturePermAllGranted => '모든 권한 허용됨.';

  @override
  String get capturePermSomeMissing => '권한 부족 — 설정에서 허용하세요.';

  @override
  String get captureHotkeyUnavailable => '전역 단축키 없음 — 앱 내 단축키 사용.';

  @override
  String get captureDlgTextCaptureTitle => '텍스트 수집';

  @override
  String get captureDlgTextCaptureBody =>
      '수동: Ctrl+Shift+D.\\n자동: 드래그·더블클릭으로 강조 텍스트 읽기.';

  @override
  String get captureDlgImageCaptureTitle => '이미지/영역 OCR';

  @override
  String get captureDlgImageCaptureBody => 'Ctrl+Shift+X로 영역 선택 OCR.';

  @override
  String get captureDlgTipsTitle => '수집 팁';

  @override
  String get captureDlgTipsBody => '장시간 작성 시 끄면 클립보드 간섭 감소.';

  @override
  String get captureHotkeyDlgTitle => '새 단축키';

  @override
  String get captureHotkeyDlgHintInitial => 'Ctrl+Shift+글자/숫자';

  @override
  String get captureHotkeyDlgHintRetry => 'Ctrl+Shift+글자/숫자 필요';

  @override
  String get vocabPageSubtitle => '검색·필터·덱 관리';

  @override
  String get vocabStudySelected => '선택 항목 학습';

  @override
  String get vocabStudyFiltered => '필터로 학습';

  @override
  String get vocabSelectBeforeStudy => '학습 전 단어를 선택하세요.';

  @override
  String get vocabNoMatchFilters => '필터와 일치하는 단어 없음.';

  @override
  String get vocabTipsTitle => '단어 팁';

  @override
  String get vocabTipsBody => '대량 작업 전 언어·출처로 필터.';

  @override
  String get vocabDeleteTitle => '저장 단어 삭제?';

  @override
  String get vocabDeleteBodyOne => '선택 항목 영구 삭제.';

  @override
  String vocabDeleteBodyMany(int count) {
    return '선택한 $count개 영구 삭제.';
  }

  @override
  String get vocabSearchPlaceholder => '용어·뜻·태그 검색';

  @override
  String get vocabAllLanguages => '모든 언어';

  @override
  String get vocabAllSources => '모든 출처';

  @override
  String get vocabAllTags => '모든 태그';

  @override
  String get vocabFilterActive => '활성';

  @override
  String get vocabFilterArchived => '보관';

  @override
  String get vocabFilterAll => '전체';

  @override
  String get vocabClearFilters => '필터 지우기';

  @override
  String get vocabTtsSectionTitle => 'Google Cloud 텍스트 음성 변환';

  @override
  String get vocabTtsSectionBody =>
      '긴 텍스트를 음성으로 합성합니다(Cloud TTS 한도 내 자동 분할). Text-to-Speech API 키와 API 사용 설정이 필요합니다.';

  @override
  String get vocabTtsApiKeyPlaceholder => 'API 키(기기에 안전하게 저장)';

  @override
  String get vocabTtsSaveApiKey => '키 저장';

  @override
  String get vocabTtsApiKeySaved => 'API 키를 저장했습니다.';

  @override
  String get vocabTtsApiKeyFromBuild => '앱 빌드 설정의 API 키를 사용 중입니다.';

  @override
  String get vocabTtsTextPlaceholder => '읽을 텍스트 입력(긴 글 지원)';

  @override
  String vocabTtsStats(int bytes, int segments) {
    return 'UTF-8 크기: $bytes · 요청 구간: $segments';
  }

  @override
  String get vocabTtsVoiceLabel => '음성';

  @override
  String get vocabTtsVoiceCustom => '사용자 지정 음성…';

  @override
  String get vocabTtsCustomVoicePlaceholder => '음성 이름(예: en-US-Neural2-J)';

  @override
  String get vocabTtsCustomLangPlaceholder => 'languageCode(예: en-US)';

  @override
  String get vocabTtsSpeakingRate => '말 속도';

  @override
  String get vocabTtsGeneratePlay => '합성 후 재생';

  @override
  String get vocabTtsSaveMp3 => 'MP3 저장…';

  @override
  String get vocabTtsNeedApiKey =>
      'Google Cloud Text-to-Speech API 키를 먼저 추가하세요.';

  @override
  String get vocabTtsNeedText => '합성할 텍스트를 입력하세요.';

  @override
  String get vocabTtsVoiceInvalid => '음성 이름과 languageCode를 모두 입력하세요.';

  @override
  String vocabTtsError(String message) {
    return '$message';
  }

  @override
  String vocabTtsSavedFile(String path) {
    return '오디오 저장됨: $path';
  }

  @override
  String get vocabEmptyLibrary => '단어 없음.';

  @override
  String get vocabColTermMeaning => '용어 / 뜻';

  @override
  String get vocabColSource => '출처';

  @override
  String get vocabColTags => '태그';

  @override
  String get vocabColNextReview => '다음 복습';

  @override
  String get vocabCtxMenuTag => '태그';

  @override
  String get vocabCtxMenuArchive => '보관';

  @override
  String get vocabCtxMenuResetSrs => 'SRS 초기화';

  @override
  String get vocabCtxMenuDelete => '삭제';

  @override
  String get bulkTagCreateTitle => '태그 만들기';

  @override
  String get bulkTagCreatePlaceholder => '새 태그 입력';

  @override
  String get bulkTagRenameTitle => '태그 이름 변경';

  @override
  String get bulkTagRenamePlaceholder => '태그 입력';

  @override
  String get bulkTagDeleteTitle => '태그 삭제';

  @override
  String bulkTagDeleteBody(String tag) {
    return '모든 단어에서 \"$tag\" 제거?';
  }

  @override
  String get bulkTagFilterPlaceholder => '태그 필터';

  @override
  String get bulkTagClearSelections => '태그 선택 해제';

  @override
  String get bulkTagRename => '이름 변경';

  @override
  String get bulkTagDelete => '삭제';

  @override
  String get bulkTagApply => '적용';

  @override
  String get bulkTagNewBadge => '신규';

  @override
  String get bulkTagPanelTitle => '일괄 태그';

  @override
  String get bulkTagEmptyLibrary => '라이브러리에 태그 없음.';

  @override
  String get bulkTagNoMatchFilter => '필터와 일치하는 태그 없음.';

  @override
  String get bulkTagValidationEmpty => '태그 이름은 비울 수 없습니다.';

  @override
  String get bulkTagValidationDuplicate => '태그가 이미 있습니다.';

  @override
  String get bulkTagManageTooltip => '태그 관리';

  @override
  String get commonCreate => '만들기';

  @override
  String get customStudyTitle => '사용자 학습';

  @override
  String customStudyEntriesCount(int count) {
    return '선택 일치: $count개';
  }

  @override
  String get customStudyMaxLabel => '최대 카드(비우면 전체)';

  @override
  String get customStudyMaxPlaceholder => '예: 50';

  @override
  String get customStudyRandomOrder => '무작위';

  @override
  String get customStudyCram => '벼락치기(일정 저장 안 함)';

  @override
  String get customStudyStart => '시작';

  @override
  String get reviewSrsTitle => 'SRS 복습';

  @override
  String get reviewCramBadge => '벼락치기';

  @override
  String reviewQueueCounts(int newCount, int learningCount, int reviewCount) {
    return '신규 $newCount · 학습 $learningCount · 복습 $reviewCount';
  }

  @override
  String get reviewAutoAudio => '자동 오디오';

  @override
  String get reviewAllLanguages => '모든 언어';

  @override
  String get reviewLanguageFilterTooltip => '언어 필터';

  @override
  String get reviewMixedProOnly => '믹스 모드는 Pro입니다.';

  @override
  String get reviewMixedEnable => '믹스 켜기';

  @override
  String get reviewMixedLocked => '믹스 (Pro)';

  @override
  String get reviewBasicMode => '기본 모드';

  @override
  String get reviewExitStudy => '학습 종료';

  @override
  String get reviewNoCardsDue => '만료 카드 없음.';

  @override
  String get reviewFinishing => '세션 종료 중…';

  @override
  String get reviewCompleted => '복습 완료.';

  @override
  String reviewReviewsToday(int used, int limit) {
    return '오늘 복습: $used/$limit';
  }

  @override
  String get reviewTipsTitle => '복습 팁';

  @override
  String get reviewTipsBody => 'Enter 뒤집기·채점, Ctrl+Enter 오디오.';

  @override
  String get reviewGradeHintForward => 'Enter 뒤집기 · Ctrl+Enter 오디오';

  @override
  String get reviewGradeHintReverse => 'Enter 확인 · Ctrl+Enter 오디오';

  @override
  String get reviewAudioFailed => '오디오 재생 실패.';

  @override
  String get reviewPlayTerm => '용어 재생';

  @override
  String get reviewPlayAudio => '오디오 재생';

  @override
  String get reviewMeaning => '의미';

  @override
  String get reviewListenType => '듣고 입력';

  @override
  String get reviewListenInstructions => '오디오 듣고 원문 입력.';

  @override
  String get reviewTypeOriginalPlaceholder => '원문 입력';

  @override
  String get reviewCheckAnswer => '확인 (Enter)';

  @override
  String get reviewCorrect => '맞음';

  @override
  String get reviewIncorrect => '틀림';

  @override
  String get reviewYourAnswer => '내 답:';

  @override
  String get reviewExpected => '정답:';

  @override
  String get reviewAnswerEmptyMarker => '(비어 있음)';

  @override
  String get reviewGradeAgain => '다시 (1)';

  @override
  String get reviewGradeHard => '어려움 (2)';

  @override
  String get reviewGradeGood => '좋음 (3)';

  @override
  String get reviewGradeEasy => '쉬움 (4)';

  @override
  String get reviewGradeNameAgain => 'again';

  @override
  String get reviewGradeNameHard => 'hard';

  @override
  String get reviewGradeNameGood => 'good';

  @override
  String get reviewGradeNameEasy => 'easy';

  @override
  String reviewSummaryWordsTitle(int count) {
    return '방금 복습한 단어 ($count)';
  }

  @override
  String get reviewSummaryClose => '닫기';

  @override
  String get reviewSummaryTitle => '세션 요약';

  @override
  String reviewSummaryGreatJob(String name) {
    return '잘했어요, $name!';
  }

  @override
  String get reviewSummaryEncourage => '오늘 목표를 달성했습니다.';

  @override
  String get reviewSummaryStatReviewed => '복습함';

  @override
  String get reviewSummaryStatMastered => '잘 기억함';

  @override
  String get reviewSummaryStatTime => '시간';

  @override
  String get reviewSummaryBackDashboard => '대시보드로';

  @override
  String get reviewSummarySeeWords => '복습 단어 보기';

  @override
  String get reviewSummaryCloudSyncing => '클라우드 동기화 중…';

  @override
  String get reviewSummaryCloudOk => '클라우드 동기화 성공';

  @override
  String get reviewSummaryCloudFail => '클라우드 동기화 실패';

  @override
  String get reviewSummaryYou => '당신';

  @override
  String reviewDurSeconds(int seconds) {
    return '$seconds초';
  }

  @override
  String reviewDurMinutes(int minutes) {
    return '$minutes분';
  }

  @override
  String reviewDurMinutesSeconds(int minutes, int seconds) {
    return '$minutes분 $seconds초';
  }

  @override
  String reviewDurHours(int hours) {
    return '$hours시간';
  }

  @override
  String reviewDurHoursMinutes(int hours, int minutes) {
    return '$hours시간 $minutes분';
  }

  @override
  String get captureSavePhrase => '구문 저장';

  @override
  String get captureSaveLine => '줄 저장';

  @override
  String get captureWholeLine => '전체 줄';

  @override
  String get captureListenSource => '원문 듣기';

  @override
  String get captureNoTextDetected => '텍스트 없음';

  @override
  String get captureAddTagLabel => '태그 추가';

  @override
  String get captureTagHint => '태그 입력';

  @override
  String get captureAutoRecentTag => '최근 태그 자동 입력';

  @override
  String get captureNoRecentTagsYet => '최근 태그 없음 — 저장 후 사용.';

  @override
  String get captureSavedToast => '저장 ✓';

  @override
  String captureDailySaveLimitReached(int limit) {
    return '오늘 저장 한도($limit회/일)에 도달했습니다. Pro로 무제한 저장.';
  }

  @override
  String captureDailyTranslateLimitReached(int limit) {
    return '오늘 번역 호출 한도($limit회/일)에 도달했습니다. Pro로 무제한.';
  }

  @override
  String get settingsTagManagerEmpty => '태그 없음.';

  @override
  String get meaningTranslating => '번역 중…';

  @override
  String get meaningNoTranslationYet => '번역 없음.';

  @override
  String get meaningDictHeading => '영어 정의';

  @override
  String get meaningFieldLabel => '의미';

  @override
  String get meaningFieldHint => '번역 편집';

  @override
  String get meaningPlayPronunciation => '발음 재생';

  @override
  String get meaningPlay => '재생';

  @override
  String get meaningPause => '일시정지';

  @override
  String get meaningPhraseMarker => '(구문)';

  @override
  String get settingsReviewAudioSection => '복습 오디오';

  @override
  String get settingsAutoPlayAudioTitle => '새 카드 자동 재생';

  @override
  String get settingsRememberTagTitle => '단어 추가 시 마지막 태그 기억';

  @override
  String get settingsLocalBackupTitle => '로컬 백업';

  @override
  String get settingsBackupNowJson => '지금 백업(JSON)';

  @override
  String get settingsImportBackup => '백업 가져오기(.db/.json)';

  @override
  String get settingsBackupFootnote => '서명 JSON 또는 .db/.json.';

  @override
  String get settingsManageTagsTitle => '태그 관리';

  @override
  String get settingsManageTagsSubtitle => '모든 단어에서 태그 편집.';

  @override
  String get settingsReplaceVocabTitle => '로컬 단어장 교체?';

  @override
  String get settingsReplaceVocabBody => '백업으로 교체. 되돌릴 수 없음.';

  @override
  String get settingsChooseFile => '파일 선택';

  @override
  String get settingsImporting => '가져오는 중…';

  @override
  String settingsImportedCount(int count, String kind) {
    return '$count개 가져옴 ($kind).';
  }

  @override
  String get settingsExportCancelled => '내보내기 취소';

  @override
  String settingsSavedPath(String path) {
    return '저장됨: $path';
  }

  @override
  String settingsExportFailed(String error) {
    return '내보내기 실패: $error';
  }

  @override
  String settingsImportFailed(String error) {
    return '가져오기 실패: $error';
  }

  @override
  String settingsLanguageLoadError(String error) {
    return '언어 설정 오류: $error';
  }

  @override
  String commonErrorPrefix(String error) {
    return '오류: $error';
  }

  @override
  String get dashLearnerPickerLabel => 'Who is learning?';

  @override
  String get dashLearnerPickerNewButton => '새로 만들기';

  @override
  String get localProfilesSectionTitle => 'Local learners';

  @override
  String get localProfilesSectionDescription =>
      'Each learner has a separate vocabulary library on this device. Switch profile to study a different word set.';

  @override
  String get localProfileDefaultName => 'Default';

  @override
  String get localProfileActiveBadge => 'Active';

  @override
  String get localProfileUseAction => 'Use';

  @override
  String get localProfileAddAction => 'Add learner';

  @override
  String get localProfileRenameAction => 'Rename';

  @override
  String get localProfileDeleteAction => 'Remove';

  @override
  String get localProfileAddTitle => 'New learner';

  @override
  String get localProfileRenameTitle => 'Rename learner';

  @override
  String get localProfileNameLabel => 'Display name';

  @override
  String get localProfileDeleteConfirmTitle => 'Remove learner?';

  @override
  String get localProfileDeleteConfirmBody =>
      'Their vocabulary stays on this device until you clear app data. You can add this learner again anytime.';
}
