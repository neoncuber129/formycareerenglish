#!/usr/bin/env python3
"""Merge app_en.arb keys/metadata into vi/ja/zh/ko ARBs with translations."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "lib" / "l10n"

# Pipe-separated rows: key|vi|ja|zh|ko (omit lines starting with #)
PATCH_TABLE = r"""
commonCancel|Hủy|キャンセル|取消|취소
commonClose|Đóng|閉じる|关闭|닫기
commonDelete|Xóa|削除|删除|삭제
commonSave|Lưu|保存|保存|저장
commonBack|Quay lại|戻る|返回|뒤로
commonOk|OK|OK|确定|확인
commonRefresh|Làm mới|更新|刷新|새로 고침
commonTips|Mẹo|ヒント|提示|팁
commonGranted|Đã cấp|許可済み|已授权|허용됨
commonMissing|Thiếu|未許可|缺失|없음
commonChecking|Đang kiểm tra…|確認中…|正在检查…|확인 중…
commonLoading|Đang tải…|読み込み中…|加载中…|로드 중…
commonStudy|Ôn tập|学習|学习|학습
commonTag|Thẻ|タグ|标签|태그
commonArchive|Lưu trữ|アーカイブ|归档|보관
commonResetSrs|Đặt lại SRS|SRS をリセット|重置 SRS|SRS 초기화
commonActivate|Kích hoạt|有効化|激活|활성화
cmdCancelEsc|Hủy (Esc)|キャンセル (Esc)|取消 (Esc)|취소 (Esc)
cmdOneItemSelected|Đã chọn 1 mục|1 件選択|已选择 1 项|1개 선택됨
cmdManyItemsSelected|Đã chọn {count} mục|{count} 件選択|已选择 {count} 项|{count}개 선택됨
dashSubtitle|Tổng quan học tập, biểu đồ và điều hướng nhanh|学習スナップショットとナビ|学习概览与快捷入口|학습 요약 및 빠른 이동
dashCouldNotLoadVocab|Không tải được từ vựng: {error}|語彙を読み込めません: {error}|无法加载词汇：{error}|단어장을 불러올 수 없습니다: {error}
dashHeroTitle|Trung tâm học tập của bạn|あなたの学習ハブ|你的学习中心|내 학습 허브
dashHeroStatsLine|{dueNow} sẵn sàng ngay · {active} thẻ trong bộ đang học · {newCount} thẻ mới|今すぐ {dueNow} · アクティブ {active} 枚 · 新規 {newCount}|即时 {dueNow} 张 · 活跃卡组 {active} · 新卡 {newCount}|지금 {dueNow}개 · 활성 덱 {active}장 · 새 카드 {newCount}
dashHeroShareCaption|Tỷ lệ bộ đang học đến hạn ôn|アクティブデッキの復習割合|活跃卡组到期占比|활성 덱 중 복습 비율
dashHeroPercentDue|{percent}% thẻ đang học đến hạn|アクティブの {percent}% が期限|活跃卡牌中 {percent}% 到期|활성 카드의 {percent}% 만료
dashStatDueNowTitle|Đến hạn ngay|今すぐ|现在到期|지금 만료
dashStatDueNowSubtitle|Sẵn sàng ôn SRS|SRS 復習対応|可进行 SRS 复习|SRS 복습 가능
dashStatActiveTitle|Bộ đang học|アクティブデッキ|活跃卡组|활성 덱
dashStatActiveSubtitle|Mục chưa lưu trữ|アーカイブ以外|未归档条目|보관 안 함
dashStatNewTitle|Mới|新規|新卡|신규
dashStatNewSubtitle|Chưa từng ôn|未復習|从未复习|복습 안 함
dashStatArchivedTitle|Đã lưu trữ|アーカイブ済み|已归档|보관됨
dashStatArchivedSubtitle|Tạm dừng khỏi hàng đợi|キューから除外|暂停队列|대기열 제외
dashInsightUpcoming|Ôn sắp tới|今後の復習|即将到来复习|예정 복습
dashInsightDeckComposition|Cấu trúc bộ thẻ|デッキ構成|卡组构成|덱 구성
dashInsightByLanguage|Theo ngôn ngữ|言語別|按语言|언어별
dashInsightPopularTags|Thẻ phổ biến|人気タグ|常用标签|인기 태그
dashEmptyLangPairs|Chưa có cặp ngôn ngữ.|言語ペアがありません。|尚无语言对。|언어 쌍이 없습니다.
dashEmptyTags|Chưa có thẻ — thêm khi thu thập.|タグがありません — 取り込み時に追加。|尚无标签 — 采集时添加。|태그 없음 — 수집 시 추가하세요.
dashDeckCompositionEmpty|Thêm từ vựng để xem cấu trúc.|語彙を追加すると構成が表示されます。|添加词汇后可查看构成。|단어를 추가하면 구성이 표시됩니다.
dashLegendNewCount|Mới · {count}|新規 · {count}|新 · {count}|신규 · {count}
dashLegendLearningCount|Đang học (1–6 lần ôn) · {count}|学習中 (1〜6回) · {count}|学习中 (1–6 次) · {count}|학습 중(1–6회) · {count}
dashLegendEstablishedCount|Ổn định (>6 lần ôn) · {count}|定着 (>6回) · {count}|巩固 (>6 次) · {count}|안정(>6회) · {count}
dashDueNowRow|Đến hạn hoặc quá hạn|期限切れ・今日期限|到期或过期|만료 또는 지각
dashDueWeekRow|Đến hạn trong 7 ngày tới (sau hôm nay)|今後7日以内（翌日以降）|未来 7 天内（不含今天）|향후 7일 이내(오늘 제외)
dashDueLaterRow|Sau đó|それ以降|更晚以后|그 이후
dashQuickActions|Thao tác nhanh|クイックアクション|快捷操作|빠른 작업
dashStartReview|Bắt đầu ôn|復習開始|开始复习|복습 시작
dashOpenVocabulary|Mở từ vựng|単語帳を開く|打开词汇库|단어장 열기
dashCapture|Thu thập|取り込み|采集|수집
dashNothingDueHint|Hiện không có thẻ đến hạn. Bạn vẫn có thể ôn trước từ tab Ôn tập.|今は期限カードがありません。復習タブで先行できます。|目前没有到期卡片，仍可在复习标签预习。|만료 카드 없음. 복습 탭에서 미리 할 수 있습니다.
mobileDashSubtitle|Tổng quan học tập|学習スナップショット|学习快照|학습 스냅샷
mobileDashLoadFailed|Không tải được từ vựng.\n{error}|語彙を読み込めません。\n{error}|无法加载词汇。\n{error}|단어장을 불러올 수 없습니다.\n{error}
mobileStatDueSubtitle|Hàng đợi SRS|SRS キュー|SRS 队列|SRS 대기열
mobileStatActiveSubtitle|Trong bộ|デッキ内|卡组中|덱 안
mobileStatNewSubtitle|Chưa ôn|未復習|未复习|미복습
mobileStatArchivedSubtitle|Tạm dừng|一時停止|已暂停|일시중지
mobileGoReview|Đi tới Ôn tập|復習へ|前往复习|복습으로
mobileGoWords|Mở Từ vựng|単語へ|打开词汇|단어로
navGuides|Hướng dẫn|ガイド|指南|가이드
guidesPageSubtitle|Mẹo cho capture, ôn tập, từ vựng và dùng hằng ngày.|キャプチャ・復習・語彙・日常利用のヒント。|采集、复习、词汇与日常使用提示。|캡처·복습·단어·일상 사용 팁.
guidesIntroTitle|Điều hướng|基本的な見方|界面导览|탭 안내
guidesIntroBody|Sử dụng các tab bên trái: Dashboard — ảnh chụp học tập; Capture — lấy chữ từ app khác; Review — ôn SRS; Vocabulary — duyệt và gọn thẻ; Guides — trợ giúp này; Settings — ngôn ngữ, sao lưu, phím tắt; About — phiên bản, Pro và hỗ trợ.|左のタブ：ダッシュボード／キャプチャ／復習／語彙／このガイド／設定／情報。|左侧标签页：仪表盘、采集、复习、词汇、本指南、设置、关于。|왼쪽 탭: 대시보드·수집·복습·단어·이 안내·설정·정보.
guidesCaptureTitle|Thu thập|キャプチャ|采集|수집
guidesCaptureBody|Phím tắt (khi đăng ký được): thường Ctrl+Shift+D cho chữ đã chọn và Ctrl+Shift+X cho OCR vùng — xem tab Capture nếu đăng ký thất bại. Bật Auto capture để theo chọn chữ app khác. Trong popup, kéo chọn trong ô nguồn để chỉ dịch một cụm; Lưu thêm thẻ vào thư viện.|ショートカットはキャプチャタブ参照。自動取り込みで他アプリ選択を追跡。ポップアップでは原文をドラッグして一部だけ翻訳。|快捷键见 Capture 标签；自动采集跟随其他应用选择；弹窗内拖选原文仅翻译片段。|단축키는 캡처 탭 참고. 자동 수집으로 다른 앱 선택 추적. 팝업에서 원문 일부 드래그해 번역.
guidesReviewTitle|Ôn tập (SRS)|復習（SRS）|复习（SRS）|복습(SRS)
guidesReviewBody|Tab Ôn tập chạy SRS. Chấm điểm trung thực để lịch ôn có ý nghĩa. Pro mở ôn mixed (xuôi, đảo nghĩa, audio trong một phiên).|復習タブでSRS。正直に評価。Proでミックス復習。|复习标签运行 SRS；如实评分；Pro 解锁混合复习。|복습 탭에서 SRS. Pro는 혼합 복습.
guidesVocabTitle|Từ vựng|語彙|词汇|단어장
guidesVocabBody|Tìm kiếm, gắn thẻ, lưu trữ và chỉnh trong tab Từ vựng. Đồng bộ và xuất tùy tài khoản và Cài đặt.|語彙タブで検索・タグ・アーカイブ。同期とエクスポートは設定依存。|词汇标签内搜索、标签、归档；同步与导出取决于账户与设置。|단어 탭에서 검색·태그·보관. 동기화는 설정 따름.
guidesSettingsTitle|Cài đặt & sao lưu|設定とバックアップ|设置与备份|설정 및 백업
guidesSettingsBody|Chọn ngôn ngữ gốc cho dịch, cỡ chữ, phím bật/tắt auto capture và thư mục sao lưu cục bộ. Sao lưu giúp khi cài lại hoặc đổi máy.|母語・文字サイズ・ホットキー・バックアップ先を設定。|设置母语、字号、热键与本地备份文件夹。|모국어·글자 크기·단축키·백업 폴더 설정.
guidesProTitle|Miễn phí và Pro|無料と Pro|免费与 Pro|무료 및 Pro
guidesProBody|Free có thể giới hạn/ngày lưu capture và gọi dịch popup trên desktop (cache thường không tính). Pro gỡ banner desktop, ôn mixed, SRS không giới hạn/ngày và gỡ giới hạn capture desktop đó. Tab Giới thiệu để cập nhật, kích hoạt và mua Pro.|無料はデスクトップの保存・翻訳に日次上限（キャッシュ除く）。Proは広告なし・ミックス・SRS無制限・キャプチャ無制限。情報タブで購入。|免费版可能对桌面捕获保存与弹窗翻译设每日上限（缓存多半不计）；Pro 去广告、混合复习、SRS 与捕获不限等。关于标签购买。|무료는 일일 한도 있을 수 있음. Pro는 배너 제거·혼합 복습·무제한 등. 정보 탭에서 구매.
aboutPageSubtitle|Thông tin ứng dụng và bản quyền|アプリ情報とライセンス|应用信息与许可|앱 정보 및 라이선스
aboutTagline|Không gian học ngôn ngữ đa nền tảng: thu thập, ôn tập và quản lý từ vựng.|クロスプラットフォームの語学学習ワークスペース。|跨平台语言学习工作台。|캡처·복습·단어 관리를 위한 학습 공간입니다.
aboutVersionPrefix|Phiên bản {version}|バージョン {version}|版本 {version}|버전 {version}
aboutUpdatesSection|Cập nhật & Pro|アップデートと Pro|更新与 Pro|업데이트 및 Pro
aboutLatestVersionLabel|Phiên bản mới nhất: {version}|最新バージョン: {version}|最新版本：{version}|최신 버전: {version}
aboutUpdateAvailable|Có bản cập nhật cho ứng dụng.|このアプリに更新があります。|此应用有可用更新。|업데이트가 있습니다.
aboutUsingLatest|Bạn đang dùng phiên bản mới nhất.|最新バージョンを使用中です。|您正在使用最新版本。|최신 버전을 사용 중입니다.
aboutReleaseNotesPrefix|Ghi chú phát hành: {notes}|リリースノート: {notes}|发行说明：{notes}|릴리스 노트: {notes}
aboutMinVersionWarning|Phiên bản này thấp hơn phiên bản tối thiểu được hỗ trợ.|サポートされる最小バージョンを下回っています。|低于最低支持版本。|지원 최소 버전 미만입니다.
aboutPlanPro|Gói hiện tại: Pro|現在のプラン: Pro|当前方案：Pro|현재 플랜: Pro
aboutPlanFree|Gói hiện tại: Miễn phí|現在のプラン: Free|当前方案：免费|현재 플랜: 무료
aboutProKeyInstructions|Dùng mã bản quyền Lemon Squeezy gửi sau thanh toán. Xem phần Pro bên dưới.|お支払い後に届く Lemon Squeezy のライセンスキーを入力。|使用 Lemon Squeezy 邮件中的许可证密钥。|Lemon Squeezy 라이선스 키를 입력하세요.
aboutCheckUpdates|Kiểm tra cập nhật|更新を確認|检查更新|업데이트 확인
aboutCheckingUpdates|Đang kiểm tra…|確認中…|正在检查…|확인 중…
aboutDownloadLatest|Tải bản mới nhất|最新をダウンロード|下载最新版|최신 다운로드
aboutVisitProWebsite|Vào trang web để mua Pro|サイトで Pro を購入|前往网站购买 Pro|웹사이트에서 Pro 구매
aboutActivating|Đang kích hoạt…|有効化中…|正在激活…|활성화 중…
aboutActivatePro|Kích hoạt Pro|Pro を有効化|激活 Pro|Pro 활성화
aboutActivateProTitle|Kích hoạt Pro|Pro を有効化|激活 Pro|Pro 활성화
aboutActivateProPlaceholder|Dán mã bản quyền từ email Lemon Squeezy|メールのライセンスキーを貼り付け|粘贴 Lemon Squeezy 邮件中的密钥|이메일의 라이선스 키 붙여넣기
aboutUpdateCheckDone|Đã kiểm tra cập nhật|更新チェック完了|已完成更新检查|업데이트 확인 완료
aboutWhatProUnlocks|Pro mở khóa gì|Pro の内容|Pro 权益|Pro 혜택
aboutOneLicense|Một license kích hoạt Pro cho desktop và mobile.|1つのライセンスでデスクトップとモバイルの Pro が有効。|一份许可证可同时激活桌面与移动版。|라이선스 하나로 데스크톱·모바일 Pro.
aboutProBenefit1|Không quảng cáo banner trên desktop khi có Pro.|Pro 時デスクトップにバナー広告なし。|桌面端 Pro 无横幅广告。|Pro 시 데스크톱 배너 광고 없음.
aboutProBenefit2|Chế độ ôn hỗn hợp: kết hợp xuôi, đảo nghĩa và nghe trong một phiên.|ミックス復習モード。|混合复习模式。|혼합 복습 모드.
aboutProBenefit3|Không giới hạn lượt chấm điểm SRS mỗi ngày (Miễn phí: tối đa 100/ngày).|SRS の日次採点が無制限（無料は100回/日）。|SRS 每日评分不限（免费每日 100）。|SRS 일일 채점 무제한(무료 100회).
aboutProBenefit4|Lưu từ mới không giới hạn từ capture trên desktop mỗi ngày (Free: giới hạn/ngày).|デスクトップのキャプチャからの語彙保存が1日あたり無制限（無料は日次上限）。|桌面端从捕获保存生词每日不限（免费版有每日上限）。|데스크톱 캡처에서 저장하는 새 단어가 일일 무제한(무료는 일일 한도).
aboutProBenefit5|Dịch không giới hạn trong popup capture trên desktop mỗi ngày; trùng cache không tính lượt (Free: giới hạn/ngày).|デスクトップのキャプチャポップアップでの翻訳が1日無制限。キャッシュはカウントされません（無料は日次上限）。|桌面捕获弹窗翻译请求每日不限；缓存命中不计入额度（免费版有每日上限）。|데스크톱 캡처 팝업 번역 요청 일일 무제한. 캐시 적중은 한도에 포함 안 됨(무료는 일일 한도).
aboutSupportLegal|Hỗ trợ & Pháp lý|サポートと法的情報|支持与法律信息|지원 및 법적 정보
aboutSupportEmailPrefix|Email hỗ trợ: {email}|サポート: {email}|支持邮箱：{email}|지원 이메일: {email}
aboutCopySupportEmail|Sao chép email hỗ trợ|サポートメールをコピー|复制支持邮箱|지원 메일 복사
aboutOpenSourceLicenses|Giấy phép mã nguồn mở|オープンソースライセンス|开源许可|오픈소스 라이선스
aboutSupportEmailCopied|Đã sao chép email hỗ trợ|コピーしました|已复制支持邮箱|복사함
capturePageSubtitle|Tự động thu thập, phím tắt và đồng bộ|自動取り込み・ショートカット・同期|自动采集、快捷键与同步|자동 수집·단축키·동기화
captureAutoCaptureTitle|Tự động thu thập|自動取り込み|自动采集|자동 수집
captureAutoCaptureBody|Bật: theo chọn chữ app khác qua chuột. Tắt: chỉ Ctrl+Shift+D.|オンで他アプリの選択を追跡。オフなら Ctrl+Shift+D のみ。|开启：跟随其他应用鼠标选择；关闭：仅用快捷键。|켜면 다른 앱 선택 추적. 끄면 Ctrl+Shift+D만.
captureAutoToggleShortcutLine|Bật nhanh bằng {shortcut}.|{shortcut} で切り替え。|使用 {shortcut} 切换。|{shortcut}(으)로 전환.
captureHotkeyToggleLabel|Phím tắt bật/tắt tự động thu thập|自動取り込み切替ホットキー|切换自动采集热键|자동 수집 전환 단축키
capturePressNewShortcut|Nhập phím tắt mới|新しいショートカットを押す|按下新快捷键|새 단축키 입력
captureAutoStatusOn|BẬT|ON|开|켜짐
captureAutoStatusOff|TẮT|OFF|关|꺼짐
captureAutoToast|Tự động thu thập: {status} ({hotkey})|自動取り込み: {status} ({hotkey})|自动采集：{status} ({hotkey})|자동 수집: {status} ({hotkey})
captureHotkeySetToast|Đặt phím tự động thu thập thành Ctrl+Shift+{key}|自動取り込みホットキーを Ctrl+Shift+{key}|自动采集热键设为 Ctrl+Shift+{key}|자동 수집 단축키 Ctrl+Shift+{key}
captureVisualGuidesCardTitle|Hướng dẫn trực quan|ビジュアルガイド|图示指南|시각 안내
captureVisualGuidesAutoHeading|Luồng tự động thu thập|自動取り込みの流れ|自动采集流程|자동 수집 흐름
captureVisualGuidesOcrHeading|OCR vùng màn hình|画面領域 OCR|屏幕区域 OCR|화면 영역 OCR
captureVisualGuidesPopupRefineHint|Mẹo: Trong popup thu thập, kéo chọn một phần đoạn gốc để chỉ dịch cụm đó — có thể chọn lại nhiều lần mà không cần đóng.|ヒント: ポップアップの原文をドラッグ選択すると、その部分だけを翻訳できます（閉じずに何度でも変えられます）。|提示：在采集弹出窗口中拖选原文片段，可仅翻译该短语；不关窗口可多次调整选区。|팁: 수집 팝업에서 원문 일부를 드래그하면 그 구만 번역합니다. 닫지 않고 여러 번 바꿀 수 있습니다.
captureAutoFlowSelectLabel|Chọn|選択|选择|선택
captureAutoFlowPauseLabel|Tạm dừng|一時停止|暂停|대기
captureAutoFlowPopupLabel|Tra cứu|調べる|查阅|조회
captureAutoFlowCaption|Ba bước khi bật (chỉ app khác).|オン時は3ステップ（他アプリ）。|开启后为三步（其他应用）。|켜짐 시 3단계(다른 앱).
captureAutoVisualGuideLink|Hướng dẫn từng bước có minh họa…|ステップごとのガイド…|分步图解指南…|단계별 안내…
captureDlgAutoCaptureTitle|Cách hoạt động tự động thu thập|自動取り込みの仕組み|自动采集如何工作|자동 수집 작동 방식
captureDlgAutoCaptureIntro|Khi bật, Formycareer theo chọn chữ bằng chuột ở app khác — không áp dụng khi thao tác trong cửa sổ Formycareer.\n\nSơ đồ dưới đây mô tả diễn biến.|オン時は Formycareer が他アプリのマウス選択を監視します（このアプリ内は対象外）。\n\n下図は流れのイメージです。|开启后，Formycareer 会监听其他程序中的鼠标选字（本应用窗口内不计）。\n\n下图示意流程。|켜면 Formycareer가 다른 앱의 마우스 선택을 감지합니다(Formycareer 창 안은 제외).\n\n아래는 흐름 도식입니다.
captureDlgAutoCaptureStep1Title|1. Chọn chữ ở app khác|1. 他アプリで選択|1. 在其他应用中选中文本|1. 다른 앱에서 선택
captureDlgAutoCaptureStep1Body|Trình duyệt/PDF/editor: kéo bôi đen hoặc double-click một từ.|ブラウザや PDF でドラッグ、または単語をダブルクリック。|浏览器或 PDF：拖动选中，或双击单词。|브라우저·PDF 등에서 드래그 또는 단어 더블클릭.
captureDlgAutoCaptureStep2Title|2. Thả chuột, chờ nhẹ|2. マウスを離して少し待つ|2. 松开鼠标稍等|2. 놓고 잠시 대기
captureDlgAutoCaptureStep2Body|Để vùng chọn ổn định trước khi app đọc.|ハイライトが安定してから読み取ります。|让高亮稳定后再读取。|선택이 안정된 뒤 읽습니다.
captureDlgAutoCaptureStep3Title|3. Popup hiện|3. ポップアップ表示|3. 弹出查阅窗口|3. 팝업 표시
captureDlgAutoCaptureStep3Body|Popup mở đoạn chữ để dịch/lưu — kéo chọn một phần trong vùng gốc để chỉ dịch cụm đó.|ポップアップで全文が開きます。原文エリアでドラッグ選択すると、その語句だけ翻訳できます。|弹出窗口显示全文以便翻译或保存；在原文区域拖选即可只翻译该片段。|팝업에서 문단을 열어 번역·저장 — 원문 영역에서 드래그하면 그 구만 번역합니다.
captureDlgAutoCaptureStep4Title|4. Chọn từng vùng chữ trong source để dịch tiếp|4. 原文で別の範囲を選び続ける|4. 继续在原文中选择片段|4. 원문에서 다른 구간 더 선택
captureDlgAutoCaptureStep4Body|Trong popup, cứ kéo chọn một đoạn khác trong ô gốc là dịch đúng cụm đó; có thể làm lặp lại nhiều lần mà không cần đóng cửa sổ.|ポップアップの原文エリアで、必要なたびに別の語句をドラッグ選択できます。選択するたびにその部分だけが翻訳され、ウィンドウを閉じずに何度でも繰り返せます。|在弹出窗口的原文区域可随时拖选另一段文字——每次选择仅翻译该片段，可反复操作而无需关闭窗口。|팝업의 원문 영역에서 필요할 때마다 다른 구간을 드래그 선택하면 그 부분만 번역되며, 창을 닫지 않고 반복할 수 있습니다.
captureDlgAutoCaptureSchemeCaption|Sơ đồ minh họa (không phải UI thật)|模式図（実際の UI ではありません）|示意图（非真实界面）|개념도(실제 UI 아님)
captureOcrFlowHotkeyLabel|Phím tắt|ショートカット|快捷键|단축키
captureOcrFlowRegionLabel|Vùng chọn|範囲指定|框选区域|영역 지정
captureOcrFlowResultLabel|Chữ OCR|OCR テキスト|识别文字|OCR 텍스트
captureOcrFlowCaption|Ctrl+Shift+X rồi kéo khung quanh phần chữ cần đọc.|Ctrl+Shift+X で範囲をドラッグ。|Ctrl+Shift+X 后在屏幕上框选文字。|Ctrl+Shift+X 후 영역을 드래그하세요.
captureOcrVisualGuideLink|Hướng dẫn OCR có hình…|OCR のステップガイド…|OCR 分步图解…|OCR 단계 안내…
captureDlgOcrGuideTitle|Cách OCR vùng màn hình|領域 OCR の流れ|区域 OCR 如何使用|영역 OCR 방법
captureDlgOcrGuideIntro|OCR vùng đọc chữ từ phần màn hình bạn chọn. Luôn chạy khi bạn kích hoạt — không gắn với Tự động thu thập.\n\nSơ đồ dưới là các bước.|領域 OCR は選択した画面領域から文字を読み取ります。自動取り込みとは無関係です。\n\n下図は流れです。|区域 OCR 从所选屏幕区域识别文字；与自动采集无关。\n\n下图示意步骤。|영역 OCR은 선택한 화면에서 글자를 읽습니다. 자동 수집과 무관합니다.\n\n아래는 단계입니다.
captureDlgOcrStep1Title|1. Bắt đầu OCR vùng|1. 領域キャプチャ開始|1. 开始区域采集|1. 영역 캡처 시작
captureDlgOcrStep1Body|Ctrl+Shift+X từ app khác hoặc phím tắt trong app khi cửa sổ này đang focus.|Ctrl+Shift+X（グローバル）またはフォーカス時のアプリ内ショートカット。|在其他应用中按 Ctrl+Shift+X，或本窗口聚焦时使用应用内快捷键。|다른 앱에서 Ctrl+Shift+X 또는 이 창 포커스 시 단축키.
captureDlgOcrStep2Title|2. Kéo hình chữ nhật|2. 矩形をドラッグ|2. 拖动矩形框选|2. 사각형 드래그
captureDlgOcrStep2Body|Màn hình tối đi — kéo khung quanh đoạn chữ/ảnh cần đọc.|画面が暗くなります。読み取りたい範囲をドラッグ。|屏幕变暗后，拖动框住要识别的文字或图像。|화면이 어두워지면 드래그로 영역 지정.
captureDlgOcrStep3Title|3. Xác nhận và xem kết quả|3. 確定して確認|3. 确认并查看结果|3. 확인 후 결과 보기
captureDlgOcrStep3Body|Xác nhận — chữ OCR mở trong popup để dịch hoặc lưu.|確定後、OCR で読み取ったテキストがポップアップで開き、翻訳や保存ができます。|确认后，识别文字在弹出窗口打开，可翻译或保存。|확인 후 OCR 결과가 팝업에서 열려 번역하거나 저장할 수 있습니다.
captureDlgOcrStep4Title|4. Chọn từng vùng chữ trong source để dịch tiếp|4. 原文で別の範囲を選び続ける|4. 继续在原文中选择片段|4. 원문에서 다른 구간 더 선택
captureDlgOcrStep4Body|Trong popup sau OCR, cứ kéo chọn một đoạn khác trong ô gốc là dịch đúng cụm đó; có thể làm lặp lại nhiều lần mà không cần đóng cửa sổ.|ポップアップの原文エリアで、必要なたびに別の語句をドラッグ選択できます。選択するたびにその部分だけが翻訳され、ウィンドウを閉じずに何度でも繰り返せます。|在弹出窗口的原文区域可随时拖选另一段文字——每次选择仅翻译该片段，可反复操作而无需关闭窗口。|팝업의 원문 영역에서 필요할 때마다 다른 구간을 드래그 선택하면 그 부분만 번역되며, 창을 닫지 않고 반복할 수 있습니다.
captureDlgOcrSchemeCaption|Sơ đồ minh họa (không phải UI thật)|模式図（実際の UI ではありません）|示意图（非真实界面）|개념도(실제 UI 아님)
captureActiveBehaviorNote|Sau khi chọn trong app khác, app đọc vùng chọn sau một nhịp chờ — clipboard có thể đổi; tắt nếu cần giữ clipboard.|他アプリで選択後、短い待機のあと読み取り。クリップボードが変わる場合があります。|在其他应用选中后，短暂停顿后读取；剪贴板可能会变化。|선택 후 잠시 뒤 읽음 — 클립보드가 바뀔 수 있음.
captureShortcutsSectionTitle|Thu thập|取り込み|采集|수집
captureShortcutsSectionBody|Ctrl+Shift+D (chữ), Ctrl+Shift+X (ảnh). Chọn chế độ để xem hướng dẫn.|Ctrl+Shift+D（テキスト）、Ctrl+Shift+X（画像）。|Ctrl+Shift+D（文本）、Ctrl+Shift+X（区域）。|Ctrl+Shift+D(텍스트), Ctrl+Shift+X(영역).
captureTextFromSelection|Chữ từ vùng chọn|選択からテキスト|从选择获取文本|선택 영역 텍스트
captureImageRegionOcr|Ảnh / OCR vùng|画像／領域 OCR|图像 / 区域 OCR|이미지/영역 OCR
capturePermissionsTitle|Quyền truy cập|権限|权限|권한
captureAccessibilityGrantedLine|Trợ năng: {state}|アクセシビリティ: {state}|辅助功能：{state}|손쉬운 사용: {state}
captureScreenRecordingGrantedLine|Ghi màn hình: {state}|画面収録: {state}|屏幕录制：{state}|화면 녹화: {state}
capturePermRefresh|Làm mới|更新|刷新|새로 고침
capturePermRequest|Yêu cầu quyền còn thiếu|不足権限をリクエスト|请求缺失权限|누락 권한 요청
capturePermChecking|Đang kiểm tra…|確認中…|正在检查…|확인 중…
capturePermAllGranted|Đã có đủ quyền thu thập.|すべての権限が許可されました。|已获得全部采集权限。|모든 권한 허용됨.
capturePermSomeMissing|Vẫn thiếu quyền. Bật trong Cài đặt > Quyền riêng tư.|権限が不足しています。システム設定で有効に。|仍有缺失权限，请在系统设置开启。|권한 부족 — 설정에서 허용하세요.
captureHotkeyUnavailable|Phím nóng toàn cục không khả dụng. Dùng Ctrl+Shift+D / Ctrl+Shift+X trong app.|グローバルホットキーは使えません。アプリ内ショートカットを。|全局热键不可用，请使用应用内快捷键。|전역 단축키 없음 — 앱 내 단축키 사용.
captureDlgTextCaptureTitle|Thu thập chữ|テキスト取り込み|文本采集|텍스트 수집
captureDlgTextCaptureBody|Thủ công:\n• Ctrl+Shift+D từ app khác.\n\nTự động:\n• Theo drag-select và double-click để đọc chữ đã bôi.\n• Không dùng UIA hay nghe clipboard.\n\nTắt nếu chỉ muốn hotkey.|手動:\n• Ctrl+Shift+D。\n\n自動:\n• ドラッグ選択とダブルクリックでハイライトを読み取り。\n• UIA／クリップボード監視は未使用。|手动：Ctrl+Shift+D。\n自动：跟随拖动选择与双击读取高亮文本；不使用 UIA 或剪贴板监听。|수동: Ctrl+Shift+D.\n자동: 드래그·더블클릭으로 강조 텍스트 읽기.
captureDlgImageCaptureTitle|Ảnh / OCR vùng|画像／領域 OCR|图像 / 区域 OCR|이미지/영역 OCR
captureDlgImageCaptureBody|Ctrl+Shift+X hoặc phím trong app.\n• Chọn khung để OCR.\nLuôn thủ công.|Ctrl+Shift+X。\n• フルスクリーンで範囲指定。|Ctrl+Shift+X 全屏框选 OCR。|Ctrl+Shift+X로 영역 선택 OCR.
captureDlgTipsTitle|Mẹo thu thập|取り込みのヒント|采集提示|수집 팁
captureDlgTipsBody|Tự động tiện tra cứu; tắt khi viết lâu để tránh ảnh hưởng clipboard.|長時間入力時はオフを推奨。|长时间写作时可关闭以免影响剪贴板。|장시간 작성 시 끄면 클립보드 간섭 감소.
captureHotkeyDlgTitle|Nhấn phím tắt mới|新しいホットキーを押す|按下新热键|새 단축키
captureHotkeyDlgHintInitial|Nhấn Ctrl+Shift+<chữ hoặc số>|Ctrl+Shift+文字/数字 を押す|按 Ctrl+Shift+字母或数字|Ctrl+Shift+글자/숫자
captureHotkeyDlgHintRetry|Cần Ctrl+Shift + chữ/số|Ctrl+Shift + 文字/数字が必要です。|需要 Ctrl+Shift 加字母或数字|Ctrl+Shift+글자/숫자 필요
vocabPageSubtitle|Tìm kiếm, lọc và quản lý bộ thẻ|検索・フィルター・管理|搜索筛选与管理卡组|검색·필터·덱 관리
vocabStudySelected|Ôn các mục đã chọn|選択項目を学習|学习所选|선택 항목 학습
vocabStudyFiltered|Ôn theo bộ lọc|フィルター結果を学習|按筛选学习|필터로 학습
vocabSelectBeforeStudy|Chọn từ trước khi ôn.|学習前に単語を選択。|请先选择词汇。|학습 전 단어를 선택하세요.
vocabNoMatchFilters|Không có từ khớp bộ lọc.|フィルターに一致する語がありません。|没有匹配筛选的词。|필터와 일치하는 단어 없음.
vocabTipsTitle|Mẹo từ vựng|語彙のヒント|词汇提示|단어 팁
vocabTipsBody|Lọc ngôn ngữ và nguồn trước khi thao tác hàng loạt.|一括操作前に言語とソースで絞り込み。|批量操作前先按语言和来源筛选。|대량 작업 전 언어·출처로 필터.
vocabDeleteTitle|Xóa từ đã lưu?|保存語を削除しますか？|删除已保存的词？|저장 단어 삭제?
vocabDeleteBodyOne|Sẽ xóa vĩnh viễn từ đã chọn.|選択した語を完全削除。|将永久删除所选词条。|선택 항목 영구 삭제.
vocabDeleteBodyMany|Sẽ xóa vĩnh viễn {count} từ đã chọn.|選択した {count} 語を削除。|将永久删除所选 {count} 条。|선택한 {count}개 영구 삭제.
vocabSearchPlaceholder|Tìm thuật ngữ, nghĩa hoặc thẻ|語・意味・タグで検索|搜索词义或标签|용어·뜻·태그 검색
vocabAllLanguages|Tất cả ngôn ngữ|すべての言語|全部语言|모든 언어
vocabAllSources|Tất cả nguồn|すべてのソース|全部来源|모든 출처
vocabAllTags|Tất cả thẻ|すべてのタグ|全部标签|모든 태그
vocabFilterActive|Đang học|アクティブ|活跃|활성
vocabFilterArchived|Đã lưu trữ|アーカイブ|归档|보관
vocabFilterAll|Tất cả|すべて|全部|전체
vocabClearFilters|Xóa bộ lọc|フィルターをクリア|清除筛选|필터 지우기
vocabEmptyLibrary|Chưa có từ vựng.|語彙がありません。|暂无词汇。|단어 없음.
vocabColTermMeaning|Thuật ngữ / Nghĩa|語／意味|词条 / 释义|용어 / 뜻
vocabColSource|Nguồn|ソース|来源|출처
vocabColTags|Thẻ|タグ|标签|태그
vocabColNextReview|Ôn tiếp theo|次の復習|下次复习|다음 복습
vocabCtxMenuTag|Thẻ|タグ|标签|태그
vocabCtxMenuArchive|Lưu trữ|アーカイブ|归档|보관
vocabCtxMenuResetSrs|Đặt lại SRS|SRS をリセット|重置 SRS|SRS 초기화
vocabCtxMenuDelete|Xóa|削除|删除|삭제
bulkTagCreateTitle|Tạo thẻ|タグ作成|新建标签|태그 만들기
bulkTagCreatePlaceholder|Nhập thẻ mới|新しいタグ|输入新标签|새 태그 입력
bulkTagRenameTitle|Đổi tên thẻ|タグの名前変更|重命名标签|태그 이름 변경
bulkTagRenamePlaceholder|Nhập thẻ|タグを入力|输入标签|태그 입력
bulkTagDeleteTitle|Xóa thẻ|タグ削除|删除标签|태그 삭제
bulkTagDeleteBody|Gỡ "{tag}" khỏi mọi từ đã lưu?|"{tag}" をすべてから削除？|从所有词条移除「{tag}」？|모든 단어에서 "{tag}" 제거?
bulkTagFilterPlaceholder|Lọc thẻ|タグをフィルター|筛选标签|태그 필터
bulkTagClearSelections|Bỏ chọn thẻ|選択解除|清除标签选择|태그 선택 해제
bulkTagRename|Đổi tên|名前変更|重命名|이름 변경
bulkTagDelete|Xóa|削除|删除|삭제
bulkTagApply|Áp dụng|適用|应用|적용
bulkTagNewBadge|Mới|新規|新|신규
bulkTagPanelTitle|Thẻ hàng loạt|一括タグ|批量标签|일괄 태그
bulkTagEmptyLibrary|Chưa có thẻ trong thư viện.|ライブラリにタグがありません。|词库尚无标签。|라이브러리에 태그 없음.
bulkTagNoMatchFilter|Không có thẻ khớp bộ lọc.|フィルターに一致するタグがありません。|没有匹配筛选的标签。|필터와 일치하는 태그 없음.
bulkTagValidationEmpty|Tên thẻ không được để trống.|タグ名は空にできません。|标签名称不能为空。|태그 이름은 비울 수 없습니다.
bulkTagValidationDuplicate|Thẻ đã tồn tại.|タグが既にあります。|标签已存在。|태그가 이미 있습니다.
bulkTagManageTooltip|Quản lý thẻ|タグを管理|管理标签|태그 관리
commonCreate|Tạo|作成|创建|만들기
customStudyTitle|Ôn tùy chỉnh|カスタム学習|自定义学习|사용자 학습
customStudyEntriesCount|Số mục khớp lựa chọn: {count}|選択に一致: {count} 件|匹配所选：{count} 条|선택 일치: {count}개
customStudyMaxLabel|Tối đa thẻ (để trống = tất cả)|最大枚数（空欄ですべて）|最大卡片数（留空为全部）|최대 카드(비우면 전체)
customStudyMaxPlaceholder|vd: 50|例: 50|例如 50|예: 50
customStudyRandomOrder|Ngẫu nhiên|ランダム順|随机顺序|무작위
customStudyCram|Cram (không lưu lịch)|クラム（スケジュール保存なし）|突击（不保存调度）|벼락치기(일정 저장 안 함)
customStudyStart|Bắt đầu|開始|开始|시작
reviewSrsTitle|Ôn SRS|SRS 復習|SRS 复习|SRS 복습
reviewCramBadge|Cram|クラム|突击|벼락치기
reviewQueueCounts|Mới {newCount} · Đang học {learningCount} · Ôn {reviewCount}|新規 {newCount}・学習中 {learningCount}・復習 {reviewCount}|新 {newCount} · 学习中 {learningCount} · 复习 {reviewCount}|신규 {newCount} · 학습 {learningCount} · 복습 {reviewCount}
reviewAutoAudio|Tự động phát âm thanh|自動オーディオ|自动音频|자동 오디오
reviewAllLanguages|Tất cả ngôn ngữ|すべての言語|全部语言|모든 언어
reviewLanguageFilterTooltip|Lọc ngôn ngữ|言語フィルター|语言筛选|언어 필터
reviewMixedProOnly|Chế độ mixed là tính năng Pro. Kích hoạt trong Giới thiệu.|ミックスモードは Pro。|混合模式需 Pro。|믹스 모드는 Pro입니다.
reviewMixedEnable|Bật mixed|ミックスを有効化|启用混合|믹스 켜기
reviewMixedLocked|Mixed (Pro)|Mixed (Pro)|混合（Pro）|믹스 (Pro)
reviewBasicMode|Chế độ cơ bản|ベーシック|基础模式|기본 모드
reviewExitStudy|Thoát phiên ôn|学習を終了|退出学习|학습 종료
reviewNoCardsDue|Không có thẻ đến hạn.|期限カードがありません。|没有到期卡片。|만료 카드 없음.
reviewFinishing|Đang kết thúc phiên…|セッション終了中…|正在结束会话…|세션 종료 중…
reviewCompleted|Đã hoàn thành ôn.|復習完了。|复习完成。|복습 완료.
reviewReviewsToday|Ôn hôm nay: {used}/{limit}|今日の復習: {used}/{limit}|今日复习：{used}/{limit}|오늘 복습: {used}/{limit}
reviewTipsTitle|Mẹo ôn tập|復習のヒント|复习提示|복습 팁
reviewTipsBody|Enter để lật/kiểm tra, 1–4 để chấm, Ctrl+Enter phát âm thanh, R phát lại.|Enter で反転／採点、Ctrl+Enter で音声。|Enter 翻面/判定，Ctrl+Enter 播放音频。|Enter 뒤집기·채점, Ctrl+Enter 오디오.
reviewGradeHintForward|Enter: Lật · 1–4: Điểm · Ctrl+Enter: Âm thanh · R: Phát lại|Enter: 表面裏 · Ctrl+Enter: 音声|Enter：翻面 · Ctrl+Enter：音频|Enter 뒤집기 · Ctrl+Enter 오디오
reviewGradeHintReverse|Enter: Kiểm tra · 1–4: Điểm · Ctrl+Enter: Âm thanh · R: Phát lại|Enter: チェック · Ctrl+Enter: 音声|Enter：检查 · Ctrl+Enter：音频|Enter 확인 · Ctrl+Enter 오디오
reviewAudioFailed|Không phát được âm thanh.|音声を再生できません。|无法播放音频。|오디오 재생 실패.
reviewPlayTerm|Phát thuật ngữ|用語を再生|播放词条|용어 재생
reviewPlayAudio|Phát âm thanh|音声を再生|播放音频|오디오 재생
reviewMeaning|Nghĩa|意味|释义|의미
reviewListenType|Nghe và gõ|聞いて入力|听写|듣고 입력
reviewListenInstructions|Phát âm và gõ từ gốc.|音声を聞いて原文を入力。|播放音频并输入原词。|오디오 듣고 원문 입력.
reviewTypeOriginalPlaceholder|Nhập từ gốc|原文を入力|输入原文|원문 입력
reviewCheckAnswer|Kiểm tra (Enter)|チェック (Enter)|检查答案（Enter）|확인 (Enter)
reviewCorrect|Đúng|正解|正确|맞음
reviewIncorrect|Sai|不正解|错误|틀림
reviewYourAnswer|Câu trả lời của bạn:|あなたの解答:|你的答案：|내 답:
reviewExpected|Đúng là:|正解:|应为：|정답:
reviewAnswerEmptyMarker|(trống)|(空)|(空)|(비어 있음)
reviewGradeAgain|Lại (1)|もう一度 (1)|重来 (1)|다시 (1)
reviewGradeHard|Khó (2)|難しい (2)|困难 (2)|어려움 (2)
reviewGradeGood|Tốt (3)|良い (3)|良好 (3)|좋음 (3)
reviewGradeEasy|Dễ (4)|簡単 (4)|简单 (4)|쉬움 (4)
reviewGradeNameAgain|again|again|again|again
reviewGradeNameHard|hard|hard|hard|hard
reviewGradeNameGood|good|good|good|good
reviewGradeNameEasy|easy|easy|easy|easy
reviewSummaryWordsTitle|Từ vừa ôn ({count})|直近で復習した語 ({count})|刚复习的词 ({count})|방금 복습한 단어 ({count})
reviewSummaryClose|Đóng|閉じる|关闭|닫기
reviewSummaryTitle|Tổng kết phiên ôn|セッションサマリー|学习会话总结|세션 요약
reviewSummaryGreatJob|Tuyệt vời, {name}!|素晴らしい、{name}さん！|太棒了，{name}！|잘했어요, {name}!
reviewSummaryEncourage|Bạn đã hoàn thành mục tiêu hôm nay.|今日の目標を達成しました。|你已完成今日目标。|오늘 목표를 달성했습니다.
reviewSummaryStatReviewed|Đã ôn|復習済み|已复习|복습함
reviewSummaryStatMastered|Ghi nhớ tốt|よく覚えた|掌握良好|잘 기억함
reviewSummaryStatTime|Thời gian|時間|用时|시간
reviewSummaryBackDashboard|Về Dashboard|ダッシュボードへ|返回仪表盘|대시보드로
reviewSummarySeeWords|Xem danh sách từ vừa ôn|復習した語を見る|查看刚复习的词|복습 단어 보기
reviewSummaryCloudSyncing|Đang đồng bộ đám mây…|クラウド同期中…|正在同步云端…|클라우드 동기화 중…
reviewSummaryCloudOk|Đồng bộ đám mây thành công|クラウド同期成功|云端同步成功|클라우드 동기화 성공
reviewSummaryCloudFail|Không đồng bộ được đám mây|クラウド同期失敗|云端同步失败|클라우드 동기화 실패
reviewSummaryYou|Bạn|あなた|你|당신
reviewDurSeconds|{seconds}s|{seconds}秒|{seconds}秒|{seconds}초
reviewDurMinutes|{minutes} phút|{minutes}分|{minutes}分钟|{minutes}분
reviewDurMinutesSeconds|{minutes} phút {seconds} giây|{minutes}分{seconds}秒|{minutes}分{seconds}秒|{minutes}분 {seconds}초
reviewDurHours|{hours} giờ|{hours}時間|{hours}小时|{hours}시간
reviewDurHoursMinutes|{hours} giờ {minutes} phút|{hours}時間{minutes}分|{hours}小时{minutes}分|{hours}시간 {minutes}분
captureSavePhrase|Lưu cụm từ|フレーズを保存|保存短语|구문 저장
captureSaveLine|Lưu dòng|行を保存|保存整行|줄 저장
captureWholeLine|Cả dòng|全文行|整行|전체 줄
captureListenSource|Nghe nguồn|ソースを再生|收听原文|원문 듣기
captureNoTextDetected|Không phát hiện chữ|テキストなし|未检测到文本|텍스트 없음
captureAddTagLabel|Thêm thẻ|タグを追加|添加标签|태그 추가
captureTagHint|Nhập thẻ|タグ入力|输入标签|태그 입력
captureAutoRecentTag|Tự điền thẻ gần đây|最近のタグを自動入力|自动填入最近标签|최근 태그 자동 입력
captureNoRecentTagsYet|Chưa có thẻ gần đây — lưu một mục có thẻ để dùng.|最近タグがありません。|尚无最近标签。|최근 태그 없음 — 저장 후 사용.
captureSavedToast|Đã lưu ✓|保存 ✓|已保存 ✓|저장 ✓
captureDailySaveLimitReached|Bạn đã đạt giới hạn lưu hôm nay ({limit} lượt/ngày). Nâng cấp Pro để lưu không giới hạn.|本日の保存上限（{limit} 回/日）に達しました。Pro で無制限に。|已达到今日保存上限（每天 {limit} 次）。升级 Pro 可无限制保存。|오늘 저장 한도({limit}회/일)에 도달했습니다. Pro로 무제한 저장.
captureDailyTranslateLimitReached|Bạn đã đạt giới hạn dịch hôm nay ({limit} lượt/ngày). Nâng cấp Pro để dịch không giới hạn.|本日の翻訳上限（{limit} 回/日）に達しました。Pro で無制限に。|已达到今日翻译次数上限（每天 {limit} 次）。升级 Pro 可无限制调用。|오늘 번역 호출 한도({limit}회/일)에 도달했습니다. Pro로 무제한.
settingsTagManagerEmpty|Chưa có thẻ.|タグがありません。|暂无标签。|태그 없음.
meaningTranslating|Đang dịch…|翻訳中…|翻译中…|번역 중…
meaningNoTranslationYet|Chưa có bản dịch.|まだ翻訳がありません。|尚无翻译。|번역 없음.
meaningDictHeading|Định nghĩa (tiếng Anh)|英語の定義|英语释义|영어 정의
meaningFieldLabel|Nghĩa|意味|释义|의미
meaningFieldHint|Sửa bản dịch|翻訳を編集|编辑翻译|번역 편집
meaningPlayPronunciation|Phát phiên âm|発音を再生|播放发音|발음 재생
meaningPlay|Phát|再生|播放|재생
meaningPause|Tạm dừng|一時停止|暂停|일시정지
meaningPhraseMarker|(CỤM TỪ)|(フレーズ)|(短语)|(구문)
settingsReviewAudioSection|Âm thanh ôn tập|復習オーディオ|复习音频|복습 오디오
settingsAutoPlayAudioTitle|Tự động phát âm thanh khi có thẻ mới|新しいカードで自動再生|新卡片自动播放音频|새 카드 자동 재생
settingsRememberTagTitle|Ghi nhớ thẻ cuối khi thêm từ|最後のタグを記憶|添加词语时记住上次标签|단어 추가 시 마지막 태그 기억
settingsLocalBackupTitle|Sao lưu cục bộ|ローカルバックアップ|本地备份|로컬 백업
settingsBackupNowJson|Sao lưu ngay (JSON)|JSON でバックアップ|立即备份（JSON）|지금 백업(JSON)
settingsImportBackup|Nhập backup (.db / .json)|バックアップをインポート|导入备份 (.db / .json)|백업 가져오기(.db/.json)
settingsBackupFootnote|Dùng JSON ký từ app hoặc backup .db/.json.|署名付き JSON または .db/.json。|使用签名 JSON 或 .db/.json。|서명 JSON 또는 .db/.json.
settingsManageTagsTitle|Quản lý thẻ|タグ管理|管理标签|태그 관리
settingsManageTagsSubtitle|Đổi tên/xóa thẻ trên mọi từ.|すべての語でタグを編集。|在所有词条重命名/删除标签。|모든 단어에서 태그 편집.
settingsReplaceVocabTitle|Thay thế từ vựng cục bộ?|ローカル語彙を置換？|替换本地词汇？|로컬 단어장 교체?
settingsReplaceVocabBody|Mọi từ đã lưu trên thiết bị sẽ bị thay bằng backup. Không hoàn tác.|バックアップで置換。元に戻せません。|设备上的词将被备份替换，不可撤销。|백업으로 교체. 되돌릴 수 없음.
settingsChooseFile|Chọn tệp|ファイルを選択|选择文件|파일 선택
settingsImporting|Đang nhập backup…|インポート中…|正在导入…|가져오는 중…
settingsImportedCount|Đã nhập {count} mục ({kind}).|{count} 件インポート ({kind})。|已导入 {count} 条 ({kind})。|{count}개 가져옴 ({kind}).
settingsExportCancelled|Đã hủy xuất|エクスポート取消|已取消导出|내보내기 취소
settingsSavedPath|Đã lưu: {path}|保存先: {path}|已保存：{path}|저장됨: {path}
settingsExportFailed|Xuất thất bại: {error}|エクスポート失敗: {error}|导出失败：{error}|내보내기 실패: {error}
settingsImportFailed|Nhập thất bại: {error}|インポート失敗: {error}|导入失败：{error}|가져오기 실패: {error}
settingsLanguageLoadError|Lỗi cài đặt ngôn ngữ: {error}|言語設定エラー: {error}|语言设置错误：{error}|언어 설정 오류: {error}
settingsTextScaleSectionTitle|Cỡ chữ|文字サイズ|字体大小|글자 크기
settingsTextScaleLabel|Tỷ lệ chữ giao diện|インターフェースの文字サイズ|界面文字缩放|인터페이스 글자 크기
settingsTextScaleDescription|Tăng giảm chữ trong cửa sổ desktop và popup thu thập. Cộng thêm với thang phóng hiển thị của Windows.|デスクトップとポップアップの文字サイズ。Windows の表示スケールと重ねがけされます。|调整桌面窗口与采集弹窗的文字大小，会与 Windows 显示缩放叠加。|데스크톱 창과 수집 팝업 글자 크기입니다. Windows 디스플레이 배율과 함께 적용됩니다.
settingsTextScalePercent|{percent}%|{percent}%|{percent}%|{percent}%
commonErrorPrefix|Lỗi: {error}|エラー: {error}|错误：{error}|오류: {error}
"""


def parse_patch_table(raw: str) -> dict[str, dict[str, str]]:
    out: dict[str, dict[str, str]] = {"vi": {}, "ja": {}, "zh": {}, "ko": {}}
    locs = ["vi", "ja", "zh", "ko"]
    for line in raw.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split("|")
        if len(parts) != 5:
            raise ValueError(f"Bad row ({len(parts)} cols): {line[:80]}")
        key = parts[0].strip()
        for i, loc in enumerate(locs):
            out[loc][key] = parts[1 + i].strip()
    return out


def main() -> None:
    patch = parse_patch_table(PATCH_TABLE)
    en_path = ROOT / "app_en.arb"
    en = json.loads(en_path.read_text(encoding="utf-8"))
    for loc in ["vi", "ja", "zh", "ko"]:
        path = ROOT / f"app_{loc}.arb"
        cur = json.loads(path.read_text(encoding="utf-8"))
        merged: dict[str, object] = {}
        merged["@@locale"] = loc
        for k, v in en.items():
            if k == "@@locale":
                continue
            if k.startswith("@"):
                merged[k] = v
            else:
                merged[k] = patch[loc].get(k, cur.get(k, v))
        path.write_text(json.dumps(merged, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
