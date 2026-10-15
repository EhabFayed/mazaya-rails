# frozen_string_literal: true

namespace :products do
  desc "Import the client product sheet (db/data/mazaya_products.xlsx by default). DRY_RUN=1 validates only."
  task :import_sheet, [ :path ] => :environment do |_t, args|
    path   = args[:path].presence || MazayaSheetImport::DEFAULT_PATH
    result = MazayaSheetImport.run(path, dry_run: ENV["DRY_RUN"].present?)
    abort "Import rolled back: fix the errors above and rerun." unless result.ok?
    puts "Published products: #{Product.published.count}" unless result.dry_run
  end
end

namespace :products do
  desc "Import 'Mazaya Catalogue Master.xlsx' (path arg or db/data/mazaya_catalogue_master.xlsx). Unpublishes every other product. DRY_RUN=1 validates only."
  task :import_master, [ :path ] => :environment do |_t, args|
    path   = args[:path].presence || MazayaMasterImport::DEFAULT_PATH
    result = MazayaMasterImport.run(path, dry_run: ENV["DRY_RUN"].present?)
    abort "Import rolled back: fix the errors above and rerun." unless result.ok?
    unless result.dry_run
      puts "Published products: #{Product.published.count}"
      puts "Needs Arabic translation:"; result.untranslated.each { |n| puts "  - #{n}" }
    end
  end
end

namespace :products do
  desc "Fill Arabic fields of published products from db/data/mazaya_master_ar.yml (overview, specs, applications, sizes)."
  task translate_ar: :environment do
    MazayaArabic.reload!
    changed = 0; missing = Hash.new(0)
    Product.published.find_each do |p|
      before = p.attributes.slice("summary_ar", "specs", "applications", "sizes")
      if (ar = MazayaArabic.overview(p.slug)) then p.summary_ar = ar else missing["overview: #{p.slug}"] += 1 end
      p.specs = p.specs.map do |r|
        v = r["value_en"].presence || r["value_ar"].to_s
        t = MazayaArabic.phrase(v); missing["spec: #{v}"] += 1 if t.nil? && v.match?(/[A-Za-z]/)
        r.merge("value_en" => v, "value_ar" => t || v)
      end
      p.applications = p.applications.map do |r|
        v = r["title_en"].presence || r["title_ar"].to_s
        t = MazayaArabic.phrase(v); missing["application: #{v}"] += 1 if t.nil?
        r.merge("title_en" => v, "title_ar" => t || v)
      end
      p.sizes = p.sizes.map do |r|
        r = r.reject { |k, _| k.end_with?("_ar") }
        r.keys.grep(/\Ac[1-9]\z/).each { |k| t = MazayaArabic.phrase(r[k]); r["#{k}_ar"] = t if t && t != r[k] }
        r
      end
      next if p.attributes.slice("summary_ar", "specs", "applications", "sizes") == before
      p.save!; changed += 1
    end
    Setting.bump_content_version!
    puts "updated #{changed} products"
    if missing.any?
      puts "still English (#{missing.size} distinct):"; missing.keys.sort.each { |m| puts "  - #{m}" }
    else
      puts "nothing left in English"
    end
  end
end
