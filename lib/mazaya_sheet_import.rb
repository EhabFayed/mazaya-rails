# frozen_string_literal: true

require "roo"
require "zip"
require "nokogiri"

# Imports the client's product identity sheet (بطاقة تعريف المنتجات), shipped
# in the repo as db/data/mazaya_products.xlsx, into the products table.
#
# The sheet does not fit ProductImporter's generic template: the header row is
# row 3, the labels differ, there is no category column, most names are English
# only, and each row carries an embedded photo in column A. Category, subcategory
# and Arabic/English names come from the META table below, keyed by product code.
#
# Idempotent: products are matched by code, then by the slug a seeded placeholder
# already owns (e.g. "single-ladder"), otherwise created. Seeded placeholders from
# SiteData::Defaults that no sheet row claims are unpublished (not deleted).
#
#   bin/rails products:import_sheet                   # default file, saves
#   DRY_RUN=1 bin/rails products:import_sheet         # validate only
#   bin/rails "products:import_sheet[/path/to.xlsx]"  # another file
#
# db:seed runs this automatically when the default file exists.
class MazayaSheetImport
  DEFAULT_PATH = Rails.root.join("db/data/mazaya_products.xlsx")
  HEADER_ROW   = 3
  COLS         = %i[image code name desc uses features materials safety audience howto sizes warranty sales].freeze

  Result = Struct.new(:rows, :images, :created, :updated, :hidden, :errors, :dry_run) do
    def ok? = errors.empty?
  end

  # code => [name_ar, name_en, category_slug, subcategory_slug, popular]
  META = {
    "AMF-RMP"       => [ "منحدر ألمنيوم",                     "Aluminum Ramp",                      "ladders",   nil,           true  ],
    "MSFL-SWIP"     => [ "سقالة ألمنيوم متحركة",              "Mobile Aluminum Scaffolding",        "ladders",   nil,           false ],
    "CLO-GAL"       => [ "عربة حاوية شبكية متحركة",           "Roll Container",                     "trolleys",  nil,           false ],
    "31024"         => [ "عربة أدوات",                        "Tools Trolley",                      "trolleys",  "tools",       false ],
    "PHT-001-P"     => [ "عربة منصة مسطحة",                   "Flatbed Trolley",                    "trolleys",  "platform",    true  ],
    "MDL-000"       => [ "سلم مزايا المزدوج",                 "Mazaya Ladder",                      "ladders",   nil,           false ],
    "DRG-000"       => [ "قناة تصريف ألمنيوم",                "Linear Drainage Channel",            "flooring",  "channels",    true  ],
    "ELD-000"       => [ "سلم مفرد",                          "Single Ladder",                      "ladders",   "single",      true  ],
    "SLD-000"       => [ "سلم قابل للتمديد",                  "Extension Ladder",                   "ladders",   "extension",   false ],
    "MLM-000"       => [ "سلم صيانة",                         "Maintenance Ladder",                 "ladders",   nil,           false ],
    "31025"         => [ "عربة منصة مسطحة بقاعدة خشبية",      "Flatbed Trolley with Wooden Base",   "trolleys",  "platform",    false ],
    "ATL-001"       => [ "عربة متعددة الاستخدامات",           "Multi-Function Trolley",             "trolleys",  nil,           false ],
    "WHL-ALU-000"   => [ "سلم مستودعات",                      "Warehouse Ladder",                   "ladders",   nil,           false ],
    "DRG-000-FSH"   => [ "قناة تصريف بنمط حراشف السمك",       "Fish-Scale Drainage Channel",        "flooring",  "channels",    false ],
    "MAF-PTL-000"   => [ "سلم النخيل",                        "Palm Tree Ladder",                   "ladders",   "single",      false ],
    "DRG-003-0-CIR" => [ "قناة تصريف ستانلس ستيل",            "Stainless Steel Drainage Channel",   "flooring",  "channels",    false ],
    "MRH-001"       => [ "فتحة صيانة للأسطح",                 "Roof Hatch",                         "covers",    "maintenance", false ],
    "ACP-GYP-CURVE" => [ "فتحة وصول منحنية",                  "Curved Access Panel",                "covers",    "access",      false ],
    "MML-000"       => [ "سلم متعدد الأوضاع",                 "Multi-Position Ladder",              "ladders",   "multi",       true  ],
    "FSC-TO3-WHI"   => [ "قاعدة متحركة للثلاجة",              "Refrigerator Movable Stand",         "trolleys",  nil,           false ],
    "DRG-LEF-000"   => [ "قناة تصريف بنمط أوراق الشجر",       "Leaf-Pattern Drainage Channel",      "flooring",  "channels",    false ],
    "WST-000"       => [ "مصد أبواب بشريط عازل",              "Weather Strips",                     "aluminium", nil,           false ],
    "MHC-000"       => [ "غطاء منهل",                         "Manhole Cover",                      "covers",    "manhole",     true  ],
    "HLD-000"       => [ "سلم منزلي",                         "Home Ladder",                        "ladders",   nil,           false ],
    "TTRO4-000"     => [ "عربة نقل مسطحة",                    "Flatbed Transportation Trolley",     "trolleys",  "platform",    false ],
    "TS WO3-000"    => [ "عربة قفصية (كيج باليت)",            "Cage Pallet",                        "trolleys",  nil,           false ],
    "ACP-20"        => [ "فتحة وصول (جاكوزي)",                "Access Panel (Jacuzzi)",             "covers",    "access",      false ]
  }.freeze

  def self.run(path = DEFAULT_PATH, dry_run: false, out: $stdout) = new(path, dry_run: dry_run, out: out).run

  def initialize(path = DEFAULT_PATH, dry_run: false, out: $stdout)
    @path    = path.to_s
    @dry_run = dry_run
    @out     = out
  end

  def run
    rows   = read_rows
    result = Result.new(rows.size, rows.count { |r| r[:image] }, 0, 0, 0, [], @dry_run)
    log "#{result.rows} product rows, #{result.images} embedded images#{@dry_run ? ' (DRY RUN)' : ''}"

    ActiveRecord::Base.transaction do
      touched = rows.each_with_index.filter_map { |r, i| import_row(r, i, result) }
      result.hidden = hide_placeholders(touched)
      log "created=#{result.created} updated=#{result.updated} hidden_placeholders=#{result.hidden} errors=#{result.errors.size}"
      result.errors.each { |n, m| log "  row #{n}: #{m}" }
      raise ActiveRecord::Rollback if @dry_run || result.errors.any?
    end

    Setting.bump_content_version! if result.ok? && !@dry_run
    result
  end

  private

  def log(msg) = @out&.puts(msg)

  # ---- reading -------------------------------------------------------------

  def read_rows
    raise ArgumentError, "sheet not found: #{@path}" unless File.exist?(@path)
    sheet  = Roo::Spreadsheet.open(@path, extension: "xlsx").sheet(0)
    images = images_by_row
    ((HEADER_ROW + 1)..sheet.last_row).filter_map do |r|
      vals = COLS.each_with_index.to_h { |k, i| [ k, cell(sheet.cell(r, i + 1)) ] }
      next if vals[:code].blank? && vals[:name].blank?
      vals.merge(row: r, image: images[r])
    end
  end

  def cell(v)
    case v
    when nil then ""
    when Float then (v == v.to_i ? v.to_i : v).to_s
    else v.to_s.strip
    end
  end

  # Embedded pictures: drawing anchors give the 0-based row, rels give the media file.
  def images_by_row
    out = {}
    Zip::File.open(@path) do |zip|
      drawing = zip.find_entry("xl/drawings/drawing1.xml") or return out
      targets = {}
      if (rels = zip.find_entry("xl/drawings/_rels/drawing1.xml.rels"))
        Nokogiri::XML(rels.get_input_stream.read).remove_namespaces!.xpath("//Relationship").each do |rel|
          targets[rel["Id"]] = "xl/" + rel["Target"].sub(%r{\A\.\./}, "")
        end
      end
      doc = Nokogiri::XML(drawing.get_input_stream.read).remove_namespaces!
      doc.xpath("//twoCellAnchor | //oneCellAnchor").each do |anchor|
        row   = anchor.at_xpath("./from/row")&.text.to_i + 1 # 1-based sheet row
        embed = anchor.at_xpath(".//blip")&.[]("embed")
        next unless embed && targets[embed]
        entry = zip.find_entry(targets[embed]) or next
        out[row] = [ File.basename(targets[embed]), entry.get_input_stream.read ]
      end
    end
    out
  end

  # ---- mapping -------------------------------------------------------------

  # "a، b، c." -> list rows; the sheet gives one free-text list per cell.
  def list_rows(text)
    text.to_s.sub(/\.\s*\z/, "").split(/[،,؛;]\s*|\n+/).map(&:strip).reject(&:blank?)
        .map { |t| { "title_ar" => t.sub(/\.\z/, ""), "title_en" => "", "desc_ar" => "", "desc_en" => "" } }
  end

  def custom?(sizes) = sizes.to_s.match?(/حسب\s*(طلب|الطلب)/)

  def specs_for(r)
    [ [ "الخامة", "Material", r[:materials] ], [ "المقاسات", "Sizes", r[:sizes] ], [ "الضمان", "Warranty", r[:warranty] ] ]
      .reject { |_, _, v| v.blank? }
      .map { |la, le, v| { "label_ar" => la, "label_en" => le, "value_ar" => v, "value_en" => "" } }
  end

  def faq_for(r)
    [ [ "لمن يناسب هذا المنتج؟",         "Who is this product for?",      r[:audience] ],
      [ "كيف يُستخدم أو يُركّب المنتج؟", "How is it used or installed?",  r[:howto] ],
      [ "ما خصائص السلامة في المنتج؟",   "What are its safety features?", r[:safety] ] ]
      .reject { |_, _, v| v.blank? }
      .map { |qa, qe, a| { "q_ar" => qa, "q_en" => qe, "a_ar" => a, "a_en" => "" } }
  end

  # ---- writing -------------------------------------------------------------

  def import_row(r, position, result)
    code = r[:code].sub(/\.0\z/, "")
    meta = META[code]
    return fail_row(result, r[:row], "no META mapping for code #{code.inspect} (#{r[:name]})") unless meta

    name_ar, name_en, cat_slug, sub_slug, popular = meta
    category = Category.find_by(slug: cat_slug)
    return fail_row(result, r[:row], "category #{cat_slug} missing (run db:seed first)") unless category
    sub  = sub_slug && category.subcategories.find_by(slug: sub_slug)
    slug = name_en.parameterize

    product = Product.find_by(code: code) || Product.where(code: [ nil, "" ]).find_by(slug: slug) || Product.new
    action  = product.new_record? ? :created : :updated

    product.assign_attributes(
      code: code, slug: slug, category: category, subcategory: sub,
      name_ar: name_ar, name_en: name_en, summary_ar: r[:desc], summary_en: nil,
      kind: custom?(r[:sizes]) ? "custom" : "ready",
      popular: popular, published: true, position: position,
      features: list_rows(r[:features]), applications: list_rows(r[:uses]),
      specs: specs_for(r), faq: faq_for(r)
    )
    return fail_row(result, r[:row], product.errors.full_messages.join("، ")) unless product.save

    attach_image(product, r[:image], slug) if r[:image] && !@dry_run && product.images.none?
    result[action] += 1
    product.id
  end

  def attach_image(product, (fname, bytes), slug)
    product.images.attach(
      io: StringIO.new(bytes), filename: "#{slug}#{File.extname(fname)}",
      content_type: Marcel::MimeType.for(StringIO.new(bytes), name: fname)
    )
  end

  def fail_row(result, n, message)
    result.errors << [ n, message ]
    nil
  end

  # Only the prototype placeholders from SiteData::Defaults are hidden; products
  # added later through the admin are never touched.
  def hide_placeholders(touched)
    slugs = SiteData::Defaults::PRODUCTS.map { |p| p[:slug] }
    Product.where(slug: slugs, published: true).where.not(id: touched).update_all(published: false)
  end
end
