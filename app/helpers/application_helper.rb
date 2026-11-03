module ApplicationHelper
  # Two-digit ordinal badge ("01"). Western digits in both locales by client request.
  def num(i) = format("%02d", i.to_i)

  def rtl? = I18n.locale != :en

  # Product listing mode carried in ?kind=: "custom" when browsing from منتجات حسب الطلب (B2C);
  # the B2B pages pass none (every product). Links inside the catalogue pass it on.
  def kind_scope = params[:kind].presence_in(%w[ready custom])
end
