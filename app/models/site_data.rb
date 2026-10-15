# frozen_string_literal: true

# Read-side facade for all site content. Views keep using the v1 constant
# API (SiteData::CATEGORIES, SiteData.product(slug), ...) while the data now
# comes from the admin-managed tables. `const_missing` resolves each constant
# from the database (cached per content version); when a table is empty the
# seed defaults in SiteData::Defaults are used instead.
module SiteData
  PENDING = nil

  DYNAMIC = %i[
    FOUNDED WHATSAPP_DISPLAY WHATSAPP_HREF EMAIL PHONE ADDRESS HOURS MAP_EMBED
    STATS PARTNER_STATS SOCIAL CLIENTS DEPARTMENTS INQUIRY_TYPES ORG_TYPES DOWNLOADS
    CATEGORIES PRODUCTS SOLUTIONS CUSTOM_FEATURES CUSTOM_STEPS PROJECTS PROJECT_FIELDS
    CERTIFICATIONS DOCUMENTS QUALITY_STEPS SAFETY_CHOOSE SAFETY_CHECKLIST SAFETY_USE SAFETY
    GUIDE_DOCS AUTHENTICITY_CHECKS COMPARISON TOPICS NEWS ARTICLES
  ].freeze

  def self.const_missing(name)
    return fetch(name) if DYNAMIC.include?(name)
    super
  end

  # Per-request memo -> cache store (keyed by content version) -> builder.
  def self.fetch(name)
    Current.site_data ||= {}
    Current.site_data[name] ||= begin
      version = Setting.table_exists? ? Setting.content_version : 0
      Rails.cache.fetch([ "site_data", name, version ], expires_in: 12.hours) { Builder.public_send(name.to_s.downcase) }
    end
  rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished
    Defaults.const_get(name)
  end

  def self.setting = (Setting.table_exists? && Setting.first) || nil

  # ---------------------------------------------------------------------------
  # Builders: DB records -> plain hashes shaped exactly like the v1 constants.
  # ---------------------------------------------------------------------------
  module Builder
    extend self
    U = Rails.application.routes.url_helpers

    def founded          = SiteData.setting&.founded || Defaults::FOUNDED
    def whatsapp_display = SiteData.setting&.whatsapp_display.presence || Defaults::WHATSAPP_DISPLAY
    def whatsapp_href    = SiteData.setting ? SiteData.setting.whatsapp_href : Defaults::WHATSAPP_HREF
    def email            = SiteData.setting&.email.presence
    def phone            = SiteData.setting&.phone.presence
    def address          = SiteData.setting&.address_ar.present? ? SiteData.setting.address : nil
    def hours            = SiteData.setting&.hours_ar.present? ? SiteData.setting.hours : nil
    def map_embed        = SiteData.setting&.map_embed.presence

    def stats         = list("stats", Defaults::STATS) { |r| { value: r["value"].to_i, suffix: r["suffix"].to_s, label: bi(r, "label"), sub: bi(r, "sub") } }
    def partner_stats = list("partner_stats", Defaults::PARTNER_STATS) { |r| { value: r["value"].to_i, suffix: r["suffix"].to_s, label: bi(r, "label"), sub: bi(r, "sub") } }
    def social        = list("social", Defaults::SOCIAL) { |r| { key: r["key"], label: bi(r, "label"), url: r["url"].presence || "#", abbr: r["abbr"] } }
    def inquiry_types = list("inquiry_types", Defaults::INQUIRY_TYPES) { |r| bi(r, "x") }
    def org_types     = list("org_types", nil)&.to_h { |r| [ r["key"], bi(r, "x") ] } || Defaults::ORG_TYPES
    def custom_features = pairs("custom_features", Defaults::CUSTOM_FEATURES)
    def custom_steps    = pairs("custom_steps", Defaults::CUSTOM_STEPS)
    def quality_steps   = pairs("quality_steps", Defaults::QUALITY_STEPS)
    def safety_choose   = pairs("safety_choose", Defaults::SAFETY_CHOOSE)
    def safety_use      = pairs("safety_use", Defaults::SAFETY_USE)
    def authenticity_checks = pairs("authenticity_checks", Defaults::AUTHENTICITY_CHECKS)
    def safety_checklist = list("safety_checklist", Defaults::SAFETY_CHECKLIST) { |r| bi(r, "text") }
    def guide_docs       = list("guide_docs", Defaults::GUIDE_DOCS) { |r| bi(r, "x") }
    def project_fields   = list("project_fields", Defaults::PROJECT_FIELDS) { |r| bi(r, "x") }
    def comparison       = list("comparison", Defaults::COMPARISON) { |r| [ bi(r, "original"), bi(r, "counterfeit") ] }
    def certifications   = list("certifications", Defaults::CERTIFICATIONS) { |r| { key: r["key"], name: bi(r, "title"), desc: bi(r, "desc"), cta: bi(r, "cta") } }
    def topics           = list("topics", nil)&.to_h { |r| [ r["key"], bi(r, "x") ] } || Defaults::TOPICS

    def clients
      rows = Client.published.ordered.with_attached_logo.to_a
      return Defaults::CLIENTS if rows.empty?
      rows.map { |c| { name: c.name, logo: c.logo.attached? ? blob_path(c.logo) : Defaults::CLIENTS.dig(c.position, :logo).to_s, bg: c.bg } }
    end

    def departments
      rows = Department.ordered.to_a
      return Defaults::DEPARTMENTS if rows.empty?
      rows.map { |d| { key: d.key, name: d.name, desc: d.desc, phone: d.phone, email: d.email } }
    end

    def downloads
      rows = Document.published.ordered.with_attached_file.to_a
      return Defaults::DOWNLOADS if rows.empty?
      rows.to_h { |d| [ d.key, { title: d.title, desc: d.desc, file: d.file_path, gated: d.gated, version: d.version.presence, updated: d.version_date && I18n.l(d.version_date, format: :month), size: d.file.attached? ? ActiveSupport::NumberHelper.number_to_human_size(d.file.byte_size) : nil, doc_type: d.doc_type } ] }
    end

    def documents
      rows = Document.published.where(doc_type: %w[certificate report]).ordered.to_a
      return Defaults::DOCUMENTS if rows.empty?
      rows.map { |d| [ d.title, d.cta.presence || d.title ] }
    end

    def categories
      rows = Category.published.ordered.includes(:subcategories).with_attached_image.to_a
      return Defaults::CATEGORIES if rows.empty?
      rows.map do |c|
        dflt = Defaults::CATEGORIES.find { |d| d[:slug] == c.slug } || {}
        {
          slug: c.slug, name: c.name, en: Bilingual.new(c.name_en.presence || c.name_ar, c.name_ar),
          image: c.image.attached? ? image_path(c.image) : (dflt[:image] || "/assets/cat-custom.jpg"),
          catalog: c.catalog_key.presence || "catalog-#{c.slug}",
          desc: c.desc, b2c: c.b2c, b2b: c.b2b, about: c.about, finder: c.finder,
          specs: c.spec_labels_bi, subcategories: c.subcategories.map { |s| { slug: s.slug, name: s.name } }
        }
      end
    end

    def products
      rows = Product.published.ordered.includes(:category, :subcategory, images_attachments: :blob).to_a
      return Defaults::PRODUCTS if rows.empty?
      rows.map do |p|
        h = {
          slug: p.slug, code: p.code.presence, name: p.name, category: p.category.slug, subcategory: p.subcategory&.slug,
          kind: p.kind.to_sym, popular: p.popular, summary: p.summary, safety: p.safety_slug.presence, related: p.related_slugs
        }
        h[:images] = p.images.map { |img| { src: image_path(img), label: p.image_label(img.blob) } } if p.images.attached?
        h[:features] = p.features_bi if p.features.any?
        h[:applications] = p.applications_bi if p.applications.any?
        h[:specs] = p.specs_bi if p.specs.any?
        h[:size_cols] = p.size_cols_bi if p.size_cols.any?
        h[:sizes] = p.sizes if p.sizes.any?
        h[:faq] = p.faq_bi if p.faq.any?
        h[:tds] = blob_path(p.tds) if p.tds.attached?
        h[:guide] = blob_path(p.guide) if p.guide.attached?
        h
      end
    end

    def solutions
      rows = Solution.published.ordered.includes(:category, :projects).with_attached_image.to_a
      return Defaults::SOLUTIONS if rows.empty?
      rows.map do |s|
        dflt = Defaults::SOLUTIONS.find { |d| d[:slug] == s.slug } || {}
        { slug: s.slug, name: s.name, en: Bilingual.new(s.name_en.presence || s.name_ar, s.name_ar), desc: s.desc_ar.present? ? s.desc : nil,
          category: s.category&.slug, image: s.image.attached? ? image_path(s.image) : (dflt[:image] || "/assets/cat-custom.jpg"),
          projects: s.projects.map(&:slug) }
      end
    end

    def projects
      rows = Project.published.ordered.includes(:solutions).with_attached_image.with_attached_gallery.to_a
      return Defaults::PROJECTS if rows.empty?
      rows.map do |p|
        dflt = Defaults::PROJECTS.find { |d| d[:slug] == p.slug } || {}
        { slug: p.slug, name: p.name, en: Bilingual.new(p.name_en.presence || p.name_ar, p.name_ar), featured: p.featured,
          image: p.image.attached? ? image_path(p.image) : (dflt[:image] || "/assets/proj-tower.jpg"),
          products: p.solutions.map(&:slug), type: p.type_ar.present? ? p.type : nil,
          fields: [ p.product_supplied_ar.presence && p.product_supplied, p.scope_ar.presence && p.scope, p.quantity_ar.presence && p.quantity, p.year.presence ],
          requirements: p.requirements_ar.present? ? p.requirements : nil, solution: p.solution_ar.present? ? p.solution : nil,
          gallery: p.gallery.map { |g| image_path(g) } }
      end
    end

    def safety
      rows = SafetyArticle.published.ordered.to_a
      return Defaults::SAFETY if rows.empty?
      rows.each_with_index.map do |a, i|
        h = { slug: a.slug, name: a.name, step: format("%02d", i + 1), summary: a.summary, products: a.related_slugs }
        h[:points] = a.points_bi if a.points.any?
        h[:checklist] = a.checklist_bi if a.checklist.any?
        h
      end
    end

    def news     = posts_of("news", Defaults::NEWS)
    def articles = posts_of("article", Defaults::ARTICLES)

    private

    def posts_of(type, fallback)
      rows = Post.published.where(post_type: type).ordered.with_attached_image.to_a
      return fallback if rows.empty?
      rows.map do |n|
        h = { slug: n.slug, type: n.post_type.to_sym, topic: n.topic, category: n.category, date: n.published_on && I18n.l(n.published_on, format: :default),
              featured: n.featured, template: n.template, image: n.image.attached? ? image_path(n.image) : "/assets/hero.jpg",
              title: n.title, excerpt: n.excerpt, body: n.paragraphs.map { |t| Bilingual.new(t, t) }, related_products: n.related_slugs, related_safety: n.related_safety_slug.presence }
        h[:body] = n.body_ar.to_s.split(/\n{2,}/).zip(n.body_en.to_s.split(/\n{2,}/)).map { |ar, en| Bilingual.new(ar.to_s.strip, (en || ar).to_s.strip) }
        h[:points] = n.points_bi if n.points.any?
        h[:checklist] = n.checklist_bi if n.checklist.any?
        h
      end
    end

    def list(key, fallback)
      items = ContentList.table_exists? ? ContentList[key] : []
      return fallback if items.blank?
      block_given? ? items.map { |r| yield r.stringify_keys } : items
    end

    def pairs(key, fallback) = list(key, fallback) { |r| Localizable.pair(r) }
    def bi(row, base) = Localizable.bi(row, base)
    def blob_path(att) = U.rails_blob_path(att, only_path: true)

    def image_path(att)
      return blob_path(att) unless att.blob.image? && att.blob.variable?
      U.rails_representation_path(att.variant(resize_to_limit: [ 1600, 1600 ], saver: { quality: 82 }), only_path: true)
    end
  end

  # ===========================================================================
  # Lookups (same API as v1)
  # ===========================================================================
  module_function

  def category(slug)  = CATEGORIES.find { |c| c[:slug] == slug }
  def product(slug)   = PRODUCTS.find { |p| p[:slug] == slug }
  def solution(slug)  = SOLUTIONS.find { |s| s[:slug] == slug }
  def project(slug)   = PROJECTS.find { |p| p[:slug] == slug }
  def safety(slug)    = SAFETY.find { |a| a[:slug] == slug }
  def download(key)   = DOWNLOADS[key]
  def post(slug)      = posts.find { |n| n[:slug] == slug }
  def posts           = NEWS + ARTICLES
  def posts_in(topic) = topic.present? ? posts.select { |n| n[:topic] == topic } : posts

  def products_in(category_slug, subcategory: nil, kind: nil)
    list = PRODUCTS.select { |p| p[:category] == category_slug }
    list = list.select { |p| p[:subcategory] == subcategory } if subcategory.present?
    list = list.select { |p| p[:kind].to_s == kind.to_s } if kind.present?
    list
  end

  def popular_products  = PRODUCTS.select { |p| p[:popular] }
  def featured_projects = PROJECTS.select { |p| p[:featured] }
  def projects_for_solution(slug) = PROJECTS.select { |p| p[:products].include?(slug) }
  def solutions_for_project(project) = project[:products].filter_map { |s| solution(s) }
  def subcategory(category, slug) = category[:subcategories].find { |s| s[:slug] == slug }

  def kind_label(kind) = I18n.t(kind.to_sym == :ready ? "common.ready" : "common.custom")

  def search(query, prefix: "")
    q = query.to_s.strip
    return [] if q.length < 2
    norm = ->(s) { s.to_s.tr("أإآ", "ااا").tr("ة", "ه").tr("ى", "ي").downcase }
    nq = norm.call(q)
    hit = ->(*fields) { fields.flatten.compact.any? { |f| f.is_a?(Bilingual) ? [ f.ar, f.en ].any? { |v| norm.call(v).include?(nq) } : norm.call(f).include?(nq) } }
    out = []
    CATEGORIES.each { |c| out << { type: I18n.t("search.types.category"), title: c[:name], url: "#{prefix}/products/#{c[:slug]}", text: c[:b2c] } if hit.call(c[:name], c[:desc], c[:subcategories].map { |s| s[:name] }) }
    PRODUCTS.each   { |p| out << { type: I18n.t("search.types.product"), title: p[:name], url: "#{prefix}/products/#{p[:category]}/#{p[:slug]}", text: p[:summary] } if hit.call(p[:name], p[:summary], p[:code]) }
    SOLUTIONS.each  { |s| out << { type: I18n.t("search.types.solution"), title: s[:name], url: "#{prefix}/solutions/#{s[:slug]}", text: nil } if hit.call(s[:name]) }
    PROJECTS.each   { |p| out << { type: I18n.t("search.types.project"), title: p[:name], url: "#{prefix}/projects/#{p[:slug]}", text: p[:en] } if hit.call(p[:name]) }
    SAFETY.each     { |a| out << { type: I18n.t("search.types.safety"), title: a[:name], url: "#{prefix}/safety/#{a[:slug]}", text: a[:summary] } if hit.call(a[:name], a[:summary]) }
    posts.each      { |n| out << { type: I18n.t(n[:type] == :news ? "search.types.news" : "search.types.article"), title: n[:title], url: "#{prefix}/news/#{n[:slug]}", text: n[:excerpt] } if !n[:template] && hit.call(n[:title], n[:excerpt], n[:body]) }
    out
  end
end
