# frozen_string_literal: true

# Single source of truth for structured site content that is not yet in the
# database. Sources:
#   - "هيكل الموقع والدايركشن v2" (IA document)
#   - "Mazaya website content" (Canva copy deck, Sept 2026, AR + EN)
#   - Category page prototype v2 (catalog tree + sample products)
#
# Page copy (headlines, descriptions, CTAs) lives in config/locales/{ar,en}.yml.
# Every human-readable value here is a Bilingual (see bi()) and renders in the
# current locale. Anything marked PENDING (nil) is data the client has not
# supplied yet; views render it as a visible placeholder instead of inventing
# a value.
#
# `kind` = Ready-made / Custom-made flag from the IA document:
#   :ready  -> B2C track, CTA "اطلب عرض سعر"
#   :custom -> B2B track, CTA "اطلب استشارة تخصيص"
# Seed / fallback data. The live site reads from the database through SiteData
# (see site_data.rb); this file only feeds db/seeds.rb and empty tables.
module SiteData::Defaults
  PENDING = nil

  def self.bi(ar, en) = Bilingual.new(ar, en)
  private_class_method :bi

  FOUNDED = 1991
  WHATSAPP_DISPLAY = "+966 55 688 7963"
  WHATSAPP_HREF = "https://wa.me/#{WHATSAPP_DISPLAY.delete('^0-9')}"
  EMAIL = PENDING          # [البريد الإلكتروني المعتمد]
  PHONE = PENDING          # [رقم التواصل المعتمد]
  ADDRESS = PENDING        # [عنوان المصنع المعتمد]
  HOURS = PENDING          # [أيام وساعات العمل]
  MAP_EMBED = PENDING      # Google Maps embed URL

  STATS = [
    { value: 35,  suffix: "+", label: bi("عامًا", "Years"),               sub: bi("من الخبرة في السوق", "of market experience") },
    { value: 4,   suffix: "+", label: bi("ملايين سلم", "Million Ladders"), sub: bi("تم إنتاجها", "produced") },
    { value: 350, suffix: "+", label: bi("موزع", "Distributors"),          sub: bi("ضمن شبكة توزيع واسعة", "across our distribution network") },
    { value: 88,  suffix: "%", label: bi("", ""),                          sub: bi("من مبيعاتنا داخل السوق السعودي", "of our sales are within the Saudi market") }
  ].freeze

  PARTNER_STATS = [
    { value: 350, suffix: "+", label: bi("موزع", "Distributors"), sub: bi("ضمن شبكة توزيع واسعة.", "across our distribution network.") },
    { value: 7,   suffix: "",  label: bi("أسواق", "Markets"),     sub: bi("السعودية و6 أسواق خارجية.", "Saudi Arabia and 6 international markets.") },
    { value: 70,  suffix: "%", label: bi("", ""),                 sub: bi("من المبيعات تمر عبر شبكة الموزعين.", "of sales are generated through our distributor network.") }
  ].freeze

  SOCIAL = [
    { key: "instagram", label: bi("إنستجرام", "Instagram"), url: "https://www.instagram.com/mazayaalu", abbr: "IG" },
    { key: "linkedin",  label: bi("لينكدإن", "LinkedIn"),   url: "https://www.linkedin.com/in/%D8%A3%D9%84%D9%85%D9%86%D9%8A%D9%88%D9%85-%D9%85%D8%B2%D8%A7%D9%8A%D8%A7-aluminum-mazaya-856a80432", abbr: "in" },
    { key: "x",         label: bi("إكس", "X"),              url: "https://x.com/Mazayaalu", abbr: "X" },
    { key: "tiktok",    label: bi("تيك توك", "TikTok"),     url: "https://www.tiktok.com/@mazayaaluminum", abbr: "TT" },
    { key: "snapchat",  label: bi("سناب شات", "Snapchat"),  url: "https://www.snapchat.com/@mazaya-alminum/0da3ede2-7112-437a-b26f-97db341d9ac2", abbr: "SC" },
    { key: "pinterest", label: bi("بنترست", "Pinterest"),   url: "https://pin.it/3j96OT9wG", abbr: "P" }
  ].freeze

  # TODO(client): confirm which client logos may appear in the trust strip.
  CLIENTS = [
    { name: bi("ساكو SACO", "SACO"),         logo: "/assets/logo-saco.png",    bg: "#0D1744" },
    { name: bi("روشن ROSHN", "ROSHN"),       logo: "/assets/logo-roshn.svg",   bg: "#FFFFFF" },
    { name: bi("الدرعية DIRIYAH", "DIRIYAH"), logo: "/assets/logo-diriyah.png", bg: "#F7F1E6" }
  ].freeze

  DEPARTMENTS = [
    { key: "sales",     name: bi("المبيعات", "Sales"),                       desc: bi("شراء منتج أو طلب عرض سعر داخل المملكة.", "Product purchases and quotations within Saudi Arabia.") },
    { key: "export",    name: bi("التصدير", "Export"),                       desc: bi("طلبات الأسواق الخارجية.", "Requests from international markets.") },
    { key: "technical", name: bi("الدعم الفني", "Technical Support"),        desc: bi("المواصفات، أدلة الاستخدام، والمعلومات الفنية.", "Specifications, user guides, and technical information.") },
    { key: "partners",  name: bi("الشراكة والتوزيع", "Partnership & Distribution"), desc: bi("الانضمام كموزّع والشراكات التجارية.", "Becoming a distributor and business partnerships.") }
  ].freeze

  INQUIRY_TYPES = [
    bi("شراء منتج", "Product Purchase"), bi("مشروع / طلب عرض سعر", "Project / Request for Quotation"), bi("تصدير", "Export"),
    bi("دعم فني", "Technical Support"), bi("شراكة / توزيع", "Partnership / Distribution"), bi("استفسار آخر", "Other Inquiry")
  ].freeze
  ORG_TYPES = { "contractor" => bi("مقاول", "Contractor"), "distributor" => bi("موزّع", "Distributor"), "project" => bi("جهة مشروع", "Project Owner"), "end_user" => bi("مستخدم", "End User"), "other" => bi("أخرى", "Other") }.freeze

  # ---------------------------------------------------------------------------
  # Downloads. Gated = 3-field lead form before the file. Files are
  # placeholders until the client delivers the real PDFs.
  # ---------------------------------------------------------------------------
  DOWNLOADS = {
    # One catalog per track: B2B pages (b2b, solutions, projects, catalog, rfq, partners) give catalog-b2b,
    # product pages give catalog-b2c; the footer follows the current page (ApplicationHelper#track_catalog).
    "catalog-b2b"       => { title: bi("كتالوج حلول الأعمال", "Business Solutions Catalog"), file: "/downloads/mazaya-catalog-b2b.pdf", gated: true },
    "catalog-b2c"       => { title: bi("كتالوج منتجات مزايا", "Mazaya Products Catalog"),     file: "/downloads/mazaya-catalog-b2c.pdf", gated: true },
    "catalog-full"      => { title: bi("كتالوج مزايا للمنتجات والحلول", "Mazaya Products & Solutions Catalog"), file: "/downloads/mazaya-catalog-b2c.pdf", gated: true, version: PENDING, updated: PENDING },
    "catalog-ladders"   => { title: bi("كتالوج السلالم وحلول الوصول", "Ladders & Access Solutions Catalog"),    file: "/downloads/mazaya-catalog-b2c.pdf", gated: true },
    "catalog-trolleys"  => { title: bi("كتالوج العربات وحلول المناولة", "Trolleys & Material Handling Catalog"), file: "/downloads/mazaya-catalog-b2c.pdf", gated: true },
    "catalog-flooring"  => { title: bi("كتالوج حلول الأرضيات والتصريف", "Flooring & Drainage Solutions Catalog"), file: "/downloads/mazaya-catalog-b2c.pdf", gated: true },
    "catalog-covers"    => { title: bi("كتالوج أغطية وفتحات الوصول", "Covers & Access Hatches Catalog"),         file: "/downloads/mazaya-catalog-b2c.pdf", gated: true },
    "catalog-aluminium" => { title: bi("كتالوج منتجات وحلول الألومنيوم", "Aluminum Products & Solutions Catalog"), file: "/downloads/mazaya-catalog-b2c.pdf", gated: true },
    "technical-catalog" => { title: bi("الكتالوج الفني", "Technical Catalog"),                                   file: "/downloads/mazaya-catalog-b2b.pdf", gated: true },
    "tds"               => { title: bi("ورقة البيانات الفنية (TDS)", "Technical Data Sheet (TDS)"),              file: "/downloads/placeholder.pdf", gated: true },
    "user-guide"        => { title: bi("دليل الاستخدام والتركيب", "User & Installation Guide"),                  file: "/downloads/placeholder.pdf", gated: false },
    "company-profile"   => { title: bi("الملف التعريفي لشركة مزايا", "Mazaya Company Profile"),                  file: "/downloads/placeholder.pdf", gated: true, size: PENDING }
  }.freeze

  # ---------------------------------------------------------------------------
  # Catalog tree (from Category Page Prototype v2). Sub-categories and sample
  # products are the prototype's; the Excel sheet will replace/extend them.
  # `en` is the Latin subtitle shown under Arabic names (and vice-versa).
  # ---------------------------------------------------------------------------
  CATEGORIES = [
    {
      slug: "ladders", name: bi("السلالم وحلول الوصول", "Ladders & Access Solutions"), en: bi("Ladders & Access Solutions", "السلالم وحلول الوصول"), image: "/assets/cat-ladders.jpg", catalog: "catalog-ladders",
      desc: bi("مجموعة متنوعة من السلالم وحلول الوصول للاستخدامات المهنية واليومية، بخيارات ومواصفات متعددة تناسب احتياجات العمل المختلفة.", "A diverse range of ladders and access solutions for professional and everyday use, with multiple options and specifications to suit different working needs."),
      b2c: bi("خيارات متنوعة للوصول والعمل على ارتفاعات مختلفة، للاستخدامات المهنية واليومية.", "A range of access solutions for different working heights, professional applications, and everyday use."),
      b2b: bi("حلول وصول للاستخدامات المهنية والصناعية ومتطلبات مواقع العمل.", "Access solutions for professional, industrial, and worksite applications."),
      about: bi("حلول للوصول والعمل على الارتفاعات لمختلف الاستخدامات.", "Solutions for access and working at different heights across various applications."),
      finder: bi("سلم", "Ladder"),
      specs: [ bi("الاستخدام", "Application"), bi("الارتفاع", "Height"), bi("عدد الدرجات", "Number of Steps"), bi("حد التحميل", "Load Capacity"), bi("الخامة", "Material") ],
      subcategories: [
        { slug: "single",    name: bi("سلالم مفردة", "Single Ladders") },
        { slug: "multi",     name: bi("سلالم متعددة الأوضاع", "Multi-Position Ladders") },
        { slug: "extension", name: bi("سلالم قابلة للتمديد", "Extension Ladders") }
      ]
    },
    {
      slug: "trolleys", name: bi("العربات وحلول المناولة", "Trolleys & Material Handling Solutions"), en: bi("Trolleys & Material Handling Solutions", "العربات وحلول المناولة"), image: "/assets/cat-carts.jpg", catalog: "catalog-trolleys",
      desc: bi("حلول للنقل والمناولة تساعد على تنظيم وتحريك الأدوات والمواد في الاستخدامات المهنية والتجارية.", "Transport and handling solutions that help organise and move tools and materials in professional and commercial applications."),
      b2c: bi("حلول تساعد على نقل ومناولة الأغراض بسهولة في الاستخدامات المختلفة.", "Solutions designed to make transporting and handling items easier across different applications."),
      b2b: bi("حلول للنقل والمناولة تدعم احتياجات التشغيل في القطاعات المختلفة.", "Transport and material handling solutions designed to support operational needs across different sectors."),
      about: bi("منتجات تساعد على نقل ومناولة الأدوات والمواد في بيئات العمل المختلفة.", "Products that support the movement and handling of tools and materials across different working environments."),
      finder: bi("عربة", "Trolley"),
      specs: [ bi("نوع العربة", "Trolley Type"), bi("الاستخدام", "Application"), bi("سعة التحميل", "Load Capacity"), bi("المقاس", "Size"), bi("الخامة", "Material") ],
      subcategories: [
        { slug: "aluminium", name: bi("عربات ألومنيوم", "Aluminum Trolleys") },
        { slug: "tools",     name: bi("عربات أدوات", "Tool Trolleys") },
        { slug: "platform",  name: bi("عربات منصة مسطحة", "Flat Platform Trolleys") }
      ]
    },
    {
      slug: "flooring", name: bi("حلول الأرضيات والتصريف", "Flooring & Drainage Solutions"), en: bi("Flooring & Drainage Solutions", "حلول الأرضيات والتصريف"), image: "/assets/proj-infra.jpg", catalog: "catalog-flooring",
      desc: bi("مجموعة من حلول الأرضيات وتصريف المياه لمتطلبات الاستخدام المختلفة في المواقع المهنية والتجارية.", "A range of flooring and water drainage solutions for different requirements in professional and commercial sites."),
      b2c: bi("مجموعة من حلول الأرضيات وتصريف المياه لمتطلبات واستخدامات متنوعة.", "A range of flooring and water drainage solutions for different needs and applications."),
      b2b: bi("منتجات وحلول تشمل الدعاسات ومصارف وقنوات تصريف المياه لتطبيقات متنوعة.", "Products and solutions including floor mats, floor drains, and drainage channels for a range of applications."),
      about: bi("حلول للأرضيات وتصريف المياه وفق متطلبات الاستخدام والموقع.", "Flooring and water drainage solutions for different site and application requirements."),
      finder: bi("حل للأرضيات أو التصريف", "Flooring or Drainage Solution"),
      specs: [ bi("نوع الحل", "Solution Type"), bi("الاستخدام", "Application"), bi("المقاس", "Size"), bi("نوع التركيب", "Installation Type"), bi("الخامة", "Material") ],
      subcategories: [
        { slug: "mats",     name: bi("دعاسات الأرضيات", "Floor Mats") },
        { slug: "drains",   name: bi("مصارف الأرضيات", "Floor Drains") },
        { slug: "channels", name: bi("قنوات تصريف المياه", "Drainage Channels") }
      ]
    },
    {
      slug: "covers", name: bi("أغطية وفتحات الوصول", "Covers & Access Hatches"), en: bi("Covers & Access Hatches", "أغطية وفتحات الوصول"), image: "/assets/proj-tower.jpg", catalog: "catalog-covers",
      desc: bi("خيارات متعددة لأغطية وفتحات الوصول والتفتيش والصيانة لمتطلبات المشاريع والاستخدامات المختلفة.", "Multiple options for covers and access, inspection, and maintenance hatches for different project and application requirements."),
      b2c: bi("خيارات متعددة لأغطية وفتحات الوصول والتفتيش والصيانة.", "A variety of covers and access hatches for inspection and maintenance applications."),
      b2b: bi("أغطية المناهل والتفتيش وفتحات الوصول والصيانة وفق متطلبات الاستخدام.", "Manhole and inspection covers, as well as access and maintenance hatches for different application requirements."),
      about: bi("حلول للوصول والتفتيش والصيانة في المشاريع والمنشآت.", "Solutions for access, inspection, and maintenance across projects and facilities."),
      finder: bi("غطاء أو فتحة وصول", "Cover or Access Hatch"),
      specs: [ bi("نوع الغطاء / الفتحة", "Cover / Hatch Type"), bi("الاستخدام", "Application"), bi("المقاس", "Size"), bi("متطلبات التحمل", "Load Requirements"), bi("الخامة", "Material") ],
      subcategories: [
        { slug: "manhole",     name: bi("أغطية مناهل وتفتيش", "Manhole & Inspection Covers") },
        { slug: "maintenance", name: bi("فتحات صيانة", "Maintenance Hatches") },
        { slug: "access",      name: bi("فتحات وصول", "Access Hatches") }
      ]
    },
    {
      slug: "aluminium", name: bi("منتجات وحلول الألومنيوم", "Aluminum Products & Solutions"), en: bi("Aluminum Products & Solutions", "منتجات وحلول الألومنيوم"), image: "/assets/cat-custom.jpg", catalog: "catalog-aluminium",
      desc: bi("منتجات وحلول ألومنيوم متنوعة للاستخدامات المهنية والتجارية والمشاريع، مع خيارات قابلة للتخصيص.", "Diverse aluminum products and solutions for professional, commercial, and project applications, with customizable options."),
      b2c: bi("منتجات ألومنيوم متنوعة للاستخدامات المهنية والتجارية المختلفة.", "A diverse range of aluminum products for professional and commercial applications."),
      b2b: bi("منتجات وحلول إضافية من الألومنيوم لتلبية متطلبات المشاريع والتطبيقات المختلفة.", "Additional aluminum products and solutions developed for diverse project and application requirements."),
      about: bi("منتجات وحلول متنوعة، مع إمكانية التخصيص وفق متطلبات المشروع.", "A diverse range of aluminum products and solutions, with customization available according to project requirements."),
      finder: bi("منتج ألومنيوم آخر", "Other Aluminum Product"),
      specs: [ bi("نوع المنتج", "Product Type"), bi("الاستخدام", "Application"), bi("المقاس", "Size"), bi("التشطيب", "Finish"), bi("الخامة", "Material") ],
      subcategories: [
        { slug: "boxes",  name: bi("صناديق ألومنيوم", "Aluminum Boxes") },
        { slug: "dust",   name: bi("مانعات وحواجز الغبار", "Dust Barriers & Guards") },
        { slug: "custom", name: bi("حلول ألومنيوم مخصصة", "Custom Aluminum Solutions") }
      ]
    }
  ].freeze

  # Sample products from the prototype. Spec values are PENDING on purpose:
  # the copy deck avoids technical figures that are not in the source material.
  PRODUCTS = [
    # Fully specified example (from the client's MML-000 product page prototype).
    {
      slug: "multi-position-ladder", name: bi("سلم متعدد الأوضاع", "Multi-Position Ladder"), code: "MML-000", category: "ladders", subcategory: "multi", kind: :ready, popular: true,
      summary: bi("سلم ألومنيوم متحرك ومتعدد الأوضاع، مزود بمفاصل قفل ذكية وعجلات، ويمكن تشكيله ليتناسب مع استخدامات ومساحات عمل مختلفة.", "A mobile, multi-position aluminum ladder with smart locking joints and wheels that can be configured to suit different applications and working spaces."),
      safety: "choose-right-product", related: [ "single-ladder", "extension-ladder", "custom-aluminium-solution" ],
      images: [
        { src: "/assets/products/mml-000-position-a.jpg", label: bi("الوضع A", "A-frame position") },
        { src: "/assets/products/mml-000-front.jpg",      label: bi("واجهة أمامية", "Front view") },
        { src: "/assets/products/mml-000-open.jpg",       label: bi("وضع مفتوح", "Extended position") },
        { src: "/assets/products/mml-000-scaffold.jpg",   label: bi("وضع السقالة", "Scaffold position") },
        { src: "/assets/products/mml-000-position-m.jpg", label: bi("وضع M", "M position") },
        { src: "/assets/products/mml-000-side.jpg",       label: bi("الوضع الجانبي", "Side position") }
      ],
      features: [
        [ bi("أوضاع متعددة", "Multiple Positions"),      bi("يتحول إلى سلم مزدوج، سلم مستقيم، منصة عمل، أو شكل M/سقالة.", "Converts into a double ladder, straight ladder, work platform, or M / scaffold shape.") ],
        [ bi("سهولة الحركة", "Easy to Move"),            bi("مزود بعجلات تساعد على نقله داخل موقع العمل.", "Fitted with wheels that make it easy to move around the worksite.") ],
        [ bi("سهولة التخزين", "Easy to Store"),          bi("تصميم قابل للطي يساعد على توفير مساحة عند التخزين.", "A foldable design that saves space in storage.") ],
        [ bi("ثبات أثناء الاستخدام", "Stable in Use"),   bi("مفاصل قفل وقواعد تساعد على تحقيق الثبات أثناء الاستخدام.", "Locking joints and feet that help keep the ladder stable during use.") ]
      ],
      applications: [
        [ bi("أعمال الدهان", "Painting Work"),                          bi("مرونة في تغيير الوضع حسب طبيعة العمل.", "Flexibility to change position according to the task.") ],
        [ bi("الصيانة المنزلية والفنية", "Home & Technical Maintenance"), bi("يساعد على الوصول إلى نقاط العمل المختلفة.", "Helps reach different working points.") ],
        [ bi("الوصول إلى المرتفعات", "Reaching Heights"),                bi("أوضاع متعددة للوصول حسب الاحتياج.", "Multiple positions for access as needed.") ],
        [ bi("المستويات غير المستوية", "Uneven Levels"),                 bi("يمكن استخدامه في بيئات مثل الدرج والسلالم.", "Can be used on stairs and stepped surfaces.") ]
      ],
      specs: [
        [ bi("نوع المنتج", "Product Type"),   bi("سلم ألومنيوم متعدد الأوضاع", "Multi-position aluminum ladder") ],
        [ bi("الخامة", "Material"),           bi("ألومنيوم", "Aluminum") ],
        [ bi("نظام القفل", "Locking System"), bi("مفاصل قفل", "Locking joints") ],
        [ bi("الحركة", "Mobility"),           bi("مزود بعجلات", "Fitted with wheels") ],
        [ bi("الاستخدام", "Application"),     bi("متعدد الأوضاع", "Multi-position") ]
      ],
      size_cols: [ bi("كود المنتج", "Product Code"), bi("المقاس", "Size"), bi("الارتفاع", "Height"), bi("عدد الدرجات", "Steps"), bi("حد التحميل", "Load") ],
      faq: [
        [ bi("هل المنتج جاهز أم حسب الطلب؟", "Is this product ready-made or custom-made?"), bi("يعرض المنتج هنا بوسم واضح يحدد حالته، وتُحدّث الحالة حسب بيانات المنتج الفعلية.", "The product carries a clear tag showing its status, updated from the actual product data.") ],
        [ bi("أين أجد المقاسات والأكواد؟", "Where can I find sizes and codes?"), bi("تظهر جميع المقاسات والأكواد المتاحة في جدول واحد داخل صفحة المنتج.", "All available sizes and codes are listed in one table on the product page.") ],
        [ bi("هل يمكن تحميل المواصفات الفنية؟", "Can I download the technical specifications?"), bi("نعم، يمكن تحميل ملف TDS بعد تعبئة النموذج المختصر المخصص للتحميل.", "Yes, the TDS file can be downloaded after completing the short download form.") ]
      ]
    },
    { slug: "single-ladder",         name: bi("سلم مفرد", "Single Ladder"),                   category: "ladders",   subcategory: "single",      kind: :ready,  popular: true,  summary: bi("خيار عملي للاستخدامات المباشرة", "A practical option for straightforward tasks"), safety: "inspect-before-use", related: [ "multi-position-ladder", "extension-ladder" ] },
    { slug: "extension-ladder",      name: bi("سلم قابل للتمديد", "Extension Ladder"),        category: "ladders",   subcategory: "extension",   kind: :ready,  popular: false, summary: bi("حل للوصول إلى ارتفاعات مختلفة", "A solution for reaching different heights"), safety: "use-correctly", related: [ "multi-position-ladder", "single-ladder" ] },
    { slug: "aluminium-trolley",     name: bi("عربة ألومنيوم", "Aluminum Trolley"),            category: "trolleys",  subcategory: "aluminium",   kind: :ready,  popular: true,  summary: bi("حركة أسهل في بيئات العمل المختلفة", "Easier movement across different working environments"), safety: "inspect-before-use", related: [ "tool-trolley", "flat-platform-trolley" ] },
    { slug: "tool-trolley",          name: bi("عربة أدوات", "Tool Trolley"),                  category: "trolleys",  subcategory: "tools",       kind: :ready,  popular: false, summary: bi("تنظيم ونقل الأدوات داخل موقع العمل", "Organising and moving tools around the worksite"), safety: "inspect-before-use", related: [ "aluminium-trolley" ] },
    { slug: "flat-platform-trolley", name: bi("عربة منصة مسطحة", "Flat Platform Trolley"),    category: "trolleys",  subcategory: "platform",    kind: :custom, popular: false, summary: bi("للنقل والمناولة في المستودعات والمواقع", "For transport and handling in warehouses and sites"), safety: "use-correctly", related: [ "aluminium-trolley" ] },
    { slug: "floor-mats",            name: bi("دعاسات أرضيات", "Floor Mats"),                 category: "flooring",  subcategory: "mats",        kind: :custom, popular: false, summary: bi("حلول مخصصة لمتطلبات المساحات المختلفة", "Custom solutions for different space requirements"), safety: nil, related: [ "floor-drains", "drainage-channels" ] },
    { slug: "floor-drains",          name: bi("مصارف أرضيات", "Floor Drains"),                category: "flooring",  subcategory: "drains",      kind: :ready,  popular: true,  summary: bi("خيارات لتصريف المياه حسب الاستخدام", "Water drainage options according to application"), safety: nil, related: [ "drainage-channels" ] },
    { slug: "drainage-channels",     name: bi("قنوات تصريف المياه", "Drainage Channels"),     category: "flooring",  subcategory: "channels",    kind: :custom, popular: false, summary: bi("حلول تصريف لمتطلبات مختلفة", "Drainage solutions for different requirements"), safety: nil, related: [ "floor-drains" ] },
    { slug: "inspection-cover",      name: bi("غطاء تفتيش", "Inspection Cover"),              category: "covers",    subcategory: "manhole",     kind: :ready,  popular: true,  summary: bi("حل للوصول إلى نقاط الخدمة والفحص", "Access to service and inspection points"), safety: nil, related: [ "maintenance-hatch", "access-hatch" ] },
    { slug: "maintenance-hatch",     name: bi("فتحة صيانة", "Maintenance Hatch"),             category: "covers",    subcategory: "maintenance", kind: :custom, popular: false, summary: bi("وصول أسهل لأعمال الفحص والصيانة", "Easier access for inspection and maintenance work"), safety: nil, related: [ "inspection-cover" ] },
    { slug: "access-hatch",          name: bi("فتحة وصول", "Access Hatch"),                   category: "covers",    subcategory: "access",      kind: :ready,  popular: false, summary: bi("خيارات لمتطلبات مختلفة بالمشروع", "Options for different project requirements"), safety: nil, related: [ "inspection-cover" ] },
    { slug: "aluminium-box",         name: bi("صندوق ألومنيوم", "Aluminum Box"),               category: "aluminium", subcategory: "boxes",       kind: :ready,  popular: true,  summary: bi("حل عملي للتخزين والاستخدام المهني", "A practical solution for storage and professional use"), safety: nil, related: [ "dust-barrier" ] },
    { slug: "dust-barrier",          name: bi("مانع غبار", "Dust Barrier"),                   category: "aluminium", subcategory: "dust",        kind: :custom, popular: false, summary: bi("حلول لمتطلبات المداخل والمساحات المختلفة", "Solutions for entrances and different spaces"), safety: nil, related: [ "aluminium-box" ] },
    { slug: "custom-aluminium-solution", name: bi("حل ألومنيوم مخصص", "Custom Aluminum Solution"), category: "aluminium", subcategory: "custom", kind: :custom, popular: false, summary: bi("يتم تطويره حسب متطلبات المشروع", "Developed according to project requirements"), safety: nil, related: [ "aluminium-box", "dust-barrier" ] }
  ].freeze

  # ---------------------------------------------------------------------------
  # B2B: custom solutions (the five named in the company profile)
  # ---------------------------------------------------------------------------
  SOLUTIONS = [
    { slug: "custom-ladders",      name: bi("السلالم الخاصة", "Custom Ladders"),                                    en: bi("Custom Ladders", "السلالم الخاصة"),                                    category: "ladders",   image: "/assets/cat-ladders.jpg", projects: [ "king-salman-park", "diriyah-gate" ] },
    { slug: "work-platforms",      name: bi("منصات العمل", "Work Platforms"),                                       en: bi("Work Platforms", "منصات العمل"),                                       category: "ladders",   image: "/assets/proj-tower.jpg",  projects: [ "riyadh-metro", "qiddiya" ] },
    { slug: "industrial-trolleys", name: bi("العربات الصناعية", "Industrial Trolleys"),                             en: bi("Industrial Trolleys", "العربات الصناعية"),                             category: "trolleys",  image: "/assets/cat-carts.jpg",   projects: [ "red-sea", "qiddiya" ] },
    { slug: "manhole-covers",      name: bi("أغطية المناهل", "Manhole Covers"),                                     en: bi("Manhole Covers", "أغطية المناهل"),                                     category: "covers",    image: "/assets/proj-infra.jpg",  projects: [ "riyadh-metro", "king-salman-park" ] },
    { slug: "custom-aluminium",    name: bi("حلول الألومنيوم والمعدن المخصصة", "Custom Aluminum & Metal Solutions"), en: bi("Custom Aluminum & Metal Solutions", "حلول الألومنيوم والمعدن المخصصة"), category: "aluminium", image: "/assets/cat-custom.jpg",  projects: [ "diriyah-gate", "red-sea" ] }
  ].freeze

  CUSTOM_FEATURES = [
    [ bi("المقاسات", "Dimensions"),                 bi("تخصيص الأبعاد وفق متطلبات المشروع والاستخدام.", "Customized according to project and application requirements.") ],
    [ bi("التصميم", "Design"),                      bi("تطوير التصميم بما يتناسب مع التطبيق والمواصفات المطلوبة.", "Developed to suit the intended application and required specifications.") ],
    [ bi("السماكات", "Thicknesses"),                bi("تحديد السماكات وفق متطلبات الحل.", "Specified according to the solution requirements.") ],
    [ bi("الأحمال والتحمّل", "Load Requirements"),  bi("مراعاة متطلبات الأحمال ضمن التصميم والاستخدام.", "Considered according to the design and intended application.") ],
    [ bi("التشطيبات والألوان", "Finishes & Colors"), bi("خيارات مختلفة للتشطيب والألوان وفق متطلبات المشروع.", "Customizable options based on project requirements.") ]
  ].freeze

  CUSTOM_STEPS = [
    [ bi("فهم المتطلبات", "Understanding Your Requirements"), bi("نبدأ بمراجعة احتياج المشروع، التطبيق والمواصفات الفنية المطلوبة.", "We begin by reviewing the project needs, application, and required technical specifications.") ],
    [ bi("التصميم الهندسي", "Engineering Design"),            bi("نعمل على الرسم المقدم من العميل، أو نطوّر التصميم وفق متطلبات الحل.", "We work from client-provided drawings or develop the design based on the solution requirements.") ],
    [ bi("اعتماد الحل", "Solution Approval"),                 bi("تتم مراجعة التصميم ومتطلباته قبل الانتقال إلى مراحل التصنيع.", "The design and its requirements are reviewed before moving into manufacturing.") ],
    [ bi("التصنيع والتسليم", "Manufacturing & Delivery"),     bi("يبدأ التصنيع وفق المواصفات المعتمدة، وصولًا إلى تجهيز الحل للمشروع.", "Manufacturing begins according to the approved specifications, followed by preparation for project delivery.") ]
  ].freeze

  # ---------------------------------------------------------------------------
  # Projects: the five reference projects named in the company profile.
  # Detail fields are PENDING until the client supplies approved data/images.
  # ---------------------------------------------------------------------------
  PROJECTS = [
    { slug: "king-salman-park", name: bi("حديقة الملك سلمان", "King Salman Park"), en: bi("King Salman Park", "حديقة الملك سلمان"), image: "/assets/proj-roshn.jpg",   featured: true,  products: [ "custom-ladders", "manhole-covers" ] },
    { slug: "qiddiya",          name: bi("مشروع القدية", "Qiddiya Project"),        en: bi("Qiddiya Project", "مشروع القدية"),        image: "/assets/proj-tower.jpg",   featured: true,  products: [ "work-platforms", "industrial-trolleys" ] },
    { slug: "red-sea",          name: bi("مشروع البحر الأحمر", "The Red Sea Project"), en: bi("Red Sea Project", "مشروع البحر الأحمر"), image: "/assets/cat-custom.jpg",   featured: false, products: [ "industrial-trolleys", "custom-aluminium" ] },
    { slug: "diriyah-gate",     name: bi("بوابة الدرعية", "Diriyah Gate"),           en: bi("Diriyah Gate", "بوابة الدرعية"),          image: "/assets/proj-diriyah.jpg", featured: false, products: [ "custom-ladders", "custom-aluminium" ] },
    { slug: "riyadh-metro",     name: bi("مترو الرياض", "Riyadh Metro"),             en: bi("Riyadh Metro", "مترو الرياض"),            image: "/assets/proj-infra.jpg",   featured: true,  products: [ "work-platforms", "manhole-covers" ] }
  ].freeze

  PROJECT_FIELDS = [ bi("المنتج المورّد", "Product Supplied"), bi("نطاق العمل", "Scope of Work"), bi("الكمية / حجم المشروع", "Quantity / Project Scale"), bi("سنة التنفيذ", "Year of Completion") ].freeze

  # ---------------------------------------------------------------------------
  # Quality & certifications
  # ---------------------------------------------------------------------------
  # NOTE: source material cites ISO 9001:2008; publish "ISO" only until the
  # current certificate/version is confirmed.
  CERTIFICATIONS = [
    { key: "iso",        name: "ISO 9001:2015",                    desc: bi("شهادة نظام إدارة الجودة وفق المواصفة الدولية ISO 9001:2015.", "Quality management system certification to the international ISO 9001:2015 standard."), cta: bi("عرض الشهادة", "View Certificate"), image: "/assets/certificates/iso.png" },
    { key: "sgs",        name: "SGS",                              desc: bi("اعتماد نظام إدارة الجودة ISO 9001 من SGS، إحدى الجهات الدولية الرائدة في الفحص والاعتماد.", "ISO 9001 quality management certification from SGS, a leading international inspection and certification body."), cta: bi("عرض الشهادة", "View Certificate"), image: "/assets/certificates/sgs.png" },
    { key: "saso",       name: "SASO",                             desc: bi("اعتمادات مرتبطة بالمواصفات والمقاييس السعودية.", "Approvals related to Saudi standards and specifications."), cta: bi("عرض الاعتماد", "View Approval"), image: "/assets/certificates/saso.png" },
    { key: "saudi_made", name: bi("صناعة سعودية", "Saudi Made"),   desc: bi("منتجات مصنّعة محليًا ضمن برنامج صناعة سعودية.", "Locally manufactured products under the Saudi Made program."), cta: bi("اعرف المزيد", "Learn More"), image: "/assets/certificates/saudi-made.png" }
  ].freeze

  DOCUMENTS = [
    [ "ISO", bi("عرض الشهادة", "View Certificate") ], [ "SASO", bi("عرض الاعتماد", "View Approval") ], [ bi("تقارير اختبارات الأحمال", "Load Testing Reports"), bi("عرض التقارير", "View Reports") ],
    [ bi("تقارير الاختبار", "Test Reports"), bi("عرض التقارير", "View Reports") ], [ bi("شهادات الجودة", "Quality Certificates"), bi("عرض الشهادات", "View Certificates") ], [ bi("شهادات السلامة", "Safety Certificates"), bi("عرض الشهادات", "View Certificates") ]
  ].freeze

  # Quality-page documents shown as image cards + lightbox. A document may span several pages (images):
  # `pages` lists files in public/assets/certificates/<dir>/; without it the single page is <dir>/<key>.webp.
  def self.scan_docs(dir, docs)
    docs.map do |d|
      pages = (d[:pages] || [ "#{d[:key]}.webp" ]).map { |f| "/assets/certificates/#{ERB::Util.url_encode(dir)}/#{ERB::Util.url_encode(f)}" }
      d.except(:pages).merge(pages: pages, image: pages.first)
    end.freeze
  end
  private_class_method :scan_docs

  # 06 — Documents: certificates, policies and the SGS report (public/assets/certificates/docs/)
  CERTIFICATE_SCANS = scan_docs("docs", [
    { key: "iso-9001-2019",     title: bi("شهادة ISO 9001:2015 — SGS (تجديد)", "ISO 9001:2015 Certificate — SGS (renewal)") },
    { key: "iso-9001-2016",     title: bi("شهادة ISO 9001:2015 — SGS", "ISO 9001:2015 Certificate — SGS") },
    { key: "saso-quality-mark", title: bi("ترخيص علامة الجودة السعودية — SASO", "Saudi Quality Mark License — SASO") },
    { key: "quality-policy",    title: bi("سياسة الجودة", "Quality Policy") },
    { key: "warranty",          title: bi("ضمان مزايا للألمنيوم", "Mazaya Aluminium Warranty") },
    { key: "sgs-test-report",   title: bi("تقرير اختبار SGS", "SGS Test Report"), pages: (1..4).map { |i| "sgs-test-report-#{i}.webp" } }
  ])

  # 04 — Load testing: load-test reports and product data sheets (public/assets/certificates/اختبارات الاحمال/)
  LOAD_TESTS = scan_docs("اختبارات الاحمال", [
    # test reports
    { key: "ladder-test-report", group: "reports", product: "ladders/step-ladder", title: bi("تقرير اختبار SGS — سلم 7 درجات", "SGS Test Report — 7-Step Ladder"),
      pages: (1..10).map { |i| format("LADDER  TEST REPORT-07 STEPS-%02d.webp", i) } },
    { key: "manhole-load-test", group: "reports", product: "covers/manhole-cover", title: bi("تقرير اختبار تحمّل أغطية المناهل الألومنيوم", "Aluminium Manhole Cover Load Test Report"),
      pages: [ "Manhole Cover (Aluminum) Test-MAT-S-26-03798-MAT-O-26-02092-24-09-2026-1.webp" ] },
    # product data sheets
    { key: "a-type-ladder", group: "ladders", product: "ladders/construction-ladder",     title: bi("نشرة فنية — سلم على شكل A", "Data Sheet — A-Type Ladder"), pages: [ "1. A-TYPE LADDER (1)-1.webp" ] },
    { key: "single-ladder", group: "ladders", product: "ladders/single-ladder",     title: bi("نشرة فنية — سلم مفرد SLD-D", "Data Sheet — Single Ladder (SLD-D)"),
      pages: [ "SLD - SINGLE LADDER-D-1.webp", "SLD - SINGLE LADDER-D-2.webp" ] },
    { key: "warehouse-ladder", group: "ladders", product: "ladders/warehouse-ladder",  title: bi("نشرة فنية — سلم المستودعات القابل للطي", "Data Sheet — Foldable Warehouse Ladder"),
      pages: [ "WAREHOUSE FOLDABLE LADDER-1.webp", "WAREHOUSE FOLDABLE LADDER-2.webp" ] },
    { key: "platform-ladder", group: "ladders", product: "ladders/mobile-platform-ladder",   title: bi("نشرة فنية — سلم بمنصة وصول", "Data Sheet — Access Platform Ladder"), pages: [ "LADDER PLATFORM DATA (1)-1.webp" ] },
    { key: "roof-ladder", group: "ladders", product: "ladders/rooftop-ladder",       title: bi("نشرة فنية — سلم الوصول للسطح", "Data Sheet — Roof Access Ladder"), pages: [ "ROOF LADDER DATA-1.webp" ] },
    { key: "mobile-scaffolding", group: "scaffolding", product: "ladders/mobile-aluminum-scaffolding", title: bi("نشرة فنية — السقالات الألومنيوم المتنقلة", "Data Sheet — Aluminium Mobile Scaffolding"),
      pages: (1..3).map { |i| "SCAFFOLDING TECH DETAILS (1)-#{i}.webp" } },
    { key: "scaffolding-double", group: "scaffolding", product: "ladders/mobile-aluminum-scaffolding", title: bi("نشرة فنية — سقالة إنشائية مزدوجة العرض (بسلم جانبي)", "Data Sheet — Double-Width Construction Scaffolding (with Side Ladder)"),
      pages: [ "scaffolding with a ladder.webp" ] },
    { key: "scaffolding-single", group: "scaffolding", product: "ladders/mobile-aluminum-scaffolding", title: bi("نشرة فنية — سقالة إنشائية مفردة العرض", "Data Sheet — Single-Width Construction Scaffolding"),
      pages: [ "scaffolding without a ladder.webp" ] },
    { key: "roof-hatch", group: "covers", product: "covers/roof-hatch",        title: bi("نشرة فنية — فتحة السطح بباب مفرد", "Data Sheet — Single-Door Roof Access Hatch"),
      pages: (1..3).map { |i| "ROOF HATCH - SINGLE DOOR-#{i}.webp" } },
    { key: "roof-hatch-tech", group: "covers", product: "covers/roof-hatch",   title: bi("نشرة فنية — فتحة السطح (التفاصيل الفنية)", "Data Sheet — Roof Access Hatch (Technical Details)"),
      pages: [ "ROOF HATCH TECH DETAILS (1)-1.webp" ] },
    { key: "ceiling-access-panel", group: "covers", product: "covers/ceiling-access-panel", title: bi("نشرة فنية — فتحة صيانة الأسقف", "Data Sheet — Ceiling Access Panel"),
      pages: (1..3).map { |i| "MAZAYA ACCESS PANEL-#{i}.webp" } },
    { key: "wall-access-panel", group: "covers", product: "covers/aluminum-wall-access-panel", title: bi("نشرة فنية — فتحة صيانة الجدران المقاومة للحريق", "Data Sheet — Fire-Resistant Wall Access Panel"),
      pages: [ "DATA SHEET ACCESS PANEL WALL Fire Resistant-1.webp" ] },
    { key: "diwan-manhole", group: "covers", product: "covers/manhole-cover",     title: bi("نشرة فنية — غطاء منهل ديوان", "Data Sheet — Diwan Manhole Cover"), pages: [ "DEWAN MANHOL COVER-1.webp" ] },
    { key: "water-tank-cover", group: "covers", product: "covers/water-tank-normal",  title: bi("نشرة فنية — غطاء خزان المياه", "Data Sheet — Water Tank Cover"),
      pages: [ "WATER TANK MANHOLE COVER- NORMAL-1.webp", "WATER TANK MANHOLE COVER- NORMAL-2.webp" ] },
    { key: "inspection-cover", group: "covers", product: "covers/manhole-cover-6-5-cm",  title: bi("نشرة فنية — غطاء غرفة التفتيش", "Data Sheet — Inspection Chamber Cover"), pages: [ "Inspection room.webp" ] },
    { key: "drainage-honeycomb", group: "drainage", product: "flooring/honeycomb-runoff-water-drainage", title: bi("نشرة فنية — تصريف مزايا (قرص العسل / حراشف السمك)", "Data Sheet — Mazaya Drainage (Honeycomb / Fish Scale)"),
      pages: [ "MZY-DRG-HONEY COMB and FISH SCALE (1)-1.webp" ] },
    { key: "drainage-fishscale", group: "drainage", product: "flooring/fish-scale-drainage-channel", title: bi("نشرة فنية — تصريف مزايا (حراشف السمك)", "Data Sheet — Mazaya Drainage (Fish Scale)"), pages: [ "fish scale Drainag-1.webp" ] },
    { key: "stream-channel", group: "drainage", product: "flooring/runoff-water-drainage",    title: bi("نشرة فنية — قناة تصريف المياه", "Data Sheet — Stream Channel Drainage"), pages: [ "stream channel.webp" ] },
    { key: "floor-mat-strip", group: "mats", product: "flooring/floor-mats",   title: bi("نشرة فنية — دعّاسة أرضيات بالشرائح", "Data Sheet — Strip Floor Mat"), pages: [ "9c. FLOORMAT - STRIP - FLOORMAT-1.webp" ] },
    { key: "remal-floor-mat", group: "mats", product: "flooring/rimal-floor-mat",   title: bi("نشرة فنية — دعّاسة رمال", "Data Sheet — Remal Floor Mat"), pages: [ "Floor Mat REMAL-1.webp" ] },
    { key: "wire-mesh", group: "other",         title: bi("نشرة فنية — الشبك المجلفن", "Data Sheet — Galvanized Wire Mesh"),
      pages: [ "GALVANIZED WIRE MESH (1)-1.webp", "GALVANIZED WIRE MESH (1)-2.webp" ] }
  ])

  QUALITY_STEPS = [
    [ bi("التصنيع", "Manufacturing"),               bi("تنفيذ المنتج وفق متطلباته ومواصفاته المحددة.", "Products are manufactured according to their defined requirements and specifications.") ],
    [ bi("الدقة والتجميع", "Precision & Assembly"), bi("الاهتمام بدقة التصنيع والتجميع وفق طبيعة كل منتج.", "Attention is given to manufacturing and assembly precision according to the nature of each product.") ],
    [ bi("اختبارات الجودة", "Quality Testing"),     bi("إجراء الاختبارات المرتبطة بجودة المنتج.", "Relevant product quality tests are conducted.") ],
    [ bi("اختبارات الأحمال", "Load Testing"),       bi("اختبار التحمل للمنتجات التي تتطلب ذلك قبل اعتمادها.", "Load testing is carried out for products where load-bearing performance is required.") ]
  ].freeze

  # ---------------------------------------------------------------------------
  # Safety & user guide
  # ---------------------------------------------------------------------------
  SAFETY_CHOOSE = [
    [ bi("حدد طبيعة الاستخدام", "Identify the Application"),          bi("اختر المنتج المصمم للمهمة التي تريد تنفيذها.", "Choose a product designed for the task you need to perform.") ],
    [ bi("راجع الارتفاع والمقاسات", "Check Height & Dimensions"),      bi("تأكد من أن أبعاد المنتج ومدى الوصول يناسبان متطلبات العمل.", "Make sure the product dimensions and reach are suitable for the job requirements.") ],
    [ bi("تحقق من الحمولة", "Check Load Capacity"),                    bi("راجع الحمولة المحددة للمنتج قبل الاستخدام.", "Review the specified load capacity before use.") ],
    [ bi("راعِ بيئة العمل", "Consider the Working Environment"),       bi("ضع في الاعتبار طبيعة الموقع وسطح الاستخدام والظروف المحيطة.", "Take the worksite, surface conditions, and surrounding environment into account.") ]
  ].freeze

  SAFETY_CHECKLIST = [
    bi("تأكد من سلامة الهيكل وعدم وجود تلف ظاهر.", "Check the structure for any visible damage."),
    bi("افحص نقاط التثبيت والأجزاء المتحركة.", "Inspect fixing points and moving parts."),
    bi("تحقق من ثبات القواعد والأجزاء الملامسة للأرض.", "Check the stability of the base and all parts in contact with the ground."),
    bi("تأكد من عمل آليات القفل والتثبيت في المنتجات المزودة بها.", "Make sure locking and securing mechanisms are functioning properly where applicable."),
    bi("لا تستخدم المنتج عند ملاحظة تلف أو جزء غير ثابت.", "Do not use the product if you notice damage or loose components.")
  ].freeze

  SAFETY_USE = [
    [ bi("استخدم المنتج على سطح مناسب", "Use on a Suitable Surface"),                bi("تأكد من ثبات المنتج واستقراره في موقع الاستخدام.", "Make sure the product is stable and properly positioned at the worksite.") ],
    [ bi("التزم بالحمولة المحددة", "Follow the Specified Load Capacity"),            bi("لا تتجاوز الحمولة الموضحة في مواصفات المنتج.", "Do not exceed the load capacity stated in the product specifications.") ],
    [ bi("استخدم أوضاع التشغيل المخصصة", "Use Only the Intended Configurations"),   bi("في المنتجات متعددة الأوضاع، استخدم فقط الأوضاع المحددة للمنتج وتأكد من تثبيتها بالشكل الصحيح.", "For multi-position products, use only the configurations specified for the product and ensure they are properly secured.") ],
    [ bi("لا تستخدم منتجًا تالفًا", "Do Not Use Damaged Products"),                 bi("أوقف الاستخدام عند اكتشاف تلف أو خلل قد يؤثر على ثبات المنتج أو تشغيله.", "Stop using the product if you identify damage or a fault that may affect its stability or operation.") ]
  ].freeze

  # Safety articles (also surfaced under News & Articles).
  SAFETY = [
    { slug: "choose-right-product", name: bi("اختر المنتج وفق طبيعة العمل", "Choose the Product Based on the Task"), step: "01", summary: bi("تختلف المنتجات باختلاف الاستخدام والارتفاع المطلوب وبيئة العمل ومتطلبات التحمل. لذلك، تبدأ السلامة باختيار المنتج المناسب للمهمة ومراجعة مواصفاته قبل الاستخدام.", "Products vary depending on the application, required height, working environment, and load requirements. Safe use therefore begins with selecting the right product for the task and reviewing its specifications before use."), points: SAFETY_CHOOSE, products: [ "multi-position-ladder", "single-ladder", "extension-ladder" ] },
    { slug: "inspect-before-use",   name: bi("افحص المنتج قبل أن تبدأ", "Inspect the Product Before You Start"),   step: "02", summary: bi("يساعد الفحص البصري قبل كل استخدام على اكتشاف أي تلف أو مشكلة ظاهرة قد تؤثر على الاستخدام.", "A visual inspection before each use can help identify visible damage or issues that may affect safe operation."), checklist: SAFETY_CHECKLIST, products: [ "single-ladder", "aluminium-trolley", "tool-trolley" ] },
    { slug: "use-correctly",        name: bi("استخدم المنتج بالطريقة المخصصة له", "Use the Product as Intended"),   step: "03", summary: bi("لكل منتج طريقة استخدام ومواصفات يجب الالتزام بها. راجع دليل المنتج واتبع التعليمات الخاصة بالتركيب والتشغيل والحمولة قبل البدء.", "Each product has specific operating requirements and specifications that should be followed. Review the product guide and follow the relevant installation, operating, and load instructions before use."), points: SAFETY_USE, products: [ "multi-position-ladder", "extension-ladder", "flat-platform-trolley" ] }
  ].freeze

  GUIDE_DOCS = [ bi("دليل الاستخدام", "User Guide"), bi("دليل التركيب — عند توفره", "Installation Guide — When Available"), bi("تعليمات السلامة — عند توفرها", "Safety Instructions — When Available") ].freeze

  # ---------------------------------------------------------------------------
  # Original vs counterfeit
  # ---------------------------------------------------------------------------
  AUTHENTICITY_CHECKS = [
    [ bi("شعار مزايا", "Mazaya Branding"),                          bi("تحقق من وجود شعار مزايا ووضوح بيانات العلامة على المنتج أو العبوة.", "Check for the Mazaya logo and clear brand information on the product or packaging.") ],
    [ bi("بيانات المنتج", "Product Information"),                   bi("راجع اسم المنتج، الكود، والمعلومات المطبوعة على العبوة.", "Review the product name, code, and information printed on the packaging.") ],
    [ bi("جودة التصنيع والتشطيب", "Manufacturing & Finish Quality"), bi("انتبه إلى تفاصيل المنتج وجودة التشطيب والتجميع.", "Pay attention to the product's construction, finishing, and assembly details.") ],
    [ bi("مصدر الشراء", "Purchase Source"),                          bi("احرص على الحصول على منتجات مزايا من قنوات البيع والموزعين المعتمدين.", "Purchase Mazaya products through authorized sales channels and distributors.") ]
  ].freeze

  COMPARISON = [
    [ bi("مصدر وتصنيع معروفان", "Known manufacturing source and origin"),                                                          bi("قد يكون المصدر غير واضح", "Origin may be unclear") ],
    [ bi("بيانات ومواصفات واضحة للمنتج", "Clear product information and specifications"),                                        bi("قد تكون البيانات ناقصة أو غير دقيقة", "Information may be incomplete or inaccurate") ],
    [ bi("يخضع لمنظومة الجودة والاختبارات المعتمدة لدى مزايا", "Backed by Mazaya's established quality and testing processes"),   bi("لا يمكن التأكد من خضوعه للمعايير نفسها", "Compliance with the same standards cannot be verified") ],
    [ bi("جودة تصنيع وتشطيب يمكن التحقق منها", "Manufacturing and finishing quality that can be verified"),                      bi("قد تختلف جودة التصنيع والتشطيب", "Manufacturing and finishing quality may vary") ],
    [ bi("يمكن الرجوع إلى مزايا أو قنواتها المعتمدة بشأن المنتج", "Product information can be verified through Mazaya or its authorized channels"), bi("قد يصعب التحقق من مصدر المنتج أو الرجوع إلى جهة موثوقة", "Product origin or responsible supplier may be difficult to verify") ]
  ].freeze

  # ---------------------------------------------------------------------------
  # News & articles
  # ---------------------------------------------------------------------------
  TOPICS = {
    "news"      => bi("أخبار مزايا", "Mazaya News"),
    "products"  => bi("المنتجات والحلول", "Products & Solutions"),
    "safety"    => bi("السلامة والاستخدام", "Safety & Usage"),
    "quality"   => bi("الجودة والاختبارات", "Quality & Testing"),
    "projects"  => bi("حلول المشاريع", "Project Solutions"),
    "original"  => bi("الأصلي مقابل المقلد", "Original vs Counterfeit")
  }.freeze

  NEWS = [
    {
      slug: "four-million-ladders", type: :news, topic: "news", category: bi("أخبار الشركة", "Company News"), date: PENDING, featured: true, image: "/assets/hero.jpg",
      title: bi("4 ملايين سلم... محطة جديدة في مسيرة مزايا.", "4 Million Ladders — A New Milestone in Mazaya's Journey."),
      excerpt: bi("منذ انطلاقتها عام 1991، واصلت مزايا تطوير خبرتها ومنتجاتها لتصل اليوم إلى محطة جديدة بتجاوز 4 ملايين سلم تم تصنيعها خلال مسيرتها.", "Since 1991, Mazaya has continued to develop its expertise and products, reaching a new milestone with more than 4 million ladders manufactured throughout its journey."),
      body: [
        bi("منذ انطلاقتها عام 1991، واصلت مزايا تطوير خبرتها ومنتجاتها لتصل اليوم إلى محطة جديدة بتجاوز 4 ملايين سلم تم تصنيعها خلال مسيرتها.", "Since 1991, Mazaya has continued to develop its expertise and products, reaching a new milestone with more than 4 million ladders manufactured throughout its journey."),
        bi("بدأت رحلة مزايا عام 1991 في تصنيع منتجات الألومنيوم، ومع تطور احتياجات السوق توسع نطاق عملنا ليشمل مجموعة أكبر من المنتجات والحلول التي تخدم المشاريع والقطاعات المختلفة.", "Mazaya's journey began in 1991 with the manufacturing of aluminum products. As market needs evolved, our scope expanded to include a broader range of products and solutions serving different projects and sectors."),
        bi("واليوم، تجمع مزايا بين المنتجات القياسية الجاهزة والحلول المخصصة، بما يتيح لنا التعامل مع متطلبات متنوعة من حيث التصميم والمقاسات والمواصفات وطبيعة الاستخدام.", "Today, Mazaya combines standard ready-made products with custom solutions, allowing us to address diverse requirements in design, dimensions, specifications, and applications.")
      ],
      related_products: [ "multi-position-ladder", "single-ladder", "extension-ladder" ]
    }
  ].freeze

  ARTICLES = [
    { slug: "how-to-choose-a-ladder", type: :article, topic: "products", category: bi("السلالم وحلول الوصول", "Ladders & Access Solutions"), date: PENDING, image: "/assets/cat-ladders.jpg",
      title: bi("كيف تختار السلم المناسب لطبيعة عملك؟", "How to Choose the Right Ladder for the Job"),
      excerpt: bi("تعرف على أهم العوامل التي يجب مراعاتها عند اختيار السلم، من طبيعة المهمة والارتفاع المطلوب إلى بيئة العمل والحمولة.", "Explore the key factors to consider when choosing a ladder, from the type of task and required height to the working environment and load capacity."),
      body: [ bi("تختلف المنتجات باختلاف الاستخدام والارتفاع المطلوب وبيئة العمل ومتطلبات التحمل. لذلك، تبدأ السلامة باختيار المنتج المناسب للمهمة ومراجعة مواصفاته قبل الاستخدام.", "Products vary depending on the application, required height, working environment, and load requirements. Safe use therefore begins with selecting the right product for the task and reviewing its specifications before use.") ],
      points: SAFETY_CHOOSE, related_products: [ "multi-position-ladder", "single-ladder", "extension-ladder" ], related_safety: "choose-right-product" }
  ].freeze
end
