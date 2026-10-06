// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'FormyCareer';

  @override
  String get navDesktop => 'Máy tính';

  @override
  String get navDashboard => 'Tổng quan';

  @override
  String get navCapture => 'Thu thập';

  @override
  String get navReview => 'Ôn tập';

  @override
  String get navVocabulary => 'Từ vựng';

  @override
  String get navGuides => 'Hướng dẫn';

  @override
  String get navSettings => 'Cài đặt';

  @override
  String get navAbout => 'Giới thiệu';

  @override
  String get navWords => 'Từ vựng';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsSubtitle => 'Ngôn ngữ và tùy chọn cục bộ';

  @override
  String get uiLanguageSectionTitle => 'Ngôn ngữ giao diện';

  @override
  String get uiLanguageLabel => 'Ngôn ngữ ứng dụng';

  @override
  String get uiLanguageDescription =>
      'Điều khiển menu và chữ trong phần cài đặt. Giải thích khi dịch vẫn theo “Ngôn ngữ mẹ đẻ” bên dưới.';

  @override
  String get uiLocaleSystem => 'Theo hệ thống';

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
  String get settingsTextScaleSectionTitle => 'Cỡ chữ';

  @override
  String get settingsTextScaleLabel => 'Tỷ lệ chữ giao diện';

  @override
  String get settingsTextScaleDescription =>
      'Tăng giảm chữ trong cửa sổ desktop và popup thu thập. Cộng thêm với thang phóng hiển thị của Windows.';

  @override
  String settingsTextScalePercent(int percent) {
    return '$percent%';
  }

  @override
  String get backupSectionTitle => 'Sao lưu & khôi phục cục bộ';

  @override
  String get backupSectionIntro => 'Sao lưu và khôi phục dữ liệu trên máy.';

  @override
  String get defaultBackupFolderTitle => 'Thư mục sao lưu mặc định';

  @override
  String get defaultBackupFolderDescription =>
      'Dùng cho sao lưu tự động theo lịch. Mặc định của app là một thư mục trong Documents. “Sao lưu ngay” bên dưới vẫn có thể lưu vào thư mục bạn chọn.';

  @override
  String get resolvingPath => 'Đang lấy đường dẫn…';

  @override
  String currentPathPrefix(String path) {
    return 'Hiện tại: $path';
  }

  @override
  String get confirmUseFolder => 'Dùng thư mục này';

  @override
  String get changeDefaultFolder => 'Đổi thư mục mặc định';

  @override
  String get useAppDefaultFolder => 'Dùng thư mục mặc định của app';

  @override
  String couldNotUseFolder(String error) {
    return 'Không thể dùng thư mục này: $error';
  }

  @override
  String defaultBackupFolderSet(String path) {
    return 'Thư mục sao lưu mặc định: $path';
  }

  @override
  String get usingAppDefaultAgain =>
      'Đã quay lại dùng thư mục mặc định của app.';

  @override
  String get automaticBackupTitle => 'Sao lưu tự động';

  @override
  String get automaticBackupDescription =>
      'Lưu bản sao thư viện theo lịch vào thư mục mặc định phía trên.';

  @override
  String get repeatEveryLabel => 'Lặp lại mỗi';

  @override
  String get backupNow => 'Sao lưu ngay';

  @override
  String get restoreFromFile => 'Khôi phục từ tệp';

  @override
  String get saveBackupHere => 'Lưu sao lưu tại đây';

  @override
  String get restoreFromThisFile => 'Khôi phục từ tệp này';

  @override
  String get backupFilesFilter => 'Tệp sao lưu';

  @override
  String backupCreated(String path) {
    return 'Đã tạo sao lưu: $path';
  }

  @override
  String restoredFrom(String restored) {
    return 'Đã khôi phục từ: $restored';
  }

  @override
  String get backupFooterNote =>
      '“Sao lưu ngay” cho phép chọn bất kỳ thư mục nào. Sao lưu tự động luôn dùng thư mục mặc định phía trên. Để khôi phục, chọn tệp .db hoặc .json.';

  @override
  String get backupIntervalHourly => 'Mỗi giờ';

  @override
  String get backupInterval6h => 'Mỗi 6 giờ';

  @override
  String get backupInterval12h => 'Mỗi 12 giờ';

  @override
  String get backupIntervalDaily => 'Mỗi ngày';

  @override
  String get backupInterval2days => 'Mỗi 2 ngày';

  @override
  String get backupIntervalWeekly => 'Mỗi tuần';

  @override
  String backupIntervalEveryHours(int hours) {
    return 'Mỗi $hours giờ';
  }

  @override
  String get translationSectionTitle => 'Dịch';

  @override
  String get nativeLanguageLabel => 'Ngôn ngữ mẹ đẻ';

  @override
  String get translationNativeHelp =>
      'Bản dịch và giải thích trong giao diện hiển thị bằng ngôn ngữ này.';

  @override
  String get translationEngineHelp =>
      'Engine dịch được chọn tự động để phản hồi nhanh nhất.';

  @override
  String get backupErrNoBackupFile => 'Chưa có tệp sao lưu để khôi phục.';

  @override
  String get backupErrSqliteMissing => 'Không tìm thấy tệp sao lưu SQLite.';

  @override
  String get backupErrFileMissing => 'Không tìm thấy tệp sao lưu đã chọn.';

  @override
  String get backupErrUnsupportedFormat =>
      'Định dạng sao lưu không hỗ trợ. Hãy chọn tệp .db hoặc .json.';

  @override
  String get backupErrInvalidCorrupt =>
      'Tệp sao lưu không hợp lệ hoặc đã hỏng.';

  @override
  String backupErrGeneric(String error) {
    return 'Sao lưu/Khôi phục thất bại. Chi tiết: $error';
  }

  @override
  String get commonCancel => 'Hủy';

  @override
  String get commonClose => 'Đóng';

  @override
  String get commonDelete => 'Xóa';

  @override
  String get commonSave => 'Lưu';

  @override
  String get commonBack => 'Quay lại';

  @override
  String get commonOk => 'OK';

  @override
  String get commonRefresh => 'Làm mới';

  @override
  String get commonTips => 'Mẹo';

  @override
  String get commonGranted => 'Đã cấp';

  @override
  String get commonMissing => 'Thiếu';

  @override
  String get commonChecking => 'Đang kiểm tra…';

  @override
  String get commonLoading => 'Đang tải…';

  @override
  String get commonStudy => 'Ôn tập';

  @override
  String get commonTag => 'Thẻ';

  @override
  String get commonArchive => 'Lưu trữ';

  @override
  String get commonResetSrs => 'Đặt lại SRS';

  @override
  String get commonActivate => 'Kích hoạt';

  @override
  String get cmdCancelEsc => 'Hủy (Esc)';

  @override
  String get cmdOneItemSelected => 'Đã chọn 1 mục';

  @override
  String cmdManyItemsSelected(int count) {
    return 'Đã chọn $count mục';
  }

  @override
  String get dashSubtitle => 'Tổng quan học tập, biểu đồ và điều hướng nhanh';

  @override
  String dashCouldNotLoadVocab(String error) {
    return 'Không tải được từ vựng: $error';
  }

  @override
  String get dashHeroTitle => 'Trung tâm học tập của bạn';

  @override
  String dashHeroStatsLine(int dueNow, int active, int newCount) {
    return '$dueNow sẵn sàng ngay · $active thẻ trong bộ đang học · $newCount thẻ mới';
  }

  @override
  String get dashHeroShareCaption => 'Tỷ lệ bộ đang học đến hạn ôn';

  @override
  String dashHeroPercentDue(int percent) {
    return '$percent% thẻ đang học đến hạn';
  }

  @override
  String get dashStatDueNowTitle => 'Đến hạn ngay';

  @override
  String get dashStatDueNowSubtitle => 'Sẵn sàng ôn SRS';

  @override
  String get dashStatActiveTitle => 'Bộ đang học';

  @override
  String get dashStatActiveSubtitle => 'Mục chưa lưu trữ';

  @override
  String get dashStatNewTitle => 'Mới';

  @override
  String get dashStatNewSubtitle => 'Chưa từng ôn';

  @override
  String get dashStatArchivedTitle => 'Đã lưu trữ';

  @override
  String get dashStatArchivedSubtitle => 'Tạm dừng khỏi hàng đợi';

  @override
  String get dashInsightUpcoming => 'Ôn sắp tới';

  @override
  String get dashInsightDeckComposition => 'Cấu trúc bộ thẻ';

  @override
  String get dashInsightByLanguage => 'Theo ngôn ngữ';

  @override
  String get dashInsightPopularTags => 'Thẻ phổ biến';

  @override
  String get dashEmptyLangPairs => 'Chưa có cặp ngôn ngữ.';

  @override
  String get dashEmptyTags => 'Chưa có thẻ — thêm khi thu thập.';

  @override
  String get dashDeckCompositionEmpty => 'Thêm từ vựng để xem cấu trúc.';

  @override
  String dashLegendNewCount(int count) {
    return 'Mới · $count';
  }

  @override
  String dashLegendLearningCount(int count) {
    return 'Đang học (1–6 lần ôn) · $count';
  }

  @override
  String dashLegendEstablishedCount(int count) {
    return 'Ổn định (>6 lần ôn) · $count';
  }

  @override
  String get dashDueNowRow => 'Đến hạn hoặc quá hạn';

  @override
  String get dashDueWeekRow => 'Đến hạn trong 7 ngày tới (sau hôm nay)';

  @override
  String get dashDueLaterRow => 'Sau đó';

  @override
  String get dashQuickActions => 'Thao tác nhanh';

  @override
  String get dashStartReview => 'Bắt đầu ôn';

  @override
  String get dashOpenVocabulary => 'Mở từ vựng';

  @override
  String get dashCapture => 'Thu thập';

  @override
  String get dashNothingDueHint =>
      'Hiện không có thẻ đến hạn. Bạn vẫn có thể ôn trước từ tab Ôn tập.';

  @override
  String get mobileDashSubtitle => 'Tổng quan học tập';

  @override
  String mobileDashLoadFailed(String error) {
    return 'Không tải được từ vựng.\\n$error';
  }

  @override
  String get mobileStatDueSubtitle => 'Hàng đợi SRS';

  @override
  String get mobileStatActiveSubtitle => 'Trong bộ';

  @override
  String get mobileStatNewSubtitle => 'Chưa ôn';

  @override
  String get mobileStatArchivedSubtitle => 'Tạm dừng';

  @override
  String get mobileGoReview => 'Đi tới Ôn tập';

  @override
  String get mobileGoWords => 'Mở Từ vựng';

  @override
  String get guidesPageSubtitle =>
      'Mẹo cho capture, ôn tập, từ vựng và dùng hằng ngày.';

  @override
  String get guidesIntroTitle => 'Điều hướng';

  @override
  String get guidesIntroBody =>
      'Sử dụng các tab bên trái: Dashboard — ảnh chụp học tập; Capture — lấy chữ từ app khác; Review — ôn SRS; Vocabulary — duyệt và gọn thẻ; Guides — trợ giúp này; Settings — ngôn ngữ, sao lưu, phím tắt; About — phiên bản, Pro và hỗ trợ.';

  @override
  String get guidesCaptureTitle => 'Thu thập';

  @override
  String get guidesCaptureBody =>
      'Phím tắt (khi đăng ký được): thường Ctrl+Shift+D cho chữ đã chọn và Ctrl+Shift+X cho OCR vùng — xem tab Capture nếu đăng ký thất bại. Bật Auto capture để theo chọn chữ app khác. Trong popup, kéo chọn trong ô nguồn để chỉ dịch một cụm; Lưu thêm thẻ vào thư viện.';

  @override
  String get guidesReviewTitle => 'Ôn tập (SRS)';

  @override
  String get guidesReviewBody =>
      'Tab Ôn tập chạy SRS. Chấm điểm trung thực để lịch ôn có ý nghĩa. Pro mở ôn mixed (xuôi, đảo nghĩa, audio trong một phiên).';

  @override
  String get guidesVocabTitle => 'Từ vựng';

  @override
  String get guidesVocabBody =>
      'Tìm kiếm, gắn thẻ, lưu trữ và chỉnh trong tab Từ vựng. Đồng bộ và xuất tùy tài khoản và Cài đặt.';

  @override
  String get guidesSettingsTitle => 'Cài đặt & sao lưu';

  @override
  String get guidesSettingsBody =>
      'Chọn ngôn ngữ gốc cho dịch, cỡ chữ, phím bật/tắt auto capture và thư mục sao lưu cục bộ. Sao lưu giúp khi cài lại hoặc đổi máy.';

  @override
  String get guidesProTitle => 'Miễn phí và Pro';

  @override
  String get guidesProBody =>
      'Free có thể giới hạn/ngày lưu capture và gọi dịch popup trên desktop (cache thường không tính). Pro gỡ banner desktop, ôn mixed, SRS không giới hạn/ngày và gỡ giới hạn capture desktop đó. Tab Giới thiệu để cập nhật, kích hoạt và mua Pro.';

  @override
  String get aboutPageSubtitle => 'Thông tin ứng dụng và bản quyền';

  @override
  String get aboutTagline =>
      'Không gian học ngôn ngữ đa nền tảng: thu thập, ôn tập và quản lý từ vựng.';

  @override
  String aboutVersionPrefix(String version) {
    return 'Phiên bản $version';
  }

  @override
  String get aboutUpdatesSection => 'Cập nhật & Pro';

  @override
  String aboutLatestVersionLabel(String version) {
    return 'Phiên bản mới nhất: $version';
  }

  @override
  String get aboutUpdateAvailable => 'Có bản cập nhật cho ứng dụng.';

  @override
  String get aboutUsingLatest => 'Bạn đang dùng phiên bản mới nhất.';

  @override
  String aboutReleaseNotesPrefix(String notes) {
    return 'Ghi chú phát hành: $notes';
  }

  @override
  String get aboutMinVersionWarning =>
      'Phiên bản này thấp hơn phiên bản tối thiểu được hỗ trợ.';

  @override
  String get aboutPlanPro => 'Gói hiện tại: Pro';

  @override
  String get aboutPlanFree => 'Gói hiện tại: Miễn phí';

  @override
  String get aboutProKeyInstructions =>
      'Dùng mã bản quyền Lemon Squeezy gửi sau thanh toán. Xem phần Pro bên dưới.';

  @override
  String get aboutCheckUpdates => 'Kiểm tra cập nhật';

  @override
  String get aboutCheckingUpdates => 'Đang kiểm tra…';

  @override
  String get aboutDownloadLatest => 'Tải bản mới nhất';

  @override
  String get aboutVisitProWebsite => 'Vào trang web để mua Pro';

  @override
  String get aboutActivating => 'Đang kích hoạt…';

  @override
  String get aboutActivatePro => 'Kích hoạt Pro';

  @override
  String get aboutActivateProTitle => 'Kích hoạt Pro';

  @override
  String get aboutActivateProPlaceholder =>
      'Dán mã bản quyền từ email Lemon Squeezy';

  @override
  String get aboutUpdateCheckDone => 'Đã kiểm tra cập nhật';

  @override
  String get aboutWhatProUnlocks => 'Pro mở khóa gì';

  @override
  String get aboutOneLicense =>
      'Một license kích hoạt Pro cho desktop và mobile.';

  @override
  String get aboutProBenefit1 =>
      'Không quảng cáo banner trên desktop khi có Pro.';

  @override
  String get aboutProBenefit2 =>
      'Chế độ ôn hỗn hợp: kết hợp xuôi, đảo nghĩa và nghe trong một phiên.';

  @override
  String get aboutProBenefit3 =>
      'Không giới hạn lượt chấm điểm SRS mỗi ngày (Miễn phí: tối đa 100/ngày).';

  @override
  String get aboutProBenefit4 =>
      'Lưu từ mới không giới hạn từ capture trên desktop mỗi ngày (Free: giới hạn/ngày).';

  @override
  String get aboutProBenefit5 =>
      'Dịch không giới hạn trong popup capture trên desktop mỗi ngày; trùng cache không tính lượt (Free: giới hạn/ngày).';

  @override
  String get aboutSupportLegal => 'Hỗ trợ & Pháp lý';

  @override
  String aboutSupportEmailPrefix(String email) {
    return 'Email hỗ trợ: $email';
  }

  @override
  String get aboutCopySupportEmail => 'Sao chép email hỗ trợ';

  @override
  String get aboutOpenSourceLicenses => 'Giấy phép mã nguồn mở';

  @override
  String get aboutPrivacyPolicy => 'Chính sách quyền riêng tư';

  @override
  String get aboutTermsOfService => 'Điều khoản dịch vụ';

  @override
  String get aboutSupportEmailCopied => 'Đã sao chép email hỗ trợ';

  @override
  String get capturePageSubtitle => 'Tự động thu thập, phím tắt và đồng bộ';

  @override
  String get captureAutoCaptureTitle => 'Tự động thu thập';

  @override
  String get captureAutoCaptureBody =>
      'Bật: theo chọn chữ app khác qua chuột. Tắt: chỉ Ctrl+Shift+D.';

  @override
  String captureAutoToggleShortcutLine(String shortcut) {
    return 'Bật nhanh bằng $shortcut.';
  }

  @override
  String get captureHotkeyToggleLabel => 'Phím tắt bật/tắt tự động thu thập';

  @override
  String get capturePressNewShortcut => 'Nhập phím tắt mới';

  @override
  String get captureAutoStatusOn => 'BẬT';

  @override
  String get captureAutoStatusOff => 'TẮT';

  @override
  String captureAutoToast(String status, String hotkey) {
    return 'Tự động thu thập: $status ($hotkey)';
  }

  @override
  String captureHotkeySetToast(String key) {
    return 'Đặt phím tự động thu thập thành Ctrl+Shift+$key';
  }

  @override
  String get captureVisualGuidesCardTitle => 'Hướng dẫn trực quan';

  @override
  String get captureVisualGuidesAutoHeading => 'Luồng tự động thu thập';

  @override
  String get captureVisualGuidesOcrHeading => 'OCR vùng màn hình';

  @override
  String get captureVisualGuidesPopupRefineHint =>
      'Mẹo: Trong popup thu thập, kéo chọn một phần đoạn gốc để chỉ dịch cụm đó — có thể chọn lại nhiều lần mà không cần đóng.';

  @override
  String get captureAutoFlowSelectLabel => 'Chọn';

  @override
  String get captureAutoFlowPauseLabel => 'Tạm dừng';

  @override
  String get captureAutoFlowPopupLabel => 'Tra cứu';

  @override
  String get captureAutoFlowCaption => 'Ba bước khi bật (chỉ app khác).';

  @override
  String get captureAutoVisualGuideLink => 'Hướng dẫn từng bước có minh họa…';

  @override
  String get captureDlgAutoCaptureTitle => 'Cách hoạt động tự động thu thập';

  @override
  String get captureDlgAutoCaptureIntro =>
      'Khi bật, Formycareer theo chọn chữ bằng chuột ở app khác — không áp dụng khi thao tác trong cửa sổ Formycareer.\\n\\nSơ đồ dưới đây mô tả diễn biến.';

  @override
  String get captureDlgAutoCaptureStep1Title => '1. Chọn chữ ở app khác';

  @override
  String get captureDlgAutoCaptureStep1Body =>
      'Trình duyệt/PDF/editor: kéo bôi đen hoặc double-click một từ.';

  @override
  String get captureDlgAutoCaptureStep2Title => '2. Thả chuột, chờ nhẹ';

  @override
  String get captureDlgAutoCaptureStep2Body =>
      'Để vùng chọn ổn định trước khi app đọc.';

  @override
  String get captureDlgAutoCaptureStep3Title => '3. Popup hiện';

  @override
  String get captureDlgAutoCaptureStep3Body =>
      'Popup mở đoạn chữ để dịch/lưu — kéo chọn một phần trong vùng gốc để chỉ dịch cụm đó.';

  @override
  String get captureDlgAutoCaptureStep4Title =>
      '4. Chọn từng vùng chữ trong source để dịch tiếp';

  @override
  String get captureDlgAutoCaptureStep4Body =>
      'Trong popup, cứ kéo chọn một đoạn khác trong ô gốc là dịch đúng cụm đó; có thể làm lặp lại nhiều lần mà không cần đóng cửa sổ.';

  @override
  String get captureDlgAutoCaptureSchemeCaption =>
      'Sơ đồ minh họa (không phải UI thật)';

  @override
  String get captureOcrFlowHotkeyLabel => 'Phím tắt';

  @override
  String get captureOcrFlowRegionLabel => 'Vùng chọn';

  @override
  String get captureOcrFlowResultLabel => 'Chữ OCR';

  @override
  String get captureOcrFlowCaption =>
      'Ctrl+Shift+X rồi kéo khung quanh phần chữ cần đọc.';

  @override
  String get captureOcrVisualGuideLink => 'Hướng dẫn OCR có hình…';

  @override
  String get captureDlgOcrGuideTitle => 'Cách OCR vùng màn hình';

  @override
  String get captureDlgOcrGuideIntro =>
      'OCR vùng đọc chữ từ phần màn hình bạn chọn. Luôn chạy khi bạn kích hoạt — không gắn với Tự động thu thập.\\n\\nSơ đồ dưới là các bước.';

  @override
  String get captureDlgOcrStep1Title => '1. Bắt đầu OCR vùng';

  @override
  String get captureDlgOcrStep1Body =>
      'Ctrl+Shift+X từ app khác hoặc phím tắt trong app khi cửa sổ này đang focus.';

  @override
  String get captureDlgOcrStep2Title => '2. Kéo hình chữ nhật';

  @override
  String get captureDlgOcrStep2Body =>
      'Màn hình tối đi — kéo khung quanh đoạn chữ/ảnh cần đọc.';

  @override
  String get captureDlgOcrStep3Title => '3. Xác nhận và xem kết quả';

  @override
  String get captureDlgOcrStep3Body =>
      'Xác nhận — chữ OCR mở trong popup để dịch hoặc lưu.';

  @override
  String get captureDlgOcrStep4Title =>
      '4. Chọn từng vùng chữ trong source để dịch tiếp';

  @override
  String get captureDlgOcrStep4Body =>
      'Trong popup sau OCR, cứ kéo chọn một đoạn khác trong ô gốc là dịch đúng cụm đó; có thể làm lặp lại nhiều lần mà không cần đóng cửa sổ.';

  @override
  String get captureDlgOcrSchemeCaption =>
      'Sơ đồ minh họa (không phải UI thật)';

  @override
  String get captureActiveBehaviorNote =>
      'Sau khi chọn trong app khác, app đọc vùng chọn sau một nhịp chờ — clipboard có thể đổi; tắt nếu cần giữ clipboard.';

  @override
  String get captureShortcutsSectionTitle => 'Thu thập';

  @override
  String get captureShortcutsSectionBody =>
      'Ctrl+Shift+D (chữ), Ctrl+Shift+X (ảnh). Chọn chế độ để xem hướng dẫn.';

  @override
  String get captureTextFromSelection => 'Chữ từ vùng chọn';

  @override
  String get captureImageRegionOcr => 'Ảnh / OCR vùng';

  @override
  String get capturePermissionsTitle => 'Quyền truy cập';

  @override
  String captureAccessibilityGrantedLine(String state) {
    return 'Trợ năng: $state';
  }

  @override
  String captureScreenRecordingGrantedLine(String state) {
    return 'Ghi màn hình: $state';
  }

  @override
  String get capturePermRefresh => 'Làm mới';

  @override
  String get capturePermRequest => 'Yêu cầu quyền còn thiếu';

  @override
  String get capturePermChecking => 'Đang kiểm tra…';

  @override
  String get capturePermAllGranted => 'Đã có đủ quyền thu thập.';

  @override
  String get capturePermSomeMissing =>
      'Vẫn thiếu quyền. Bật trong Cài đặt > Quyền riêng tư.';

  @override
  String get captureHotkeyUnavailable =>
      'Phím nóng toàn cục không khả dụng. Dùng Ctrl+Shift+D / Ctrl+Shift+X trong app.';

  @override
  String get captureDlgTextCaptureTitle => 'Thu thập chữ';

  @override
  String get captureDlgTextCaptureBody =>
      'Thủ công:\\n• Ctrl+Shift+D từ app khác.\\n\\nTự động:\\n• Theo drag-select và double-click để đọc chữ đã bôi.\\n• Không dùng UIA hay nghe clipboard.\\n\\nTắt nếu chỉ muốn hotkey.';

  @override
  String get captureDlgImageCaptureTitle => 'Ảnh / OCR vùng';

  @override
  String get captureDlgImageCaptureBody =>
      'Ctrl+Shift+X hoặc phím trong app.\\n• Chọn khung để OCR.\\nLuôn thủ công.';

  @override
  String get captureDlgTipsTitle => 'Mẹo thu thập';

  @override
  String get captureDlgTipsBody =>
      'Tự động tiện tra cứu; tắt khi viết lâu để tránh ảnh hưởng clipboard.';

  @override
  String get captureHotkeyDlgTitle => 'Nhấn phím tắt mới';

  @override
  String get captureHotkeyDlgHintInitial => 'Nhấn Ctrl+Shift+<chữ hoặc số>';

  @override
  String get captureHotkeyDlgHintRetry => 'Cần Ctrl+Shift + chữ/số';

  @override
  String get vocabPageSubtitle => 'Tìm kiếm, lọc và quản lý bộ thẻ';

  @override
  String get vocabStudySelected => 'Ôn các mục đã chọn';

  @override
  String get vocabStudyFiltered => 'Ôn theo bộ lọc';

  @override
  String get vocabSelectBeforeStudy => 'Chọn từ trước khi ôn.';

  @override
  String get vocabNoMatchFilters => 'Không có từ khớp bộ lọc.';

  @override
  String get vocabTipsTitle => 'Mẹo từ vựng';

  @override
  String get vocabTipsBody =>
      'Lọc ngôn ngữ và nguồn trước khi thao tác hàng loạt.';

  @override
  String get vocabDeleteTitle => 'Xóa từ đã lưu?';

  @override
  String get vocabDeleteBodyOne => 'Sẽ xóa vĩnh viễn từ đã chọn.';

  @override
  String vocabDeleteBodyMany(int count) {
    return 'Sẽ xóa vĩnh viễn $count từ đã chọn.';
  }

  @override
  String get vocabSearchPlaceholder => 'Tìm thuật ngữ, nghĩa hoặc thẻ';

  @override
  String get vocabAllLanguages => 'Tất cả ngôn ngữ';

  @override
  String get vocabAllSources => 'Tất cả nguồn';

  @override
  String get vocabAllTags => 'Tất cả thẻ';

  @override
  String get vocabFilterActive => 'Đang học';

  @override
  String get vocabFilterArchived => 'Đã lưu trữ';

  @override
  String get vocabFilterAll => 'Tất cả';

  @override
  String get vocabClearFilters => 'Xóa bộ lọc';

  @override
  String get vocabTtsSectionTitle =>
      'Google Cloud — chuyển văn bản thành giọng nói';

  @override
  String get vocabTtsSectionBody =>
      'Tổng hợp giọng đọc cho văn bản dài (tự chia nhỏ trong giới hạn Cloud TTS). Cần khóa API Text-to-Speech và bật API Cloud Text-to-Speech trên Google Cloud.';

  @override
  String get vocabTtsApiKeyPlaceholder => 'Khóa API (lưu an toàn trên máy)';

  @override
  String get vocabTtsSaveApiKey => 'Lưu khóa';

  @override
  String get vocabTtsApiKeySaved => 'Đã lưu khóa API.';

  @override
  String get vocabTtsApiKeyFromBuild =>
      'Đang dùng khóa API từ cấu hình build ứng dụng.';

  @override
  String get vocabTtsTextPlaceholder =>
      'Dán hoặc nhập văn bản cần đọc (hỗ trợ đoạn dài)';

  @override
  String vocabTtsStats(int bytes, int segments) {
    return 'Kích thước UTF-8: $bytes · số đoạn gửi API: $segments';
  }

  @override
  String get vocabTtsVoiceLabel => 'Giọng';

  @override
  String get vocabTtsVoiceCustom => 'Giọng tùy chỉnh…';

  @override
  String get vocabTtsCustomVoicePlaceholder =>
      'Tên giọng (vd. en-US-Neural2-J)';

  @override
  String get vocabTtsCustomLangPlaceholder => 'languageCode (vd. en-US)';

  @override
  String get vocabTtsSpeakingRate => 'Tốc độ đọc';

  @override
  String get vocabTtsGeneratePlay => 'Tổng hợp & phát';

  @override
  String get vocabTtsSaveMp3 => 'Lưu MP3…';

  @override
  String get vocabTtsNeedApiKey =>
      'Thêm khóa API Google Cloud Text-to-Speech trước.';

  @override
  String get vocabTtsNeedText => 'Nhập nội dung cần tổng hợp giọng.';

  @override
  String get vocabTtsVoiceInvalid => 'Nhập đủ tên giọng và mã ngôn ngữ.';

  @override
  String vocabTtsError(String message) {
    return '$message';
  }

  @override
  String vocabTtsSavedFile(String path) {
    return 'Đã lưu âm thanh: $path';
  }

  @override
  String get vocabEmptyLibrary => 'Chưa có từ vựng.';

  @override
  String get vocabColTermMeaning => 'Thuật ngữ / Nghĩa';

  @override
  String get vocabColSource => 'Nguồn';

  @override
  String get vocabColTags => 'Thẻ';

  @override
  String get vocabColNextReview => 'Ôn tiếp theo';

  @override
  String get vocabCtxMenuTag => 'Thẻ';

  @override
  String get vocabCtxMenuArchive => 'Lưu trữ';

  @override
  String get vocabCtxMenuResetSrs => 'Đặt lại SRS';

  @override
  String get vocabCtxMenuDelete => 'Xóa';

  @override
  String get bulkTagCreateTitle => 'Tạo thẻ';

  @override
  String get bulkTagCreatePlaceholder => 'Nhập thẻ mới';

  @override
  String get bulkTagRenameTitle => 'Đổi tên thẻ';

  @override
  String get bulkTagRenamePlaceholder => 'Nhập thẻ';

  @override
  String get bulkTagDeleteTitle => 'Xóa thẻ';

  @override
  String bulkTagDeleteBody(String tag) {
    return 'Gỡ \"$tag\" khỏi mọi từ đã lưu?';
  }

  @override
  String get bulkTagFilterPlaceholder => 'Lọc thẻ';

  @override
  String get bulkTagClearSelections => 'Bỏ chọn thẻ';

  @override
  String get bulkTagRename => 'Đổi tên';

  @override
  String get bulkTagDelete => 'Xóa';

  @override
  String get bulkTagApply => 'Áp dụng';

  @override
  String get bulkTagNewBadge => 'Mới';

  @override
  String get bulkTagPanelTitle => 'Thẻ hàng loạt';

  @override
  String get bulkTagEmptyLibrary => 'Chưa có thẻ trong thư viện.';

  @override
  String get bulkTagNoMatchFilter => 'Không có thẻ khớp bộ lọc.';

  @override
  String get bulkTagValidationEmpty => 'Tên thẻ không được để trống.';

  @override
  String get bulkTagValidationDuplicate => 'Thẻ đã tồn tại.';

  @override
  String get bulkTagManageTooltip => 'Quản lý thẻ';

  @override
  String get commonCreate => 'Tạo';

  @override
  String get customStudyTitle => 'Ôn tùy chỉnh';

  @override
  String customStudyEntriesCount(int count) {
    return 'Số mục khớp lựa chọn: $count';
  }

  @override
  String get customStudyMaxLabel => 'Tối đa thẻ (để trống = tất cả)';

  @override
  String get customStudyMaxPlaceholder => 'vd: 50';

  @override
  String get customStudyRandomOrder => 'Ngẫu nhiên';

  @override
  String get customStudyCram => 'Cram (không lưu lịch)';

  @override
  String get customStudyStart => 'Bắt đầu';

  @override
  String get reviewSrsTitle => 'Ôn SRS';

  @override
  String get reviewCramBadge => 'Cram';

  @override
  String reviewQueueCounts(int newCount, int learningCount, int reviewCount) {
    return 'Mới $newCount · Đang học $learningCount · Ôn $reviewCount';
  }

  @override
  String get reviewAutoAudio => 'Tự động phát âm thanh';

  @override
  String get reviewAllLanguages => 'Tất cả ngôn ngữ';

  @override
  String get reviewLanguageFilterTooltip => 'Lọc ngôn ngữ';

  @override
  String get reviewMixedProOnly =>
      'Chế độ mixed là tính năng Pro. Kích hoạt trong Giới thiệu.';

  @override
  String get reviewMixedEnable => 'Bật mixed';

  @override
  String get reviewMixedLocked => 'Mixed (Pro)';

  @override
  String get reviewBasicMode => 'Chế độ cơ bản';

  @override
  String get reviewExitStudy => 'Thoát phiên ôn';

  @override
  String get reviewNoCardsDue => 'Không có thẻ đến hạn.';

  @override
  String get reviewFinishing => 'Đang kết thúc phiên…';

  @override
  String get reviewCompleted => 'Đã hoàn thành ôn.';

  @override
  String reviewReviewsToday(int used, int limit) {
    return 'Ôn hôm nay: $used/$limit';
  }

  @override
  String get reviewTipsTitle => 'Mẹo ôn tập';

  @override
  String get reviewTipsBody =>
      'Enter để lật/kiểm tra, 1–4 để chấm, Ctrl+Enter phát âm thanh, R phát lại.';

  @override
  String get reviewGradeHintForward =>
      'Enter: Lật · 1–4: Điểm · Ctrl+Enter: Âm thanh · R: Phát lại';

  @override
  String get reviewGradeHintReverse =>
      'Enter: Kiểm tra · 1–4: Điểm · Ctrl+Enter: Âm thanh · R: Phát lại';

  @override
  String get reviewAudioFailed => 'Không phát được âm thanh.';

  @override
  String get reviewPlayTerm => 'Phát thuật ngữ';

  @override
  String get reviewPlayAudio => 'Phát âm thanh';

  @override
  String get reviewMeaning => 'Nghĩa';

  @override
  String get reviewListenType => 'Nghe và gõ';

  @override
  String get reviewListenInstructions => 'Phát âm và gõ từ gốc.';

  @override
  String get reviewTypeOriginalPlaceholder => 'Nhập từ gốc';

  @override
  String get reviewCheckAnswer => 'Kiểm tra (Enter)';

  @override
  String get reviewCorrect => 'Đúng';

  @override
  String get reviewIncorrect => 'Sai';

  @override
  String get reviewYourAnswer => 'Câu trả lời của bạn:';

  @override
  String get reviewExpected => 'Đúng là:';

  @override
  String get reviewAnswerEmptyMarker => '(trống)';

  @override
  String get reviewGradeAgain => 'Lại (1)';

  @override
  String get reviewGradeHard => 'Khó (2)';

  @override
  String get reviewGradeGood => 'Tốt (3)';

  @override
  String get reviewGradeEasy => 'Dễ (4)';

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
    return 'Từ vừa ôn ($count)';
  }

  @override
  String get reviewSummaryClose => 'Đóng';

  @override
  String get reviewSummaryTitle => 'Tổng kết phiên ôn';

  @override
  String reviewSummaryGreatJob(String name) {
    return 'Tuyệt vời, $name!';
  }

  @override
  String get reviewSummaryEncourage => 'Bạn đã hoàn thành mục tiêu hôm nay.';

  @override
  String get reviewSummaryStatReviewed => 'Đã ôn';

  @override
  String get reviewSummaryStatMastered => 'Ghi nhớ tốt';

  @override
  String get reviewSummaryStatTime => 'Thời gian';

  @override
  String get reviewSummaryBackDashboard => 'Về Dashboard';

  @override
  String get reviewSummarySeeWords => 'Xem danh sách từ vừa ôn';

  @override
  String get reviewSummaryCloudSyncing => 'Đang đồng bộ đám mây…';

  @override
  String get reviewSummaryCloudOk => 'Đồng bộ đám mây thành công';

  @override
  String get reviewSummaryCloudFail => 'Không đồng bộ được đám mây';

  @override
  String get reviewSummaryYou => 'Bạn';

  @override
  String reviewDurSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String reviewDurMinutes(int minutes) {
    return '$minutes phút';
  }

  @override
  String reviewDurMinutesSeconds(int minutes, int seconds) {
    return '$minutes phút $seconds giây';
  }

  @override
  String reviewDurHours(int hours) {
    return '$hours giờ';
  }

  @override
  String reviewDurHoursMinutes(int hours, int minutes) {
    return '$hours giờ $minutes phút';
  }

  @override
  String get captureSavePhrase => 'Lưu cụm từ';

  @override
  String get captureSaveLine => 'Lưu dòng';

  @override
  String get captureWholeLine => 'Cả dòng';

  @override
  String get captureListenSource => 'Nghe nguồn';

  @override
  String get captureNoTextDetected => 'Không phát hiện chữ';

  @override
  String get captureAddTagLabel => 'Thêm thẻ';

  @override
  String get captureTagHint => 'Nhập thẻ';

  @override
  String get captureAutoRecentTag => 'Tự điền thẻ gần đây';

  @override
  String get captureNoRecentTagsYet =>
      'Chưa có thẻ gần đây — lưu một mục có thẻ để dùng.';

  @override
  String get captureSavedToast => 'Đã lưu ✓';

  @override
  String captureDailySaveLimitReached(int limit) {
    return 'Bạn đã đạt giới hạn lưu hôm nay ($limit lượt/ngày). Nâng cấp Pro để lưu không giới hạn.';
  }

  @override
  String captureDailyTranslateLimitReached(int limit) {
    return 'Bạn đã đạt giới hạn dịch hôm nay ($limit lượt/ngày). Nâng cấp Pro để dịch không giới hạn.';
  }

  @override
  String get settingsTagManagerEmpty => 'Chưa có thẻ.';

  @override
  String get meaningTranslating => 'Đang dịch…';

  @override
  String get meaningNoTranslationYet => 'Chưa có bản dịch.';

  @override
  String get meaningDictHeading => 'Định nghĩa (tiếng Anh)';

  @override
  String get meaningFieldLabel => 'Nghĩa';

  @override
  String get meaningFieldHint => 'Sửa bản dịch';

  @override
  String get meaningPlayPronunciation => 'Phát phiên âm';

  @override
  String get meaningPlay => 'Phát';

  @override
  String get meaningPause => 'Tạm dừng';

  @override
  String get meaningPhraseMarker => '(CỤM TỪ)';

  @override
  String get settingsReviewAudioSection => 'Âm thanh ôn tập';

  @override
  String get settingsAutoPlayAudioTitle =>
      'Tự động phát âm thanh khi có thẻ mới';

  @override
  String get settingsRememberTagTitle => 'Ghi nhớ thẻ cuối khi thêm từ';

  @override
  String get settingsLocalBackupTitle => 'Sao lưu cục bộ';

  @override
  String get settingsBackupNowJson => 'Sao lưu ngay (JSON)';

  @override
  String get settingsImportBackup => 'Nhập backup (.db / .json)';

  @override
  String get settingsBackupFootnote =>
      'Dùng JSON ký từ app hoặc backup .db/.json.';

  @override
  String get settingsManageTagsTitle => 'Quản lý thẻ';

  @override
  String get settingsManageTagsSubtitle => 'Đổi tên/xóa thẻ trên mọi từ.';

  @override
  String get settingsReplaceVocabTitle => 'Thay thế từ vựng cục bộ?';

  @override
  String get settingsReplaceVocabBody =>
      'Mọi từ đã lưu trên thiết bị sẽ bị thay bằng backup. Không hoàn tác.';

  @override
  String get settingsChooseFile => 'Chọn tệp';

  @override
  String get settingsImporting => 'Đang nhập backup…';

  @override
  String settingsImportedCount(int count, String kind) {
    return 'Đã nhập $count mục ($kind).';
  }

  @override
  String get settingsExportCancelled => 'Đã hủy xuất';

  @override
  String settingsSavedPath(String path) {
    return 'Đã lưu: $path';
  }

  @override
  String settingsExportFailed(String error) {
    return 'Xuất thất bại: $error';
  }

  @override
  String settingsImportFailed(String error) {
    return 'Nhập thất bại: $error';
  }

  @override
  String settingsLanguageLoadError(String error) {
    return 'Lỗi cài đặt ngôn ngữ: $error';
  }

  @override
  String commonErrorPrefix(String error) {
    return 'Lỗi: $error';
  }

  @override
  String get dashLearnerPickerLabel => 'Ai đang học?';

  @override
  String get dashLearnerPickerNewButton => 'Tạo mới';

  @override
  String get localProfilesSectionTitle => 'Người học trên máy';

  @override
  String get localProfilesSectionDescription =>
      'Mỗi người có một bộ từ riêng trên thiết bị này. Đổi hồ sơ để học bộ từ khác.';

  @override
  String get localProfileDefaultName => 'Mặc định';

  @override
  String get localProfileActiveBadge => 'Đang dùng';

  @override
  String get localProfileUseAction => 'Chọn';

  @override
  String get localProfileAddAction => 'Thêm người học';

  @override
  String get localProfileRenameAction => 'Đổi tên';

  @override
  String get localProfileDeleteAction => 'Xóa';

  @override
  String get localProfileAddTitle => 'Người học mới';

  @override
  String get localProfileRenameTitle => 'Đổi tên người học';

  @override
  String get localProfileNameLabel => 'Tên hiển thị';

  @override
  String get localProfileDeleteConfirmTitle => 'Xóa người học?';

  @override
  String get localProfileDeleteConfirmBody =>
      'Từ vựng của họ vẫn lưu trên máy cho đến khi bạn xóa dữ liệu app. Bạn có thể thêm lại bất cứ lúc nào.';
}
