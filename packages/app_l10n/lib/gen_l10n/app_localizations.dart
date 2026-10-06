import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('vi'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'FormyCareer'**
  String get appTitle;

  /// No description provided for @navDesktop.
  ///
  /// In en, this message translates to:
  /// **'Desktop'**
  String get navDesktop;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navCapture.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get navCapture;

  /// No description provided for @navReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get navReview;

  /// No description provided for @navVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get navVocabulary;

  /// No description provided for @navGuides.
  ///
  /// In en, this message translates to:
  /// **'Guides'**
  String get navGuides;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get navAbout;

  /// No description provided for @navWords.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get navWords;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Language and local preferences'**
  String get settingsSubtitle;

  /// No description provided for @uiLanguageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Interface language'**
  String get uiLanguageSectionTitle;

  /// No description provided for @uiLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get uiLanguageLabel;

  /// No description provided for @uiLanguageDescription.
  ///
  /// In en, this message translates to:
  /// **'Controls menus and settings text. Translation explanations still follow “Native language” below.'**
  String get uiLanguageDescription;

  /// No description provided for @uiLocaleSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get uiLocaleSystem;

  /// No description provided for @uiLocaleEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get uiLocaleEnglish;

  /// No description provided for @uiLocaleVietnamese.
  ///
  /// In en, this message translates to:
  /// **'Tiếng Việt'**
  String get uiLocaleVietnamese;

  /// No description provided for @uiLocaleJapanese.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get uiLocaleJapanese;

  /// No description provided for @uiLocaleChinese.
  ///
  /// In en, this message translates to:
  /// **'中文（简体）'**
  String get uiLocaleChinese;

  /// No description provided for @uiLocaleKorean.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get uiLocaleKorean;

  /// No description provided for @settingsTextScaleSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get settingsTextScaleSectionTitle;

  /// No description provided for @settingsTextScaleLabel.
  ///
  /// In en, this message translates to:
  /// **'Interface text scale'**
  String get settingsTextScaleLabel;

  /// No description provided for @settingsTextScaleDescription.
  ///
  /// In en, this message translates to:
  /// **'Adjusts text in the desktop window and capture popup. This stacks with Windows display scaling.'**
  String get settingsTextScaleDescription;

  /// No description provided for @settingsTextScalePercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String settingsTextScalePercent(int percent);

  /// No description provided for @backupSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Local backup & restore'**
  String get backupSectionTitle;

  /// No description provided for @backupSectionIntro.
  ///
  /// In en, this message translates to:
  /// **'Backup and restore data locally.'**
  String get backupSectionIntro;

  /// No description provided for @defaultBackupFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Default backup folder'**
  String get defaultBackupFolderTitle;

  /// No description provided for @defaultBackupFolderDescription.
  ///
  /// In en, this message translates to:
  /// **'Used for scheduled automatic backups. The built-in default is a folder under your Documents directory. “Backup now” below can still save to any folder you choose.'**
  String get defaultBackupFolderDescription;

  /// No description provided for @resolvingPath.
  ///
  /// In en, this message translates to:
  /// **'Resolving path…'**
  String get resolvingPath;

  /// No description provided for @currentPathPrefix.
  ///
  /// In en, this message translates to:
  /// **'Current: {path}'**
  String currentPathPrefix(String path);

  /// No description provided for @confirmUseFolder.
  ///
  /// In en, this message translates to:
  /// **'Use this folder'**
  String get confirmUseFolder;

  /// No description provided for @changeDefaultFolder.
  ///
  /// In en, this message translates to:
  /// **'Change default folder'**
  String get changeDefaultFolder;

  /// No description provided for @useAppDefaultFolder.
  ///
  /// In en, this message translates to:
  /// **'Use app default folder'**
  String get useAppDefaultFolder;

  /// No description provided for @couldNotUseFolder.
  ///
  /// In en, this message translates to:
  /// **'Could not use this folder: {error}'**
  String couldNotUseFolder(String error);

  /// No description provided for @defaultBackupFolderSet.
  ///
  /// In en, this message translates to:
  /// **'Default backup folder: {path}'**
  String defaultBackupFolderSet(String path);

  /// No description provided for @usingAppDefaultAgain.
  ///
  /// In en, this message translates to:
  /// **'Using the app default folder again.'**
  String get usingAppDefaultAgain;

  /// No description provided for @automaticBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic backup'**
  String get automaticBackupTitle;

  /// No description provided for @automaticBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Saves a copy of your library on a schedule to the default folder above.'**
  String get automaticBackupDescription;

  /// No description provided for @repeatEveryLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat every'**
  String get repeatEveryLabel;

  /// No description provided for @backupNow.
  ///
  /// In en, this message translates to:
  /// **'Backup now'**
  String get backupNow;

  /// No description provided for @restoreFromFile.
  ///
  /// In en, this message translates to:
  /// **'Restore from file'**
  String get restoreFromFile;

  /// No description provided for @saveBackupHere.
  ///
  /// In en, this message translates to:
  /// **'Save backup here'**
  String get saveBackupHere;

  /// No description provided for @restoreFromThisFile.
  ///
  /// In en, this message translates to:
  /// **'Restore from this file'**
  String get restoreFromThisFile;

  /// No description provided for @backupFilesFilter.
  ///
  /// In en, this message translates to:
  /// **'Backup files'**
  String get backupFilesFilter;

  /// No description provided for @backupCreated.
  ///
  /// In en, this message translates to:
  /// **'Backup created: {path}'**
  String backupCreated(String path);

  /// No description provided for @restoredFrom.
  ///
  /// In en, this message translates to:
  /// **'Restored from: {restored}'**
  String restoredFrom(String restored);

  /// No description provided for @backupFooterNote.
  ///
  /// In en, this message translates to:
  /// **'“Backup now” lets you pick any folder. Automatic backups always use the default folder above. For restore, choose a .db or .json file.'**
  String get backupFooterNote;

  /// No description provided for @backupIntervalHourly.
  ///
  /// In en, this message translates to:
  /// **'Every hour'**
  String get backupIntervalHourly;

  /// No description provided for @backupInterval6h.
  ///
  /// In en, this message translates to:
  /// **'Every 6 hours'**
  String get backupInterval6h;

  /// No description provided for @backupInterval12h.
  ///
  /// In en, this message translates to:
  /// **'Every 12 hours'**
  String get backupInterval12h;

  /// No description provided for @backupIntervalDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get backupIntervalDaily;

  /// No description provided for @backupInterval2days.
  ///
  /// In en, this message translates to:
  /// **'Every 2 days'**
  String get backupInterval2days;

  /// No description provided for @backupIntervalWeekly.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get backupIntervalWeekly;

  /// No description provided for @backupIntervalEveryHours.
  ///
  /// In en, this message translates to:
  /// **'Every {hours} hours'**
  String backupIntervalEveryHours(int hours);

  /// No description provided for @translationSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translationSectionTitle;

  /// No description provided for @nativeLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Native language'**
  String get nativeLanguageLabel;

  /// No description provided for @translationNativeHelp.
  ///
  /// In en, this message translates to:
  /// **'Translations and UI explanations are shown in this language.'**
  String get translationNativeHelp;

  /// No description provided for @translationEngineHelp.
  ///
  /// In en, this message translates to:
  /// **'Translation engine is selected automatically for fastest response.'**
  String get translationEngineHelp;

  /// No description provided for @backupErrNoBackupFile.
  ///
  /// In en, this message translates to:
  /// **'No backup file found to restore.'**
  String get backupErrNoBackupFile;

  /// No description provided for @backupErrSqliteMissing.
  ///
  /// In en, this message translates to:
  /// **'SQLite backup file was not found.'**
  String get backupErrSqliteMissing;

  /// No description provided for @backupErrFileMissing.
  ///
  /// In en, this message translates to:
  /// **'The selected backup file was not found.'**
  String get backupErrFileMissing;

  /// No description provided for @backupErrUnsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'Unsupported backup format. Choose a .db or .json file.'**
  String get backupErrUnsupportedFormat;

  /// No description provided for @backupErrInvalidCorrupt.
  ///
  /// In en, this message translates to:
  /// **'The backup file is invalid or corrupted.'**
  String get backupErrInvalidCorrupt;

  /// No description provided for @backupErrGeneric.
  ///
  /// In en, this message translates to:
  /// **'Backup or restore failed. Details: {error}'**
  String backupErrGeneric(String error);

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

  /// No description provided for @commonTips.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get commonTips;

  /// No description provided for @commonGranted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get commonGranted;

  /// No description provided for @commonMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get commonMissing;

  /// No description provided for @commonChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get commonChecking;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get commonStudy;

  /// No description provided for @commonTag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get commonTag;

  /// No description provided for @commonArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get commonArchive;

  /// No description provided for @commonResetSrs.
  ///
  /// In en, this message translates to:
  /// **'Reset SRS'**
  String get commonResetSrs;

  /// No description provided for @commonActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get commonActivate;

  /// No description provided for @cmdCancelEsc.
  ///
  /// In en, this message translates to:
  /// **'Cancel (Esc)'**
  String get cmdCancelEsc;

  /// No description provided for @cmdOneItemSelected.
  ///
  /// In en, this message translates to:
  /// **'1 item selected'**
  String get cmdOneItemSelected;

  /// No description provided for @cmdManyItemsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} items selected'**
  String cmdManyItemsSelected(int count);

  /// No description provided for @dashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Study snapshot, insights, and quick navigation'**
  String get dashSubtitle;

  /// No description provided for @dashCouldNotLoadVocab.
  ///
  /// In en, this message translates to:
  /// **'Could not load vocabulary: {error}'**
  String dashCouldNotLoadVocab(String error);

  /// No description provided for @dashHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Your study hub'**
  String get dashHeroTitle;

  /// No description provided for @dashHeroStatsLine.
  ///
  /// In en, this message translates to:
  /// **'{dueNow} ready now · {active} cards in active deck · {newCount} new'**
  String dashHeroStatsLine(int dueNow, int active, int newCount);

  /// No description provided for @dashHeroShareCaption.
  ///
  /// In en, this message translates to:
  /// **'Share of active deck due for review'**
  String get dashHeroShareCaption;

  /// No description provided for @dashHeroPercentDue.
  ///
  /// In en, this message translates to:
  /// **'{percent}% due among active cards'**
  String dashHeroPercentDue(int percent);

  /// No description provided for @dashStatDueNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Due now'**
  String get dashStatDueNowTitle;

  /// No description provided for @dashStatDueNowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ready for SRS review'**
  String get dashStatDueNowSubtitle;

  /// No description provided for @dashStatActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Active deck'**
  String get dashStatActiveTitle;

  /// No description provided for @dashStatActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Non-archived entries'**
  String get dashStatActiveSubtitle;

  /// No description provided for @dashStatNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get dashStatNewTitle;

  /// No description provided for @dashStatNewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Never reviewed'**
  String get dashStatNewSubtitle;

  /// No description provided for @dashStatArchivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get dashStatArchivedTitle;

  /// No description provided for @dashStatArchivedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paused from queue'**
  String get dashStatArchivedSubtitle;

  /// No description provided for @dashInsightUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming reviews'**
  String get dashInsightUpcoming;

  /// No description provided for @dashInsightDeckComposition.
  ///
  /// In en, this message translates to:
  /// **'Deck composition'**
  String get dashInsightDeckComposition;

  /// No description provided for @dashInsightByLanguage.
  ///
  /// In en, this message translates to:
  /// **'By language'**
  String get dashInsightByLanguage;

  /// No description provided for @dashInsightPopularTags.
  ///
  /// In en, this message translates to:
  /// **'Popular tags'**
  String get dashInsightPopularTags;

  /// No description provided for @dashEmptyLangPairs.
  ///
  /// In en, this message translates to:
  /// **'No language pairs yet.'**
  String get dashEmptyLangPairs;

  /// No description provided for @dashEmptyTags.
  ///
  /// In en, this message translates to:
  /// **'No tags yet — add tags when capturing.'**
  String get dashEmptyTags;

  /// No description provided for @dashDeckCompositionEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add vocabulary to see composition.'**
  String get dashDeckCompositionEmpty;

  /// No description provided for @dashLegendNewCount.
  ///
  /// In en, this message translates to:
  /// **'New · {count}'**
  String dashLegendNewCount(int count);

  /// No description provided for @dashLegendLearningCount.
  ///
  /// In en, this message translates to:
  /// **'Learning (1–6 reviews) · {count}'**
  String dashLegendLearningCount(int count);

  /// No description provided for @dashLegendEstablishedCount.
  ///
  /// In en, this message translates to:
  /// **'Established (>6 reviews) · {count}'**
  String dashLegendEstablishedCount(int count);

  /// No description provided for @dashDueNowRow.
  ///
  /// In en, this message translates to:
  /// **'Due now or overdue'**
  String get dashDueNowRow;

  /// No description provided for @dashDueWeekRow.
  ///
  /// In en, this message translates to:
  /// **'Due in the next 7 days (after today)'**
  String get dashDueWeekRow;

  /// No description provided for @dashDueLaterRow.
  ///
  /// In en, this message translates to:
  /// **'Due later'**
  String get dashDueLaterRow;

  /// No description provided for @dashQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get dashQuickActions;

  /// No description provided for @dashStartReview.
  ///
  /// In en, this message translates to:
  /// **'Start review'**
  String get dashStartReview;

  /// No description provided for @dashOpenVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Open vocabulary'**
  String get dashOpenVocabulary;

  /// No description provided for @dashCapture.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get dashCapture;

  /// No description provided for @dashNothingDueHint.
  ///
  /// In en, this message translates to:
  /// **'Nothing due right now. You can still review ahead from the Review tab.'**
  String get dashNothingDueHint;

  /// No description provided for @mobileDashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Study snapshot'**
  String get mobileDashSubtitle;

  /// No description provided for @mobileDashLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load vocabulary.\n{error}'**
  String mobileDashLoadFailed(String error);

  /// No description provided for @mobileStatDueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'SRS queue'**
  String get mobileStatDueSubtitle;

  /// No description provided for @mobileStatActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'In deck'**
  String get mobileStatActiveSubtitle;

  /// No description provided for @mobileStatNewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Not reviewed'**
  String get mobileStatNewSubtitle;

  /// No description provided for @mobileStatArchivedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get mobileStatArchivedSubtitle;

  /// No description provided for @mobileGoReview.
  ///
  /// In en, this message translates to:
  /// **'Go to Review'**
  String get mobileGoReview;

  /// No description provided for @mobileGoWords.
  ///
  /// In en, this message translates to:
  /// **'Open Words'**
  String get mobileGoWords;

  /// No description provided for @guidesPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tips for capture, review, vocabulary, and everyday use.'**
  String get guidesPageSubtitle;

  /// No description provided for @guidesIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Getting around'**
  String get guidesIntroTitle;

  /// No description provided for @guidesIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Use the tabs on the left: Dashboard for your learning snapshot; Capture to grab text from other apps; Review for SRS sessions; Vocabulary to browse and organize cards; Guides for tips like these; Settings for language, backups, and hotkeys; About for versions, Pro, and support.'**
  String get guidesIntroBody;

  /// No description provided for @guidesCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get guidesCaptureTitle;

  /// No description provided for @guidesCaptureBody.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts (when registered): typically Ctrl+Shift+D for selected text and Ctrl+Shift+X for region OCR—see the Capture tab if global registration fails. Turn on Auto capture to follow mouse text selection in other apps, or capture from the Capture tab. In the popup, drag-select in the source field to translate only a phrase; save adds the card to your library.'**
  String get guidesCaptureBody;

  /// No description provided for @guidesReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review (SRS)'**
  String get guidesReviewTitle;

  /// No description provided for @guidesReviewBody.
  ///
  /// In en, this message translates to:
  /// **'The Review tab runs spaced repetition. Grade each card honestly so intervals stay meaningful. Pro unlocks mixed review (forward, reverse meaning, and reverse audio in one session).'**
  String get guidesReviewBody;

  /// No description provided for @guidesVocabTitle.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get guidesVocabTitle;

  /// No description provided for @guidesVocabBody.
  ///
  /// In en, this message translates to:
  /// **'Search, tag, archive, and edit entries in the Vocabulary tab. Sync and export options depend on your account and backup settings under Settings.'**
  String get guidesVocabBody;

  /// No description provided for @guidesSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings & backup'**
  String get guidesSettingsTitle;

  /// No description provided for @guidesSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Set your native language for translations, adjust text scale, configure the auto-capture toggle hotkey, and choose local backup folders. Keeping backups protects you when reinstalling or moving to a new PC.'**
  String get guidesSettingsBody;

  /// No description provided for @guidesProTitle.
  ///
  /// In en, this message translates to:
  /// **'Free and Pro'**
  String get guidesProTitle;

  /// No description provided for @guidesProBody.
  ///
  /// In en, this message translates to:
  /// **'Free tier may apply daily limits on desktop capture saves and capture-popup translation requests (phrases served from cache usually do not count). Pro removes banner ads on desktop, unlocks mixed review and unlimited SRS grades per day, and removes those desktop capture limits. Open the About tab for update checks, activation, and a link to buy Pro.'**
  String get guidesProBody;

  /// No description provided for @aboutPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App info and licensing'**
  String get aboutPageSubtitle;

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'A cross-platform language learning workspace for capture, review, and vocabulary management.'**
  String get aboutTagline;

  /// No description provided for @aboutVersionPrefix.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersionPrefix(String version);

  /// No description provided for @aboutUpdatesSection.
  ///
  /// In en, this message translates to:
  /// **'Updates & Pro'**
  String get aboutUpdatesSection;

  /// No description provided for @aboutLatestVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Latest version: {version}'**
  String aboutLatestVersionLabel(String version);

  /// No description provided for @aboutUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available for this app.'**
  String get aboutUpdateAvailable;

  /// No description provided for @aboutUsingLatest.
  ///
  /// In en, this message translates to:
  /// **'You are using the latest version.'**
  String get aboutUsingLatest;

  /// No description provided for @aboutReleaseNotesPrefix.
  ///
  /// In en, this message translates to:
  /// **'Release notes: {notes}'**
  String aboutReleaseNotesPrefix(String notes);

  /// No description provided for @aboutMinVersionWarning.
  ///
  /// In en, this message translates to:
  /// **'This version is below minimum supported version.'**
  String get aboutMinVersionWarning;

  /// No description provided for @aboutPlanPro.
  ///
  /// In en, this message translates to:
  /// **'Current plan: Pro'**
  String get aboutPlanPro;

  /// No description provided for @aboutPlanFree.
  ///
  /// In en, this message translates to:
  /// **'Current plan: Free'**
  String get aboutPlanFree;

  /// No description provided for @aboutProKeyInstructions.
  ///
  /// In en, this message translates to:
  /// **'Use the license key sent by Lemon Squeezy after payment. See “What Pro unlocks” below for included benefits.'**
  String get aboutProKeyInstructions;

  /// No description provided for @aboutCheckUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check updates'**
  String get aboutCheckUpdates;

  /// No description provided for @aboutCheckingUpdates.
  ///
  /// In en, this message translates to:
  /// **'Checking updates…'**
  String get aboutCheckingUpdates;

  /// No description provided for @aboutDownloadLatest.
  ///
  /// In en, this message translates to:
  /// **'Download latest'**
  String get aboutDownloadLatest;

  /// No description provided for @aboutVisitProWebsite.
  ///
  /// In en, this message translates to:
  /// **'Visit website to Buy Pro'**
  String get aboutVisitProWebsite;

  /// No description provided for @aboutActivating.
  ///
  /// In en, this message translates to:
  /// **'Activating…'**
  String get aboutActivating;

  /// No description provided for @aboutActivatePro.
  ///
  /// In en, this message translates to:
  /// **'Activate Pro'**
  String get aboutActivatePro;

  /// No description provided for @aboutActivateProTitle.
  ///
  /// In en, this message translates to:
  /// **'Activate Pro'**
  String get aboutActivateProTitle;

  /// No description provided for @aboutActivateProPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Paste license key from your Lemon Squeezy email'**
  String get aboutActivateProPlaceholder;

  /// No description provided for @aboutUpdateCheckDone.
  ///
  /// In en, this message translates to:
  /// **'Update check completed'**
  String get aboutUpdateCheckDone;

  /// No description provided for @aboutWhatProUnlocks.
  ///
  /// In en, this message translates to:
  /// **'What Pro unlocks'**
  String get aboutWhatProUnlocks;

  /// No description provided for @aboutOneLicense.
  ///
  /// In en, this message translates to:
  /// **'One license activates Pro on desktop and mobile.'**
  String get aboutOneLicense;

  /// No description provided for @aboutProBenefit1.
  ///
  /// In en, this message translates to:
  /// **'No banner ads on desktop when Pro is active.'**
  String get aboutProBenefit1;

  /// No description provided for @aboutProBenefit2.
  ///
  /// In en, this message translates to:
  /// **'Mixed review mode: combine forward, reverse meaning, and reverse audio in one session (Free uses basic forward-only review).'**
  String get aboutProBenefit2;

  /// No description provided for @aboutProBenefit3.
  ///
  /// In en, this message translates to:
  /// **'Unlimited SRS review grades per calendar day (Free: up to 100 per local calendar day).'**
  String get aboutProBenefit3;

  /// No description provided for @aboutProBenefit4.
  ///
  /// In en, this message translates to:
  /// **'Unlimited new vocabulary saves from desktop capture per calendar day (Free: daily limit).'**
  String get aboutProBenefit4;

  /// No description provided for @aboutProBenefit5.
  ///
  /// In en, this message translates to:
  /// **'Unlimited translation requests in the desktop capture popup per calendar day; phrases served from cache do not count toward the limit (Free: daily limit).'**
  String get aboutProBenefit5;

  /// No description provided for @aboutSupportLegal.
  ///
  /// In en, this message translates to:
  /// **'Support & Legal'**
  String get aboutSupportLegal;

  /// No description provided for @aboutSupportEmailPrefix.
  ///
  /// In en, this message translates to:
  /// **'Support email: {email}'**
  String aboutSupportEmailPrefix(String email);

  /// No description provided for @aboutCopySupportEmail.
  ///
  /// In en, this message translates to:
  /// **'Copy support email'**
  String get aboutCopySupportEmail;

  /// No description provided for @aboutOpenSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get aboutOpenSourceLicenses;

  /// No description provided for @aboutPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get aboutPrivacyPolicy;

  /// No description provided for @aboutTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get aboutTermsOfService;

  /// No description provided for @aboutSupportEmailCopied.
  ///
  /// In en, this message translates to:
  /// **'Support email copied'**
  String get aboutSupportEmailCopied;

  /// No description provided for @capturePageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-capture, shortcuts, and sync'**
  String get capturePageSubtitle;

  /// No description provided for @captureAutoCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto capture'**
  String get captureAutoCaptureTitle;

  /// No description provided for @captureAutoCaptureBody.
  ///
  /// In en, this message translates to:
  /// **'When on, follow text selection in other apps via the mouse path below. When off, use Ctrl+Shift+D only.'**
  String get captureAutoCaptureBody;

  /// No description provided for @captureAutoToggleShortcutLine.
  ///
  /// In en, this message translates to:
  /// **'Toggle quickly with {shortcut}.'**
  String captureAutoToggleShortcutLine(String shortcut);

  /// No description provided for @captureHotkeyToggleLabel.
  ///
  /// In en, this message translates to:
  /// **'Hotkey to toggle auto-capture'**
  String get captureHotkeyToggleLabel;

  /// No description provided for @capturePressNewShortcut.
  ///
  /// In en, this message translates to:
  /// **'Press new shortcut'**
  String get capturePressNewShortcut;

  /// No description provided for @captureAutoStatusOn.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get captureAutoStatusOn;

  /// No description provided for @captureAutoStatusOff.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get captureAutoStatusOff;

  /// No description provided for @captureAutoToast.
  ///
  /// In en, this message translates to:
  /// **'Auto capture: {status} ({hotkey})'**
  String captureAutoToast(String status, String hotkey);

  /// No description provided for @captureHotkeySetToast.
  ///
  /// In en, this message translates to:
  /// **'Auto-capture hotkey set to Ctrl+Shift+{key}'**
  String captureHotkeySetToast(String key);

  /// No description provided for @captureVisualGuidesCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Visual guides'**
  String get captureVisualGuidesCardTitle;

  /// No description provided for @captureVisualGuidesAutoHeading.
  ///
  /// In en, this message translates to:
  /// **'Auto capture flow'**
  String get captureVisualGuidesAutoHeading;

  /// No description provided for @captureVisualGuidesOcrHeading.
  ///
  /// In en, this message translates to:
  /// **'Region OCR'**
  String get captureVisualGuidesOcrHeading;

  /// No description provided for @captureVisualGuidesPopupRefineHint.
  ///
  /// In en, this message translates to:
  /// **'Tip: In the capture popup, drag-select part of the source text to translate just that phrase—you can refine focus more than once without closing the popup.'**
  String get captureVisualGuidesPopupRefineHint;

  /// No description provided for @captureAutoFlowSelectLabel.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get captureAutoFlowSelectLabel;

  /// No description provided for @captureAutoFlowPauseLabel.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get captureAutoFlowPauseLabel;

  /// No description provided for @captureAutoFlowPopupLabel.
  ///
  /// In en, this message translates to:
  /// **'Lookup'**
  String get captureAutoFlowPopupLabel;

  /// No description provided for @captureAutoFlowCaption.
  ///
  /// In en, this message translates to:
  /// **'Typical flow when auto capture is on (other apps only).'**
  String get captureAutoFlowCaption;

  /// No description provided for @captureAutoVisualGuideLink.
  ///
  /// In en, this message translates to:
  /// **'Step-by-step guide with pictures…'**
  String get captureAutoVisualGuideLink;

  /// No description provided for @captureDlgAutoCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'How auto capture works'**
  String get captureDlgAutoCaptureTitle;

  /// No description provided for @captureDlgAutoCaptureIntro.
  ///
  /// In en, this message translates to:
  /// **'With Auto capture enabled, Formycareer watches for mouse-based text selection in other programs—not when you interact inside Formycareer itself.\n\nThe pictures below outline what happens.'**
  String get captureDlgAutoCaptureIntro;

  /// No description provided for @captureDlgAutoCaptureStep1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Select text elsewhere'**
  String get captureDlgAutoCaptureStep1Title;

  /// No description provided for @captureDlgAutoCaptureStep1Body.
  ///
  /// In en, this message translates to:
  /// **'In a browser, PDF, or editor: drag across the words you want, or double-click a single word so it highlights.'**
  String get captureDlgAutoCaptureStep1Body;

  /// No description provided for @captureDlgAutoCaptureStep2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Release and wait briefly'**
  String get captureDlgAutoCaptureStep2Title;

  /// No description provided for @captureDlgAutoCaptureStep2Body.
  ///
  /// In en, this message translates to:
  /// **'Let the highlight settle. A very short pause helps the app detect a stable selection.'**
  String get captureDlgAutoCaptureStep2Body;

  /// No description provided for @captureDlgAutoCaptureStep3Title.
  ///
  /// In en, this message translates to:
  /// **'3. Popup opens'**
  String get captureDlgAutoCaptureStep3Title;

  /// No description provided for @captureDlgAutoCaptureStep3Body.
  ///
  /// In en, this message translates to:
  /// **'The capture popup appears with the passage so you can translate, save, or review. Drag-select any substring in the source area to translate only that phrase.'**
  String get captureDlgAutoCaptureStep3Body;

  /// No description provided for @captureDlgAutoCaptureStep4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Pick another span in the source'**
  String get captureDlgAutoCaptureStep4Title;

  /// No description provided for @captureDlgAutoCaptureStep4Body.
  ///
  /// In en, this message translates to:
  /// **'Whenever you want a different phrase, drag-select another span in the source area—the translation updates to match only that selection, and you can repeat this as many times as you like without closing the popup.'**
  String get captureDlgAutoCaptureStep4Body;

  /// No description provided for @captureDlgAutoCaptureSchemeCaption.
  ///
  /// In en, this message translates to:
  /// **'Schematic (not actual UI)'**
  String get captureDlgAutoCaptureSchemeCaption;

  /// No description provided for @captureOcrFlowHotkeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Shortcut'**
  String get captureOcrFlowHotkeyLabel;

  /// No description provided for @captureOcrFlowRegionLabel.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get captureOcrFlowRegionLabel;

  /// No description provided for @captureOcrFlowResultLabel.
  ///
  /// In en, this message translates to:
  /// **'OCR text'**
  String get captureOcrFlowResultLabel;

  /// No description provided for @captureOcrFlowCaption.
  ///
  /// In en, this message translates to:
  /// **'On-demand capture: Ctrl+Shift+X, then drag a rectangle over the text you want read.'**
  String get captureOcrFlowCaption;

  /// No description provided for @captureOcrVisualGuideLink.
  ///
  /// In en, this message translates to:
  /// **'OCR step-by-step with pictures…'**
  String get captureOcrVisualGuideLink;

  /// No description provided for @captureDlgOcrGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'How region OCR works'**
  String get captureDlgOcrGuideTitle;

  /// No description provided for @captureDlgOcrGuideIntro.
  ///
  /// In en, this message translates to:
  /// **'Region OCR reads text from a screen area you choose. It always runs when you trigger it—not tied to Auto capture.\n\nThe pictures below outline the flow.'**
  String get captureDlgOcrGuideIntro;

  /// No description provided for @captureDlgOcrStep1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Start region capture'**
  String get captureDlgOcrStep1Title;

  /// No description provided for @captureDlgOcrStep1Body.
  ///
  /// In en, this message translates to:
  /// **'Press Ctrl+Shift+X from another app, or use the in-app shortcut while this window is focused.'**
  String get captureDlgOcrStep1Body;

  /// No description provided for @captureDlgOcrStep2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Drag a rectangle'**
  String get captureDlgOcrStep2Title;

  /// No description provided for @captureDlgOcrStep2Body.
  ///
  /// In en, this message translates to:
  /// **'The screen dims. Drag a box around the words or image text you want; adjust until the area looks right.'**
  String get captureDlgOcrStep2Body;

  /// No description provided for @captureDlgOcrStep3Title.
  ///
  /// In en, this message translates to:
  /// **'3. Confirm and review'**
  String get captureDlgOcrStep3Title;

  /// No description provided for @captureDlgOcrStep3Body.
  ///
  /// In en, this message translates to:
  /// **'Confirm the selection. Recognized text opens in the capture popup so you can translate or save it.'**
  String get captureDlgOcrStep3Body;

  /// No description provided for @captureDlgOcrStep4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Pick another span in the source'**
  String get captureDlgOcrStep4Title;

  /// No description provided for @captureDlgOcrStep4Body.
  ///
  /// In en, this message translates to:
  /// **'Whenever you want a different phrase, drag-select another span in the source area—the translation updates to match only that selection, and you can repeat this as many times as you like without closing the popup.'**
  String get captureDlgOcrStep4Body;

  /// No description provided for @captureDlgOcrSchemeCaption.
  ///
  /// In en, this message translates to:
  /// **'Schematic (not actual UI)'**
  String get captureDlgOcrSchemeCaption;

  /// No description provided for @captureActiveBehaviorNote.
  ///
  /// In en, this message translates to:
  /// **'Active behavior: after you drag-select or double-click to select text in another app (outside Formycareer), the app reads that selection after a short pause. Your clipboard may change; avoid Auto capture while you must keep clipboard contents. SelectionHost (UIA) and clipboard listening are not used.'**
  String get captureActiveBehaviorNote;

  /// No description provided for @captureShortcutsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get captureShortcutsSectionTitle;

  /// No description provided for @captureShortcutsSectionBody.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts: Ctrl+Shift+D (text), Ctrl+Shift+X (region image). Tap a mode for instructions.'**
  String get captureShortcutsSectionBody;

  /// No description provided for @captureTextFromSelection.
  ///
  /// In en, this message translates to:
  /// **'Text from selection'**
  String get captureTextFromSelection;

  /// No description provided for @captureImageRegionOcr.
  ///
  /// In en, this message translates to:
  /// **'Image / region OCR'**
  String get captureImageRegionOcr;

  /// No description provided for @capturePermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get capturePermissionsTitle;

  /// No description provided for @captureAccessibilityGrantedLine.
  ///
  /// In en, this message translates to:
  /// **'Accessibility: {state}'**
  String captureAccessibilityGrantedLine(String state);

  /// No description provided for @captureScreenRecordingGrantedLine.
  ///
  /// In en, this message translates to:
  /// **'Screen Recording: {state}'**
  String captureScreenRecordingGrantedLine(String state);

  /// No description provided for @capturePermRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get capturePermRefresh;

  /// No description provided for @capturePermRequest.
  ///
  /// In en, this message translates to:
  /// **'Request missing permissions'**
  String get capturePermRequest;

  /// No description provided for @capturePermChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get capturePermChecking;

  /// No description provided for @capturePermAllGranted.
  ///
  /// In en, this message translates to:
  /// **'All capture permissions are granted.'**
  String get capturePermAllGranted;

  /// No description provided for @capturePermSomeMissing.
  ///
  /// In en, this message translates to:
  /// **'Some permissions are still missing. Enable them in System Settings > Privacy & Security.'**
  String get capturePermSomeMissing;

  /// No description provided for @captureHotkeyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Global hotkey unavailable. Use in-app Ctrl+Shift+D / Ctrl+Shift+X.'**
  String get captureHotkeyUnavailable;

  /// No description provided for @captureDlgTextCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Text capture'**
  String get captureDlgTextCaptureTitle;

  /// No description provided for @captureDlgTextCaptureBody.
  ///
  /// In en, this message translates to:
  /// **'Manual:\n• Press Ctrl+Shift+D from another app (or use the in-app shortcut when this window is focused).\n\nAuto capture (toggle on this page):\n• When enabled, the app follows drag-select and double-click word select in other programs to read highlighted text.\n• UI Automation and clipboard-based detection are not used.\n\nTurn off auto capture if you only want hotkey-based capture.'**
  String get captureDlgTextCaptureBody;

  /// No description provided for @captureDlgImageCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Image / region OCR'**
  String get captureDlgImageCaptureTitle;

  /// No description provided for @captureDlgImageCaptureBody.
  ///
  /// In en, this message translates to:
  /// **'Manual:\n• Press Ctrl+Shift+X (global hotkey) or use the in-app shortcut when this window is focused.\n• A fullscreen selector appears: drag a rectangle over the screen area you want to OCR, then confirm.\n\nThis flow always runs on demand; it is not tied to auto capture.'**
  String get captureDlgImageCaptureBody;

  /// No description provided for @captureDlgTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Capture tips'**
  String get captureDlgTipsTitle;

  /// No description provided for @captureDlgTipsBody.
  ///
  /// In en, this message translates to:
  /// **'Use auto-capture for quick lookup. Turn it off when writing for long periods to avoid clipboard interference.'**
  String get captureDlgTipsBody;

  /// No description provided for @captureHotkeyDlgTitle.
  ///
  /// In en, this message translates to:
  /// **'Press new hotkey'**
  String get captureHotkeyDlgTitle;

  /// No description provided for @captureHotkeyDlgHintInitial.
  ///
  /// In en, this message translates to:
  /// **'Press Ctrl+Shift+<letter or number>'**
  String get captureHotkeyDlgHintInitial;

  /// No description provided for @captureHotkeyDlgHintRetry.
  ///
  /// In en, this message translates to:
  /// **'Need Ctrl+Shift + letter/number'**
  String get captureHotkeyDlgHintRetry;

  /// No description provided for @vocabPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search, filter, and manage your deck'**
  String get vocabPageSubtitle;

  /// No description provided for @vocabStudySelected.
  ///
  /// In en, this message translates to:
  /// **'Study selected'**
  String get vocabStudySelected;

  /// No description provided for @vocabStudyFiltered.
  ///
  /// In en, this message translates to:
  /// **'Study filtered'**
  String get vocabStudyFiltered;

  /// No description provided for @vocabSelectBeforeStudy.
  ///
  /// In en, this message translates to:
  /// **'Please select words before studying.'**
  String get vocabSelectBeforeStudy;

  /// No description provided for @vocabNoMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No words match the current filters.'**
  String get vocabNoMatchFilters;

  /// No description provided for @vocabTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary tips'**
  String get vocabTipsTitle;

  /// No description provided for @vocabTipsBody.
  ///
  /// In en, this message translates to:
  /// **'Filter by language and source before bulk actions to clean up faster and avoid editing the wrong items.'**
  String get vocabTipsBody;

  /// No description provided for @vocabDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete saved words?'**
  String get vocabDeleteTitle;

  /// No description provided for @vocabDeleteBodyOne.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the selected saved word.'**
  String get vocabDeleteBodyOne;

  /// No description provided for @vocabDeleteBodyMany.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete {count} selected saved words.'**
  String vocabDeleteBodyMany(int count);

  /// No description provided for @vocabSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search term, meaning, or tag'**
  String get vocabSearchPlaceholder;

  /// No description provided for @vocabAllLanguages.
  ///
  /// In en, this message translates to:
  /// **'All languages'**
  String get vocabAllLanguages;

  /// No description provided for @vocabAllSources.
  ///
  /// In en, this message translates to:
  /// **'All sources'**
  String get vocabAllSources;

  /// No description provided for @vocabAllTags.
  ///
  /// In en, this message translates to:
  /// **'All tags'**
  String get vocabAllTags;

  /// No description provided for @vocabFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get vocabFilterActive;

  /// No description provided for @vocabFilterArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get vocabFilterArchived;

  /// No description provided for @vocabFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get vocabFilterAll;

  /// No description provided for @vocabClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get vocabClearFilters;

  /// No description provided for @vocabTtsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Google Cloud text-to-speech'**
  String get vocabTtsSectionTitle;

  /// No description provided for @vocabTtsSectionBody.
  ///
  /// In en, this message translates to:
  /// **'Synthesize speech from long text (split automatically within Cloud TTS limits). Requires a Text-to-Speech API key with the Cloud Text-to-Speech API enabled.'**
  String get vocabTtsSectionBody;

  /// No description provided for @vocabTtsApiKeyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'API key (stored securely on this device)'**
  String get vocabTtsApiKeyPlaceholder;

  /// No description provided for @vocabTtsSaveApiKey.
  ///
  /// In en, this message translates to:
  /// **'Save key'**
  String get vocabTtsSaveApiKey;

  /// No description provided for @vocabTtsApiKeySaved.
  ///
  /// In en, this message translates to:
  /// **'API key saved.'**
  String get vocabTtsApiKeySaved;

  /// No description provided for @vocabTtsApiKeyFromBuild.
  ///
  /// In en, this message translates to:
  /// **'Using API key from app build configuration.'**
  String get vocabTtsApiKeyFromBuild;

  /// No description provided for @vocabTtsTextPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Paste or type text to read aloud (long passages supported)'**
  String get vocabTtsTextPlaceholder;

  /// No description provided for @vocabTtsStats.
  ///
  /// In en, this message translates to:
  /// **'UTF-8 size: {bytes} · request segments: {segments}'**
  String vocabTtsStats(int bytes, int segments);

  /// No description provided for @vocabTtsVoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get vocabTtsVoiceLabel;

  /// No description provided for @vocabTtsVoiceCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom voice…'**
  String get vocabTtsVoiceCustom;

  /// No description provided for @vocabTtsCustomVoicePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Voice name (e.g. en-US-Neural2-J)'**
  String get vocabTtsCustomVoicePlaceholder;

  /// No description provided for @vocabTtsCustomLangPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'languageCode (e.g. en-US)'**
  String get vocabTtsCustomLangPlaceholder;

  /// No description provided for @vocabTtsSpeakingRate.
  ///
  /// In en, this message translates to:
  /// **'Speaking rate'**
  String get vocabTtsSpeakingRate;

  /// No description provided for @vocabTtsGeneratePlay.
  ///
  /// In en, this message translates to:
  /// **'Synthesize & play'**
  String get vocabTtsGeneratePlay;

  /// No description provided for @vocabTtsSaveMp3.
  ///
  /// In en, this message translates to:
  /// **'Save MP3…'**
  String get vocabTtsSaveMp3;

  /// No description provided for @vocabTtsNeedApiKey.
  ///
  /// In en, this message translates to:
  /// **'Add your Google Cloud Text-to-Speech API key first.'**
  String get vocabTtsNeedApiKey;

  /// No description provided for @vocabTtsNeedText.
  ///
  /// In en, this message translates to:
  /// **'Enter some text to synthesize.'**
  String get vocabTtsNeedText;

  /// No description provided for @vocabTtsVoiceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter both voice name and language code.'**
  String get vocabTtsVoiceInvalid;

  /// No description provided for @vocabTtsError.
  ///
  /// In en, this message translates to:
  /// **'{message}'**
  String vocabTtsError(String message);

  /// No description provided for @vocabTtsSavedFile.
  ///
  /// In en, this message translates to:
  /// **'Saved audio: {path}'**
  String vocabTtsSavedFile(String path);

  /// No description provided for @vocabEmptyLibrary.
  ///
  /// In en, this message translates to:
  /// **'No vocabulary yet.'**
  String get vocabEmptyLibrary;

  /// No description provided for @vocabColTermMeaning.
  ///
  /// In en, this message translates to:
  /// **'Term / Meaning'**
  String get vocabColTermMeaning;

  /// No description provided for @vocabColSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get vocabColSource;

  /// No description provided for @vocabColTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get vocabColTags;

  /// No description provided for @vocabColNextReview.
  ///
  /// In en, this message translates to:
  /// **'Next review'**
  String get vocabColNextReview;

  /// No description provided for @vocabCtxMenuTag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get vocabCtxMenuTag;

  /// No description provided for @vocabCtxMenuArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get vocabCtxMenuArchive;

  /// No description provided for @vocabCtxMenuResetSrs.
  ///
  /// In en, this message translates to:
  /// **'Reset SRS'**
  String get vocabCtxMenuResetSrs;

  /// No description provided for @vocabCtxMenuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get vocabCtxMenuDelete;

  /// No description provided for @bulkTagCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create tag'**
  String get bulkTagCreateTitle;

  /// No description provided for @bulkTagCreatePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter a new tag'**
  String get bulkTagCreatePlaceholder;

  /// No description provided for @bulkTagRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename tag'**
  String get bulkTagRenameTitle;

  /// No description provided for @bulkTagRenamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter a tag'**
  String get bulkTagRenamePlaceholder;

  /// No description provided for @bulkTagDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete tag'**
  String get bulkTagDeleteTitle;

  /// No description provided for @bulkTagDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{tag}\" from all saved words?'**
  String bulkTagDeleteBody(String tag);

  /// No description provided for @bulkTagFilterPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Filter tags'**
  String get bulkTagFilterPlaceholder;

  /// No description provided for @bulkTagClearSelections.
  ///
  /// In en, this message translates to:
  /// **'Clear tag selections'**
  String get bulkTagClearSelections;

  /// No description provided for @bulkTagRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get bulkTagRename;

  /// No description provided for @bulkTagDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get bulkTagDelete;

  /// No description provided for @bulkTagApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get bulkTagApply;

  /// No description provided for @bulkTagNewBadge.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get bulkTagNewBadge;

  /// No description provided for @bulkTagPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Bulk tags'**
  String get bulkTagPanelTitle;

  /// No description provided for @bulkTagEmptyLibrary.
  ///
  /// In en, this message translates to:
  /// **'No tags in library yet.'**
  String get bulkTagEmptyLibrary;

  /// No description provided for @bulkTagNoMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No tags match filter.'**
  String get bulkTagNoMatchFilter;

  /// No description provided for @bulkTagValidationEmpty.
  ///
  /// In en, this message translates to:
  /// **'Tag name cannot be empty.'**
  String get bulkTagValidationEmpty;

  /// No description provided for @bulkTagValidationDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Tag already exists.'**
  String get bulkTagValidationDuplicate;

  /// No description provided for @bulkTagManageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Manage tag'**
  String get bulkTagManageTooltip;

  /// No description provided for @commonCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get commonCreate;

  /// No description provided for @customStudyTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom study'**
  String get customStudyTitle;

  /// No description provided for @customStudyEntriesCount.
  ///
  /// In en, this message translates to:
  /// **'Entries matching your selection: {count}'**
  String customStudyEntriesCount(int count);

  /// No description provided for @customStudyMaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Max cards (leave empty for all)'**
  String get customStudyMaxLabel;

  /// No description provided for @customStudyMaxPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. 50'**
  String get customStudyMaxPlaceholder;

  /// No description provided for @customStudyRandomOrder.
  ///
  /// In en, this message translates to:
  /// **'Random order'**
  String get customStudyRandomOrder;

  /// No description provided for @customStudyCram.
  ///
  /// In en, this message translates to:
  /// **'Cram (do not save scheduling)'**
  String get customStudyCram;

  /// No description provided for @customStudyStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get customStudyStart;

  /// No description provided for @reviewSrsTitle.
  ///
  /// In en, this message translates to:
  /// **'SRS Review'**
  String get reviewSrsTitle;

  /// No description provided for @reviewCramBadge.
  ///
  /// In en, this message translates to:
  /// **'Cram'**
  String get reviewCramBadge;

  /// No description provided for @reviewQueueCounts.
  ///
  /// In en, this message translates to:
  /// **'New {newCount} · Learning {learningCount} · Review {reviewCount}'**
  String reviewQueueCounts(int newCount, int learningCount, int reviewCount);

  /// No description provided for @reviewAutoAudio.
  ///
  /// In en, this message translates to:
  /// **'Auto-audio'**
  String get reviewAutoAudio;

  /// No description provided for @reviewAllLanguages.
  ///
  /// In en, this message translates to:
  /// **'All languages'**
  String get reviewAllLanguages;

  /// No description provided for @reviewLanguageFilterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Language filter'**
  String get reviewLanguageFilterTooltip;

  /// No description provided for @reviewMixedProOnly.
  ///
  /// In en, this message translates to:
  /// **'Mixed mode is a Pro feature. Activate Pro in About.'**
  String get reviewMixedProOnly;

  /// No description provided for @reviewMixedEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable mixed'**
  String get reviewMixedEnable;

  /// No description provided for @reviewMixedLocked.
  ///
  /// In en, this message translates to:
  /// **'Mixed (Pro)'**
  String get reviewMixedLocked;

  /// No description provided for @reviewBasicMode.
  ///
  /// In en, this message translates to:
  /// **'Basic mode'**
  String get reviewBasicMode;

  /// No description provided for @reviewExitStudy.
  ///
  /// In en, this message translates to:
  /// **'Exit study'**
  String get reviewExitStudy;

  /// No description provided for @reviewNoCardsDue.
  ///
  /// In en, this message translates to:
  /// **'No cards due right now.'**
  String get reviewNoCardsDue;

  /// No description provided for @reviewFinishing.
  ///
  /// In en, this message translates to:
  /// **'Finishing review session…'**
  String get reviewFinishing;

  /// No description provided for @reviewCompleted.
  ///
  /// In en, this message translates to:
  /// **'Review completed.'**
  String get reviewCompleted;

  /// No description provided for @reviewReviewsToday.
  ///
  /// In en, this message translates to:
  /// **'Reviews today: {used}/{limit}'**
  String reviewReviewsToday(int used, int limit);

  /// No description provided for @reviewTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Review tips'**
  String get reviewTipsTitle;

  /// No description provided for @reviewTipsBody.
  ///
  /// In en, this message translates to:
  /// **'Enter to flip/check, 1-4 to grade card recall, Ctrl+Enter to replay audio, R to replay.'**
  String get reviewTipsBody;

  /// No description provided for @reviewGradeHintForward.
  ///
  /// In en, this message translates to:
  /// **'Enter: Flip | 1-4: Grade | Ctrl+Enter: Audio | R: Replay'**
  String get reviewGradeHintForward;

  /// No description provided for @reviewGradeHintReverse.
  ///
  /// In en, this message translates to:
  /// **'Enter: Check | 1-4: Grade | Ctrl+Enter: Audio | R: Replay'**
  String get reviewGradeHintReverse;

  /// No description provided for @reviewAudioFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not play audio.'**
  String get reviewAudioFailed;

  /// No description provided for @reviewPlayTerm.
  ///
  /// In en, this message translates to:
  /// **'Play term'**
  String get reviewPlayTerm;

  /// No description provided for @reviewPlayAudio.
  ///
  /// In en, this message translates to:
  /// **'Play audio'**
  String get reviewPlayAudio;

  /// No description provided for @reviewMeaning.
  ///
  /// In en, this message translates to:
  /// **'Meaning'**
  String get reviewMeaning;

  /// No description provided for @reviewListenType.
  ///
  /// In en, this message translates to:
  /// **'Listen & type'**
  String get reviewListenType;

  /// No description provided for @reviewListenInstructions.
  ///
  /// In en, this message translates to:
  /// **'Play audio and type the original word.'**
  String get reviewListenInstructions;

  /// No description provided for @reviewTypeOriginalPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type original word'**
  String get reviewTypeOriginalPlaceholder;

  /// No description provided for @reviewCheckAnswer.
  ///
  /// In en, this message translates to:
  /// **'Check answer (Enter)'**
  String get reviewCheckAnswer;

  /// No description provided for @reviewCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get reviewCorrect;

  /// No description provided for @reviewIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get reviewIncorrect;

  /// No description provided for @reviewYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer:'**
  String get reviewYourAnswer;

  /// No description provided for @reviewExpected.
  ///
  /// In en, this message translates to:
  /// **'Expected:'**
  String get reviewExpected;

  /// No description provided for @reviewAnswerEmptyMarker.
  ///
  /// In en, this message translates to:
  /// **'(empty)'**
  String get reviewAnswerEmptyMarker;

  /// No description provided for @reviewGradeAgain.
  ///
  /// In en, this message translates to:
  /// **'Again (1)'**
  String get reviewGradeAgain;

  /// No description provided for @reviewGradeHard.
  ///
  /// In en, this message translates to:
  /// **'Hard (2)'**
  String get reviewGradeHard;

  /// No description provided for @reviewGradeGood.
  ///
  /// In en, this message translates to:
  /// **'Good (3)'**
  String get reviewGradeGood;

  /// No description provided for @reviewGradeEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy (4)'**
  String get reviewGradeEasy;

  /// No description provided for @reviewGradeNameAgain.
  ///
  /// In en, this message translates to:
  /// **'again'**
  String get reviewGradeNameAgain;

  /// No description provided for @reviewGradeNameHard.
  ///
  /// In en, this message translates to:
  /// **'hard'**
  String get reviewGradeNameHard;

  /// No description provided for @reviewGradeNameGood.
  ///
  /// In en, this message translates to:
  /// **'good'**
  String get reviewGradeNameGood;

  /// No description provided for @reviewGradeNameEasy.
  ///
  /// In en, this message translates to:
  /// **'easy'**
  String get reviewGradeNameEasy;

  /// No description provided for @reviewSummaryWordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Words just reviewed ({count})'**
  String reviewSummaryWordsTitle(int count);

  /// No description provided for @reviewSummaryClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get reviewSummaryClose;

  /// No description provided for @reviewSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Session summary'**
  String get reviewSummaryTitle;

  /// No description provided for @reviewSummaryGreatJob.
  ///
  /// In en, this message translates to:
  /// **'Great job, {name}!'**
  String reviewSummaryGreatJob(String name);

  /// No description provided for @reviewSummaryEncourage.
  ///
  /// In en, this message translates to:
  /// **'You finished today’s study goal.'**
  String get reviewSummaryEncourage;

  /// No description provided for @reviewSummaryStatReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get reviewSummaryStatReviewed;

  /// No description provided for @reviewSummaryStatMastered.
  ///
  /// In en, this message translates to:
  /// **'Remembered well'**
  String get reviewSummaryStatMastered;

  /// No description provided for @reviewSummaryStatTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get reviewSummaryStatTime;

  /// No description provided for @reviewSummaryBackDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get reviewSummaryBackDashboard;

  /// No description provided for @reviewSummarySeeWords.
  ///
  /// In en, this message translates to:
  /// **'See reviewed words'**
  String get reviewSummarySeeWords;

  /// No description provided for @reviewSummaryCloudSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing cloud data…'**
  String get reviewSummaryCloudSyncing;

  /// No description provided for @reviewSummaryCloudOk.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync succeeded'**
  String get reviewSummaryCloudOk;

  /// No description provided for @reviewSummaryCloudFail.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync failed'**
  String get reviewSummaryCloudFail;

  /// No description provided for @reviewSummaryYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get reviewSummaryYou;

  /// No description provided for @reviewDurSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String reviewDurSeconds(int seconds);

  /// No description provided for @reviewDurMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String reviewDurMinutes(int minutes);

  /// No description provided for @reviewDurMinutesSeconds.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m {seconds}s'**
  String reviewDurMinutesSeconds(int minutes, int seconds);

  /// No description provided for @reviewDurHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String reviewDurHours(int hours);

  /// No description provided for @reviewDurHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String reviewDurHoursMinutes(int hours, int minutes);

  /// No description provided for @captureSavePhrase.
  ///
  /// In en, this message translates to:
  /// **'Save phrase'**
  String get captureSavePhrase;

  /// No description provided for @captureSaveLine.
  ///
  /// In en, this message translates to:
  /// **'Save line'**
  String get captureSaveLine;

  /// No description provided for @captureWholeLine.
  ///
  /// In en, this message translates to:
  /// **'Whole line'**
  String get captureWholeLine;

  /// No description provided for @captureListenSource.
  ///
  /// In en, this message translates to:
  /// **'Listen to source'**
  String get captureListenSource;

  /// No description provided for @captureNoTextDetected.
  ///
  /// In en, this message translates to:
  /// **'No text detected'**
  String get captureNoTextDetected;

  /// No description provided for @captureAddTagLabel.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get captureAddTagLabel;

  /// No description provided for @captureTagHint.
  ///
  /// In en, this message translates to:
  /// **'Type tag'**
  String get captureTagHint;

  /// No description provided for @captureAutoRecentTag.
  ///
  /// In en, this message translates to:
  /// **'Auto-fill recent tag'**
  String get captureAutoRecentTag;

  /// No description provided for @captureNoRecentTagsYet.
  ///
  /// In en, this message translates to:
  /// **'No recent tags yet — save an entry with a tag to use this.'**
  String get captureNoRecentTagsYet;

  /// No description provided for @captureSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Saved ✓'**
  String get captureSavedToast;

  /// No description provided for @captureDailySaveLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached today\'s save limit ({limit} saves per day). Upgrade to Pro for unlimited saves.'**
  String captureDailySaveLimitReached(int limit);

  /// No description provided for @captureDailyTranslateLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached today\'s translation limit ({limit} calls per day). Upgrade to Pro for unlimited translations.'**
  String captureDailyTranslateLimitReached(int limit);

  /// No description provided for @settingsTagManagerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tags yet.'**
  String get settingsTagManagerEmpty;

  /// No description provided for @meaningTranslating.
  ///
  /// In en, this message translates to:
  /// **'Translating…'**
  String get meaningTranslating;

  /// No description provided for @meaningNoTranslationYet.
  ///
  /// In en, this message translates to:
  /// **'No translation yet.'**
  String get meaningNoTranslationYet;

  /// No description provided for @meaningDictHeading.
  ///
  /// In en, this message translates to:
  /// **'Definition (English)'**
  String get meaningDictHeading;

  /// No description provided for @meaningFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Meaning'**
  String get meaningFieldLabel;

  /// No description provided for @meaningFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Edit translation'**
  String get meaningFieldHint;

  /// No description provided for @meaningPlayPronunciation.
  ///
  /// In en, this message translates to:
  /// **'Play pronunciation'**
  String get meaningPlayPronunciation;

  /// No description provided for @meaningPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get meaningPlay;

  /// No description provided for @meaningPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get meaningPause;

  /// No description provided for @meaningPhraseMarker.
  ///
  /// In en, this message translates to:
  /// **'(PHRASE)'**
  String get meaningPhraseMarker;

  /// No description provided for @settingsReviewAudioSection.
  ///
  /// In en, this message translates to:
  /// **'Review audio'**
  String get settingsReviewAudioSection;

  /// No description provided for @settingsAutoPlayAudioTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-play audio on new card'**
  String get settingsAutoPlayAudioTitle;

  /// No description provided for @settingsRememberTagTitle.
  ///
  /// In en, this message translates to:
  /// **'Remember last tag when adding words'**
  String get settingsRememberTagTitle;

  /// No description provided for @settingsLocalBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Local backup'**
  String get settingsLocalBackupTitle;

  /// No description provided for @settingsBackupNowJson.
  ///
  /// In en, this message translates to:
  /// **'Backup now (JSON)'**
  String get settingsBackupNowJson;

  /// No description provided for @settingsImportBackup.
  ///
  /// In en, this message translates to:
  /// **'Import backup (.db / .json)'**
  String get settingsImportBackup;

  /// No description provided for @settingsBackupFootnote.
  ///
  /// In en, this message translates to:
  /// **'Use signed JSON from this app or a .db / .json vocabulary backup.'**
  String get settingsBackupFootnote;

  /// No description provided for @settingsManageTagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage tags'**
  String get settingsManageTagsTitle;

  /// No description provided for @settingsManageTagsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rename/delete tags across saved words.'**
  String get settingsManageTagsSubtitle;

  /// No description provided for @settingsReplaceVocabTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace local vocabulary?'**
  String get settingsReplaceVocabTitle;

  /// No description provided for @settingsReplaceVocabBody.
  ///
  /// In en, this message translates to:
  /// **'All saved words on this device will be replaced by the backup. This cannot be undone.'**
  String get settingsReplaceVocabBody;

  /// No description provided for @settingsChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get settingsChooseFile;

  /// No description provided for @settingsImporting.
  ///
  /// In en, this message translates to:
  /// **'Importing backup…'**
  String get settingsImporting;

  /// No description provided for @settingsImportedCount.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} items ({kind}).'**
  String settingsImportedCount(int count, String kind);

  /// No description provided for @settingsExportCancelled.
  ///
  /// In en, this message translates to:
  /// **'Export cancelled'**
  String get settingsExportCancelled;

  /// No description provided for @settingsSavedPath.
  ///
  /// In en, this message translates to:
  /// **'Saved: {path}'**
  String settingsSavedPath(String path);

  /// No description provided for @settingsExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String settingsExportFailed(String error);

  /// No description provided for @settingsImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String settingsImportFailed(String error);

  /// No description provided for @settingsLanguageLoadError.
  ///
  /// In en, this message translates to:
  /// **'Language settings error: {error}'**
  String settingsLanguageLoadError(String error);

  /// No description provided for @commonErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String commonErrorPrefix(String error);

  /// No description provided for @dashLearnerPickerLabel.
  ///
  /// In en, this message translates to:
  /// **'Who is learning?'**
  String get dashLearnerPickerLabel;

  /// No description provided for @dashLearnerPickerNewButton.
  ///
  /// In en, this message translates to:
  /// **'Create new'**
  String get dashLearnerPickerNewButton;

  /// No description provided for @localProfilesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Local learners'**
  String get localProfilesSectionTitle;

  /// No description provided for @localProfilesSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Each learner has a separate vocabulary library on this device. Switch profile to study a different word set.'**
  String get localProfilesSectionDescription;

  /// No description provided for @localProfileDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get localProfileDefaultName;

  /// No description provided for @localProfileActiveBadge.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get localProfileActiveBadge;

  /// No description provided for @localProfileUseAction.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get localProfileUseAction;

  /// No description provided for @localProfileAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add learner'**
  String get localProfileAddAction;

  /// No description provided for @localProfileRenameAction.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get localProfileRenameAction;

  /// No description provided for @localProfileDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get localProfileDeleteAction;

  /// No description provided for @localProfileAddTitle.
  ///
  /// In en, this message translates to:
  /// **'New learner'**
  String get localProfileAddTitle;

  /// No description provided for @localProfileRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename learner'**
  String get localProfileRenameTitle;

  /// No description provided for @localProfileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get localProfileNameLabel;

  /// No description provided for @localProfileDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove learner?'**
  String get localProfileDeleteConfirmTitle;

  /// No description provided for @localProfileDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Their vocabulary stays on this device until you clear app data. You can add this learner again anytime.'**
  String get localProfileDeleteConfirmBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'vi', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
