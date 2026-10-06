// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FormyCareer';

  @override
  String get navDesktop => 'Desktop';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navCapture => 'Capture';

  @override
  String get navReview => 'Review';

  @override
  String get navVocabulary => 'Vocabulary';

  @override
  String get navGuides => 'Guides';

  @override
  String get navSettings => 'Settings';

  @override
  String get navAbout => 'About';

  @override
  String get navWords => 'Words';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'Language and local preferences';

  @override
  String get uiLanguageSectionTitle => 'Interface language';

  @override
  String get uiLanguageLabel => 'App language';

  @override
  String get uiLanguageDescription =>
      'Controls menus and settings text. Translation explanations still follow “Native language” below.';

  @override
  String get uiLocaleSystem => 'Follow system';

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
  String get settingsTextScaleSectionTitle => 'Text size';

  @override
  String get settingsTextScaleLabel => 'Interface text scale';

  @override
  String get settingsTextScaleDescription =>
      'Adjusts text in the desktop window and capture popup. This stacks with Windows display scaling.';

  @override
  String settingsTextScalePercent(int percent) {
    return '$percent%';
  }

  @override
  String get backupSectionTitle => 'Local backup & restore';

  @override
  String get backupSectionIntro => 'Backup and restore data locally.';

  @override
  String get defaultBackupFolderTitle => 'Default backup folder';

  @override
  String get defaultBackupFolderDescription =>
      'Used for scheduled automatic backups. The built-in default is a folder under your Documents directory. “Backup now” below can still save to any folder you choose.';

  @override
  String get resolvingPath => 'Resolving path…';

  @override
  String currentPathPrefix(String path) {
    return 'Current: $path';
  }

  @override
  String get confirmUseFolder => 'Use this folder';

  @override
  String get changeDefaultFolder => 'Change default folder';

  @override
  String get useAppDefaultFolder => 'Use app default folder';

  @override
  String couldNotUseFolder(String error) {
    return 'Could not use this folder: $error';
  }

  @override
  String defaultBackupFolderSet(String path) {
    return 'Default backup folder: $path';
  }

  @override
  String get usingAppDefaultAgain => 'Using the app default folder again.';

  @override
  String get automaticBackupTitle => 'Automatic backup';

  @override
  String get automaticBackupDescription =>
      'Saves a copy of your library on a schedule to the default folder above.';

  @override
  String get repeatEveryLabel => 'Repeat every';

  @override
  String get backupNow => 'Backup now';

  @override
  String get restoreFromFile => 'Restore from file';

  @override
  String get saveBackupHere => 'Save backup here';

  @override
  String get restoreFromThisFile => 'Restore from this file';

  @override
  String get backupFilesFilter => 'Backup files';

  @override
  String backupCreated(String path) {
    return 'Backup created: $path';
  }

  @override
  String restoredFrom(String restored) {
    return 'Restored from: $restored';
  }

  @override
  String get backupFooterNote =>
      '“Backup now” lets you pick any folder. Automatic backups always use the default folder above. For restore, choose a .db or .json file.';

  @override
  String get backupIntervalHourly => 'Every hour';

  @override
  String get backupInterval6h => 'Every 6 hours';

  @override
  String get backupInterval12h => 'Every 12 hours';

  @override
  String get backupIntervalDaily => 'Every day';

  @override
  String get backupInterval2days => 'Every 2 days';

  @override
  String get backupIntervalWeekly => 'Every week';

  @override
  String backupIntervalEveryHours(int hours) {
    return 'Every $hours hours';
  }

  @override
  String get translationSectionTitle => 'Translation';

  @override
  String get nativeLanguageLabel => 'Native language';

  @override
  String get translationNativeHelp =>
      'Translations and UI explanations are shown in this language.';

  @override
  String get translationEngineHelp =>
      'Translation engine is selected automatically for fastest response.';

  @override
  String get backupErrNoBackupFile => 'No backup file found to restore.';

  @override
  String get backupErrSqliteMissing => 'SQLite backup file was not found.';

  @override
  String get backupErrFileMissing => 'The selected backup file was not found.';

  @override
  String get backupErrUnsupportedFormat =>
      'Unsupported backup format. Choose a .db or .json file.';

  @override
  String get backupErrInvalidCorrupt =>
      'The backup file is invalid or corrupted.';

  @override
  String backupErrGeneric(String error) {
    return 'Backup or restore failed. Details: $error';
  }

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSave => 'Save';

  @override
  String get commonBack => 'Back';

  @override
  String get commonOk => 'OK';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonTips => 'Tips';

  @override
  String get commonGranted => 'Granted';

  @override
  String get commonMissing => 'Missing';

  @override
  String get commonChecking => 'Checking…';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonStudy => 'Study';

  @override
  String get commonTag => 'Tag';

  @override
  String get commonArchive => 'Archive';

  @override
  String get commonResetSrs => 'Reset SRS';

  @override
  String get commonActivate => 'Activate';

  @override
  String get cmdCancelEsc => 'Cancel (Esc)';

  @override
  String get cmdOneItemSelected => '1 item selected';

  @override
  String cmdManyItemsSelected(int count) {
    return '$count items selected';
  }

  @override
  String get dashSubtitle => 'Study snapshot, insights, and quick navigation';

  @override
  String dashCouldNotLoadVocab(String error) {
    return 'Could not load vocabulary: $error';
  }

  @override
  String get dashHeroTitle => 'Your study hub';

  @override
  String dashHeroStatsLine(int dueNow, int active, int newCount) {
    return '$dueNow ready now · $active cards in active deck · $newCount new';
  }

  @override
  String get dashHeroShareCaption => 'Share of active deck due for review';

  @override
  String dashHeroPercentDue(int percent) {
    return '$percent% due among active cards';
  }

  @override
  String get dashStatDueNowTitle => 'Due now';

  @override
  String get dashStatDueNowSubtitle => 'Ready for SRS review';

  @override
  String get dashStatActiveTitle => 'Active deck';

  @override
  String get dashStatActiveSubtitle => 'Non-archived entries';

  @override
  String get dashStatNewTitle => 'New';

  @override
  String get dashStatNewSubtitle => 'Never reviewed';

  @override
  String get dashStatArchivedTitle => 'Archived';

  @override
  String get dashStatArchivedSubtitle => 'Paused from queue';

  @override
  String get dashInsightUpcoming => 'Upcoming reviews';

  @override
  String get dashInsightDeckComposition => 'Deck composition';

  @override
  String get dashInsightByLanguage => 'By language';

  @override
  String get dashInsightPopularTags => 'Popular tags';

  @override
  String get dashEmptyLangPairs => 'No language pairs yet.';

  @override
  String get dashEmptyTags => 'No tags yet — add tags when capturing.';

  @override
  String get dashDeckCompositionEmpty => 'Add vocabulary to see composition.';

  @override
  String dashLegendNewCount(int count) {
    return 'New · $count';
  }

  @override
  String dashLegendLearningCount(int count) {
    return 'Learning (1–6 reviews) · $count';
  }

  @override
  String dashLegendEstablishedCount(int count) {
    return 'Established (>6 reviews) · $count';
  }

  @override
  String get dashDueNowRow => 'Due now or overdue';

  @override
  String get dashDueWeekRow => 'Due in the next 7 days (after today)';

  @override
  String get dashDueLaterRow => 'Due later';

  @override
  String get dashQuickActions => 'Quick actions';

  @override
  String get dashStartReview => 'Start review';

  @override
  String get dashOpenVocabulary => 'Open vocabulary';

  @override
  String get dashCapture => 'Capture';

  @override
  String get dashNothingDueHint =>
      'Nothing due right now. You can still review ahead from the Review tab.';

  @override
  String get mobileDashSubtitle => 'Study snapshot';

  @override
  String mobileDashLoadFailed(String error) {
    return 'Could not load vocabulary.\n$error';
  }

  @override
  String get mobileStatDueSubtitle => 'SRS queue';

  @override
  String get mobileStatActiveSubtitle => 'In deck';

  @override
  String get mobileStatNewSubtitle => 'Not reviewed';

  @override
  String get mobileStatArchivedSubtitle => 'Paused';

  @override
  String get mobileGoReview => 'Go to Review';

  @override
  String get mobileGoWords => 'Open Words';

  @override
  String get guidesPageSubtitle =>
      'Tips for capture, review, vocabulary, and everyday use.';

  @override
  String get guidesIntroTitle => 'Getting around';

  @override
  String get guidesIntroBody =>
      'Use the tabs on the left: Dashboard for your learning snapshot; Capture to grab text from other apps; Review for SRS sessions; Vocabulary to browse and organize cards; Guides for tips like these; Settings for language, backups, and hotkeys; About for versions, Pro, and support.';

  @override
  String get guidesCaptureTitle => 'Capture';

  @override
  String get guidesCaptureBody =>
      'Keyboard shortcuts (when registered): typically Ctrl+Shift+D for selected text and Ctrl+Shift+X for region OCR—see the Capture tab if global registration fails. Turn on Auto capture to follow mouse text selection in other apps, or capture from the Capture tab. In the popup, drag-select in the source field to translate only a phrase; save adds the card to your library.';

  @override
  String get guidesReviewTitle => 'Review (SRS)';

  @override
  String get guidesReviewBody =>
      'The Review tab runs spaced repetition. Grade each card honestly so intervals stay meaningful. Pro unlocks mixed review (forward, reverse meaning, and reverse audio in one session).';

  @override
  String get guidesVocabTitle => 'Vocabulary';

  @override
  String get guidesVocabBody =>
      'Search, tag, archive, and edit entries in the Vocabulary tab. Sync and export options depend on your account and backup settings under Settings.';

  @override
  String get guidesSettingsTitle => 'Settings & backup';

  @override
  String get guidesSettingsBody =>
      'Set your native language for translations, adjust text scale, configure the auto-capture toggle hotkey, and choose local backup folders. Keeping backups protects you when reinstalling or moving to a new PC.';

  @override
  String get guidesProTitle => 'Free and Pro';

  @override
  String get guidesProBody =>
      'Free tier may apply daily limits on desktop capture saves and capture-popup translation requests (phrases served from cache usually do not count). Pro removes banner ads on desktop, unlocks mixed review and unlimited SRS grades per day, and removes those desktop capture limits. Open the About tab for update checks, activation, and a link to buy Pro.';

  @override
  String get aboutPageSubtitle => 'App info and licensing';

  @override
  String get aboutTagline =>
      'A cross-platform language learning workspace for capture, review, and vocabulary management.';

  @override
  String aboutVersionPrefix(String version) {
    return 'Version $version';
  }

  @override
  String get aboutUpdatesSection => 'Updates & Pro';

  @override
  String aboutLatestVersionLabel(String version) {
    return 'Latest version: $version';
  }

  @override
  String get aboutUpdateAvailable => 'Update available for this app.';

  @override
  String get aboutUsingLatest => 'You are using the latest version.';

  @override
  String aboutReleaseNotesPrefix(String notes) {
    return 'Release notes: $notes';
  }

  @override
  String get aboutMinVersionWarning =>
      'This version is below minimum supported version.';

  @override
  String get aboutPlanPro => 'Current plan: Pro';

  @override
  String get aboutPlanFree => 'Current plan: Free';

  @override
  String get aboutProKeyInstructions =>
      'Use the license key sent by Lemon Squeezy after payment. See “What Pro unlocks” below for included benefits.';

  @override
  String get aboutCheckUpdates => 'Check updates';

  @override
  String get aboutCheckingUpdates => 'Checking updates…';

  @override
  String get aboutDownloadLatest => 'Download latest';

  @override
  String get aboutVisitProWebsite => 'Visit website to Buy Pro';

  @override
  String get aboutActivating => 'Activating…';

  @override
  String get aboutActivatePro => 'Activate Pro';

  @override
  String get aboutActivateProTitle => 'Activate Pro';

  @override
  String get aboutActivateProPlaceholder =>
      'Paste license key from your Lemon Squeezy email';

  @override
  String get aboutUpdateCheckDone => 'Update check completed';

  @override
  String get aboutWhatProUnlocks => 'What Pro unlocks';

  @override
  String get aboutOneLicense =>
      'One license activates Pro on desktop and mobile.';

  @override
  String get aboutProBenefit1 => 'No banner ads on desktop when Pro is active.';

  @override
  String get aboutProBenefit2 =>
      'Mixed review mode: combine forward, reverse meaning, and reverse audio in one session (Free uses basic forward-only review).';

  @override
  String get aboutProBenefit3 =>
      'Unlimited SRS review grades per calendar day (Free: up to 100 per local calendar day).';

  @override
  String get aboutProBenefit4 =>
      'Unlimited new vocabulary saves from desktop capture per calendar day (Free: daily limit).';

  @override
  String get aboutProBenefit5 =>
      'Unlimited translation requests in the desktop capture popup per calendar day; phrases served from cache do not count toward the limit (Free: daily limit).';

  @override
  String get aboutSupportLegal => 'Support & Legal';

  @override
  String aboutSupportEmailPrefix(String email) {
    return 'Support email: $email';
  }

  @override
  String get aboutCopySupportEmail => 'Copy support email';

  @override
  String get aboutOpenSourceLicenses => 'Open-source licenses';

  @override
  String get aboutPrivacyPolicy => 'Privacy Policy';

  @override
  String get aboutTermsOfService => 'Terms of Service';

  @override
  String get aboutSupportEmailCopied => 'Support email copied';

  @override
  String get capturePageSubtitle => 'Auto-capture, shortcuts, and sync';

  @override
  String get captureAutoCaptureTitle => 'Auto capture';

  @override
  String get captureAutoCaptureBody =>
      'When on, follow text selection in other apps via the mouse path below. When off, use Ctrl+Shift+D only.';

  @override
  String captureAutoToggleShortcutLine(String shortcut) {
    return 'Toggle quickly with $shortcut.';
  }

  @override
  String get captureHotkeyToggleLabel => 'Hotkey to toggle auto-capture';

  @override
  String get capturePressNewShortcut => 'Press new shortcut';

  @override
  String get captureAutoStatusOn => 'ON';

  @override
  String get captureAutoStatusOff => 'OFF';

  @override
  String captureAutoToast(String status, String hotkey) {
    return 'Auto capture: $status ($hotkey)';
  }

  @override
  String captureHotkeySetToast(String key) {
    return 'Auto-capture hotkey set to Ctrl+Shift+$key';
  }

  @override
  String get captureVisualGuidesCardTitle => 'Visual guides';

  @override
  String get captureVisualGuidesAutoHeading => 'Auto capture flow';

  @override
  String get captureVisualGuidesOcrHeading => 'Region OCR';

  @override
  String get captureVisualGuidesPopupRefineHint =>
      'Tip: In the capture popup, drag-select part of the source text to translate just that phrase—you can refine focus more than once without closing the popup.';

  @override
  String get captureAutoFlowSelectLabel => 'Select';

  @override
  String get captureAutoFlowPauseLabel => 'Pause';

  @override
  String get captureAutoFlowPopupLabel => 'Lookup';

  @override
  String get captureAutoFlowCaption =>
      'Typical flow when auto capture is on (other apps only).';

  @override
  String get captureAutoVisualGuideLink => 'Step-by-step guide with pictures…';

  @override
  String get captureDlgAutoCaptureTitle => 'How auto capture works';

  @override
  String get captureDlgAutoCaptureIntro =>
      'With Auto capture enabled, Formycareer watches for mouse-based text selection in other programs—not when you interact inside Formycareer itself.\n\nThe pictures below outline what happens.';

  @override
  String get captureDlgAutoCaptureStep1Title => '1. Select text elsewhere';

  @override
  String get captureDlgAutoCaptureStep1Body =>
      'In a browser, PDF, or editor: drag across the words you want, or double-click a single word so it highlights.';

  @override
  String get captureDlgAutoCaptureStep2Title => '2. Release and wait briefly';

  @override
  String get captureDlgAutoCaptureStep2Body =>
      'Let the highlight settle. A very short pause helps the app detect a stable selection.';

  @override
  String get captureDlgAutoCaptureStep3Title => '3. Popup opens';

  @override
  String get captureDlgAutoCaptureStep3Body =>
      'The capture popup appears with the passage so you can translate, save, or review. Drag-select any substring in the source area to translate only that phrase.';

  @override
  String get captureDlgAutoCaptureStep4Title =>
      '4. Pick another span in the source';

  @override
  String get captureDlgAutoCaptureStep4Body =>
      'Whenever you want a different phrase, drag-select another span in the source area—the translation updates to match only that selection, and you can repeat this as many times as you like without closing the popup.';

  @override
  String get captureDlgAutoCaptureSchemeCaption => 'Schematic (not actual UI)';

  @override
  String get captureOcrFlowHotkeyLabel => 'Shortcut';

  @override
  String get captureOcrFlowRegionLabel => 'Region';

  @override
  String get captureOcrFlowResultLabel => 'OCR text';

  @override
  String get captureOcrFlowCaption =>
      'On-demand capture: Ctrl+Shift+X, then drag a rectangle over the text you want read.';

  @override
  String get captureOcrVisualGuideLink => 'OCR step-by-step with pictures…';

  @override
  String get captureDlgOcrGuideTitle => 'How region OCR works';

  @override
  String get captureDlgOcrGuideIntro =>
      'Region OCR reads text from a screen area you choose. It always runs when you trigger it—not tied to Auto capture.\n\nThe pictures below outline the flow.';

  @override
  String get captureDlgOcrStep1Title => '1. Start region capture';

  @override
  String get captureDlgOcrStep1Body =>
      'Press Ctrl+Shift+X from another app, or use the in-app shortcut while this window is focused.';

  @override
  String get captureDlgOcrStep2Title => '2. Drag a rectangle';

  @override
  String get captureDlgOcrStep2Body =>
      'The screen dims. Drag a box around the words or image text you want; adjust until the area looks right.';

  @override
  String get captureDlgOcrStep3Title => '3. Confirm and review';

  @override
  String get captureDlgOcrStep3Body =>
      'Confirm the selection. Recognized text opens in the capture popup so you can translate or save it.';

  @override
  String get captureDlgOcrStep4Title => '4. Pick another span in the source';

  @override
  String get captureDlgOcrStep4Body =>
      'Whenever you want a different phrase, drag-select another span in the source area—the translation updates to match only that selection, and you can repeat this as many times as you like without closing the popup.';

  @override
  String get captureDlgOcrSchemeCaption => 'Schematic (not actual UI)';

  @override
  String get captureActiveBehaviorNote =>
      'Active behavior: after you drag-select or double-click to select text in another app (outside Formycareer), the app reads that selection after a short pause. Your clipboard may change; avoid Auto capture while you must keep clipboard contents. SelectionHost (UIA) and clipboard listening are not used.';

  @override
  String get captureShortcutsSectionTitle => 'Capture';

  @override
  String get captureShortcutsSectionBody =>
      'Shortcuts: Ctrl+Shift+D (text), Ctrl+Shift+X (region image). Tap a mode for instructions.';

  @override
  String get captureTextFromSelection => 'Text from selection';

  @override
  String get captureImageRegionOcr => 'Image / region OCR';

  @override
  String get capturePermissionsTitle => 'Permissions';

  @override
  String captureAccessibilityGrantedLine(String state) {
    return 'Accessibility: $state';
  }

  @override
  String captureScreenRecordingGrantedLine(String state) {
    return 'Screen Recording: $state';
  }

  @override
  String get capturePermRefresh => 'Refresh';

  @override
  String get capturePermRequest => 'Request missing permissions';

  @override
  String get capturePermChecking => 'Checking…';

  @override
  String get capturePermAllGranted => 'All capture permissions are granted.';

  @override
  String get capturePermSomeMissing =>
      'Some permissions are still missing. Enable them in System Settings > Privacy & Security.';

  @override
  String get captureHotkeyUnavailable =>
      'Global hotkey unavailable. Use in-app Ctrl+Shift+D / Ctrl+Shift+X.';

  @override
  String get captureDlgTextCaptureTitle => 'Text capture';

  @override
  String get captureDlgTextCaptureBody =>
      'Manual:\n• Press Ctrl+Shift+D from another app (or use the in-app shortcut when this window is focused).\n\nAuto capture (toggle on this page):\n• When enabled, the app follows drag-select and double-click word select in other programs to read highlighted text.\n• UI Automation and clipboard-based detection are not used.\n\nTurn off auto capture if you only want hotkey-based capture.';

  @override
  String get captureDlgImageCaptureTitle => 'Image / region OCR';

  @override
  String get captureDlgImageCaptureBody =>
      'Manual:\n• Press Ctrl+Shift+X (global hotkey) or use the in-app shortcut when this window is focused.\n• A fullscreen selector appears: drag a rectangle over the screen area you want to OCR, then confirm.\n\nThis flow always runs on demand; it is not tied to auto capture.';

  @override
  String get captureDlgTipsTitle => 'Capture tips';

  @override
  String get captureDlgTipsBody =>
      'Use auto-capture for quick lookup. Turn it off when writing for long periods to avoid clipboard interference.';

  @override
  String get captureHotkeyDlgTitle => 'Press new hotkey';

  @override
  String get captureHotkeyDlgHintInitial =>
      'Press Ctrl+Shift+<letter or number>';

  @override
  String get captureHotkeyDlgHintRetry => 'Need Ctrl+Shift + letter/number';

  @override
  String get vocabPageSubtitle => 'Search, filter, and manage your deck';

  @override
  String get vocabStudySelected => 'Study selected';

  @override
  String get vocabStudyFiltered => 'Study filtered';

  @override
  String get vocabSelectBeforeStudy => 'Please select words before studying.';

  @override
  String get vocabNoMatchFilters => 'No words match the current filters.';

  @override
  String get vocabTipsTitle => 'Vocabulary tips';

  @override
  String get vocabTipsBody =>
      'Filter by language and source before bulk actions to clean up faster and avoid editing the wrong items.';

  @override
  String get vocabDeleteTitle => 'Delete saved words?';

  @override
  String get vocabDeleteBodyOne =>
      'This will permanently delete the selected saved word.';

  @override
  String vocabDeleteBodyMany(int count) {
    return 'This will permanently delete $count selected saved words.';
  }

  @override
  String get vocabSearchPlaceholder => 'Search term, meaning, or tag';

  @override
  String get vocabAllLanguages => 'All languages';

  @override
  String get vocabAllSources => 'All sources';

  @override
  String get vocabAllTags => 'All tags';

  @override
  String get vocabFilterActive => 'Active';

  @override
  String get vocabFilterArchived => 'Archived';

  @override
  String get vocabFilterAll => 'All';

  @override
  String get vocabClearFilters => 'Clear filters';

  @override
  String get vocabTtsSectionTitle => 'Google Cloud text-to-speech';

  @override
  String get vocabTtsSectionBody =>
      'Synthesize speech from long text (split automatically within Cloud TTS limits). Requires a Text-to-Speech API key with the Cloud Text-to-Speech API enabled.';

  @override
  String get vocabTtsApiKeyPlaceholder =>
      'API key (stored securely on this device)';

  @override
  String get vocabTtsSaveApiKey => 'Save key';

  @override
  String get vocabTtsApiKeySaved => 'API key saved.';

  @override
  String get vocabTtsApiKeyFromBuild =>
      'Using API key from app build configuration.';

  @override
  String get vocabTtsTextPlaceholder =>
      'Paste or type text to read aloud (long passages supported)';

  @override
  String vocabTtsStats(int bytes, int segments) {
    return 'UTF-8 size: $bytes · request segments: $segments';
  }

  @override
  String get vocabTtsVoiceLabel => 'Voice';

  @override
  String get vocabTtsVoiceCustom => 'Custom voice…';

  @override
  String get vocabTtsCustomVoicePlaceholder =>
      'Voice name (e.g. en-US-Neural2-J)';

  @override
  String get vocabTtsCustomLangPlaceholder => 'languageCode (e.g. en-US)';

  @override
  String get vocabTtsSpeakingRate => 'Speaking rate';

  @override
  String get vocabTtsGeneratePlay => 'Synthesize & play';

  @override
  String get vocabTtsSaveMp3 => 'Save MP3…';

  @override
  String get vocabTtsNeedApiKey =>
      'Add your Google Cloud Text-to-Speech API key first.';

  @override
  String get vocabTtsNeedText => 'Enter some text to synthesize.';

  @override
  String get vocabTtsVoiceInvalid => 'Enter both voice name and language code.';

  @override
  String vocabTtsError(String message) {
    return '$message';
  }

  @override
  String vocabTtsSavedFile(String path) {
    return 'Saved audio: $path';
  }

  @override
  String get vocabEmptyLibrary => 'No vocabulary yet.';

  @override
  String get vocabColTermMeaning => 'Term / Meaning';

  @override
  String get vocabColSource => 'Source';

  @override
  String get vocabColTags => 'Tags';

  @override
  String get vocabColNextReview => 'Next review';

  @override
  String get vocabCtxMenuTag => 'Tag';

  @override
  String get vocabCtxMenuArchive => 'Archive';

  @override
  String get vocabCtxMenuResetSrs => 'Reset SRS';

  @override
  String get vocabCtxMenuDelete => 'Delete';

  @override
  String get bulkTagCreateTitle => 'Create tag';

  @override
  String get bulkTagCreatePlaceholder => 'Enter a new tag';

  @override
  String get bulkTagRenameTitle => 'Rename tag';

  @override
  String get bulkTagRenamePlaceholder => 'Enter a tag';

  @override
  String get bulkTagDeleteTitle => 'Delete tag';

  @override
  String bulkTagDeleteBody(String tag) {
    return 'Remove \"$tag\" from all saved words?';
  }

  @override
  String get bulkTagFilterPlaceholder => 'Filter tags';

  @override
  String get bulkTagClearSelections => 'Clear tag selections';

  @override
  String get bulkTagRename => 'Rename';

  @override
  String get bulkTagDelete => 'Delete';

  @override
  String get bulkTagApply => 'Apply';

  @override
  String get bulkTagNewBadge => 'New';

  @override
  String get bulkTagPanelTitle => 'Bulk tags';

  @override
  String get bulkTagEmptyLibrary => 'No tags in library yet.';

  @override
  String get bulkTagNoMatchFilter => 'No tags match filter.';

  @override
  String get bulkTagValidationEmpty => 'Tag name cannot be empty.';

  @override
  String get bulkTagValidationDuplicate => 'Tag already exists.';

  @override
  String get bulkTagManageTooltip => 'Manage tag';

  @override
  String get commonCreate => 'Create';

  @override
  String get customStudyTitle => 'Custom study';

  @override
  String customStudyEntriesCount(int count) {
    return 'Entries matching your selection: $count';
  }

  @override
  String get customStudyMaxLabel => 'Max cards (leave empty for all)';

  @override
  String get customStudyMaxPlaceholder => 'e.g. 50';

  @override
  String get customStudyRandomOrder => 'Random order';

  @override
  String get customStudyCram => 'Cram (do not save scheduling)';

  @override
  String get customStudyStart => 'Start';

  @override
  String get reviewSrsTitle => 'SRS Review';

  @override
  String get reviewCramBadge => 'Cram';

  @override
  String reviewQueueCounts(int newCount, int learningCount, int reviewCount) {
    return 'New $newCount · Learning $learningCount · Review $reviewCount';
  }

  @override
  String get reviewAutoAudio => 'Auto-audio';

  @override
  String get reviewAllLanguages => 'All languages';

  @override
  String get reviewLanguageFilterTooltip => 'Language filter';

  @override
  String get reviewMixedProOnly =>
      'Mixed mode is a Pro feature. Activate Pro in About.';

  @override
  String get reviewMixedEnable => 'Enable mixed';

  @override
  String get reviewMixedLocked => 'Mixed (Pro)';

  @override
  String get reviewBasicMode => 'Basic mode';

  @override
  String get reviewExitStudy => 'Exit study';

  @override
  String get reviewNoCardsDue => 'No cards due right now.';

  @override
  String get reviewFinishing => 'Finishing review session…';

  @override
  String get reviewCompleted => 'Review completed.';

  @override
  String reviewReviewsToday(int used, int limit) {
    return 'Reviews today: $used/$limit';
  }

  @override
  String get reviewTipsTitle => 'Review tips';

  @override
  String get reviewTipsBody =>
      'Enter to flip/check, 1-4 to grade card recall, Ctrl+Enter to replay audio, R to replay.';

  @override
  String get reviewGradeHintForward =>
      'Enter: Flip | 1-4: Grade | Ctrl+Enter: Audio | R: Replay';

  @override
  String get reviewGradeHintReverse =>
      'Enter: Check | 1-4: Grade | Ctrl+Enter: Audio | R: Replay';

  @override
  String get reviewAudioFailed => 'Could not play audio.';

  @override
  String get reviewPlayTerm => 'Play term';

  @override
  String get reviewPlayAudio => 'Play audio';

  @override
  String get reviewMeaning => 'Meaning';

  @override
  String get reviewListenType => 'Listen & type';

  @override
  String get reviewListenInstructions =>
      'Play audio and type the original word.';

  @override
  String get reviewTypeOriginalPlaceholder => 'Type original word';

  @override
  String get reviewCheckAnswer => 'Check answer (Enter)';

  @override
  String get reviewCorrect => 'Correct';

  @override
  String get reviewIncorrect => 'Incorrect';

  @override
  String get reviewYourAnswer => 'Your answer:';

  @override
  String get reviewExpected => 'Expected:';

  @override
  String get reviewAnswerEmptyMarker => '(empty)';

  @override
  String get reviewGradeAgain => 'Again (1)';

  @override
  String get reviewGradeHard => 'Hard (2)';

  @override
  String get reviewGradeGood => 'Good (3)';

  @override
  String get reviewGradeEasy => 'Easy (4)';

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
    return 'Words just reviewed ($count)';
  }

  @override
  String get reviewSummaryClose => 'Close';

  @override
  String get reviewSummaryTitle => 'Session summary';

  @override
  String reviewSummaryGreatJob(String name) {
    return 'Great job, $name!';
  }

  @override
  String get reviewSummaryEncourage => 'You finished today’s study goal.';

  @override
  String get reviewSummaryStatReviewed => 'Reviewed';

  @override
  String get reviewSummaryStatMastered => 'Remembered well';

  @override
  String get reviewSummaryStatTime => 'Time';

  @override
  String get reviewSummaryBackDashboard => 'Back to Dashboard';

  @override
  String get reviewSummarySeeWords => 'See reviewed words';

  @override
  String get reviewSummaryCloudSyncing => 'Syncing cloud data…';

  @override
  String get reviewSummaryCloudOk => 'Cloud sync succeeded';

  @override
  String get reviewSummaryCloudFail => 'Cloud sync failed';

  @override
  String get reviewSummaryYou => 'You';

  @override
  String reviewDurSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String reviewDurMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String reviewDurMinutesSeconds(int minutes, int seconds) {
    return '${minutes}m ${seconds}s';
  }

  @override
  String reviewDurHours(int hours) {
    return '${hours}h';
  }

  @override
  String reviewDurHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get captureSavePhrase => 'Save phrase';

  @override
  String get captureSaveLine => 'Save line';

  @override
  String get captureWholeLine => 'Whole line';

  @override
  String get captureListenSource => 'Listen to source';

  @override
  String get captureNoTextDetected => 'No text detected';

  @override
  String get captureAddTagLabel => 'Add tag';

  @override
  String get captureTagHint => 'Type tag';

  @override
  String get captureAutoRecentTag => 'Auto-fill recent tag';

  @override
  String get captureNoRecentTagsYet =>
      'No recent tags yet — save an entry with a tag to use this.';

  @override
  String get captureSavedToast => 'Saved ✓';

  @override
  String captureDailySaveLimitReached(int limit) {
    return 'You\'ve reached today\'s save limit ($limit saves per day). Upgrade to Pro for unlimited saves.';
  }

  @override
  String captureDailyTranslateLimitReached(int limit) {
    return 'You\'ve reached today\'s translation limit ($limit calls per day). Upgrade to Pro for unlimited translations.';
  }

  @override
  String get settingsTagManagerEmpty => 'No tags yet.';

  @override
  String get meaningTranslating => 'Translating…';

  @override
  String get meaningNoTranslationYet => 'No translation yet.';

  @override
  String get meaningDictHeading => 'Definition (English)';

  @override
  String get meaningFieldLabel => 'Meaning';

  @override
  String get meaningFieldHint => 'Edit translation';

  @override
  String get meaningPlayPronunciation => 'Play pronunciation';

  @override
  String get meaningPlay => 'Play';

  @override
  String get meaningPause => 'Pause';

  @override
  String get meaningPhraseMarker => '(PHRASE)';

  @override
  String get settingsReviewAudioSection => 'Review audio';

  @override
  String get settingsAutoPlayAudioTitle => 'Auto-play audio on new card';

  @override
  String get settingsRememberTagTitle => 'Remember last tag when adding words';

  @override
  String get settingsLocalBackupTitle => 'Local backup';

  @override
  String get settingsBackupNowJson => 'Backup now (JSON)';

  @override
  String get settingsImportBackup => 'Import backup (.db / .json)';

  @override
  String get settingsBackupFootnote =>
      'Use signed JSON from this app or a .db / .json vocabulary backup.';

  @override
  String get settingsManageTagsTitle => 'Manage tags';

  @override
  String get settingsManageTagsSubtitle =>
      'Rename/delete tags across saved words.';

  @override
  String get settingsReplaceVocabTitle => 'Replace local vocabulary?';

  @override
  String get settingsReplaceVocabBody =>
      'All saved words on this device will be replaced by the backup. This cannot be undone.';

  @override
  String get settingsChooseFile => 'Choose file';

  @override
  String get settingsImporting => 'Importing backup…';

  @override
  String settingsImportedCount(int count, String kind) {
    return 'Imported $count items ($kind).';
  }

  @override
  String get settingsExportCancelled => 'Export cancelled';

  @override
  String settingsSavedPath(String path) {
    return 'Saved: $path';
  }

  @override
  String settingsExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String settingsImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String settingsLanguageLoadError(String error) {
    return 'Language settings error: $error';
  }

  @override
  String commonErrorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get dashLearnerPickerLabel => 'Who is learning?';

  @override
  String get dashLearnerPickerNewButton => 'Create new';

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
