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

  def social_icon(s) = SOCIAL_ICONS[s[:key].to_s] || s[:abbr]
end
