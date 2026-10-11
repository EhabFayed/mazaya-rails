# frozen_string_literal: true

# Flattens config/locales/{ar,en}.yml into dotted keys for the admin
# translations editor, and maps top-level keys to page labels.
module TranslationCatalog
  SKIP = %w[date time admin activerecord].freeze
  # Top-level scalars (brand, tagline) are shown under this page.
  ROOT_PAGE = "common"

  PAGES = {
    "home" => "الرئيسية", "b2b" => "حلول الأعمال", "solutions" => "الحلول المخصصة", "catalog" => "الكتالوج",
    "rfq" => "طلب عرض سعر", "partners" => "الشراكة", "b2c" => "المنتجات", "category" => "صفحة الفئة",
    "product" => "صفحة المنتج", "about" => "من نحن", "projects" => "المشاريع", "original" => "الأصلي والمقلد",
    "quality" => "الجودة", "safety" => "السلامة", "news" => "الأخبار", "contact" => "تواصل", "search" => "البحث",
    "nav" => "القائمة", "footer" => "الفوتر", "common" => "عام", "gate" => "نموذج التحميل"
  }.freeze

  module_function

  # { "home.hero.badge" => { "ar" => "...", "en" => "..." }, ... } (arrays => :array marker)
  def defaults
    @defaults ||= begin
      out = {}
      %w[ar en].each do |loc|
        yaml = YAML.load_file(Rails.root.join("config/locales/#{loc}.yml"))[loc] || {}
        flatten(yaml.except(*SKIP)).each { |k, v| (out[k] ||= {})[loc] = v }
      end
      out
    end
  end

  def reload! = (@defaults = nil)

  # Pages present in the YAML, in PAGES order (unknown top-level keys appended with the key as label).
  def pages
    present = defaults.keys.map { |k| page_of(k) }.uniq
    PAGES.select { |k, _| present.include?(k) }.merge(present.reject { |k| PAGES.key?(k) }.to_h { |k| [ k, k ] })
  end

  def page_of(key)
    key.include?(".") ? key.split(".").first : ROOT_PAGE
  end

  # Keys for one page (nil = every page), optionally filtered by a search term (key or ar/en text).
  def keys_for(page, q = nil)
    q = q.to_s.strip.downcase
    defaults.select do |k, v|
      (page.nil? || page_of(k) == page) && (q.blank? || k.downcase.include?(q) || v.values.any? { |t| t.is_a?(String) && t.downcase.include?(q) })
    end
  end

  def array?(key) = defaults.dig(key, "ar") == :array || defaults.dig(key, "en") == :array

  def flatten(hash, prefix = nil, out = {})
    hash.each do |k, v|
      key = [ prefix, k ].compact.join(".")
      case v
      when Hash  then flatten(v, key, out)
      when Array then out[key] = :array
      else out[key] = v.to_s
      end
    end
    out
  end
end
