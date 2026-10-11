# frozen_string_literal: true

# `localized :name, :desc` defines `name` / `desc` readers returning a
# Bilingual built from the `_ar` / `_en` columns (English falls back to Arabic).
module Localizable
  extend ActiveSupport::Concern

  class_methods do
    def localized(*attrs)
      attrs.each do |attr|
        define_method(attr) do
          ar = public_send("#{attr}_ar")
          en = public_send("#{attr}_en")
          Bilingual.new(ar.to_s, en.presence || ar.to_s)
        end
      end
    end
  end

  # Turn a JSON row {title_ar, title_en, desc_ar, desc_en} into [Bilingual, Bilingual].
  def self.pair(row)
    row = row.to_h.stringify_keys
    [ bi(row, "title"), bi(row, "desc") ]
  end

  def self.bi(row, base)
    row = row.to_h.stringify_keys
    ar = row["#{base}_ar"].presence || row["ar"].presence || row[base].to_s
    en = row["#{base}_en"].presence || row["en"].presence || ar
    Bilingual.new(ar.to_s, en.to_s)
  end
end
