// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'FormyCareer';

  @override
  String get navDesktop => '桌面';

  @override
  String get navDashboard => '仪表盘';

  @override
  String get navCapture => '采集';

  @override
  String get navReview => '复习';

  @override
  String get navVocabulary => '词汇库';

  @override
  String get navGuides => '指南';

  @override
  String get navSettings => '设置';

  @override
  String get navAbout => '关于';

  @override
  String get navWords => '词汇';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSubtitle => '语言和本地偏好';

  @override
  String get uiLanguageSectionTitle => '界面语言';

  @override
  String get uiLanguageLabel => '应用语言';

  @override
  String get uiLanguageDescription => '控制菜单与设置界面文字。翻译说明仍遵循下方的“母语”设置。';

  @override
  String get uiLocaleSystem => '跟随系统';

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
  String get settingsTextScaleSectionTitle => '字体大小';

  @override
  String get settingsTextScaleLabel => '界面文字缩放';

  @override
  String get settingsTextScaleDescription =>
      '调整桌面窗口与采集弹窗的文字大小，会与 Windows 显示缩放叠加。';

  @override
  String settingsTextScalePercent(int percent) {
    return '$percent%';
  }

  @override
  String get backupSectionTitle => '本地备份与恢复';

  @override
  String get backupSectionIntro => '在本地备份和恢复数据。';

  @override
  String get defaultBackupFolderTitle => '默认备份文件夹';

  @override
  String get defaultBackupFolderDescription =>
      '用于定时自动备份。内置默认位于“文档”文件夹下。下方的“立即备份”仍可选择任意文件夹。';

  @override
  String get resolvingPath => '正在解析路径…';

  @override
  String currentPathPrefix(String path) {
    return '当前：$path';
  }

  @override
  String get confirmUseFolder => '使用此文件夹';

  @override
  String get changeDefaultFolder => '更改默认文件夹';

  @override
  String get useAppDefaultFolder => '使用应用默认文件夹';

  @override
  String couldNotUseFolder(String error) {
    return '无法使用此文件夹：$error';
  }

  @override
  String defaultBackupFolderSet(String path) {
    return '默认备份文件夹：$path';
  }

  @override
  String get usingAppDefaultAgain => '已恢复使用应用默认文件夹。';

  @override
  String get automaticBackupTitle => '自动备份';

  @override
  String get automaticBackupDescription => '按计划将资料库副本保存到上方的默认文件夹。';

  @override
  String get repeatEveryLabel => '重复间隔';

  @override
  String get backupNow => '立即备份';

  @override
  String get restoreFromFile => '从文件恢复';

  @override
  String get saveBackupHere => '备份保存到此';

  @override
  String get restoreFromThisFile => '从此文件恢复';

  @override
  String get backupFilesFilter => '备份文件';

  @override
  String backupCreated(String path) {
    return '已创建备份：$path';
  }

  @override
  String restoredFrom(String restored) {
    return '已从以下位置恢复：$restored';
  }

  @override
  String get backupFooterNote =>
      '“立即备份”可选择任意文件夹；自动备份始终使用上方默认文件夹。恢复时请选取 .db 或 .json 文件。';

  @override
  String get backupIntervalHourly => '每小时';

  @override
  String get backupInterval6h => '每 6 小时';

  @override
  String get backupInterval12h => '每 12 小时';

  @override
  String get backupIntervalDaily => '每天';

  @override
  String get backupInterval2days => '每 2 天';

  @override
  String get backupIntervalWeekly => '每周';

  @override
  String backupIntervalEveryHours(int hours) {
    return '每 $hours 小时';
  }

  @override
  String get translationSectionTitle => '翻译';

  @override
  String get nativeLanguageLabel => '母语';

  @override
  String get translationNativeHelp => '翻译与界面解释以此语言显示。';

  @override
  String get translationEngineHelp => '为获得最快响应，翻译引擎会自动选择。';

  @override
  String get backupErrNoBackupFile => '未找到可恢复的备份文件。';

  @override
  String get backupErrSqliteMissing => '未找到 SQLite 备份文件。';

  @override
  String get backupErrFileMissing => '未找到所选备份文件。';

  @override
  String get backupErrUnsupportedFormat => '不支持的备份格式。请选择 .db 或 .json 文件。';

  @override
  String get backupErrInvalidCorrupt => '备份文件无效或已损坏。';

  @override
  String backupErrGeneric(String error) {
    return '备份或恢复失败。详情：$error';
  }

  @override
  String get commonCancel => '取消';

  @override
  String get commonClose => '关闭';

  @override
  String get commonDelete => '删除';

  @override
  String get commonSave => '保存';

  @override
  String get commonBack => '返回';

  @override
  String get commonOk => '确定';

  @override
  String get commonRefresh => '刷新';

  @override
  String get commonTips => '提示';

  @override
  String get commonGranted => '已授权';

  @override
  String get commonMissing => '缺失';

  @override
  String get commonChecking => '正在检查…';

  @override
  String get commonLoading => '加载中…';

  @override
  String get commonStudy => '学习';

  @override
  String get commonTag => '标签';

  @override
  String get commonArchive => '归档';

  @override
  String get commonResetSrs => '重置 SRS';

  @override
  String get commonActivate => '激活';

  @override
  String get cmdCancelEsc => '取消 (Esc)';

  @override
  String get cmdOneItemSelected => '已选择 1 项';

  @override
  String cmdManyItemsSelected(int count) {
    return '已选择 $count 项';
  }

  @override
  String get dashSubtitle => '学习概览与快捷入口';

  @override
  String dashCouldNotLoadVocab(String error) {
    return '无法加载词汇：$error';
  }

  @override
  String get dashHeroTitle => '你的学习中心';

  @override
  String dashHeroStatsLine(int dueNow, int active, int newCount) {
    return '即时 $dueNow 张 · 活跃卡组 $active · 新卡 $newCount';
  }

  @override
  String get dashHeroShareCaption => '活跃卡组到期占比';

  @override
  String dashHeroPercentDue(int percent) {
    return '活跃卡牌中 $percent% 到期';
  }

  @override
  String get dashStatDueNowTitle => '现在到期';

  @override
  String get dashStatDueNowSubtitle => '可进行 SRS 复习';

  @override
  String get dashStatActiveTitle => '活跃卡组';

  @override
  String get dashStatActiveSubtitle => '未归档条目';

  @override
  String get dashStatNewTitle => '新卡';

  @override
  String get dashStatNewSubtitle => '从未复习';

  @override
  String get dashStatArchivedTitle => '已归档';

  @override
  String get dashStatArchivedSubtitle => '暂停队列';

  @override
  String get dashInsightUpcoming => '即将到来复习';

  @override
  String get dashInsightDeckComposition => '卡组构成';

  @override
  String get dashInsightByLanguage => '按语言';

  @override
  String get dashInsightPopularTags => '常用标签';

  @override
  String get dashEmptyLangPairs => '尚无语言对。';

  @override
  String get dashEmptyTags => '尚无标签 — 采集时添加。';

  @override
  String get dashDeckCompositionEmpty => '添加词汇后可查看构成。';

  @override
  String dashLegendNewCount(int count) {
    return '新 · $count';
  }

  @override
  String dashLegendLearningCount(int count) {
    return '学习中 (1–6 次) · $count';
  }

  @override
  String dashLegendEstablishedCount(int count) {
    return '巩固 (>6 次) · $count';
  }

  @override
  String get dashDueNowRow => '到期或过期';

  @override
  String get dashDueWeekRow => '未来 7 天内（不含今天）';

  @override
  String get dashDueLaterRow => '更晚以后';

  @override
  String get dashQuickActions => '快捷操作';

  @override
  String get dashStartReview => '开始复习';

  @override
  String get dashOpenVocabulary => '打开词汇库';

  @override
  String get dashCapture => '采集';

  @override
  String get dashNothingDueHint => '目前没有到期卡片，仍可在复习标签预习。';

  @override
  String get mobileDashSubtitle => '学习快照';

  @override
  String mobileDashLoadFailed(String error) {
    return '无法加载词汇。\\n$error';
  }

  @override
  String get mobileStatDueSubtitle => 'SRS 队列';

  @override
  String get mobileStatActiveSubtitle => '卡组中';

  @override
  String get mobileStatNewSubtitle => '未复习';

  @override
  String get mobileStatArchivedSubtitle => '已暂停';

  @override
  String get mobileGoReview => '前往复习';

  @override
  String get mobileGoWords => '打开词汇';

  @override
  String get guidesPageSubtitle => '采集、复习、词汇与日常使用提示。';

  @override
  String get guidesIntroTitle => '界面导览';

  @override
  String get guidesIntroBody => '左侧标签页：仪表盘、采集、复习、词汇、本指南、设置、关于。';

  @override
  String get guidesCaptureTitle => '采集';

  @override
  String get guidesCaptureBody => '快捷键见 Capture 标签；自动采集跟随其他应用选择；弹窗内拖选原文仅翻译片段。';

  @override
  String get guidesReviewTitle => '复习（SRS）';

  @override
  String get guidesReviewBody => '复习标签运行 SRS；如实评分；Pro 解锁混合复习。';

  @override
  String get guidesVocabTitle => '词汇';

  @override
  String get guidesVocabBody => '词汇标签内搜索、标签、归档；同步与导出取决于账户与设置。';

  @override
  String get guidesSettingsTitle => '设置与备份';

  @override
  String get guidesSettingsBody => '设置母语、字号、热键与本地备份文件夹。';

  @override
  String get guidesProTitle => '免费与 Pro';

  @override
  String get guidesProBody =>
      '免费版可能对桌面捕获保存与弹窗翻译设每日上限（缓存多半不计）；Pro 去广告、混合复习、SRS 与捕获不限等。关于标签购买。';

  @override
  String get aboutPageSubtitle => '应用信息与许可';

  @override
  String get aboutTagline => '跨平台语言学习工作台。';

  @override
  String aboutVersionPrefix(String version) {
    return '版本 $version';
  }

  @override
  String get aboutUpdatesSection => '更新与 Pro';

  @override
  String aboutLatestVersionLabel(String version) {
    return '最新版本：$version';
  }

  @override
  String get aboutUpdateAvailable => '此应用有可用更新。';

  @override
  String get aboutUsingLatest => '您正在使用最新版本。';

  @override
  String aboutReleaseNotesPrefix(String notes) {
    return '发行说明：$notes';
  }

  @override
  String get aboutMinVersionWarning => '低于最低支持版本。';

  @override
  String get aboutPlanPro => '当前方案：Pro';

  @override
  String get aboutPlanFree => '当前方案：免费';

  @override
  String get aboutProKeyInstructions => '使用 Lemon Squeezy 邮件中的许可证密钥。';

  @override
  String get aboutCheckUpdates => '检查更新';

  @override
  String get aboutCheckingUpdates => '正在检查…';

  @override
  String get aboutDownloadLatest => '下载最新版';

  @override
  String get aboutVisitProWebsite => '前往网站购买 Pro';

  @override
  String get aboutActivating => '正在激活…';

  @override
  String get aboutActivatePro => '激活 Pro';

  @override
  String get aboutActivateProTitle => '激活 Pro';

  @override
  String get aboutActivateProPlaceholder => '粘贴 Lemon Squeezy 邮件中的密钥';

  @override
  String get aboutUpdateCheckDone => '已完成更新检查';

  @override
  String get aboutWhatProUnlocks => 'Pro 权益';

  @override
  String get aboutOneLicense => '一份许可证可同时激活桌面与移动版。';

  @override
  String get aboutProBenefit1 => '桌面端 Pro 无横幅广告。';

  @override
  String get aboutProBenefit2 => '混合复习模式。';

  @override
  String get aboutProBenefit3 => 'SRS 每日评分不限（免费每日 100）。';

  @override
  String get aboutProBenefit4 => '桌面端从捕获保存生词每日不限（免费版有每日上限）。';

  @override
  String get aboutProBenefit5 => '桌面捕获弹窗翻译请求每日不限；缓存命中不计入额度（免费版有每日上限）。';

  @override
  String get aboutSupportLegal => '支持与法律信息';

  @override
  String aboutSupportEmailPrefix(String email) {
    return '支持邮箱：$email';
  }

  @override
  String get aboutCopySupportEmail => '复制支持邮箱';

  @override
  String get aboutOpenSourceLicenses => '开源许可';

  @override
  String get aboutPrivacyPolicy => '隐私政策';

  @override
  String get aboutTermsOfService => '服务条款';

  @override
  String get aboutSupportEmailCopied => '已复制支持邮箱';

  @override
  String get capturePageSubtitle => '自动采集、快捷键与同步';

  @override
  String get captureAutoCaptureTitle => '自动采集';

  @override
  String get captureAutoCaptureBody => '开启：跟随其他应用鼠标选择；关闭：仅用快捷键。';

  @override
  String captureAutoToggleShortcutLine(String shortcut) {
    return '使用 $shortcut 切换。';
  }

  @override
  String get captureHotkeyToggleLabel => '切换自动采集热键';

  @override
  String get capturePressNewShortcut => '按下新快捷键';

  @override
  String get captureAutoStatusOn => '开';

  @override
  String get captureAutoStatusOff => '关';

  @override
  String captureAutoToast(String status, String hotkey) {
    return '自动采集：$status ($hotkey)';
  }

  @override
  String captureHotkeySetToast(String key) {
    return '自动采集热键设为 Ctrl+Shift+$key';
  }

  @override
  String get captureVisualGuidesCardTitle => '图示指南';

  @override
  String get captureVisualGuidesAutoHeading => '自动采集流程';

  @override
  String get captureVisualGuidesOcrHeading => '屏幕区域 OCR';

  @override
  String get captureVisualGuidesPopupRefineHint =>
      '提示：在采集弹出窗口中拖选原文片段，可仅翻译该短语；不关窗口可多次调整选区。';

  @override
  String get captureAutoFlowSelectLabel => '选择';

  @override
  String get captureAutoFlowPauseLabel => '暂停';

  @override
  String get captureAutoFlowPopupLabel => '查阅';

  @override
  String get captureAutoFlowCaption => '开启后为三步（其他应用）。';

  @override
  String get captureAutoVisualGuideLink => '分步图解指南…';

  @override
  String get captureDlgAutoCaptureTitle => '自动采集如何工作';

  @override
  String get captureDlgAutoCaptureIntro =>
      '开启后，Formycareer 会监听其他程序中的鼠标选字（本应用窗口内不计）。\\n\\n下图示意流程。';

  @override
  String get captureDlgAutoCaptureStep1Title => '1. 在其他应用中选中文本';

  @override
  String get captureDlgAutoCaptureStep1Body => '浏览器或 PDF：拖动选中，或双击单词。';

  @override
  String get captureDlgAutoCaptureStep2Title => '2. 松开鼠标稍等';

  @override
  String get captureDlgAutoCaptureStep2Body => '让高亮稳定后再读取。';

  @override
  String get captureDlgAutoCaptureStep3Title => '3. 弹出查阅窗口';

  @override
  String get captureDlgAutoCaptureStep3Body =>
      '弹出窗口显示全文以便翻译或保存；在原文区域拖选即可只翻译该片段。';

  @override
  String get captureDlgAutoCaptureStep4Title => '4. 继续在原文中选择片段';

  @override
  String get captureDlgAutoCaptureStep4Body =>
      '在弹出窗口的原文区域可随时拖选另一段文字——每次选择仅翻译该片段，可反复操作而无需关闭窗口。';

  @override
  String get captureDlgAutoCaptureSchemeCaption => '示意图（非真实界面）';

  @override
  String get captureOcrFlowHotkeyLabel => '快捷键';

  @override
  String get captureOcrFlowRegionLabel => '框选区域';

  @override
  String get captureOcrFlowResultLabel => '识别文字';

  @override
  String get captureOcrFlowCaption => 'Ctrl+Shift+X 后在屏幕上框选文字。';

  @override
  String get captureOcrVisualGuideLink => 'OCR 分步图解…';

  @override
  String get captureDlgOcrGuideTitle => '区域 OCR 如何使用';

  @override
  String get captureDlgOcrGuideIntro =>
      '区域 OCR 从所选屏幕区域识别文字；与自动采集无关。\\n\\n下图示意步骤。';

  @override
  String get captureDlgOcrStep1Title => '1. 开始区域采集';

  @override
  String get captureDlgOcrStep1Body => '在其他应用中按 Ctrl+Shift+X，或本窗口聚焦时使用应用内快捷键。';

  @override
  String get captureDlgOcrStep2Title => '2. 拖动矩形框选';

  @override
  String get captureDlgOcrStep2Body => '屏幕变暗后，拖动框住要识别的文字或图像。';

  @override
  String get captureDlgOcrStep3Title => '3. 确认并查看结果';

  @override
  String get captureDlgOcrStep3Body => '确认后，识别文字在弹出窗口打开，可翻译或保存。';

  @override
  String get captureDlgOcrStep4Title => '4. 继续在原文中选择片段';

  @override
  String get captureDlgOcrStep4Body =>
      '在弹出窗口的原文区域可随时拖选另一段文字——每次选择仅翻译该片段，可反复操作而无需关闭窗口。';

  @override
  String get captureDlgOcrSchemeCaption => '示意图（非真实界面）';

  @override
  String get captureActiveBehaviorNote => '在其他应用选中后，短暂停顿后读取；剪贴板可能会变化。';

  @override
  String get captureShortcutsSectionTitle => '采集';

  @override
  String get captureShortcutsSectionBody =>
      'Ctrl+Shift+D（文本）、Ctrl+Shift+X（区域）。';

  @override
  String get captureTextFromSelection => '从选择获取文本';

  @override
  String get captureImageRegionOcr => '图像 / 区域 OCR';

  @override
  String get capturePermissionsTitle => '权限';

  @override
  String captureAccessibilityGrantedLine(String state) {
    return '辅助功能：$state';
  }

  @override
  String captureScreenRecordingGrantedLine(String state) {
    return '屏幕录制：$state';
  }

  @override
  String get capturePermRefresh => '刷新';

  @override
  String get capturePermRequest => '请求缺失权限';

  @override
  String get capturePermChecking => '正在检查…';

  @override
  String get capturePermAllGranted => '已获得全部采集权限。';

  @override
  String get capturePermSomeMissing => '仍有缺失权限，请在系统设置开启。';

  @override
  String get captureHotkeyUnavailable => '全局热键不可用，请使用应用内快捷键。';

  @override
  String get captureDlgTextCaptureTitle => '文本采集';

  @override
  String get captureDlgTextCaptureBody =>
      '手动：Ctrl+Shift+D。\\n自动：跟随拖动选择与双击读取高亮文本；不使用 UIA 或剪贴板监听。';

  @override
  String get captureDlgImageCaptureTitle => '图像 / 区域 OCR';

  @override
  String get captureDlgImageCaptureBody => 'Ctrl+Shift+X 全屏框选 OCR。';

  @override
  String get captureDlgTipsTitle => '采集提示';

  @override
  String get captureDlgTipsBody => '长时间写作时可关闭以免影响剪贴板。';

  @override
  String get captureHotkeyDlgTitle => '按下新热键';

  @override
  String get captureHotkeyDlgHintInitial => '按 Ctrl+Shift+字母或数字';

  @override
  String get captureHotkeyDlgHintRetry => '需要 Ctrl+Shift 加字母或数字';

  @override
  String get vocabPageSubtitle => '搜索筛选与管理卡组';

  @override
  String get vocabStudySelected => '学习所选';

  @override
  String get vocabStudyFiltered => '按筛选学习';

  @override
  String get vocabSelectBeforeStudy => '请先选择词汇。';

  @override
  String get vocabNoMatchFilters => '没有匹配筛选的词。';

  @override
  String get vocabTipsTitle => '词汇提示';

  @override
  String get vocabTipsBody => '批量操作前先按语言和来源筛选。';

  @override
  String get vocabDeleteTitle => '删除已保存的词？';

  @override
  String get vocabDeleteBodyOne => '将永久删除所选词条。';

  @override
  String vocabDeleteBodyMany(int count) {
    return '将永久删除所选 $count 条。';
  }

  @override
  String get vocabSearchPlaceholder => '搜索词义或标签';

  @override
  String get vocabAllLanguages => '全部语言';

  @override
  String get vocabAllSources => '全部来源';

  @override
  String get vocabAllTags => '全部标签';

  @override
  String get vocabFilterActive => '活跃';

  @override
  String get vocabFilterArchived => '归档';

  @override
  String get vocabFilterAll => '全部';

  @override
  String get vocabClearFilters => '清除筛选';

  @override
  String get vocabTtsSectionTitle => 'Google Cloud 文字转语音';

  @override
  String get vocabTtsSectionBody =>
      '将长文本合成为语音（在 Cloud TTS 限制内自动分段）。需要启用 Cloud Text-to-Speech API 并配置 API 密钥。';

  @override
  String get vocabTtsApiKeyPlaceholder => 'API 密钥（安全保存在本机）';

  @override
  String get vocabTtsSaveApiKey => '保存密钥';

  @override
  String get vocabTtsApiKeySaved => '已保存 API 密钥。';

  @override
  String get vocabTtsApiKeyFromBuild => '正在使用应用构建配置中的 API 密钥。';

  @override
  String get vocabTtsTextPlaceholder => '粘贴或输入要朗读的文本（支持长文）';

  @override
  String vocabTtsStats(int bytes, int segments) {
    return 'UTF-8 大小：$bytes · 请求分段：$segments';
  }

  @override
  String get vocabTtsVoiceLabel => '语音';

  @override
  String get vocabTtsVoiceCustom => '自定义语音…';

  @override
  String get vocabTtsCustomVoicePlaceholder => '语音名称（如 en-US-Neural2-J）';

  @override
  String get vocabTtsCustomLangPlaceholder => 'languageCode（如 en-US）';

  @override
  String get vocabTtsSpeakingRate => '语速';

  @override
  String get vocabTtsGeneratePlay => '合成并播放';

  @override
  String get vocabTtsSaveMp3 => '保存 MP3…';

  @override
  String get vocabTtsNeedApiKey => '请先添加 Google Cloud Text-to-Speech API 密钥。';

  @override
  String get vocabTtsNeedText => '请输入要合成的文本。';

  @override
  String get vocabTtsVoiceInvalid => '请填写语音名称和 languageCode。';

  @override
  String vocabTtsError(String message) {
    return '$message';
  }

  @override
  String vocabTtsSavedFile(String path) {
    return '已保存音频：$path';
  }

  @override
  String get vocabEmptyLibrary => '暂无词汇。';

  @override
  String get vocabColTermMeaning => '词条 / 释义';

  @override
  String get vocabColSource => '来源';

  @override
  String get vocabColTags => '标签';

  @override
  String get vocabColNextReview => '下次复习';

  @override
  String get vocabCtxMenuTag => '标签';

  @override
  String get vocabCtxMenuArchive => '归档';

  @override
  String get vocabCtxMenuResetSrs => '重置 SRS';

  @override
  String get vocabCtxMenuDelete => '删除';

  @override
  String get bulkTagCreateTitle => '新建标签';

  @override
  String get bulkTagCreatePlaceholder => '输入新标签';

  @override
  String get bulkTagRenameTitle => '重命名标签';

  @override
  String get bulkTagRenamePlaceholder => '输入标签';

  @override
  String get bulkTagDeleteTitle => '删除标签';

  @override
  String bulkTagDeleteBody(String tag) {
    return '从所有词条移除「$tag」？';
  }

  @override
  String get bulkTagFilterPlaceholder => '筛选标签';

  @override
  String get bulkTagClearSelections => '清除标签选择';

  @override
  String get bulkTagRename => '重命名';

  @override
  String get bulkTagDelete => '删除';

  @override
  String get bulkTagApply => '应用';

  @override
  String get bulkTagNewBadge => '新';

  @override
  String get bulkTagPanelTitle => '批量标签';

  @override
  String get bulkTagEmptyLibrary => '词库尚无标签。';

  @override
  String get bulkTagNoMatchFilter => '没有匹配筛选的标签。';

  @override
  String get bulkTagValidationEmpty => '标签名称不能为空。';

  @override
  String get bulkTagValidationDuplicate => '标签已存在。';

  @override
  String get bulkTagManageTooltip => '管理标签';

  @override
  String get commonCreate => '创建';

  @override
  String get customStudyTitle => '自定义学习';

  @override
  String customStudyEntriesCount(int count) {
    return '匹配所选：$count 条';
  }

  @override
  String get customStudyMaxLabel => '最大卡片数（留空为全部）';

  @override
  String get customStudyMaxPlaceholder => '例如 50';

  @override
  String get customStudyRandomOrder => '随机顺序';

  @override
  String get customStudyCram => '突击（不保存调度）';

  @override
  String get customStudyStart => '开始';

  @override
  String get reviewSrsTitle => 'SRS 复习';

  @override
  String get reviewCramBadge => '突击';

  @override
  String reviewQueueCounts(int newCount, int learningCount, int reviewCount) {
    return '新 $newCount · 学习中 $learningCount · 复习 $reviewCount';
  }

  @override
  String get reviewAutoAudio => '自动音频';

  @override
  String get reviewAllLanguages => '全部语言';

  @override
  String get reviewLanguageFilterTooltip => '语言筛选';

  @override
  String get reviewMixedProOnly => '混合模式需 Pro。';

  @override
  String get reviewMixedEnable => '启用混合';

  @override
  String get reviewMixedLocked => '混合（Pro）';

  @override
  String get reviewBasicMode => '基础模式';

  @override
  String get reviewExitStudy => '退出学习';

  @override
  String get reviewNoCardsDue => '没有到期卡片。';

  @override
  String get reviewFinishing => '正在结束会话…';

  @override
  String get reviewCompleted => '复习完成。';

  @override
  String reviewReviewsToday(int used, int limit) {
    return '今日复习：$used/$limit';
  }

  @override
  String get reviewTipsTitle => '复习提示';

  @override
  String get reviewTipsBody => 'Enter 翻面/判定，Ctrl+Enter 播放音频。';

  @override
  String get reviewGradeHintForward => 'Enter：翻面 · Ctrl+Enter：音频';

  @override
  String get reviewGradeHintReverse => 'Enter：检查 · Ctrl+Enter：音频';

  @override
  String get reviewAudioFailed => '无法播放音频。';

  @override
  String get reviewPlayTerm => '播放词条';

  @override
  String get reviewPlayAudio => '播放音频';

  @override
  String get reviewMeaning => '释义';

  @override
  String get reviewListenType => '听写';

  @override
  String get reviewListenInstructions => '播放音频并输入原词。';

  @override
  String get reviewTypeOriginalPlaceholder => '输入原文';

  @override
  String get reviewCheckAnswer => '检查答案（Enter）';

  @override
  String get reviewCorrect => '正确';

  @override
  String get reviewIncorrect => '错误';

  @override
  String get reviewYourAnswer => '你的答案：';

  @override
  String get reviewExpected => '应为：';

  @override
  String get reviewAnswerEmptyMarker => '(空)';

  @override
  String get reviewGradeAgain => '重来 (1)';

  @override
  String get reviewGradeHard => '困难 (2)';

  @override
  String get reviewGradeGood => '良好 (3)';

  @override
  String get reviewGradeEasy => '简单 (4)';

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
    return '刚复习的词 ($count)';
  }

  @override
  String get reviewSummaryClose => '关闭';

  @override
  String get reviewSummaryTitle => '学习会话总结';

  @override
  String reviewSummaryGreatJob(String name) {
    return '太棒了，$name！';
  }

  @override
  String get reviewSummaryEncourage => '你已完成今日目标。';

  @override
  String get reviewSummaryStatReviewed => '已复习';

  @override
  String get reviewSummaryStatMastered => '掌握良好';

  @override
  String get reviewSummaryStatTime => '用时';

  @override
  String get reviewSummaryBackDashboard => '返回仪表盘';

  @override
  String get reviewSummarySeeWords => '查看刚复习的词';

  @override
  String get reviewSummaryCloudSyncing => '正在同步云端…';

  @override
  String get reviewSummaryCloudOk => '云端同步成功';

  @override
  String get reviewSummaryCloudFail => '云端同步失败';

  @override
  String get reviewSummaryYou => '你';

  @override
  String reviewDurSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String reviewDurMinutes(int minutes) {
    return '$minutes分钟';
  }

  @override
  String reviewDurMinutesSeconds(int minutes, int seconds) {
    return '$minutes分$seconds秒';
  }

  @override
  String reviewDurHours(int hours) {
    return '$hours小时';
  }

  @override
  String reviewDurHoursMinutes(int hours, int minutes) {
    return '$hours小时$minutes分';
  }

  @override
  String get captureSavePhrase => '保存短语';

  @override
  String get captureSaveLine => '保存整行';

  @override
  String get captureWholeLine => '整行';

  @override
  String get captureListenSource => '收听原文';

  @override
  String get captureNoTextDetected => '未检测到文本';

  @override
  String get captureAddTagLabel => '添加标签';

  @override
  String get captureTagHint => '输入标签';

  @override
  String get captureAutoRecentTag => '自动填入最近标签';

  @override
  String get captureNoRecentTagsYet => '尚无最近标签。';

  @override
  String get captureSavedToast => '已保存 ✓';

  @override
  String captureDailySaveLimitReached(int limit) {
    return '已达到今日保存上限（每天 $limit 次）。升级 Pro 可无限制保存。';
  }

  @override
  String captureDailyTranslateLimitReached(int limit) {
    return '已达到今日翻译次数上限（每天 $limit 次）。升级 Pro 可无限制调用。';
  }

  @override
  String get settingsTagManagerEmpty => '暂无标签。';

  @override
  String get meaningTranslating => '翻译中…';

  @override
  String get meaningNoTranslationYet => '尚无翻译。';

  @override
  String get meaningDictHeading => '英语释义';

  @override
  String get meaningFieldLabel => '释义';

  @override
  String get meaningFieldHint => '编辑翻译';

  @override
  String get meaningPlayPronunciation => '播放发音';

  @override
  String get meaningPlay => '播放';

  @override
  String get meaningPause => '暂停';

  @override
  String get meaningPhraseMarker => '(短语)';

  @override
  String get settingsReviewAudioSection => '复习音频';

  @override
  String get settingsAutoPlayAudioTitle => '新卡片自动播放音频';

  @override
  String get settingsRememberTagTitle => '添加词语时记住上次标签';

  @override
  String get settingsLocalBackupTitle => '本地备份';

  @override
  String get settingsBackupNowJson => '立即备份（JSON）';

  @override
  String get settingsImportBackup => '导入备份 (.db / .json)';

  @override
  String get settingsBackupFootnote => '使用签名 JSON 或 .db/.json。';

  @override
  String get settingsManageTagsTitle => '管理标签';

  @override
  String get settingsManageTagsSubtitle => '在所有词条重命名/删除标签。';

  @override
  String get settingsReplaceVocabTitle => '替换本地词汇？';

  @override
  String get settingsReplaceVocabBody => '设备上的词将被备份替换，不可撤销。';

  @override
  String get settingsChooseFile => '选择文件';

  @override
  String get settingsImporting => '正在导入…';

  @override
  String settingsImportedCount(int count, String kind) {
    return '已导入 $count 条 ($kind)。';
  }

  @override
  String get settingsExportCancelled => '已取消导出';

  @override
  String settingsSavedPath(String path) {
    return '已保存：$path';
  }

  @override
  String settingsExportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String settingsImportFailed(String error) {
    return '导入失败：$error';
  }

  @override
  String settingsLanguageLoadError(String error) {
    return '语言设置错误：$error';
  }

  @override
  String commonErrorPrefix(String error) {
    return '错误：$error';
  }

  @override
  String get dashLearnerPickerLabel => 'Who is learning?';

  @override
  String get dashLearnerPickerNewButton => '新建';

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
