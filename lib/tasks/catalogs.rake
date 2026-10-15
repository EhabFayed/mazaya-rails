# Per-category PDF catalogs, generated from the product data (the master-sheet import).
#
#   1. node script/catalogs/build.mjs https://<site> <out-dir>   # prints /catalog/:category/print → catalog-<slug>.pdf
#   2. bin/rails catalogs:attach DIR=<out-dir>                     # attaches each PDF to its Document
#
# Rebuild both steps after every product import so the catalogs match the website.
namespace :catalogs do
  desc "Attach DIR/catalog-<category>.pdf to each category's catalog Document (DRY_RUN=1 to preview)"
  task attach: :environment do
    dir = ENV["DIR"].presence or abort "DIR= (folder holding catalog-<slug>.pdf) is required"
    dry = ENV["DRY_RUN"].present?

    Category.published.ordered.each do |category|
      key = category.catalog_key.presence || "catalog-#{category.slug}"
      path = File.join(dir, "#{key}.pdf")
      unless File.exist?(path)
        puts "skip  #{key}: no #{File.basename(path)} (category without products keeps its current file)"
        next
      end
      doc = Document.find_by(key: key) or (puts("skip  #{key}: no Document with that key"); next)
      puts "#{dry ? 'would attach' : 'attach'} #{key} ← #{File.basename(path)} (#{(File.size(path) / 1024.0 / 1024).round(1)} MB)"
      next if dry

      # The category slots used to share one blob with catalog-full: detach (keeps the blob)
      # instead of replacing, which would purge it out from under the other documents.
      doc.file.detach if doc.file.attached?
      doc.file.attach(io: File.open(path), filename: "mazaya-catalog-#{category.slug}.pdf", content_type: "application/pdf")
      doc.update!(version: "1", version_date: Date.current) if doc.version.blank?
    end
  end
end
