class Product < ApplicationRecord
  include ContentRecord
  KINDS = %w[ready custom].freeze
  localized :name, :summary
  sluggable

  belongs_to :category
  belongs_to :subcategory, optional: true
  has_many_attached :images
  has_one_attached :tds
  has_one_attached :guide

  validates :name_ar, presence: true
  validates :kind, inclusion: { in: KINDS }
  validate  :subcategory_belongs_to_category

  scope :popular, -> { where(popular: true) }

  def image_label(blob) = Localizable.bi(image_labels[blob.id.to_s] || {}, "label").presence || name

  def features_bi     = features.map { |r| Localizable.pair(r) }
  def applications_bi = applications.map { |r| Localizable.pair(r) }
  def faq_bi          = faq.map { |r| [ Localizable.bi(r, "q"), Localizable.bi(r, "a") ] }
  def specs_bi        = specs.map { |r| [ Localizable.bi(r, "label"), (r["value_ar"].present? || r["value_en"].present? ? Localizable.bi(r, "value") : nil) ] }
  def size_cols_bi    = size_cols.map { |r| Localizable.bi(r, "col") }

  private

  def subcategory_belongs_to_category
    errors.add(:subcategory, "لا تنتمي لهذه الفئة") if subcategory && subcategory.category_id != category_id
  end
end
