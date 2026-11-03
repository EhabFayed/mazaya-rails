# Imports SiteData::Defaults (the client copy deck + prototypes) into the
# admin-managed tables. Idempotent: existing rows (matched by slug/key) are
# left untouched so admin edits survive re-seeding.
D = SiteData::Defaults

def ar(v) = v.is_a?(Bilingual) ? v.ar : v.to_s
def en(v) = v.is_a?(Bilingual) ? v.en : v.to_s
def pair_rows(list) = list.map { |t, d| { "title_ar" => ar(t), "title_en" => en(t), "desc_ar" => ar(d), "desc_en" => en(d) } }

puts "== Settings"
setting = Setting.first || Setting.create!
setting.update!(whatsapp_display: setting.whatsapp_display.presence || D::WHATSAPP_DISPLAY, founded: setting.founded || D::FOUNDED)

puts "== Lists"
lists = {
  "stats"               => D::STATS.map { |s| { "value" => s[:value], "suffix" => s[:suffix], "label_ar" => ar(s[:label]), "label_en" => en(s[:label]), "sub_ar" => ar(s[:sub]), "sub_en" => en(s[:sub]) } },
  "partner_stats"       => D::PARTNER_STATS.map { |s| { "value" => s[:value], "suffix" => s[:suffix], "label_ar" => ar(s[:label]), "label_en" => en(s[:label]), "sub_ar" => ar(s[:sub]), "sub_en" => en(s[:sub]) } },
  "social"              => D::SOCIAL.map { |s| { "key" => s[:key], "label_ar" => ar(s[:label]), "label_en" => en(s[:label]), "url" => s[:url], "abbr" => s[:abbr] } },
  "inquiry_types"       => D::INQUIRY_TYPES.map { |v| { "ar" => ar(v), "en" => en(v) } },
  "org_types"           => D::ORG_TYPES.map { |k, v| { "key" => k, "ar" => ar(v), "en" => en(v) } },
  "custom_features"     => pair_rows(D::CUSTOM_FEATURES),
  "custom_steps"        => pair_rows(D::CUSTOM_STEPS),
  "certifications"      => D::CERTIFICATIONS.map { |c| { "key" => c[:key], "title_ar" => ar(c[:name]), "title_en" => en(c[:name]), "desc_ar" => ar(c[:desc]), "desc_en" => en(c[:desc]), "cta_ar" => ar(c[:cta]), "cta_en" => en(c[:cta]) } },
  "quality_steps"       => pair_rows(D::QUALITY_STEPS),
  "safety_choose"       => pair_rows(D::SAFETY_CHOOSE),
  "safety_checklist"    => D::SAFETY_CHECKLIST.map { |v| { "text_ar" => ar(v), "text_en" => en(v) } },
  "safety_use"          => pair_rows(D::SAFETY_USE),
  "authenticity_checks" => pair_rows(D::AUTHENTICITY_CHECKS),
  "comparison"          => D::COMPARISON.map { |o, c| { "original_ar" => ar(o), "original_en" => en(o), "counterfeit_ar" => ar(c), "counterfeit_en" => en(c) } },
  "topics"              => D::TOPICS.map { |k, v| { "key" => k, "ar" => ar(v), "en" => en(v) } },
  "guide_docs"          => D::GUIDE_DOCS.map { |v| { "ar" => ar(v), "en" => en(v) } },
  "project_fields"      => D::PROJECT_FIELDS.map { |v| { "ar" => ar(v), "en" => en(v) } }
}
lists.each { |key, items| ContentList.find_or_create_by!(key: key) { |l| l.items = items } }

puts "== Clients / departments"
D::CLIENTS.each_with_index do |c, i|
  Client.find_or_create_by!(name_ar: ar(c[:name])) do |cl|
    cl.name_en = en(c[:name]); cl.bg = c[:bg]; cl.position = i
    path = Rails.root.join("public#{c[:logo]}")
    cl.logo.attach(io: File.open(path), filename: File.basename(path)) if File.exist?(path)
  end
end
D::DEPARTMENTS.each_with_index { |d, i| Department.find_or_create_by!(key: d[:key]) { |x| x.name_ar = ar(d[:name]); x.name_en = en(d[:name]); x.desc_ar = ar(d[:desc]); x.desc_en = en(d[:desc]); x.position = i } }

puts "== Documents"
D::DOWNLOADS.each_with_index do |(key, d), i|
  Document.find_or_create_by!(key: key) do |doc|
    doc.title_ar = ar(d[:title]); doc.title_en = en(d[:title]); doc.gated = d[:gated]; doc.position = i
    doc.doc_type = case key
    when /\Acatalog-/ then "catalog"
    when "technical-catalog" then "technical"
    when "company-profile" then "profile"
    when "tds" then "tds"
    when "user-guide" then "guide"
    else "catalog"
    end
  end
end
[ [ "cert-iso", "ISO", "ISO", "certificate", "عرض الشهادة", "View Certificate" ], [ "cert-saso", "SASO", "SASO", "certificate", "عرض الاعتماد", "View Approval" ],
  [ "report-load", "تقارير اختبارات الأحمال", "Load Testing Reports", "report", "عرض التقارير", "View Reports" ], [ "report-tests", "تقارير الاختبار", "Test Reports", "report", "عرض التقارير", "View Reports" ],
  [ "cert-quality", "شهادات الجودة", "Quality Certificates", "certificate", "عرض الشهادات", "View Certificates" ], [ "cert-safety", "شهادات السلامة", "Safety Certificates", "certificate", "عرض الشهادات", "View Certificates" ] ].each_with_index do |(key, t_ar, t_en, type, c_ar, c_en), i|
  Document.find_or_create_by!(key: key) { |doc| doc.title_ar = t_ar; doc.title_en = t_en; doc.doc_type = type; doc.cta_ar = c_ar; doc.cta_en = c_en; doc.gated = false; doc.position = 20 + i }
end

puts "== Categories / products"
D::CATEGORIES.each_with_index do |c, i|
  cat = Category.find_or_create_by!(slug: c[:slug]) do |x|
    x.name_ar = ar(c[:name]); x.name_en = en(c[:name]); x.desc_ar = ar(c[:desc]); x.desc_en = en(c[:desc])
    x.b2c_ar = ar(c[:b2c]); x.b2c_en = en(c[:b2c]); x.b2b_ar = ar(c[:b2b]); x.b2b_en = en(c[:b2b]); x.about_ar = ar(c[:about]); x.about_en = en(c[:about])
    x.finder_ar = ar(c[:finder]); x.finder_en = en(c[:finder]); x.catalog_key = c[:catalog]; x.position = i
    x.spec_labels = c[:specs].map { |s| { "label_ar" => ar(s), "label_en" => en(s) } }
    path = Rails.root.join("public#{c[:image]}")
    x.image.attach(io: File.open(path), filename: File.basename(path)) if File.exist?(path)
  end
  c[:subcategories].each_with_index { |s, j| cat.subcategories.find_or_create_by!(slug: s[:slug]) { |x| x.name_ar = ar(s[:name]); x.name_en = en(s[:name]); x.position = j } }
end

D::PRODUCTS.each_with_index do |p, i|
  next if Product.exists?(slug: p[:slug])
  cat = Category.find_by!(slug: p[:category])
  prod = Product.new(
    slug: p[:slug], code: p[:code], category: cat, subcategory: cat.subcategories.find_by(slug: p[:subcategory]),
    name_ar: ar(p[:name]), name_en: en(p[:name]), summary_ar: ar(p[:summary]), summary_en: en(p[:summary]),
    kind: p[:kind].to_s, popular: p[:popular], position: i, safety_slug: p[:safety], related_slugs: p[:related] || [],
    features: pair_rows(p[:features] || []), applications: pair_rows(p[:applications] || []),
    specs: (p[:specs] || []).map { |l, v| { "label_ar" => ar(l), "label_en" => en(l), "value_ar" => ar(v), "value_en" => en(v) } },
    size_cols: (p[:size_cols] || []).map { |c| { "col_ar" => ar(c), "col_en" => en(c) } },
    faq: (p[:faq] || []).map { |q, a| { "q_ar" => ar(q), "q_en" => en(q), "a_ar" => ar(a), "a_en" => en(a) } }
  )
  labels = {}
  (p[:images] || []).each do |img|
    path = Rails.root.join("public#{img[:src]}")
    next unless File.exist?(path)
    prod.images.attach(io: File.open(path), filename: File.basename(path))
    labels[File.basename(path)] = { "label_ar" => ar(img[:label]), "label_en" => en(img[:label]) }
  end
  prod.save!
  prod.images.each { |a| prod.image_labels[a.blob.id.to_s] = labels[a.blob.filename.to_s] if labels[a.blob.filename.to_s] }
  prod.save! if labels.any?
end

puts "== Solutions / projects"
D::SOLUTIONS.each_with_index do |s, i|
  Solution.find_or_create_by!(slug: s[:slug]) do |x|
    x.name_ar = ar(s[:name]); x.name_en = en(s[:name]); x.category = Category.find_by(slug: s[:category]); x.position = i
    path = Rails.root.join("public#{s[:image]}"); x.image.attach(io: File.open(path), filename: File.basename(path)) if File.exist?(path)
  end
end
D::PROJECTS.each_with_index do |p, i|
  pr = Project.find_or_create_by!(slug: p[:slug]) do |x|
    x.name_ar = ar(p[:name]); x.name_en = en(p[:name]); x.featured = p[:featured]; x.position = i
    path = Rails.root.join("public#{p[:image]}"); x.image.attach(io: File.open(path), filename: File.basename(path)) if File.exist?(path)
  end
  pr.solutions = Solution.where(slug: p[:products]) if pr.solutions.empty?
end

puts "== Safety / posts"
D::SAFETY.each_with_index do |a, i|
  SafetyArticle.find_or_create_by!(slug: a[:slug]) do |x|
    x.name_ar = ar(a[:name]); x.name_en = en(a[:name]); x.summary_ar = ar(a[:summary]); x.summary_en = en(a[:summary]); x.position = i
    x.points = pair_rows(a[:points] || []); x.checklist = (a[:checklist] || []).map { |v| { "text_ar" => ar(v), "text_en" => en(v) } }; x.related_slugs = a[:products]
  end
end
(D::NEWS + D::ARTICLES).each_with_index do |n, i|
  Post.find_or_create_by!(slug: n[:slug]) do |x|
    x.post_type = n[:type].to_s; x.topic = n[:topic]; x.category_ar = ar(n[:category]); x.category_en = en(n[:category])
    x.title_ar = ar(n[:title]); x.title_en = en(n[:title]); x.excerpt_ar = ar(n[:excerpt]); x.excerpt_en = en(n[:excerpt])
    x.body_ar = n[:body].map { |b| ar(b) }.join("\n\n"); x.body_en = n[:body].map { |b| en(b) }.join("\n\n")
    x.featured = n[:featured] || false; x.template = n[:template] || false; x.position = i
    x.points = pair_rows(n[:points] || []); x.checklist = (n[:checklist] || []).map { |v| { "text_ar" => ar(v), "text_en" => en(v) } }
    x.related_slugs = n[:related_products] || []; x.related_safety_slug = n[:related_safety]
    path = Rails.root.join("public#{n[:image]}"); x.image.attach(io: File.open(path), filename: File.basename(path)) if n[:image] && File.exist?(path)
  end
end

puts "== Client product sheet"
if File.exist?(MazayaSheetImport::DEFAULT_PATH)
  MazayaSheetImport.run # idempotent; replaces the prototype placeholders above with the real catalog
else
  puts "   db/data/mazaya_products.xlsx not found — keeping prototype products"
end

puts "== Admin user"
if User.none?
  email = ENV.fetch("ADMIN_EMAIL", "admin@mazaya.local")
  password = ENV.fetch("ADMIN_PASSWORD", "mazaya-admin-2026")
  User.create!(name: "Admin", email: email, password: password, role: "admin")
  puts "   created #{email} / #{password}  (change it from /admin/users)"
end

Setting.bump_content_version!
puts "== Done"
