require "test_helper"

class ProductImporterTest < ActiveSupport::TestCase
  FIXTURE = Rails.root.join("test/fixtures/files/products_import.csv")

  test "creates categories, subcategories and products from CSV" do
    result = ProductImporter.new(FIXTURE, filename: "products_import.csv").run
    assert_equal 4, result.total
    assert_equal 3, result.created
    assert_equal 0, result.updated
    assert_equal 1, result.skipped
    assert_equal [ 5 ], result.errors.map(&:first)
    assert_match(/الاسم العربي/, result.errors.first.last)

    ladders = Category.find_by!(name_ar: "سلالم")
    assert_equal "ladders", ladders.slug
    assert_equal "Ladders", ladders.name_en
    single = ladders.subcategories.find_by!(name_ar: "سلم مفرد")
    assert_equal "single-ladder", single.slug

    p = Product.find_by!(code: "MML-100")
    assert_equal ladders, p.category
    assert_equal single, p.subcategory
    assert_equal "ready", p.kind
    assert p.popular
    assert_equal 2, p.specs.size
    assert_equal({ "label_ar" => "الخامة", "label_en" => "Material", "value_ar" => "ألومنيوم", "value_en" => "Aluminium" }, p.specs.first)

    p2 = Product.find_by!(code: "MML-101")
    assert_equal "ready", p2.kind # Arabic "جاهز"
    assert_not p2.popular
    assert_equal 1, p2.specs.size

    cart = Product.find_by!(name_ar: "عربة نقل مخصصة")
    assert_nil cart.code
    assert_equal "custom", cart.kind
    assert_equal "carts", cart.category.slug
  end

  test "re-import updates existing products by code instead of duplicating" do
    ProductImporter.new(FIXTURE, filename: "products_import.csv").run
    result = ProductImporter.new(FIXTURE, filename: "products_import.csv").run
    assert_equal 0, result.created
    assert_equal 3, result.updated
    assert_equal 1, Product.where(code: "MML-100").count
    assert_equal 1, Category.where(name_ar: "سلالم").count
  end

  test "dry run reports without writing anything" do
    result = nil
    assert_no_difference([ "Product.count", "Category.count", "Subcategory.count" ]) do
      result = ProductImporter.new(FIXTURE, filename: "products_import.csv", dry_run: true).run
    end
    assert result.dry_run
    assert_equal 3, result.created
    assert_equal 1, result.skipped
  end

  test "accepts Arabic headers" do
    path = Rails.root.join("tmp/import-arabic-#{SecureRandom.hex(3)}.csv")
    File.write(path, "﻿الفئة,الكود,الاسم,النوع,مميز,مواصفة 1,مواصفة 1 (إنجليزي),قيمة 1\nسلالم,MML-200,سلم منصة,حسب الطلب,نعم,الحمولة,Load,١٥٠ كجم\n")
    result = ProductImporter.new(path, filename: "x.csv").run
    assert_equal 1, result.created, result.errors.inspect
    p = Product.find_by!(code: "MML-200")
    assert_equal "custom", p.kind
    assert p.popular
    assert_equal "Load", p.specs.first["label_en"]
  ensure
    File.delete(path) if path && File.exist?(path)
  end

  test "reads xlsx workbooks via roo" do
    path = Rails.root.join("tmp/import-#{SecureRandom.hex(3)}.xlsx")
    write_xlsx(path, [ %w[category_ar code name_ar kind], [ "سلالم", 1001, "سلم رقمي", "ready" ] ])
    result = ProductImporter.new(path, filename: "sheet.xlsx").run
    assert_equal 1, result.created, result.errors.inspect
    assert_equal "1001", Product.last.code # numeric cell -> integer string
  ensure
    File.delete(path) if path && File.exist?(path)
  end

  test "raises a friendly error when the name column is missing" do
    path = Rails.root.join("tmp/import-bad-#{SecureRandom.hex(3)}.csv")
    File.write(path, "foo,bar\n1,2\n")
    assert_raises(ProductImporter::Error) { ProductImporter.new(path, filename: "bad.csv").run }
  ensure
    File.delete(path) if path && File.exist?(path)
  end

  test "template csv lists every supported header" do
    csv = ProductImporter.template_csv
    assert csv.start_with?("﻿")
    assert_includes csv, "spec_8_value_en"
  end

  private

  # Minimal xlsx writer (roo only reads) — a single sheet with inline strings.
  def write_xlsx(path, rows)
    require "zip"
    col = ->(i) { s = ""; i += 1; while i > 0; i, r = (i - 1).divmod(26); s = (65 + r).chr + s; end; s }
    sheet_rows = rows.each_with_index.map do |cells, ri|
      cs = cells.each_with_index.map do |v, ci|
        ref = "#{col.call(ci)}#{ri + 1}"
        v.is_a?(Numeric) ? %(<c r="#{ref}"><v>#{v}</v></c>) : %(<c r="#{ref}" t="inlineStr"><is><t>#{ERB::Util.html_escape(v)}</t></is></c>)
      end.join
      %(<row r="#{ri + 1}">#{cs}</row>)
    end.join
    files = {
      "[Content_Types].xml" => %(<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/></Types>),
      "_rels/.rels" => %(<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>),
      "xl/workbook.xml" => %(<?xml version="1.0" encoding="UTF-8"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets></workbook>),
      "xl/_rels/workbook.xml.rels" => %(<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>),
      "xl/styles.xml" => %(<?xml version="1.0" encoding="UTF-8"?><styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><numFmts count="0"/><fonts count="1"><font/></fonts><fills count="1"><fill/></fills><borders count="1"><border/></borders><cellStyleXfs count="1"><xf/></cellStyleXfs><cellXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellXfs></styleSheet>),
      "xl/worksheets/sheet1.xml" => %(<?xml version="1.0" encoding="UTF-8"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>#{sheet_rows}</sheetData></worksheet>)
    }
    Zip::File.open(path.to_s, create: true) { |zip| files.each { |name, xml| zip.get_output_stream(name) { |io| io.write(xml) } } }
  end
end
