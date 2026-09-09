class Category < ApplicationRecord
  include ContentRecord
  localized :name, :desc, :b2c, :b2b, :about, :finder
  sluggable

  has_many :subcategories, -> { ordered }, dependent: :destroy, inverse_of: :category
  has_many :products, dependent: :restrict_with_error
  has_many :solutions, dependent: :nullify
  has_one_attached :image
  accepts_nested_attributes_for :subcategories, allow_destroy: true, reject_if: ->(a) { a["name_ar"].blank? }

  validates :name_ar, presence: true

  def spec_labels_bi = spec_labels.map { |r| Localizable.bi(r, "label") }
end
