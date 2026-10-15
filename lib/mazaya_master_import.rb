# frozen_string_literal: true

require "roo"
require "zip"
require "nokogiri"
require "image_processing/vips"

# Imports "Mazaya Catalogue Master.xlsx" (the client's central product database:
# one sheet per product family, one row per code, in-cell product photos).
#
#   bin/rails "products:import_master[/path/to/Mazaya Catalogue Master.xlsx]"
#   DRY_RUN=1 bin/rails "products:import_master[...]"
#
# Rows that share a product name within a sheet are size variants of one product:
# they become a single Product whose `sizes` table lists each code. Columns map to
# summary (overview), specs (material, model, load, finish, dimensions),
# applications, and images. Categories come from the sheet; subcategories are
# created under them by English name when missing.
#
# The sheet is English-first with Arabic product names only, while the site is
# Arabic-first and renders blank where Arabic is empty. Where no Arabic exists the
# English text is copied into the *_ar fields so nothing renders blank; those
# products are listed at the end so they can be translated in /admin/products.
#
# Every published product not produced by this file is unpublished (never deleted).
# Categories are never hidden: the B2B solutions pages look their category up by
# slug and 500 on an unpublished one (e.g. "aluminium" has solutions but no products).
# Idempotent: products are matched by slug; existing images are kept.
class MazayaMasterImport
  DEFAULT_PATH = Rails.root.join("db/data/mazaya_catalogue_master.xlsx")
  MAX_PX       = 1600

  Result = Struct.new(:rows, :products, :created, :updated, :hidden, :images, :errors, :dry_run, :untranslated) do
    def ok? = errors.empty?
  end

  # sheet name => [category_slug, overrides by the sheet's own "Category" cell]
  SHEETS = {
    "Industrial Ladder"         => "ladders",
    "Professional Duty Ladders" => "ladders",
    "Access & Covers"           => "covers",
    "Drainage"                  => "flooring",
    "ACCESS PRODUCTS"           => "covers",
    "Logistics Products"        => "trolleys",
    "FLOOR MAT"                 => "flooring"
  }.freeze
  CATEGORY_CELL = { "drainage" => "flooring", "access & covers" => "covers", "floor mats" => "flooring",
                    "logistics products" => "trolleys", "aluminum ladders" => "ladders", "ladders" => "ladders" }.freeze

  # Subcategory English name => [existing slug to reuse, Arabic name]
  SUBCATEGORIES = {
    "Platform Ladders"           => [ nil,        "سلالم منصة" ],
    "Double Platform Ladder"     => [ nil,        "سلالم منصة مزدوجة" ],
    "Double Platform Ladders"    => [ nil,        "سلالم منصة مزدوجة" ],
    "Mobile Platform Ladders"    => [ nil,        "سلالم منصة متحركة" ],
    "Mobile Access Platforms"    => [ nil,        "منصات وصول متحركة" ],
    "A-Frame / Double-Sided Ladder" => [ nil,     "سلالم مزدوجة الجانب" ],
    "Adjustable Ladders"         => [ nil,        "سلالم قابلة للتعديل" ],
    "Step Ladders"               => [ nil,        "سلالم درجات" ],
    "Mobile Platform Ladder"     => [ nil,        "سلالم منصة متحركة" ],
    "Fixed Ladders"              => [ nil,        "سلالم ثابتة" ],
    "Mobile Access Platform"     => [ nil,        "منصات وصول متحركة" ],
    "Industrial Platform Ladder" => [ nil,        "سلالم منصة صناعية" ],
    "Industrial Stairs"          => [ nil,        "درج صناعي" ],
    "Shelf Ladders"              => [ nil,        "سلالم رفوف" ],
    "Straight Ladder"            => [ nil,        "سلالم مستقيمة" ],
    "Wheeled Ladder"             => [ nil,        "سلالم بعجلات" ],
    "A-Frame / Double-Sided"     => [ nil,        "سلالم مزدوجة الجانب" ],
    "Work Ladder"                => [ nil,        "سلالم عمل" ],
    "Ladders"                    => [ "single",   nil ],
    "Manhole Covers"             => [ "manhole",  nil ],
    "Clean-Out Covers"           => [ nil,        "أغطية فتحات التنظيف" ],
    "Water Tank Covers"          => [ nil,        "أغطية خزانات المياه" ],
    "Floor Drain Recess"         => [ "drains",   nil ],
    "Drainage"                   => [ "channels", nil ],
    "Wall Access Panel"          => [ "access",   nil ],
    "Roof Access"                => [ "maintenance", nil ],
    "Ceiling Access Panel"       => [ nil,        "فتحات وصول سقفية" ],
    "Roll Cage"                  => [ nil,        "أقفاص متحركة" ],
    "Cage Pallet"                => [ nil,        "بالتات قفصية" ],
    "Platform Trolley"           => [ "platform", nil ],
    "Floor Mats"                 => [ "mats",     nil ]
  }.freeze
  SUBCATEGORY_ALIASES = { "cage / roll cage" => "Roll Cage" }.freeze

  SPEC_LABELS = {
    "Material"          => [ "الخامة",      "Material" ],
    "Model / Type"      => [ "الطراز",      "Model / Type" ],
    "Load Capacity"     => [ "سعة التحميل", "Load Capacity" ],
    "Finish"            => [ "التشطيب",     "Finish" ],
    "DEPTH"             => [ "العمق",       "Depth" ],
    "Size / Dimensions" => [ "المقاس",      "Size / Dimensions" ],
    "Height (mm)"       => [ "الارتفاع",    "Height" ],
    "Width (mm)"        => [ "العرض",       "Width" ],
    "Length (mm)"       => [ "الطول",       "Length" ]
  }.freeze
  SIZE_COLS = [ [ "Product Code", "الكود", "Code" ], [ "Size / Dimensions", "المقاس", "Size" ], [ "Height (mm)", "الارتفاع", "Height" ],
                [ "Width (mm)", "العرض", "Width" ], [ "Length (mm)", "الطول", "Length" ], [ "Load Capacity", "حد التحميل", "Load" ] ].freeze
  NS = { "m" => "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
         "rd" => "http://schemas.microsoft.com/office/spreadsheetml/2017/richdata",
         "r" => "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
         "rel" => "http://schemas.openxmlformats.org/package/2006/relationships" }.freeze

  def self.run(path = DEFAULT_PATH, dry_run: false, out: $stdout) = new(path, dry_run: dry_run, out: out).run

  def initialize(path = DEFAULT_PATH, dry_run: false, out: $stdout)
    @path, @dry_run, @out = path.to_s, dry_run, out
  end

  def run
    raise ArgumentError, "sheet not found: #{@path}" unless File.exist?(@path)
    groups = read_groups
    result = Result.new(groups.sum { |g| g[:rows].size }, groups.size, 0, 0, 0, 0, [], @dry_run, [])
    log "#{result.rows} rows → #{result.products} products#{@dry_run ? ' (DRY RUN)' : ''}"

    ActiveRecord::Base.transaction do
      touched = groups.each_with_index.filter_map { |g, i| import_group(g, i, result) }
      result.hidden = Product.where(published: true).where.not(id: touched).update_all(published: false)
      pruned = prune_empty_subcategories
      log "created=#{result.created} updated=#{result.updated} images=#{result.images} hidden=#{result.hidden} pruned_subcategories=#{pruned} errors=#{result.errors.size}"
      result.errors.each { |n, m| log "  #{n}: #{m}" }
      raise ActiveRecord::Rollback if @dry_run || result.errors.any?
    end

    if result.ok? && !@dry_run
      Setting.bump_content_version!
      log "Products still without an Arabic overview: #{result.untranslated.size}"
    end
    result
  end

  private

  def log(msg) = @out&.puts(msg)

  # ---- reading -------------------------------------------------------------

  def read_groups
    book   = Roo::Spreadsheet.open(@path, extension: "xlsx")
    images = ImageIndex.new(@path)
    groups = {}
    book.sheets.each do |name|
      key = name.strip
      next unless SHEETS.key?(key)
      sheet   = book.sheet(name)
      headers = (1..sheet.last_column).map { |c| norm_header(sheet.cell(1, c)) }
      (2..sheet.last_row).each do |r|
        row = headers.each_with_index.to_h { |h, i| [ h, clean(sheet.cell(r, i + 1)) ] }
        name_en = clean_name(row["Product Name EN"])
        next if name_en.blank?
        row[:images] = images.for_row(key, r)
        gkey = [ key, name_en.downcase ]
        groups[gkey] ||= { sheet: key, name_en: name_en, rows: [], headers: headers }
        groups[gkey][:rows] << row
      end
    end
    groups.values
  end

  def norm_header(h) = h.to_s.gsub(/\s+/, " ").strip

  def clean(v)
    s = case v
        when nil then ""
        when Float then (v == v.to_i ? v.to_i : v).to_s
        else v.to_s
    end
    s = s.strip
    return "" if s == "#VALUE!"
    s.gsub(/[ \t]*\n[ \t]*/, "\n").gsub(/ {2,}/, " ").strip
  end

  def clean_name(s)
    s = s.to_s.sub(/\A[:\s]+/, "").gsub(/\s+/, " ").strip
    return s unless s =~ /[A-Za-z]/ && (s == s.upcase || s == s.downcase)
    s.split(" ").map { |w| %w[with and or for].include?(w.downcase) ? w.downcase : w.capitalize }.join(" ")
  end

  def one_line(s) = s.to_s.gsub(/\s*\n+\s*/, ", ").squeeze(" ").strip

  # ---- mapping -------------------------------------------------------------

  def import_group(g, position, result)
    first    = g[:rows].first
    category = Category.find_by(slug: category_slug(g[:sheet], first["Category"]))
    return fail_row(result, g[:name_en], "category missing for sheet #{g[:sheet]}") unless category
    sub      = subcategory_for(category, first["Sub Category"], g[:sheet])
    slug     = unique_slug(g[:name_en].parameterize, g)
    product  = Product.find_by(slug: slug) || Product.new(slug: slug)
    action   = product.new_record? ? :created : :updated

    name_ar  = g[:rows].map { |r| r["Product Name AR"].to_s.sub(/\A[:\s]+/, "").sub(/[.،:\s]+\z/, "").strip }.find(&:present?)
    overview = one_line(first["Product Overview:"])
    code     = primary_code(first["Product Code"])
    multi    = g[:rows].size > 1
    loads    = g[:rows].map { |r| r["Load Capacity"] }.uniq.reject(&:blank?)

    product.assign_attributes(
      code: code, category: category, subcategory: sub,
      name_en: g[:name_en], name_ar: name_ar.presence || g[:name_en],
      summary_en: overview, summary_ar: MazayaArabic.overview(slug) || overview,
      kind: custom?(loads.first) ? "custom" : "ready",
      popular: position_is_first_in_sheet?(g, position), published: true, position: position,
      specs: specs_for(first, multi: multi, loads: loads),
      applications: applications_for(g[:rows]),
      size_cols: size_cols_for(g[:rows]).map { |_, ar, en| { "col_ar" => ar, "col_en" => en } },
      sizes: sizes_for(g[:rows]) # one row per code; single-code products get a one-row table instead of placeholders
    )
    return fail_row(result, g[:name_en], product.errors.full_messages.join("، ")) unless product.save

    result.untranslated << "#{product.code || '-'} #{product.name_en}" if overview.present? && MazayaArabic.overview(slug).nil?
    result.images += attach_images(product, g[:rows].flat_map { |r| r[:images] }.uniq { |fname, _| fname }, slug) unless @dry_run || product.images.any?
    result[action] += 1
    product.id
  end

  def category_slug(sheet, cell) = CATEGORY_CELL[cell.to_s.strip.downcase] || SHEETS[sheet]

  def subcategory_for(category, raw, sheet)
    name = raw.to_s.sub(%r{\s*/\s*[A-Z]{2,}-\d.*\z}, "").gsub(/\s+/, " ").strip
    name = "Floor Mats" if sheet == "FLOOR MAT"
    return nil if name.blank?
    name = SUBCATEGORY_ALIASES[name.downcase] || SUBCATEGORIES.keys.find { |k| k.casecmp?(name) } || name.split(" ").map(&:capitalize).join(" ")
    reuse, ar = SUBCATEGORIES[name]
    if reuse && (existing = category.subcategories.find_by(slug: reuse))
      return existing
    end
    existing = category.subcategories.where("lower(name_en) = ?", name.downcase).or(category.subcategories.where(slug: name.parameterize)).first
    if existing
      existing.update!(name_en: name, name_ar: ar && existing.name_ar.casecmp?(existing.name_en) ? ar : existing.name_ar)
      return existing
    end
    category.subcategories.create!(name_en: name, name_ar: ar || name, slug: unique_sub_slug(category, name.parameterize),
                                     position: category.subcategories.maximum(:position).to_i + 1)
  end

  def unique_sub_slug(category, base)
    slug = base.presence || SecureRandom.hex(3)
    slug = "#{base}-#{category.slug}" if Subcategory.where(slug: slug).where.not(category_id: category.id).exists?
    slug
  end

  def unique_slug(base, g)
    base = base.presence || SecureRandom.hex(4)
    return base unless (other = Product.find_by(slug: base)) && other.name_en.to_s.downcase != g[:name_en].downcase
    "#{base}-#{g[:sheet].parameterize}"
  end

  def primary_code(cell)
    code = cell.to_s.sub(/\A[:\s]+/, "").split(%r{\s+/\s+}).first.to_s.strip # "A / B" lists codes; "TS W03/PDC" is one code
    code.blank? || code.casecmp?("TBD") ? nil : code
  end

  def custom?(load) = load.blank? || load !~ /\d/

  def position_is_first_in_sheet?(g, position)
    @first_positions ||= {}
    @first_positions[g[:sheet]] ||= position
    @first_positions[g[:sheet]] == position
  end

  def specs_for(row, multi:, loads:)
    SPEC_LABELS.filter_map do |col, (ar, en)|
      next if multi && col.in?([ "Size / Dimensions", "Height (mm)", "Width (mm)", "Length (mm)" ])
      value = col == "Load Capacity" ? (loads.size == 1 ? loads.first : nil) : row[col]
      next if value.blank?
      next if col == "Model / Type" && value.casecmp?(row["Product Code"].to_s)
      v = one_line(value)
      { "label_ar" => ar, "label_en" => en, "value_ar" => MazayaArabic.phrase(v) || v, "value_en" => v }
    end
  end

  def applications_for(rows)
    text = rows.flat_map { |r| r.select { |k, v| k.to_s.start_with?("Applications") && v.is_a?(String) }.values }.join("\n")
    text.split(%r{\s*[/,،;\n]\s*}).map(&:strip).reject(&:blank?).uniq
        .map { |t| { "title_ar" => MazayaArabic.phrase(t) || t, "title_en" => t, "desc_ar" => "", "desc_en" => "" } }
  end

  def size_cols_for(rows)
    cols = SIZE_COLS.select { |col, _, _| rows.any? { |r| r[col].present? } }
    cols.size > 1 ? cols : [] # a code alone is not a sizes table
  end

  def sizes_for(rows)
    cols = size_cols_for(rows)
    rows.map do |r|
      cols.each_with_index.each_with_object({}) do |((col, _, _), i), row|
        v = one_line(r[col].to_s.sub(/\A[:\s]+/, ""))
        row["c#{i}"] = v
        ar = i.zero? ? nil : MazayaArabic.phrase(v)
        row["c#{i}_ar"] = ar if ar && ar != v
      end
    end
  end

  # Subcategories with no published product would show as empty filter chips.
  def prune_empty_subcategories
    used = Product.published.where.not(subcategory_id: nil).select(:subcategory_id)
    Subcategory.where.not(id: used).destroy_all.size
  end

  def fail_row(result, name, message)
    result.errors << [ name, message ]
    nil
  end

  # ---- images --------------------------------------------------------------

  def attach_images(product, images, slug)
    images.each_with_index do |(fname, bytes), i|
      io, filename, type = shrink(bytes, fname, "#{slug}#{i.zero? ? '' : "-#{i + 1}"}")
      product.images.attach(io: io, filename: filename, content_type: type)
    end
    images.size
  end

  # Catalogue photos are up to 9 MB; store a web-sized copy instead.
  def shrink(bytes, fname, base)
    Tempfile.create([ "mz", File.extname(fname) ], binmode: true) do |src|
      src.write(bytes); src.flush
      img   = Vips::Image.new_from_file(src.path)
      jpeg  = !img.has_alpha?
      out   = ImageProcessing::Vips.source(src.path).resize_to_limit(MAX_PX, MAX_PX)
      out   = jpeg ? out.convert("jpg").saver(quality: 85) : out.saver(compression: 9)
      file  = out.call
      return [ StringIO.new(File.binread(file.path)), "#{base}.#{jpeg ? 'jpg' : 'png'}", jpeg ? "image/jpeg" : "image/png" ]
    end
  rescue Vips::Error => e
    log "  image #{fname}: #{e.message.lines.first&.strip} — stored as is"
    [ StringIO.new(bytes), "#{base}#{File.extname(fname)}", Marcel::MimeType.for(StringIO.new(bytes), name: fname) ]
  end

  # In-cell pictures (Excel "Place in Cell"): cell @vm → metadata.xml valueMetadata
  # → futureMetadata rvb → richData/rdrichvalue.xml rv → richValueRel.xml rel → media.
  class ImageIndex
    def initialize(path)
      @zip = Zip::File.open(path)
      meta = xml("xl/metadata.xml")
      @value_meta  = meta.xpath("//m:valueMetadata/m:bk/m:rc", NS).map { |rc| rc["v"].to_i }
      @future_meta = meta.xpath("//m:futureMetadata[@name='XLRICHVALUE']/m:bk", NS).map { |bk| bk.at_xpath(".//rd:rvb", NS)&.[]("i").to_i }
      @rich_values = xml("xl/richData/rdrichvalue.xml").xpath("//rd:rv", NS).map { |rv| rv.at_xpath("./rd:v", NS)&.text.to_i }
      @rel_ids     = xml("xl/richData/richValueRel.xml").xpath("//*[local-name()='rel']").map { |rel| rel.attribute_with_ns("id", NS["r"])&.value }
      @targets     = xml("xl/richData/_rels/richValueRel.xml.rels").xpath("//rel:Relationship", NS).to_h { |r| [ r["Id"], "xl/richData/" + r["Target"] ] }
      wb_rels      = xml("xl/_rels/workbook.xml.rels").xpath("//rel:Relationship", NS).to_h { |r| [ r["Id"], "xl/" + r["Target"].sub(%r{\A/?xl/}, "") ] }
      @sheet_parts = xml("xl/workbook.xml").xpath("//m:sheets/m:sheet", NS).to_h { |sh| [ sh["name"].to_s.strip, wb_rels[sh.attribute_with_ns("id", NS["r"])&.value] ] }
      @cells = {}
    rescue Zip::Error, Errno::ENOENT
      @cells = {}
    end

    # => [[filename, bytes], ...] for every picture cell in that sheet row
    def for_row(sheet_name, row)
      load_sheet(sheet_name)
      Array(@cells[[ sheet_name, row ]]).filter_map do |vm|
        rc  = @value_meta[vm - 1] or next
        rvb = @future_meta[rc] or next
        rel = @rich_values[rvb] or next
        rid = @rel_ids[rel] or next
        target = @targets[rid] or next
        entry = @zip.find_entry(target.sub(%r{xl/richData/\.\./}, "xl/")) or next
        [ File.basename(target), entry.get_input_stream.read ]
      end
    end

    private

    def load_sheet(sheet_name)
      return if @loaded&.include?(sheet_name)
      (@loaded ||= []) << sheet_name
      part = @sheet_parts&.[](sheet_name) or return
      doc  = xml(part) or return
      doc.xpath("//m:c[@vm]", NS).each do |c|
        row = c["r"].to_s[/\d+/].to_i
        (@cells[[ sheet_name, row ]] ||= []) << c["vm"].to_i
      end
    end

    def xml(name)
      entry = @zip.find_entry(name) or return nil
      Nokogiri::XML(entry.get_input_stream.read)
    end
  end
end
