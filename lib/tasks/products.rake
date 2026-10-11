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
