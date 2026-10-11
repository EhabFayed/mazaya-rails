# Ordered lists of bilingual rows. Row shape depends on the key (see SCHEMA).
class ContentList < ApplicationRecord
  include ContentRecord
  SCHEMA = {
    "stats"               => { label: "أرقام الرئيسية",            fields: %w[value suffix label_ar label_en sub_ar sub_en] },
    "partner_stats"       => { label: "أرقام صفحة الشراكة",        fields: %w[value suffix label_ar label_en sub_ar sub_en] },
    "social"              => { label: "روابط السوشيال",            fields: %w[key label_ar label_en url abbr] },
    "inquiry_types"       => { label: "أنواع الاستفسار (تواصل)",   fields: %w[ar en] },
    "org_types"           => { label: "أنواع الجهة (نماذج التحميل)", fields: %w[key ar en] },
    "custom_features"     => { label: "إمكانيات التخصيص",         fields: %w[title_ar title_en desc_ar desc_en] },
    "custom_steps"        => { label: "خطوات التصنيع حسب الطلب",   fields: %w[title_ar title_en desc_ar desc_en] },
    "certifications"      => { label: "كروت الشهادات (الجودة)",    fields: %w[key title_ar title_en desc_ar desc_en cta_ar cta_en] },
    "quality_steps"       => { label: "خطوات الجودة في التصنيع",   fields: %w[title_ar title_en desc_ar desc_en] },
    "safety_choose"       => { label: "السلامة: اختر المنتج",      fields: %w[title_ar title_en desc_ar desc_en] },
    "safety_checklist"    => { label: "السلامة: قائمة الفحص",      fields: %w[text_ar text_en] },
    "safety_use"          => { label: "السلامة: أثناء الاستخدام",  fields: %w[title_ar title_en desc_ar desc_en] },
    "authenticity_checks" => { label: "علامات الأصالة",             fields: %w[title_ar title_en desc_ar desc_en] },
    "comparison"          => { label: "جدول الأصلي/المقلد",        fields: %w[original_ar original_en counterfeit_ar counterfeit_en] },
    "topics"              => { label: "مواضيع الأخبار",            fields: %w[key ar en] },
    "guide_docs"          => { label: "وثائق مكتبة الأدلة",        fields: %w[ar en] },
    "project_fields"      => { label: "حقول صفحة المشروع",         fields: %w[ar en] }
  }.freeze

  validates :key, presence: true, uniqueness: true, inclusion: { in: SCHEMA.keys }

  def self.[](key) = find_by(key: key)&.items || []
  def fields = SCHEMA.dig(key, :fields) || []
  def label  = super.presence || SCHEMA.dig(key, :label) || key
end
