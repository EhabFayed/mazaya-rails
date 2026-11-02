module ApplicationHelper
  # Two-digit ordinal badge ("01"). Western digits in both locales by client request.
  def num(i) = format("%02d", i.to_i)

  def rtl? = I18n.locale != :en

  # Product listing mode carried in ?kind=: "ready" when browsing from المنتجات الجاهزة (B2C only),
  # "custom" when coming from the B2B pages (every product). Links inside the catalogue pass it on.
  def kind_scope = params[:kind].presence_in(Product::KINDS)
end
