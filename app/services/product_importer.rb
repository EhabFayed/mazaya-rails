# frozen_string_literal: true

require "csv"

# Bulk upsert of products from an Excel (.xlsx/.xls/.ods via roo) or CSV sheet.
# Header row may use the English keys below or their Arabic labels.
# Products are matched by `code` (or by name_ar when the code is blank);
# categories/subcategories are found by name_ar or created (slug from name_en).
class ProductImporter
  class Error < StandardError; end

  Result = Struct.new(:created, :updated, :skipped, :errors, :dry_run, :total) do
    def ok? = errors.empty?
  end

  SPEC_COUNT = 8
  BASE_HEADERS = %w[category_ar category_en subcategory_ar subcategory_en code name_ar name_en summary_ar summary_en kind popular].freeze
  SPEC_HEADERS = (1..SPEC_COUNT).flat_map { |i| %w[label_ar label_en value_ar value_en].map { |s| "spec_#{i}_#{s}" } }.freeze
  HEADERS = (BASE_HEADERS + SPEC_HEADERS).freeze

  ARABIC_HEADERS = {
    "الفئة" => "category_ar", "الفئة (إنجليزي)" => "category_en",
    "الفئة الفرعية" => "subcategory_ar", "الفئة الفرعية (إنجليزي)" => "subcategory_en",
    "الكود" => "code", "الاسم" => "name_ar", "الاسم (إنجليزي)" => "name_en",
    "الوصف" => "summary_ar", "الوصف (إنجليزي)" => "summary_en", "النوع" => "kind", "مميز" => "popular", "الأكثر طلبًا" => "popular"
  }.freeze
  # "مواصفة 1" / "مواصفة 1 (إنجليزي)" / "قيمة 1" / "قيمة 1 (إنجليزي)"
  ARABIC_SPEC = /\A(مواصفة|قيمة)\s*(\d)\s*(\(?(?:إنجليزي|en)\)?)?\z/

  CUSTOM_WORDS = %w[custom مخصص حسب\ الطلب حسب-الطلب].freeze
  READY_WORDS  = %w[ready جاهز].freeze
  YES_WORDS    = %w[yes y true 1 نعم ✓].freeze
  NO_WORDS     = %w[no n false 0 لا].freeze

  def self.template_csv
    "\uFEFF" + CSV.generate { |csv| csv << HEADERS }
  end

  def initialize(path, filename: nil, dry_run: false)
    @path     = path.to_s
    @filename = (filename || path).to_s
    @dry_run  = dry_run
  end

  def run
    result = Result.new(0, 0, 0, [], @dry_run, 0)
    rows = read_rows
    ActiveRecord::Base.transaction do
      rows.each_with_index do |row, i|
        result.total += 1
        import_row(row, i + 2, result)
      end
      raise ActiveRecord::Rollback if @dry_run
    end
    result
  end

  # ---- parsing -------------------------------------------------------------

  def read_rows
    raw = extension.in?(%w[csv txt]) ? read_csv : read_sheet
    raise Error, "الملف فارغ." if raw.empty?
    headers = raw.shift.map { |h| normalize_header(h) }
    raise Error, "لم يتم العثور على عمود «name_ar / الاسم» في صف العناوين." unless headers.include?("name_ar")
    raw.filter_map do |cells|
      next if cells.all? { |c| cell_to_s(c).blank? }
      headers.each_with_index.with_object({}) { |(h, i), acc| acc[h] = cell_to_s(cells[i]) if h }
    end
  end

  def extension = File.extname(@filename).delete(".").downcase

  def read_csv
    CSV.read(@path, encoding: "bom|utf-8")
  rescue CSV::MalformedCSVError, ArgumentError => e
    raise Error, "تعذّر قراءة ملف CSV: #{e.message}"
  end

  def read_sheet
    book = Roo::Spreadsheet.open(@path, extension: extension.presence || "xlsx")
    sheet = book.sheet(0)
    return [] unless sheet.first_row
    (sheet.first_row..sheet.last_row).map { |r| sheet.row(r) }
  rescue Zip::Error, IOError, ArgumentError, Roo::Error => e
    raise Error, "تعذّر قراءة ملف Excel: #{e.message}"
  end

  def normalize_header(h)
    s = h.to_s.strip
    return nil if s.blank?
    en = s.downcase.tr(" -", "__").gsub(/_+/, "_")
    return en if HEADERS.include?(en)
    return ARABIC_HEADERS[s] if ARABIC_HEADERS.key?(s)
    if (m = s.match(ARABIC_SPEC))
      kind = m[1] == "مواصفة" ? "label" : "value"
      return "spec_#{m[2]}_#{kind}_#{m[3] ? 'en' : 'ar'}"
    end
    nil
  end

  def cell_to_s(c)
    case c
    when nil then ""
    when Float then (c == c.to_i ? c.to_i : c).to_s
    when Date, Time, DateTime then c.to_s
    else c.to_s.strip
    end
  end

  # ---- upsert --------------------------------------------------------------

  def import_row(r, n, result)
    if r["name_ar"].blank?
      return skip(result, n, "الاسم العربي مطلوب")
    elsif r["category_ar"].blank?
      return skip(result, n, "الفئة مطلوبة")
    end

    category = find_or_create_category(r)
    return skip(result, n, "الفئة: #{category.errors.full_messages.join('، ')}") unless category.persisted?
    sub = nil
    if r["subcategory_ar"].present?
      sub = find_or_create_subcategory(category, r)
      return skip(result, n, "الفئة الفرعية: #{sub.errors.full_messages.join('، ')}") unless sub.persisted?
    end

    product = r["code"].present? ? Product.find_by(code: r["code"]) : Product.where(code: [ nil, "" ]).find_by(name_ar: r["name_ar"])
    action  = product ? :updated : :created
    product ||= Product.new(code: r["code"].presence)

    product.category = category
    product.subcategory = sub
    product.name_ar = r["name_ar"]
    %w[name_en summary_ar summary_en].each { |k| product[k] = r[k] if r[k].present? }
    product.code = r["code"] if r["code"].present?
    kind = parse_kind(r["kind"])
    product.kind = kind if kind
    popular = parse_bool(r["popular"])
    product.popular = popular unless popular.nil?
    specs = build_specs(r)
    product.specs = specs if specs.any?

    if product.save
      result[action] += 1
    else
      skip(result, n, product.errors.full_messages.join("، "))
    end
  end

  def skip(result, n, message)
    result.skipped += 1
    result.errors << [ n, message ]
  end

  def find_or_create_category(r)
    Category.find_by(name_ar: r["category_ar"]) || Category.create(name_ar: r["category_ar"], name_en: r["category_en"].presence, slug: slug_for(r["category_en"]), position: Category.maximum(:position).to_i + 1)
  end

  def find_or_create_subcategory(category, r)
    category.subcategories.find_by(name_ar: r["subcategory_ar"]) ||
      category.subcategories.create(name_ar: r["subcategory_ar"], name_en: r["subcategory_en"].presence, slug: slug_for(r["subcategory_en"]), position: category.subcategories.maximum(:position).to_i + 1)
  end

  def slug_for(name_en) = name_en.to_s.parameterize.presence

  def parse_kind(v)
    s = v.to_s.strip.downcase
    return nil if s.blank?
    return "custom" if CUSTOM_WORDS.include?(s)
    return "ready"  if READY_WORDS.include?(s)
    nil
  end

  def parse_bool(v)
    s = v.to_s.strip.downcase
    return true  if YES_WORDS.include?(s)
    return false if NO_WORDS.include?(s)
    nil
  end

  def build_specs(r)
    (1..SPEC_COUNT).filter_map do |i|
      row = { "label_ar" => r["spec_#{i}_label_ar"], "label_en" => r["spec_#{i}_label_en"], "value_ar" => r["spec_#{i}_value_ar"], "value_en" => r["spec_#{i}_value_en"] }.compact_blank
      next if row["label_ar"].blank? && row["label_en"].blank?
      row
    end
  end
end
