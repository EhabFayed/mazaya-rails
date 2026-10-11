# frozen_string_literal: true

# A value that renders as Arabic or English depending on I18n.locale.
# Used for structured data in SiteData so views can keep writing
# `<%= category[:name] %>` and get the right language automatically
# (ERB, string interpolation, I18n interpolation and JSON all call #to_s).
class Bilingual
  attr_reader :ar, :en

  def initialize(ar, en)
    @ar = ar
    @en = en
  end

  def to_s = I18n.locale.to_s == "en" ? @en : @ar
  alias to_str to_s
  def as_json(*) = to_s
  def to_json(*) = to_s.to_json
  def ==(other) = to_s == other.to_s
  def inspect = "#<Bilingual #{@ar.inspect} / #{@en.inspect}>"
  def blank? = to_s.blank?
  def present? = !blank?
  def presence = present? ? self : nil
  def length = to_s.length
  def include?(str) = to_s.include?(str)
  def html_safe? = false
end
