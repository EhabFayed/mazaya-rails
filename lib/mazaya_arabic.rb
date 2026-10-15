# frozen_string_literal: true

# Arabic for the English-only catalogue content (db/data/mazaya_master_ar.yml).
#
#   MazayaArabic.overview("platform-ladder")      # => Arabic summary or nil
#   MazayaArabic.phrase("Industrial Facilities")  # => "المنشآت الصناعية"
#   MazayaArabic.phrase("150 kg")                 # => "150 كجم"   (unit rules)
#   MazayaArabic.phrase("WTC-C")                  # => nil         (a code; keep English)
#
# Lookup order: exact phrase (case/space/punctuation-insensitive) → comma list
# translated item by item → unit/dimension rules. Returns nil when English words
# would be left over, so callers fall back to the English text.
module MazayaArabic
  PATH = Rails.root.join("db/data/mazaya_master_ar.yml")

  UNIT_RULES = [
    [ /\(\s*H\s*×\s*W\s*×\s*D\s*\)/i,        "(الارتفاع × العرض × العمق)" ],
    [ /(\d+(?:\.\d+)?)\s*mm\s+width/i,       'عرض \1 مم' ],
    [ /(\d+(?:\.\d+)?)\s*mm\s+depth/i,       'عمق \1 مم' ],
    [ /\bwidth\s*:/i,                        "العرض:" ],
    [ /\bdepth\s*:/i,                        "العمق:" ],
    [ /\bheight\s*:/i,                       "الارتفاع:" ],
    [ /\blength\s*:/i,                       "الطول:" ],
    [ /\bcustome?\s+sizes\b/i,               "مقاسات مخصصة" ],
    [ /\bcustom\b/i,                         "مخصص" ],
    [ /\bas\s+required\b/i,                  "حسب الطلب" ],
    [ /(?<=\d)\s*kgs?\b/i,                  " كجم" ],
    [ /(?<=\d)\s*tons?\b/i,                 " طن" ],
    [ /(?<=\d)\s*mm\b/i,                    " مم" ],
    [ /(?<=\d)\s*cm\b/i,                    " سم" ],
    [ /(\d)\s*m\b(?!m)/i,                    '\1 م' ],
    [ /(\d)\s*(?:"|inch(?:es)?)/i,           '\1 بوصة' ],
    [ /\bto\b/i,                             "إلى" ],
    [ /\bor\b/i,                             "أو" ],
    [ /\s+x\s+/i,                            " × " ]
  ].freeze

  class << self
    def overview(slug) = data["overviews"][slug.to_s]

    def phrase(en)
      s = en.to_s.gsub(/\s+/, " ").strip
      return nil if s.blank? || s.match?(/\p{Arabic}/)
      exact(s) || list(s) || rule(s)
    end

    def reload! = (@data = @index = nil)

    private

    def data  = @data  ||= YAML.safe_load_file(PATH)
    def index = @index ||= data["phrases"].to_h { |k, v| [ norm(k), v ] }
    def norm(s) = s.to_s.gsub(/\s+/, " ").strip.sub(/[.,،:;]+\z/, "").downcase
    def exact(s) = index[norm(s)]

    # "Available in different heights, 3.70 m, 4.80 m" → each part on its own
    def list(s)
      parts = s.split(/\s*,\s*/)
      return nil if parts.size < 2
      out = parts.map { |p| exact(p) || rule(p) }
      out.all? ? out.join("، ") : nil
    end

    def rule(s)
      t = UNIT_RULES.reduce(s) { |acc, (re, rep)| acc.gsub(re, rep) }
      t.match?(/[A-Za-z]/) ? nil : t.strip
    end
  end
end
