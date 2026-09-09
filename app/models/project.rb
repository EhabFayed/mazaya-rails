class Project < ApplicationRecord
  include ContentRecord
  self.inheritance_column = nil # `type_ar/type_en` are plain columns
  localized :name, :type, :product_supplied, :scope, :quantity, :requirements, :solution
  sluggable
  has_and_belongs_to_many :solutions
  has_one_attached :image
  has_many_attached :gallery
  validates :name_ar, presence: true
  scope :featured, -> { where(featured: true) }
end
