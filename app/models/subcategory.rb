class Subcategory < ApplicationRecord
  include ContentRecord
  localized :name
  belongs_to :category, inverse_of: :subcategories
  has_many :products, dependent: :nullify
  before_validation { self.slug = slug.presence || name_ar.to_s.parameterize.presence || SecureRandom.hex(3) }
  validates :name_ar, presence: true
  validates :slug, presence: true, uniqueness: { scope: :category_id }
end
