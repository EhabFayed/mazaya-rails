module ApplicationHelper
  # Two-digit ordinal badge ("01"). Western digits in both locales by client request.
  def num(i) = format("%02d", i.to_i)

  def rtl? = I18n.locale != :en

  # Product listing mode carried in ?kind=: "custom" when browsing from منتجات حسب الطلب (B2C);
  # the B2B pages pass none (every product). Links inside the catalogue pass it on.
  def kind_scope = params[:kind].presence_in(%w[ready custom])

  # Brand glyph for a social link (app/assets/social_icons/<key>.svg, Simple Icons, CC0),
  # inlined so it takes the link's text color. Unknown keys fall back to the text abbreviation.
  SOCIAL_ICONS = Dir[Rails.root.join("app/assets/social_icons/*.svg")].to_h do |f|
    svg = File.read(f).sub(%r{<title>.*?</title>}, "")
                      .sub("<svg ", '<svg class="social-ico" aria-hidden="true" focusable="false" fill="currentColor" ')
                      .sub(/ role="img"/, "")
    [ File.basename(f, ".svg"), svg.html_safe ]
  end.freeze

  # True when a download has a real file: an admin upload (blob path) or an existing file under
  # public/downloads that isn't the placeholder. Buttons for files not delivered yet are hidden.
  def download_ready?(key)
    file = SiteData.download(key)&.dig(:file).to_s
    return false if file.blank? || file.end_with?("placeholder.pdf")
    return true unless file.start_with?("/downloads/")
    File.exist?(Rails.public_path.join(file.delete_prefix("/")))
  end

  # Download key of the catalog for the current page's track (pages set content_for :nav_active).
  def track_catalog = content_for(:nav_active) == "b2b" ? "catalog-b2b" : "catalog-b2c"

  def social_icon(s) = SOCIAL_ICONS[s[:key].to_s] || s[:abbr]
end
