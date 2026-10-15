module ApplicationHelper
  # Two-digit ordinal badge ("01"). Western digits in both locales by client request.
  def num(i) = format("%02d", i.to_i)

  def rtl? = I18n.locale != :en
end
