// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'FormyCareer';

  @override
  String get navDesktop => 'デスクトップ';

  @override
  String get navDashboard => 'ダッシュボード';

  @override
  String get navCapture => '取り込み';

  @override
  String get navReview => '復習';

  @override
  String get navVocabulary => '単語帳';

  @override
  String get navGuides => 'ガイド';

  @override
  String get navSettings => '設定';

  @override
  String get navAbout => '情報';

  @override
  String get navWords => '単語';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSubtitle => '言語とローカルの環境設定';

  @override
  String get uiLanguageSectionTitle => '表示言語';

  @override
  String get uiLanguageLabel => 'アプリの言語';

  @override
  String get uiLanguageDescription =>
      'メニューと設定画面の文言を切り替えます。説明文の翻訳は下の「母語」の設定に従います。';

  @override
  String get uiLocaleSystem => 'システムに合わせる';

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
  String get settingsTextScaleSectionTitle => '文字サイズ';

  @override
  String get settingsTextScaleLabel => 'インターフェースの文字サイズ';

  @override
  String get settingsTextScaleDescription =>
      'デスクトップとポップアップの文字サイズ。Windows の表示スケールと重ねがけされます。';

  @override
  String settingsTextScalePercent(int percent) {
    return '$percent%';
  }

  @override
  String get backupSectionTitle => 'ローカルのバックアップと復元';

  @override
  String get backupSectionIntro => 'データをこの PC 上でバックアップ・復元します。';

  @override
  String get defaultBackupFolderTitle => '既定のバックアップフォルダー';

  @override
  String get defaultBackupFolderDescription =>
      '定期自動バックアップで使用します。既定はドキュメント配下のフォルダーです。下の「今すぐバックアップ」では別フォルダーを選べます。';

  @override
  String get resolvingPath => 'パスを取得しています…';

  @override
  String currentPathPrefix(String path) {
    return '現在: $path';
  }

  @override
  String get confirmUseFolder => 'このフォルダーを使う';

  @override
  String get changeDefaultFolder => '既定フォルダーを変更';

  @override
  String get useAppDefaultFolder => 'アプリ既定に戻す';

  @override
  String couldNotUseFolder(String error) {
    return 'このフォルダーを使えません: $error';
  }

  @override
  String defaultBackupFolderSet(String path) {
    return '既定のバックアップフォルダー: $path';
  }

  @override
  String get usingAppDefaultAgain => 'アプリ既定のフォルダーに戻しました。';

  @override
  String get automaticBackupTitle => '自動バックアップ';

  @override
  String get automaticBackupDescription =>
      '上記の既定フォルダーへスケジュールに従ってライブラリのコピーを保存します。';

  @override
  String get repeatEveryLabel => '繰り返し間隔';

  @override
  String get backupNow => '今すぐバックアップ';

  @override
  String get restoreFromFile => 'ファイルから復元';

  @override
  String get saveBackupHere => 'ここに保存';

  @override
  String get restoreFromThisFile => 'このファイルから復元';

  @override
  String get backupFilesFilter => 'バックアップファイル';

  @override
  String backupCreated(String path) {
    return 'バックアップを作成しました: $path';
  }

  @override
  String restoredFrom(String restored) {
    return '復元元: $restored';
  }

  @override
  String get backupFooterNote =>
      '「今すぐバックアップ」では任意のフォルダーを選べます。自動バックアップは常に上の既定フォルダーを使います。復元では .db または .json を選んでください。';

  @override
  String get backupIntervalHourly => '1 時間ごと';

  @override
  String get backupInterval6h => '6 時間ごと';

  @override
  String get backupInterval12h => '12 時間ごと';

  @override
  String get backupIntervalDaily => '毎日';

  @override
  String get backupInterval2days => '2 日ごと';

  @override
  String get backupIntervalWeekly => '毎週';

  @override
  String backupIntervalEveryHours(int hours) {
    return '$hours 時間ごと';
  }

  @override
  String get translationSectionTitle => '翻訳';

  @override
  String get nativeLanguageLabel => '母語';

  @override
  String get translationNativeHelp => '翻訳と説明はこの言語で表示されます。';

  @override
  String get translationEngineHelp => '応答が速いように翻訳エンジンは自動で選ばれます。';

  @override
  String get backupErrNoBackupFile => '復元できるバックアップがありません。';

  @override
  String get backupErrSqliteMissing => 'SQLite のバックアップファイルが見つかりません。';

  @override
  String get backupErrFileMissing => '選択したバックアップが見つかりません。';

  @override
  String get backupErrUnsupportedFormat => '未対応の形式です。.db または .json を選んでください。';

  @override
  String get backupErrInvalidCorrupt => 'バックアップが無効か破損しています。';

  @override
  String backupErrGeneric(String error) {
    return 'バックアップまたは復元に失敗しました。詳細: $error';
  }

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonDelete => '削除';

  @override
  String get commonSave => '保存';

  @override
  String get commonBack => '戻る';

  @override
  String get commonOk => 'OK';

  @override
  String get commonRefresh => '更新';

  @override
  String get commonTips => 'ヒント';

  @override
  String get commonGranted => '許可済み';

  @override
  String get commonMissing => '未許可';

  @override
  String get commonChecking => '確認中…';

  @override
  String get commonLoading => '読み込み中…';

  @override
  String get commonStudy => '学習';

  @override
  String get commonTag => 'タグ';

  @override
  String get commonArchive => 'アーカイブ';

  @override
  String get commonResetSrs => 'SRS をリセット';

  @override
  String get commonActivate => '有効化';

  @override
  String get cmdCancelEsc => 'キャンセル (Esc)';

  @override
  String get cmdOneItemSelected => '1 件選択';

  @override
  String cmdManyItemsSelected(int count) {
    return '$count 件選択';
  }

  @override
  String get dashSubtitle => '学習スナップショットとナビ';

  @override
  String dashCouldNotLoadVocab(String error) {
    return '語彙を読み込めません: $error';
  }

  @override
  String get dashHeroTitle => 'あなたの学習ハブ';

  @override
  String dashHeroStatsLine(int dueNow, int active, int newCount) {
    return '今すぐ $dueNow · アクティブ $active 枚 · 新規 $newCount';
  }

  @override
  String get dashHeroShareCaption => 'アクティブデッキの復習割合';

  @override
  String dashHeroPercentDue(int percent) {
    return 'アクティブの $percent% が期限';
  }

  @override
  String get dashStatDueNowTitle => '今すぐ';

  @override
  String get dashStatDueNowSubtitle => 'SRS 復習対応';

  @override
  String get dashStatActiveTitle => 'アクティブデッキ';

  @override
  String get dashStatActiveSubtitle => 'アーカイブ以外';

  @override
  String get dashStatNewTitle => '新規';

  @override
  String get dashStatNewSubtitle => '未復習';

  @override
  String get dashStatArchivedTitle => 'アーカイブ済み';

  @override
  String get dashStatArchivedSubtitle => 'キューから除外';

  @override
  String get dashInsightUpcoming => '今後の復習';

  @override
  String get dashInsightDeckComposition => 'デッキ構成';

  @override
  String get dashInsightByLanguage => '言語別';

  @override
  String get dashInsightPopularTags => '人気タグ';

  @override
  String get dashEmptyLangPairs => '言語ペアがありません。';

  @override
  String get dashEmptyTags => 'タグがありません — 取り込み時に追加。';

  @override
  String get dashDeckCompositionEmpty => '語彙を追加すると構成が表示されます。';

  @override
  String dashLegendNewCount(int count) {
    return '新規 · $count';
  }

  @override
  String dashLegendLearningCount(int count) {
    return '学習中 (1〜6回) · $count';
  }

  @override
  String dashLegendEstablishedCount(int count) {
    return '定着 (>6回) · $count';
  }

  @override
  String get dashDueNowRow => '期限切れ・今日期限';

  @override
  String get dashDueWeekRow => '今後7日以内（翌日以降）';

  @override
  String get dashDueLaterRow => 'それ以降';

  @override
  String get dashQuickActions => 'クイックアクション';

  @override
  String get dashStartReview => '復習開始';

  @override
  String get dashOpenVocabulary => '単語帳を開く';

  @override
  String get dashCapture => '取り込み';

  @override
  String get dashNothingDueHint => '今は期限カードがありません。復習タブで先行できます。';

  @override
  String get mobileDashSubtitle => '学習スナップショット';

  @override
  String mobileDashLoadFailed(String error) {
    return '語彙を読み込めません。\\n$error';
  }

  @override
  String get mobileStatDueSubtitle => 'SRS キュー';

  @override
  String get mobileStatActiveSubtitle => 'デッキ内';

  @override
  String get mobileStatNewSubtitle => '未復習';

  @override
  String get mobileStatArchivedSubtitle => '一時停止';

  @override
  String get mobileGoReview => '復習へ';

  @override
  String get mobileGoWords => '単語へ';

  @override
  String get guidesPageSubtitle => 'キャプチャ・復習・語彙・日常利用のヒント。';

  @override
  String get guidesIntroTitle => '基本的な見方';

  @override
  String get guidesIntroBody => '左のタブ：ダッシュボード／キャプチャ／復習／語彙／このガイド／設定／情報。';

  @override
  String get guidesCaptureTitle => 'キャプチャ';

  @override
  String get guidesCaptureBody =>
      'ショートカットはキャプチャタブ参照。自動取り込みで他アプリ選択を追跡。ポップアップでは原文をドラッグして一部だけ翻訳。';

  @override
  String get guidesReviewTitle => '復習（SRS）';

  @override
  String get guidesReviewBody => '復習タブでSRS。正直に評価。Proでミックス復習。';

  @override
  String get guidesVocabTitle => '語彙';

  @override
  String get guidesVocabBody => '語彙タブで検索・タグ・アーカイブ。同期とエクスポートは設定依存。';

  @override
  String get guidesSettingsTitle => '設定とバックアップ';

  @override
  String get guidesSettingsBody => '母語・文字サイズ・ホットキー・バックアップ先を設定。';

  @override
  String get guidesProTitle => '無料と Pro';

  @override
  String get guidesProBody =>
      '無料はデスクトップの保存・翻訳に日次上限（キャッシュ除く）。Proは広告なし・ミックス・SRS無制限・キャプチャ無制限。情報タブで購入。';

  @override
  String get aboutPageSubtitle => 'アプリ情報とライセンス';

  @override
  String get aboutTagline => 'クロスプラットフォームの語学学習ワークスペース。';

  @override
  String aboutVersionPrefix(String version) {
    return 'バージョン $version';
  }

  @override
  String get aboutUpdatesSection => 'アップデートと Pro';

  @override
  String aboutLatestVersionLabel(String version) {
    return '最新バージョン: $version';
  }

  @override
  String get aboutUpdateAvailable => 'このアプリに更新があります。';

  @override
  String get aboutUsingLatest => '最新バージョンを使用中です。';

  @override
  String aboutReleaseNotesPrefix(String notes) {
    return 'リリースノート: $notes';
  }

  @override
  String get aboutMinVersionWarning => 'サポートされる最小バージョンを下回っています。';

  @override
  String get aboutPlanPro => '現在のプラン: Pro';

  @override
  String get aboutPlanFree => '現在のプラン: Free';

  @override
  String get aboutProKeyInstructions => 'お支払い後に届く Lemon Squeezy のライセンスキーを入力。';

  @override
  String get aboutCheckUpdates => '更新を確認';

  @override
  String get aboutCheckingUpdates => '確認中…';

  @override
  String get aboutDownloadLatest => '最新をダウンロード';

  @override
  String get aboutVisitProWebsite => 'サイトで Pro を購入';

  @override
  String get aboutActivating => '有効化中…';

  @override
  String get aboutActivatePro => 'Pro を有効化';

  @override
  String get aboutActivateProTitle => 'Pro を有効化';

  @override
  String get aboutActivateProPlaceholder => 'メールのライセンスキーを貼り付け';

  @override
  String get aboutUpdateCheckDone => '更新チェック完了';

  @override
  String get aboutWhatProUnlocks => 'Pro の内容';

  @override
  String get aboutOneLicense => '1つのライセンスでデスクトップとモバイルの Pro が有効。';

  @override
  String get aboutProBenefit1 => 'Pro 時デスクトップにバナー広告なし。';

  @override
  String get aboutProBenefit2 => 'ミックス復習モード。';

  @override
  String get aboutProBenefit3 => 'SRS の日次採点が無制限（無料は100回/日）。';

  @override
  String get aboutProBenefit4 => 'デスクトップのキャプチャからの語彙保存が1日あたり無制限（無料は日次上限）。';

  @override
  String get aboutProBenefit5 =>
      'デスクトップのキャプチャポップアップでの翻訳が1日無制限。キャッシュはカウントされません（無料は日次上限）。';

  @override
  String get aboutSupportLegal => 'サポートと法的情報';

  @override
  String aboutSupportEmailPrefix(String email) {
    return 'サポート: $email';
  }

  @override
  String get aboutCopySupportEmail => 'サポートメールをコピー';

  @override
  String get aboutOpenSourceLicenses => 'オープンソースライセンス';

  @override
  String get aboutPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get aboutTermsOfService => '利用規約';

  @override
  String get aboutSupportEmailCopied => 'コピーしました';

  @override
  String get capturePageSubtitle => '自動取り込み・ショートカット・同期';

  @override
  String get captureAutoCaptureTitle => '自動取り込み';

  @override
  String get captureAutoCaptureBody => 'オンで他アプリの選択を追跡。オフなら Ctrl+Shift+D のみ。';

  @override
  String captureAutoToggleShortcutLine(String shortcut) {
    return '$shortcut で切り替え。';
  }

  @override
  String get captureHotkeyToggleLabel => '自動取り込み切替ホットキー';

  @override
  String get capturePressNewShortcut => '新しいショートカットを押す';

  @override
  String get captureAutoStatusOn => 'ON';

  @override
  String get captureAutoStatusOff => 'OFF';

  @override
  String captureAutoToast(String status, String hotkey) {
    return '自動取り込み: $status ($hotkey)';
  }

  @override
  String captureHotkeySetToast(String key) {
    return '自動取り込みホットキーを Ctrl+Shift+$key';
  }

  @override
  String get captureVisualGuidesCardTitle => 'ビジュアルガイド';

  @override
  String get captureVisualGuidesAutoHeading => '自動取り込みの流れ';

  @override
  String get captureVisualGuidesOcrHeading => '画面領域 OCR';

  @override
  String get captureVisualGuidesPopupRefineHint =>
      'ヒント: ポップアップの原文をドラッグ選択すると、その部分だけを翻訳できます（閉じずに何度でも変えられます）。';

  @override
  String get captureAutoFlowSelectLabel => '選択';

  @override
  String get captureAutoFlowPauseLabel => '一時停止';

  @override
  String get captureAutoFlowPopupLabel => '調べる';

  @override
  String get captureAutoFlowCaption => 'オン時は3ステップ（他アプリ）。';

  @override
  String get captureAutoVisualGuideLink => 'ステップごとのガイド…';

  @override
  String get captureDlgAutoCaptureTitle => '自動取り込みの仕組み';

  @override
  String get captureDlgAutoCaptureIntro =>
      'オン時は Formycareer が他アプリのマウス選択を監視します（このアプリ内は対象外）。\\n\\n下図は流れのイメージです。';

  @override
  String get captureDlgAutoCaptureStep1Title => '1. 他アプリで選択';

  @override
  String get captureDlgAutoCaptureStep1Body => 'ブラウザや PDF でドラッグ、または単語をダブルクリック。';

  @override
  String get captureDlgAutoCaptureStep2Title => '2. マウスを離して少し待つ';

  @override
  String get captureDlgAutoCaptureStep2Body => 'ハイライトが安定してから読み取ります。';

  @override
  String get captureDlgAutoCaptureStep3Title => '3. ポップアップ表示';

  @override
  String get captureDlgAutoCaptureStep3Body =>
      'ポップアップで全文が開きます。原文エリアでドラッグ選択すると、その語句だけ翻訳できます。';

  @override
  String get captureDlgAutoCaptureStep4Title => '4. 原文で別の範囲を選び続ける';

  @override
  String get captureDlgAutoCaptureStep4Body =>
      'ポップアップの原文エリアで、必要なたびに別の語句をドラッグ選択できます。選択するたびにその部分だけが翻訳され、ウィンドウを閉じずに何度でも繰り返せます。';

  @override
  String get captureDlgAutoCaptureSchemeCaption => '模式図（実際の UI ではありません）';

  @override
  String get captureOcrFlowHotkeyLabel => 'ショートカット';

  @override
  String get captureOcrFlowRegionLabel => '範囲指定';

  @override
  String get captureOcrFlowResultLabel => 'OCR テキスト';

  @override
  String get captureOcrFlowCaption => 'Ctrl+Shift+X で範囲をドラッグ。';

  @override
  String get captureOcrVisualGuideLink => 'OCR のステップガイド…';

  @override
  String get captureDlgOcrGuideTitle => '領域 OCR の流れ';

  @override
  String get captureDlgOcrGuideIntro =>
      '領域 OCR は選択した画面領域から文字を読み取ります。自動取り込みとは無関係です。\\n\\n下図は流れです。';

  @override
  String get captureDlgOcrStep1Title => '1. 領域キャプチャ開始';

  @override
  String get captureDlgOcrStep1Body =>
      'Ctrl+Shift+X（グローバル）またはフォーカス時のアプリ内ショートカット。';

  @override
  String get captureDlgOcrStep2Title => '2. 矩形をドラッグ';

  @override
  String get captureDlgOcrStep2Body => '画面が暗くなります。読み取りたい範囲をドラッグ。';

  @override
  String get captureDlgOcrStep3Title => '3. 確定して確認';

  @override
  String get captureDlgOcrStep3Body =>
      '確定後、OCR で読み取ったテキストがポップアップで開き、翻訳や保存ができます。';

  @override
  String get captureDlgOcrStep4Title => '4. 原文で別の範囲を選び続ける';

  @override
  String get captureDlgOcrStep4Body =>
      'ポップアップの原文エリアで、必要なたびに別の語句をドラッグ選択できます。選択するたびにその部分だけが翻訳され、ウィンドウを閉じずに何度でも繰り返せます。';

  @override
  String get captureDlgOcrSchemeCaption => '模式図（実際の UI ではありません）';

  @override
  String get captureActiveBehaviorNote =>
      '他アプリで選択後、短い待機のあと読み取り。クリップボードが変わる場合があります。';

  @override
  String get captureShortcutsSectionTitle => '取り込み';

  @override
  String get captureShortcutsSectionBody =>
      'Ctrl+Shift+D（テキスト）、Ctrl+Shift+X（画像）。';

  @override
  String get captureTextFromSelection => '選択からテキスト';

  @override
  String get captureImageRegionOcr => '画像／領域 OCR';

  @override
  String get capturePermissionsTitle => '権限';

  @override
  String captureAccessibilityGrantedLine(String state) {
    return 'アクセシビリティ: $state';
  }

  @override
  String captureScreenRecordingGrantedLine(String state) {
    return '画面収録: $state';
  }

  @override
  String get capturePermRefresh => '更新';

  @override
  String get capturePermRequest => '不足権限をリクエスト';

  @override
  String get capturePermChecking => '確認中…';

  @override
  String get capturePermAllGranted => 'すべての権限が許可されました。';

  @override
  String get capturePermSomeMissing => '権限が不足しています。システム設定で有効に。';

  @override
  String get captureHotkeyUnavailable => 'グローバルホットキーは使えません。アプリ内ショートカットを。';

  @override
  String get captureDlgTextCaptureTitle => 'テキスト取り込み';

  @override
  String get captureDlgTextCaptureBody =>
      '手動:\\n• Ctrl+Shift+D。\\n\\n自動:\\n• ドラッグ選択とダブルクリックでハイライトを読み取り。\\n• UIA／クリップボード監視は未使用。';

  @override
  String get captureDlgImageCaptureTitle => '画像／領域 OCR';

  @override
  String get captureDlgImageCaptureBody => 'Ctrl+Shift+X。\\n• フルスクリーンで範囲指定。';

  @override
  String get captureDlgTipsTitle => '取り込みのヒント';

  @override
  String get captureDlgTipsBody => '長時間入力時はオフを推奨。';

  @override
  String get captureHotkeyDlgTitle => '新しいホットキーを押す';

  @override
  String get captureHotkeyDlgHintInitial => 'Ctrl+Shift+文字/数字 を押す';

  @override
  String get captureHotkeyDlgHintRetry => 'Ctrl+Shift + 文字/数字が必要です。';

  @override
  String get vocabPageSubtitle => '検索・フィルター・管理';

  @override
  String get vocabStudySelected => '選択項目を学習';

  @override
  String get vocabStudyFiltered => 'フィルター結果を学習';

  @override
  String get vocabSelectBeforeStudy => '学習前に単語を選択。';

  @override
  String get vocabNoMatchFilters => 'フィルターに一致する語がありません。';

  @override
  String get vocabTipsTitle => '語彙のヒント';

  @override
  String get vocabTipsBody => '一括操作前に言語とソースで絞り込み。';

  @override
  String get vocabDeleteTitle => '保存語を削除しますか？';

  @override
  String get vocabDeleteBodyOne => '選択した語を完全削除。';

  @override
  String vocabDeleteBodyMany(int count) {
    return '選択した $count 語を削除。';
  }

  @override
  String get vocabSearchPlaceholder => '語・意味・タグで検索';

  @override
  String get vocabAllLanguages => 'すべての言語';

  @override
  String get vocabAllSources => 'すべてのソース';

  @override
  String get vocabAllTags => 'すべてのタグ';

  @override
  String get vocabFilterActive => 'アクティブ';

  @override
  String get vocabFilterArchived => 'アーカイブ';

  @override
  String get vocabFilterAll => 'すべて';

  @override
  String get vocabClearFilters => 'フィルターをクリア';

  @override
  String get vocabTtsSectionTitle => 'Google Cloud テキスト読み上げ';

  @override
  String get vocabTtsSectionBody =>
      '長いテキストを音声化（Cloud TTS の上限内で自動分割）。Text-to-Speech API キーと API の有効化が必要です。';

  @override
  String get vocabTtsApiKeyPlaceholder => 'API キー（端末に安全に保存）';

  @override
  String get vocabTtsSaveApiKey => 'キーを保存';

  @override
  String get vocabTtsApiKeySaved => 'API キーを保存しました。';

  @override
  String get vocabTtsApiKeyFromBuild => 'ビルド設定の API キーを使用しています。';

  @override
  String get vocabTtsTextPlaceholder => '読み上げるテキストを入力（長文対応）';

  @override
  String vocabTtsStats(int bytes, int segments) {
    return 'UTF-8 サイズ: $bytes · リクエスト分割: $segments';
  }

  @override
  String get vocabTtsVoiceLabel => '音声';

  @override
  String get vocabTtsVoiceCustom => 'カスタム音声…';

  @override
  String get vocabTtsCustomVoicePlaceholder => '音声名（例: en-US-Neural2-J）';

  @override
  String get vocabTtsCustomLangPlaceholder => 'languageCode（例: en-US）';

  @override
  String get vocabTtsSpeakingRate => '話速';

  @override
  String get vocabTtsGeneratePlay => '合成して再生';

  @override
  String get vocabTtsSaveMp3 => 'MP3 を保存…';

  @override
  String get vocabTtsNeedApiKey =>
      '先に Google Cloud Text-to-Speech の API キーを追加してください。';

  @override
  String get vocabTtsNeedText => '合成するテキストを入力してください。';

  @override
  String get vocabTtsVoiceInvalid => '音声名と languageCode の両方を入力してください。';

  @override
  String vocabTtsError(String message) {
    return '$message';
  }

  @override
  String vocabTtsSavedFile(String path) {
    return '音声を保存しました: $path';
  }

  @override
  String get vocabEmptyLibrary => '語彙がありません。';

  @override
  String get vocabColTermMeaning => '語／意味';

  @override
  String get vocabColSource => 'ソース';

  @override
  String get vocabColTags => 'タグ';

  @override
  String get vocabColNextReview => '次の復習';

  @override
  String get vocabCtxMenuTag => 'タグ';

  @override
  String get vocabCtxMenuArchive => 'アーカイブ';

  @override
  String get vocabCtxMenuResetSrs => 'SRS をリセット';

  @override
  String get vocabCtxMenuDelete => '削除';

  @override
  String get bulkTagCreateTitle => 'タグ作成';

  @override
  String get bulkTagCreatePlaceholder => '新しいタグ';

  @override
  String get bulkTagRenameTitle => 'タグの名前変更';

  @override
  String get bulkTagRenamePlaceholder => 'タグを入力';

  @override
  String get bulkTagDeleteTitle => 'タグ削除';

  @override
  String bulkTagDeleteBody(String tag) {
    return '\"$tag\" をすべてから削除？';
  }

  @override
  String get bulkTagFilterPlaceholder => 'タグをフィルター';

  @override
  String get bulkTagClearSelections => '選択解除';

  @override
  String get bulkTagRename => '名前変更';

  @override
  String get bulkTagDelete => '削除';

  @override
  String get bulkTagApply => '適用';

  @override
  String get bulkTagNewBadge => '新規';

  @override
  String get bulkTagPanelTitle => '一括タグ';

  @override
  String get bulkTagEmptyLibrary => 'ライブラリにタグがありません。';

  @override
  String get bulkTagNoMatchFilter => 'フィルターに一致するタグがありません。';

  @override
  String get bulkTagValidationEmpty => 'タグ名は空にできません。';

  @override
  String get bulkTagValidationDuplicate => 'タグが既にあります。';

  @override
  String get bulkTagManageTooltip => 'タグを管理';

  @override
  String get commonCreate => '作成';

  @override
  String get customStudyTitle => 'カスタム学習';

  @override
  String customStudyEntriesCount(int count) {
    return '選択に一致: $count 件';
  }

  @override
  String get customStudyMaxLabel => '最大枚数（空欄ですべて）';

  @override
  String get customStudyMaxPlaceholder => '例: 50';

  @override
  String get customStudyRandomOrder => 'ランダム順';

  @override
  String get customStudyCram => 'クラム（スケジュール保存なし）';

  @override
  String get customStudyStart => '開始';

  @override
  String get reviewSrsTitle => 'SRS 復習';

  @override
  String get reviewCramBadge => 'クラム';

  @override
  String reviewQueueCounts(int newCount, int learningCount, int reviewCount) {
    return '新規 $newCount・学習中 $learningCount・復習 $reviewCount';
  }

  @override
  String get reviewAutoAudio => '自動オーディオ';

  @override
  String get reviewAllLanguages => 'すべての言語';

  @override
  String get reviewLanguageFilterTooltip => '言語フィルター';

  @override
  String get reviewMixedProOnly => 'ミックスモードは Pro。';

  @override
  String get reviewMixedEnable => 'ミックスを有効化';

  @override
  String get reviewMixedLocked => 'Mixed (Pro)';

  @override
  String get reviewBasicMode => 'ベーシック';

  @override
  String get reviewExitStudy => '学習を終了';

  @override
  String get reviewNoCardsDue => '期限カードがありません。';

  @override
  String get reviewFinishing => 'セッション終了中…';

  @override
  String get reviewCompleted => '復習完了。';

  @override
  String reviewReviewsToday(int used, int limit) {
    return '今日の復習: $used/$limit';
  }

  @override
  String get reviewTipsTitle => '復習のヒント';

  @override
  String get reviewTipsBody => 'Enter で反転／採点、Ctrl+Enter で音声。';

  @override
  String get reviewGradeHintForward => 'Enter: 表面裏 · Ctrl+Enter: 音声';

  @override
  String get reviewGradeHintReverse => 'Enter: チェック · Ctrl+Enter: 音声';

  @override
  String get reviewAudioFailed => '音声を再生できません。';

  @override
  String get reviewPlayTerm => '用語を再生';

  @override
  String get reviewPlayAudio => '音声を再生';

  @override
  String get reviewMeaning => '意味';

  @override
  String get reviewListenType => '聞いて入力';

  @override
  String get reviewListenInstructions => '音声を聞いて原文を入力。';

  @override
  String get reviewTypeOriginalPlaceholder => '原文を入力';

  @override
  String get reviewCheckAnswer => 'チェック (Enter)';

  @override
  String get reviewCorrect => '正解';

  @override
  String get reviewIncorrect => '不正解';

  @override
  String get reviewYourAnswer => 'あなたの解答:';

  @override
  String get reviewExpected => '正解:';

  @override
  String get reviewAnswerEmptyMarker => '(空)';

  @override
  String get reviewGradeAgain => 'もう一度 (1)';

  @override
  String get reviewGradeHard => '難しい (2)';

  @override
  String get reviewGradeGood => '良い (3)';

  @override
  String get reviewGradeEasy => '簡単 (4)';

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
    return '直近で復習した語 ($count)';
  }

  @override
  String get reviewSummaryClose => '閉じる';

  @override
  String get reviewSummaryTitle => 'セッションサマリー';

  @override
  String reviewSummaryGreatJob(String name) {
    return '素晴らしい、$nameさん！';
  }

  @override
  String get reviewSummaryEncourage => '今日の目標を達成しました。';

  @override
  String get reviewSummaryStatReviewed => '復習済み';

  @override
  String get reviewSummaryStatMastered => 'よく覚えた';

  @override
  String get reviewSummaryStatTime => '時間';

  @override
  String get reviewSummaryBackDashboard => 'ダッシュボードへ';

  @override
  String get reviewSummarySeeWords => '復習した語を見る';

  @override
  String get reviewSummaryCloudSyncing => 'クラウド同期中…';

  @override
  String get reviewSummaryCloudOk => 'クラウド同期成功';

  @override
  String get reviewSummaryCloudFail => 'クラウド同期失敗';

  @override
  String get reviewSummaryYou => 'あなた';

  @override
  String reviewDurSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String reviewDurMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String reviewDurMinutesSeconds(int minutes, int seconds) {
    return '$minutes分$seconds秒';
  }

  @override
  String reviewDurHours(int hours) {
    return '$hours時間';
  }

  @override
  String reviewDurHoursMinutes(int hours, int minutes) {
    return '$hours時間$minutes分';
  }

  @override
  String get captureSavePhrase => 'フレーズを保存';

  @override
  String get captureSaveLine => '行を保存';

  @override
  String get captureWholeLine => '全文行';

  @override
  String get captureListenSource => 'ソースを再生';

  @override
  String get captureNoTextDetected => 'テキストなし';

  @override
  String get captureAddTagLabel => 'タグを追加';

  @override
  String get captureTagHint => 'タグ入力';

  @override
  String get captureAutoRecentTag => '最近のタグを自動入力';

  @override
  String get captureNoRecentTagsYet => '最近タグがありません。';

  @override
  String get captureSavedToast => '保存 ✓';

  @override
  String captureDailySaveLimitReached(int limit) {
    return '本日の保存上限（$limit 回/日）に達しました。Pro で無制限に。';
  }

  @override
  String captureDailyTranslateLimitReached(int limit) {
    return '本日の翻訳上限（$limit 回/日）に達しました。Pro で無制限に。';
  }

  @override
  String get settingsTagManagerEmpty => 'タグがありません。';

  @override
  String get meaningTranslating => '翻訳中…';

  @override
  String get meaningNoTranslationYet => 'まだ翻訳がありません。';

  @override
  String get meaningDictHeading => '英語の定義';

  @override
  String get meaningFieldLabel => '意味';

  @override
  String get meaningFieldHint => '翻訳を編集';

  @override
  String get meaningPlayPronunciation => '発音を再生';

  @override
  String get meaningPlay => '再生';

  @override
  String get meaningPause => '一時停止';

  @override
  String get meaningPhraseMarker => '(フレーズ)';

  @override
  String get settingsReviewAudioSection => '復習オーディオ';

  @override
  String get settingsAutoPlayAudioTitle => '新しいカードで自動再生';

  @override
  String get settingsRememberTagTitle => '最後のタグを記憶';

  @override
  String get settingsLocalBackupTitle => 'ローカルバックアップ';

  @override
  String get settingsBackupNowJson => 'JSON でバックアップ';

  @override
  String get settingsImportBackup => 'バックアップをインポート';

  @override
  String get settingsBackupFootnote => '署名付き JSON または .db/.json。';

  @override
  String get settingsManageTagsTitle => 'タグ管理';

  @override
  String get settingsManageTagsSubtitle => 'すべての語でタグを編集。';

  @override
  String get settingsReplaceVocabTitle => 'ローカル語彙を置換？';

  @override
  String get settingsReplaceVocabBody => 'バックアップで置換。元に戻せません。';

  @override
  String get settingsChooseFile => 'ファイルを選択';

  @override
  String get settingsImporting => 'インポート中…';

  @override
  String settingsImportedCount(int count, String kind) {
    return '$count 件インポート ($kind)。';
  }

  @override
  String get settingsExportCancelled => 'エクスポート取消';

  @override
  String settingsSavedPath(String path) {
    return '保存先: $path';
  }

  @override
  String settingsExportFailed(String error) {
    return 'エクスポート失敗: $error';
  }

  @override
  String settingsImportFailed(String error) {
    return 'インポート失敗: $error';
  }

  @override
  String settingsLanguageLoadError(String error) {
    return '言語設定エラー: $error';
  }

  @override
  String commonErrorPrefix(String error) {
    return 'エラー: $error';
  }

  @override
  String get dashLearnerPickerLabel => 'Who is learning?';

  @override
  String get dashLearnerPickerNewButton => '新規作成';

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
