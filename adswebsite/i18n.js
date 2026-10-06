/* Client-side UI translations (English, Vietnamese, Simplified Chinese). */
(function () {
  var STORAGE_KEY = "formycareer-site-lang";

  var STRINGS = {
    en: {
      "skip.main": "Skip to content",
      "lang.label": "Language",
      "nav.home": "Home",
      "nav.download": "Download",
      "nav.blog": "Blog",
      "nav.about": "About",
      "nav.privacy": "Privacy",
      "nav.contact": "Contact",
      "footer.about": "About",
      "footer.download": "Download",
      "footer.terms": "Terms",
      "footer.cookies": "Cookies",
      "footer.disclaimer": "Disclaimer",
      "footer.privacy": "Privacy",
      "footer.contact": "Contact",
      "footer.blog": "Blog",
      "footer.home": "Home",
      "cookie.dialogAria": "Cookie notice",
      "cookie.banner":
        'We use essential cookies and, with your consent, may use cookies for ads and analytics. See our <a href="/cookies.html">Cookie Policy</a> and <a href="/privacy.html">Privacy Policy</a>.',
      "cookie.accept": "Accept",
      "cookie.decline": "Decline non-essential",
      "blog.title": "Blog",
      "blog.intro":
        "Practical guides on careers, interviews, learning systems, and productivity—with search and tag filters.",
      "blog.searchLabel": "Search posts",
      "blog.searchPlaceholder": "Try: interview, SRS, portfolio, remote…",
      "blog.publishedPrefix": "Published",
      "blog.noMatch": "No matching posts found. Try another keyword or tag.",
      "blog.loadFail": "Could not load blog posts right now.",
      "article.back": "← Back to Blog",
      "article.author": "Author:",
      "article.reviewedNote": "Reviewed and updated monthly for accuracy.",
      "article.downloadBtn": "Download FormyCareer",
      "article.related": "Related articles",
      "tag.all": "All",
      "tag.career": "Career",
      "tag.interview": "Interview",
      "tag.learning": "Learning",
      "tag.productivity": "Productivity",
      "tag.product": "Product",
      "crumb.home": "Home",
      "crumb.blog": "Blog",
      "crumb.about": "About",
      "404.title": "Page not found",
      "404.lead": "The page you requested does not exist or has moved.",
      "404.backHome": "Back to home",
      "home.hero.badge": "Vocabulary-first · SRS · Practical learning",
      "home.hero.title": "Words that stick for work and interviews.",
      "home.hero.lead":
        "FormyCareer focuses on long-term vocabulary retention for real situations. Build your library from work, study, and interviews—then review with spaced repetition.",
      "home.cta.download": "Download app",
      "home.cta.buyPro": "Buy FormyCareer Pro License",
      "home.cta.readBlog": "Read the blog",
      "home.cta.privacy": "Privacy policy",
      "home.stat.srs": "SRS scheduling",
      "home.stat.modes": "4 review modes",
      "home.stat.tags": "Tags + search",
      "home.stat.archive": "Archive control",
      "home.sec.what.title": "What FormyCareer does",
      "home.sec.what.p1":
        "FormyCareer is a vocabulary-first learning app. Collect words that matter—technical terms, workplace English, interview language—and retain them with spaced repetition.",
      "home.sec.what.p2":
        "The product centers on retrieval practice: recall meaning on a schedule that strengthens memory.",
      "home.sec.what.li1": "Create and manage vocabulary with source text and translation.",
      "home.sec.what.li2": "Organize entries with tags, filters, search, and archive.",
      "home.sec.what.li3": "Run SRS-based review sessions with multiple prompt modes.",
      "home.sec.status.title": "Current feature status",
      "home.sec.status.note":
        "This list reflects features currently available in the app.",
      "home.feat.library.tag": "Available",
      "home.feat.library.title": "Vocabulary library",
      "home.feat.library.desc": "Add, edit, and manage translation pairs.",
      "home.feat.srs.tag": "Available",
      "home.feat.srs.title": "SRS review",
      "home.feat.srs.desc": "Review cards using spaced repetition scheduling.",
      "home.feat.modes.tag": "Available",
      "home.feat.modes.title": "Review modes",
      "home.feat.modes.desc": "Forward, reverse meaning, reverse audio, and mixed.",
      "home.feat.tags.tag": "Available",
      "home.feat.tags.title": "Tags and filters",
      "home.feat.tags.desc": "Tag words, filter lists, search, archive entries.",
      "home.feat.settings.tag": "Available",
      "home.feat.settings.title": "Settings and diagnostics",
      "home.feat.settings.desc": "Manage tags and export logs for troubleshooting.",
      "home.feat.blog.tag": "Content",
      "home.feat.blog.title": "Career learning blog",
      "home.feat.blog.desc": "Articles on CV writing, interviews, and study systems.",
      "home.sec.use.title": "How people use it",
      "home.sec.use.li1": "Early-career professionals building workplace vocabulary.",
      "home.sec.use.li2": "Job seekers preparing precise interview language.",
      "home.sec.use.li3": "Students turning reading inputs into durable memory.",
      "home.sec.ads.title": "Editorial and ads transparency",
      "home.sec.ads.p":
        "This site is the official hub for FormyCareer. We publish educational articles and may display ads where eligible.",
      "home.sec.ads.li1": "Content aims for learning value, not clickbait.",
      "home.sec.ads.li2": "Policy pages are public and maintained.",
      "home.sec.ads.li3": "Support: formycareersupport@gmail.com",
      "home.faq.q1": "Is FormyCareer a full language course?",
      "home.faq.a1":
        "No. It is a vocabulary and retention system focused on practical phrases.",
      "home.faq.q2": "What are the core features today?",
      "home.faq.a2":
        "Vocabulary management, tag/search/archive, SRS review, and multiple review modes.",
      "home.faq.q3": "How can I contact support?",
      "home.faq.a3":
        "Email formycareersupport@gmail.com—we reply within 2–5 business days.",
      "home.pro.title": "FormyCareer Pro",
      "home.pro.p":
        "One license activates Pro on desktop and mobile. Checkout opens in a secure overlay powered by Lemon Squeezy. After purchase, open About → Activate Pro and paste your license key from email.",
      "home.pro.activate": "Activate Pro",
      "home.pro.featuresTitle": "What Pro includes",
      "home.pro.li1": "No banner ads on desktop when Pro is active.",
      "home.pro.li2":
        "Mixed review mode on desktop and mobile: combine forward, reverse meaning, and reverse audio prompts in one session (Free uses basic forward-only review).",
      "home.pro.li3":
        "Unlimited SRS review grades per calendar day on your device (Free: up to 100 grades per local calendar day).",
      "home.pro.li4":
        "Unlimited new vocabulary saves from desktop capture per calendar day (Free: daily limit).",
      "home.pro.li5":
        "Unlimited translation requests in the desktop capture popup per calendar day; cache hits do not count (Free: daily limit).",
      "home.download.title": "Download FormyCareer",
      "home.download.intro":
        "Install from official release links. Replace placeholders when builds are published.",
      "home.download.win.title": "Windows",
      "home.download.win.note": "Installer (.exe or .msi) from release assets.",
      "home.download.win.btn": "Coming soon",
      "home.download.android.title": "Android",
      "home.download.android.note": "APK release for testing.",
      "home.download.android.btn": "Coming soon",
      "home.download.src.title": "Source code",
      "home.download.src.note": "Track releases and updates on GitHub.",
      "home.download.src.btn": "Add GitHub link",
      "home.download.tip": "Tip: link GitHub Releases when your first build is ready.",
      "home.resources.title": "Career resources",
      "home.resources.p": "Guides on planning, interviews, and efficient learning.",
      "home.resources.btn": "Explore all articles",
      "dl.title": "Download FormyCareer",
      "dl.intro":
        "Use official links below. Replace placeholders with GitHub release URLs when ready.",
      "dl.pro.title": "FormyCareer Pro",
      "dl.pro.p":
        "One license activates Pro on desktop and mobile. Checkout uses Lemon Squeezy (overlay or full page).",
      "dl.pro.buy": "Buy FormyCareer Pro License",
      "dl.pro.checkoutTab": "Open checkout in a new tab",
      "dl.pro.note": "After purchase: About → Activate Pro with your license key.",
      "dl.viewChangelog": "View release notes",
      "about.title": "About FormyCareer",
      "about.updatedLabel": "Last updated:",
      "about.updatedDate": "May 1, 2026",
      "about.p1":
        "FormyCareer is vocabulary-first for real situations: meetings, technical reading, and interviews—with spaced repetition instead of generic lists.",
      "about.mission.title": "Our mission",
      "about.mission.p":
        "Help you build a personal library of terms you actually use, then review on a schedule that supports memory.",
      "about.publish.title": "What we publish on this site",
      "about.publish.p":
        "Official hub: product info, blog, downloads, policies. Content is educational—not legal, financial, or career advice. See our disclaimer.",
      "about.contact.title": "Contact and support",
      "about.contact.p":
        "Questions about the app or site: formycareersupport@gmail.com (2–5 business days).",
      "about.contact.btn": "Go to contact page",
      "contact.title": "Contact",
      "changelog.title": "Changelog",
    },
    vi: {
      "skip.main": "Chuyển đến nội dung",
      "lang.label": "Ngôn ngữ",
      "nav.home": "Trang chủ",
      "nav.download": "Tải xuống",
      "nav.blog": "Blog",
      "nav.about": "Giới thiệu",
      "nav.privacy": "Quyền riêng tư",
      "nav.contact": "Liên hệ",
      "footer.about": "Giới thiệu",
      "footer.download": "Tải xuống",
      "footer.terms": "Điều khoản",
      "footer.cookies": "Cookie",
      "footer.disclaimer": "Miễn trừ",
      "footer.privacy": "Quyền riêng tư",
      "footer.contact": "Liên hệ",
      "footer.blog": "Blog",
      "footer.home": "Trang chủ",
      "cookie.dialogAria": "Thông báo cookie",
      "cookie.banner":
        'Chúng tôi dùng cookie cần thiết và, khi bạn đồng ý, có thể dùng cookie cho quảng cáo và phân tích. Xem <a href="/cookies.html">Chính sách cookie</a> và <a href="/privacy.html">Chính sách quyền riêng tư</a>.',
      "cookie.accept": "Chấp nhận",
      "cookie.decline": "Từ chối không thiết yếu",
      "blog.title": "Blog",
      "blog.intro":
        "Hướng dẫn về sự nghiệp, phỏng vấn, học tập và năng suất—có tìm kiếm và lọc thẻ.",
      "blog.searchLabel": "Tìm bài viết",
      "blog.searchPlaceholder": "Thử: interview, SRS, portfolio, remote…",
      "blog.publishedPrefix": "Đăng",
      "blog.noMatch": "Không có bài phù hợp. Thử từ khóa hoặc thẻ khác.",
      "blog.loadFail": "Không tải được danh sách bài viết.",
      "article.back": "← Quay lại Blog",
      "article.author": "Tác giả:",
      "article.reviewedNote": "Được rà soát và cập nhật hàng tháng.",
      "article.downloadBtn": "Tải FormyCareer",
      "article.related": "Bài liên quan",
      "tag.all": "Tất cả",
      "tag.career": "Sự nghiệp",
      "tag.interview": "Phỏng vấn",
      "tag.learning": "Học tập",
      "tag.productivity": "Năng suất",
      "tag.product": "Sản phẩm",
      "crumb.home": "Trang chủ",
      "crumb.blog": "Blog",
      "crumb.about": "Giới thiệu",
      "404.title": "Không tìm thấy trang",
      "404.lead": "Trang bạn yêu cầu không tồn tại hoặc đã được chuyển.",
      "404.backHome": "Về trang chủ",
      "home.hero.badge": "Từ vựng trọng tâm · SRS · Học thực tế",
      "home.hero.title": "Từ vựng bám lâu cho công việc và phỏng vấn.",
      "home.hero.lead":
        "FormyCareer giúp ghi nhớ từ vựng lâu dài trong tình huống thật. Xây thư viện từ công việc, học tập và phỏng vấn—ôn lại bằng spaced repetition.",
      "home.cta.download": "Tải ứng dụng",
      "home.cta.buyPro": "Mua FormyCareer Pro License",
      "home.cta.readBlog": "Đọc blog",
      "home.cta.privacy": "Chính sách quyền riêng tư",
      "home.stat.srs": "Lịch SRS",
      "home.stat.modes": "4 chế độ ôn",
      "home.stat.tags": "Thẻ + tìm kiếm",
      "home.stat.archive": "Quản lý lưu trữ",
      "home.sec.what.title": "FormyCareer làm gì",
      "home.sec.what.p1":
        "Ứng dụng tập trung từ vựng: thu thập từ quan trọng—thuật ngữ IT, tiếng Anh công sở, ngôn ngữ phỏng vấn—và giữ nhớ với SRS.",
      "home.sec.what.p2":
        "Trọng tâm là luyện nhớ lại (recall), không chỉ đọc qua.",
      "home.sec.what.li1": "Tạo và quản lý mục từ vựng có ngữ cảnh và bản dịch.",
      "home.sec.what.li2": "Tổ chức bằng thẻ, bộ lọc, tìm kiếm và lưu trữ.",
      "home.sec.what.li3": "Phiên ôn SRS với nhiều kiểu gợi ý.",
      "home.sec.status.title": "Tính năng hiện có",
      "home.sec.status.note":
        "Danh sách phản ánh tính năng đang có trong ứng dụng.",
      "home.feat.library.tag": "Có sẵn",
      "home.feat.library.title": "Thư viện từ vựng",
      "home.feat.library.desc": "Thêm, sửa và quản lý cặp dịch.",
      "home.feat.srs.tag": "Có sẵn",
      "home.feat.srs.title": "Ôn SRS",
      "home.feat.srs.desc": "Ôn thẻ theo lịch spaced repetition.",
      "home.feat.modes.tag": "Có sẵn",
      "home.feat.modes.title": "Chế độ ôn",
      "home.feat.modes.desc": "Thuận, đảo nghĩa, đảo âm và trộn.",
      "home.feat.tags.tag": "Có sẵn",
      "home.feat.tags.title": "Thẻ và bộ lọc",
      "home.feat.tags.desc": "Gắn thẻ, lọc danh sách, tìm kiếm, lưu trữ.",
      "home.feat.settings.tag": "Có sẵn",
      "home.feat.settings.title": "Cài đặt và chẩn đoán",
      "home.feat.settings.desc": "Quản lý thẻ và xuất log hỗ trợ.",
      "home.feat.blog.tag": "Nội dung",
      "home.feat.blog.title": "Blog sự nghiệp",
      "home.feat.blog.desc": "Bài viết về CV, phỏng vấn và hệ thống học.",
      "home.sec.use.title": "Ai đang dùng",
      "home.sec.use.li1": "Người mới đi làm xây từ vựng công sở.",
      "home.sec.use.li2": "Ứng viên chuẩn bị ngôn ngữ phỏng vấn chính xác.",
      "home.sec.use.li3": "Sinh viên và người tự học biến đọc thành trí nhớ lâu.",
      "home.sec.ads.title": "Minh bạch nội dung và quảng cáo",
      "home.sec.ads.p":
        "Đây là trung tâm thông tin chính thức của FormyCareer. Chúng tôi có thể hiển thị quảng cáo nơi phù hợp.",
      "home.sec.ads.li1": "Nội dung hướng đến giá trị học tập.",
      "home.sec.ads.li2": "Trang chính sách được duy trì công khai.",
      "home.sec.ads.li3": "Hỗ trợ: formycareersupport@gmail.com",
      "home.faq.q1": "FormyCareer có phải khóa học ngôn ngữ đầy đủ không?",
      "home.faq.a1":
        "Không. Đây là hệ thống từ vựng và ghi nhớ cho cụm từ thực tế.",
      "home.faq.q2": "Tính năng lõi hiện tại là gì?",
      "home.faq.a2":
        "Quản lý từ vựng, thẻ/tìm kiếm/lưu trữ, ôn SRS và nhiều chế độ ôn.",
      "home.faq.q3": "Liên hệ hỗ trợ như thế nào?",
      "home.faq.a3":
        "Gửi email formycareersupport@gmail.com—phản hồi trong 2–5 ngày làm việc.",
      "home.pro.title": "FormyCareer Pro",
      "home.pro.p":
        "Một license kích hoạt Pro trên bản desktop và mobile. Thanh toán qua Lemon Squeezy (overlay bảo mật). Sau khi mua: mở Giới thiệu → Kích hoạt Pro và dán license trong email.",
      "home.pro.activate": "Giới thiệu → Kích hoạt Pro",
      "home.pro.featuresTitle": "Pro gồm những gì",
      "home.pro.li1": "Không có banner quảng cáo trên desktop khi đã Pro.",
      "home.pro.li2":
        "Chế độ ôn mixed trên desktop và mobile: kết hợp forward, reverse nghĩa và reverse audio trong một phiên (bản Free chỉ ôn forward cơ bản).",
      "home.pro.li3":
        "Không giới hạn số lần chấm điểm SRS mỗi ngày theo lịch máy (Free: tối đa 100 lần/ngày lịch local).",
      "home.pro.li4":
        "Lưu từ mới không giới hạn từ capture trên desktop mỗi ngày (Free: giới hạn/ngày).",
      "home.pro.li5":
        "Gọi dịch không giới hạn trong popup capture trên desktop mỗi ngày; trùng cache không tính lượt (Free: giới hạn/ngày).",
      "home.download.title": "Tải FormyCareer",
      "home.download.intro":
        "Cài đặt từ liên kết chính thức. Thay placeholder khi đã có bản build.",
      "home.download.win.title": "Windows",
      "home.download.win.note": "Trình cài (.exe hoặc .msi) từ release.",
      "home.download.win.btn": "Sắp có",
      "home.download.android.title": "Android",
      "home.download.android.note": "APK cho thử nghiệm.",
      "home.download.android.btn": "Sắp có",
      "home.download.src.title": "Mã nguồn",
      "home.download.src.note": "Theo dõi release trên GitHub.",
      "home.download.src.btn": "Thêm liên kết GitHub",
      "home.download.tip":
        "Mẹo: gắn liên kết GitHub Releases khi có bản đầu tiên.",
      "home.resources.title": "Tài nguyên sự nghiệp",
      "home.resources.p": "Hướng dẫn về kế hoạch, phỏng vấn và học hiệu quả.",
      "home.resources.btn": "Xem tất cả bài viết",
      "dl.title": "Tải FormyCareer",
      "dl.intro":
        "Dùng liên kết bên dưới. Thay placeholder bằng URL GitHub Releases khi sẵn sàng.",
      "dl.pro.title": "FormyCareer Pro",
      "dl.pro.p":
        "Một license kích hoạt Pro trên desktop và mobile. Thanh toán qua Lemon Squeezy (overlay hoặc trang đầy đủ).",
      "dl.pro.buy": "Mua FormyCareer Pro License",
      "dl.pro.checkoutTab": "Mở thanh toán tab mới",
      "dl.pro.note": "Sau khi mua: Giới thiệu → Kích hoạt Pro bằng license.",
      "dl.viewChangelog": "Xem nhật ký phát hành",
      "about.title": "Giới thiệu FormyCareer",
      "about.updatedLabel": "Cập nhật lần cuối:",
      "about.updatedDate": "1 tháng 5, 2026",
      "about.p1":
        "FormyCareer tập trung từ vựng cho tình huống thật: họp, đọc kỹ thuật và phỏng vấn—với SRS thay vì danh sách chung chung.",
      "about.mission.title": "Sứ mệnh",
      "about.mission.p":
        "Giúp bạn xây thư viện thuật ngữ thực sự dùng rồi ôn đúng lịch để nhớ lâu.",
      "about.publish.title": "Chúng tôi xuất bản gì trên site",
      "about.publish.p":
        "Trung tâm chính thức: sản phẩm, blog, tải xuống, chính sách. Nội dung mang tính giáo dục—không thay lời tư pháp lý hay tài chính. Xem miễn trừ.",
      "about.contact.title": "Liên hệ và hỗ trợ",
      "about.contact.p":
        "Thắc mắc về app hoặc site: formycareersupport@gmail.com (2–5 ngày làm việc).",
      "about.contact.btn": "Đến trang liên hệ",
      "contact.title": "Liên hệ",
      "changelog.title": "Nhật ký thay đổi",
    },
    zh: {
      "skip.main": "跳到主要内容",
      "lang.label": "语言",
      "nav.home": "首页",
      "nav.download": "下载",
      "nav.blog": "博客",
      "nav.about": "关于",
      "nav.privacy": "隐私",
      "nav.contact": "联系",
      "footer.about": "关于",
      "footer.download": "下载",
      "footer.terms": "条款",
      "footer.cookies": "Cookie",
      "footer.disclaimer": "免责声明",
      "footer.privacy": "隐私",
      "footer.contact": "联系",
      "footer.blog": "博客",
      "footer.home": "首页",
      "cookie.dialogAria": "Cookie 提示",
      "cookie.banner":
        '我们使用必要的 Cookie；在您同意后，也可能用于广告与分析。请参阅<a href="/cookies.html">Cookie 政策</a>与<a href="/privacy.html">隐私政策</a>。',
      "cookie.accept": "接受",
      "cookie.decline": "拒绝非必要",
      "blog.title": "博客",
      "blog.intro":
        "实用的职业发展、面试、学习与生产力指南——支持搜索与标签筛选。",
      "blog.searchLabel": "搜索文章",
      "blog.searchPlaceholder": "试试：interview、SRS、portfolio、remote…",
      "blog.publishedPrefix": "发布于",
      "blog.noMatch": "没有匹配的文章，请更换关键词或标签。",
      "blog.loadFail": "暂时无法加载文章列表。",
      "article.back": "← 返回博客",
      "article.author": "作者：",
      "article.reviewedNote": "每月审核更新以确保准确性。",
      "article.downloadBtn": "下载 FormyCareer",
      "article.related": "相关文章",
      "tag.all": "全部",
      "tag.career": "职业",
      "tag.interview": "面试",
      "tag.learning": "学习",
      "tag.productivity": "效率",
      "tag.product": "产品",
      "crumb.home": "首页",
      "crumb.blog": "博客",
      "crumb.about": "关于",
      "404.title": "页面未找到",
      "404.lead": "您访问的页面不存在或已移动。",
      "404.backHome": "返回首页",
      "home.hero.badge": "词汇优先 · SRS · 面向实战",
      "home.hero.title": "让工作与面试用词真正记住。",
      "home.hero.lead":
        "FormyCareer 专注于真实场景的长期词汇保持。从工作、学习与面试中建立词库，并用间隔复习巩固记忆。",
      "home.cta.download": "下载应用",
      "home.cta.buyPro": "购买 FormyCareer Pro License",
      "home.cta.readBlog": "阅读博客",
      "home.cta.privacy": "隐私政策",
      "home.stat.srs": "SRS 排程",
      "home.stat.modes": "4 种复习模式",
      "home.stat.tags": "标签 + 搜索",
      "home.stat.archive": "归档管理",
      "home.sec.what.title": "FormyCareer 能做什么",
      "home.sec.what.p1":
        "这是一款以词汇为核心的学习应用：收集对你重要的术语与表达，并用间隔复习巩固。",
      "home.sec.what.p2": "核心是检索练习：在时间安排下回忆含义以强化记忆。",
      "home.sec.what.li1": "创建并管理带来源与翻译的词条。",
      "home.sec.what.li2": "通过标签、筛选、搜索与归档整理词条。",
      "home.sec.what.li3": "运行基于 SRS 的多模式复习会话。",
      "home.sec.status.title": "当前功能状态",
      "home.sec.status.note": "列表反映应用中已上线的功能。",
      "home.feat.library.tag": "可用",
      "home.feat.library.title": "词汇库",
      "home.feat.library.desc": "添加、编辑与管理释义对。",
      "home.feat.srs.tag": "可用",
      "home.feat.srs.title": "SRS 复习",
      "home.feat.srs.desc": "按间隔复习节奏复习卡片。",
      "home.feat.modes.tag": "可用",
      "home.feat.modes.title": "复习模式",
      "home.feat.modes.desc": "正向、反向释义、反向音频与混合。",
      "home.feat.tags.tag": "可用",
      "home.feat.tags.title": "标签与筛选",
      "home.feat.tags.desc": "打标签、筛选列表、搜索与归档。",
      "home.feat.settings.tag": "可用",
      "home.feat.settings.title": "设置与诊断",
      "home.feat.settings.desc": "管理标签并导出日志便于排查。",
      "home.feat.blog.tag": "内容",
      "home.feat.blog.title": "职业学习博客",
      "home.feat.blog.desc": "关于简历、面试与学习系统的文章。",
      "home.sec.use.title": "典型用户",
      "home.sec.use.li1": "初入职场与资深新人扩展职场英语词汇。",
      "home.sec.use.li2": "求职者打磨精准的面试用语。",
      "home.sec.use.li3": "学生与自学者把阅读输入转为长期记忆。",
      "home.sec.ads.title": "内容与广告透明说明",
      "home.sec.ads.p":
        "本站为 FormyCareer 官方信息与内容枢纽；符合条件的位置可能展示广告。",
      "home.sec.ads.li1": "内容以学习价值为导向。",
      "home.sec.ads.li2": "政策页面公开维护。",
      "home.sec.ads.li3": "支持邮箱：formycareersupport@gmail.com",
      "home.faq.q1": "FormyCareer 是完整语言课程吗？",
      "home.faq.a1": "不是。它是聚焦实用表达的词汇与记忆系统。",
      "home.faq.q2": "当前核心功能有哪些？",
      "home.faq.a2": "词汇管理、标签/搜索/归档、SRS 复习与多种复习模式。",
      "home.faq.q3": "如何联系支持？",
      "home.faq.a3":
        "发送邮件至 formycareersupport@gmail.com，我们通常 2–5 个工作日内回复。",
      "home.pro.title": "FormyCareer Pro",
      "home.pro.p":
        "一份许可证可在桌面端与移动端激活 Pro。结账通过 Lemon Squeezy（安全叠加层）。购买后在应用中打开关于 → 激活 Pro，粘贴邮件中的密钥。",
      "home.pro.activate": "关于 → 激活 Pro",
      "home.pro.featuresTitle": "Pro 包含内容",
      "home.pro.li1": "激活 Pro 后桌面端不再显示横幅广告。",
      "home.pro.li2":
        "桌面端与移动端可使用混合复习模式：在同一会话中组合正向、反向释义与反向听力提示（免费版为基础正向复习）。",
      "home.pro.li3":
        "当地日历日内 SRS 评分次数不限（免费版：每个本地日历日最多 100 次评分）。",
      "home.pro.li4":
        "桌面端从捕获保存生词每日不限（免费版有每日上限）。",
      "home.pro.li5":
        "桌面捕获弹窗翻译请求每日不限；缓存命中不计入额度（免费版有每日上限）。",
      "home.download.title": "下载 FormyCareer",
      "home.download.intro":
        "请使用下方官方链接安装；构建发布后替换占位链接。",
      "home.download.win.title": "Windows",
      "home.download.win.note": "来自发行资产的安装包（.exe 或 .msi）。",
      "home.download.win.btn": "敬请期待",
      "home.download.android.title": "Android",
      "home.download.android.note": "用于测试的 APK 发行版。",
      "home.download.android.btn": "敬请期待",
      "home.download.src.title": "源代码",
      "home.download.src.note": "在 GitHub 跟踪发行与更新。",
      "home.download.src.btn": "添加 GitHub 链接",
      "home.download.tip": "提示：首个构建发布后请替换为 GitHub Releases 链接。",
      "home.resources.title": "职业资源",
      "home.resources.p": "关于规划、面试与高效学习的指南。",
      "home.resources.btn": "查看全部文章",
      "dl.title": "下载 FormyCareer",
      "dl.intro":
        "使用下方官方链接安装 FormyCareer；准备好后用 GitHub Release 替换占位 URL。",
      "dl.pro.title": "FormyCareer Pro",
      "dl.pro.p": "一份许可证可在桌面端与移动端激活 Pro。结账使用 Lemon Squeezy（叠加层或新标签完整页）。",
      "dl.pro.buy": "购买 FormyCareer Pro License",
      "dl.pro.checkoutTab": "在新标签打开结账页",
      "dl.pro.note": "购买后在应用中：关于 → 使用邮件中的密钥激活 Pro。",
      "dl.viewChangelog": "查看发行说明",
      "about.title": "关于 FormyCareer",
      "about.updatedLabel": "最近更新：",
      "about.updatedDate": "2026年5月1日",
      "about.p1":
        "FormyCareer 面向真实场景（会议、技术阅读与面试）的词汇需求，用间隔复习代替泛泛词表。",
      "about.mission.title": "我们的使命",
      "about.mission.p":
        "帮助你建立真正使用的术语库，并按有助于记忆的节律复习。",
      "about.publish.title": "本站发布的内容",
      "about.publish.p":
        "官方枢纽：产品信息、博客、下载与政策页面。内容为教育性质，不构成职业、法律或财务建议；详见免责声明。",
      "about.contact.title": "联系与支持",
      "about.contact.p":
        "应用或网站问题：formycareersupport@gmail.com（约 2–5 个工作日回复）。",
      "about.contact.btn": "前往联系页面",
      "contact.title": "联系",
      "changelog.title": "更新日志",
    },
  };

  window.FormyCareerStrings = STRINGS;

  function langFromQuery() {
    try {
      var q = new URLSearchParams(window.location.search).get("lang");
      if (q === "vi" || q === "zh" || q === "en") return q;
    } catch (e) {}
    return null;
  }

  function storedLang() {
    var q = langFromQuery();
    if (q) return q;
    try {
      var s = localStorage.getItem(STORAGE_KEY);
      if (s === "vi" || s === "zh" || s === "en") return s;
    } catch (e) {}
    return "en";
  }

  function ensureZhFont() {
    if (document.getElementById("font-noto-sc")) return;
    var link = document.createElement("link");
    link.id = "font-noto-sc";
    link.rel = "stylesheet";
    link.href =
      "https://fonts.googleapis.com/css2?family=Noto+Sans+SC:wght@400;500;600;700&display=swap";
    document.head.appendChild(link);
  }

  function apply(lang) {
    var pack = STRINGS[lang] || STRINGS.en;
    document.documentElement.lang =
      lang === "zh" ? "zh-Hans" : lang === "vi" ? "vi" : "en";
    document.documentElement.classList.remove("lang-en", "lang-vi", "lang-zh");
    document.documentElement.classList.add("lang-" + lang);
    if (lang === "zh") ensureZhFont();

    document.querySelectorAll("[data-i18n]").forEach(function (el) {
      var key = el.getAttribute("data-i18n");
      if (!key || pack[key] == null) return;
      el.textContent = pack[key];
    });
    document.querySelectorAll("[data-i18n-html]").forEach(function (el) {
      var key = el.getAttribute("data-i18n-html");
      if (!key || pack[key] == null) return;
      el.innerHTML = pack[key];
    });
    document.querySelectorAll("[data-i18n-placeholder]").forEach(function (el) {
      var key = el.getAttribute("data-i18n-placeholder");
      if (!key || pack[key] == null) return;
      el.setAttribute("placeholder", pack[key]);
    });
    document.querySelectorAll("[data-i18n-aria]").forEach(function (el) {
      var key = el.getAttribute("data-i18n-aria");
      if (!key || pack[key] == null) return;
      el.setAttribute("aria-label", pack[key]);
    });

    var sel = document.getElementById("site-lang");
    if (sel) sel.value = lang;

    window.dispatchEvent(new Event("formycareer-langchange"));
  }

  function setLang(lang) {
    if (lang !== "vi" && lang !== "zh" && lang !== "en") lang = "en";
    try {
      localStorage.setItem(STORAGE_KEY, lang);
    } catch (e) {}
    apply(lang);
  }

  function init() {
    var lang = storedLang();
    apply(lang);
    var sel = document.getElementById("site-lang");
    if (sel) {
      sel.addEventListener("change", function () {
        setLang(sel.value);
      });
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
