module ApplicationHelper
  # Two-digit ordinal badge in the current script: "٠١" (ar) / "01" (en).
  def num(i)
    s = format("%02d", i.to_i)
    I18n.locale == :en ? s : s.tr("0-9", "٠-٩")
  end

  def rtl? = I18n.locale != :en
end
