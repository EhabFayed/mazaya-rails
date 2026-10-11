class Solution < ApplicationRecord
  include ContentRecord
  localized :name, :desc
  sluggable
  belongs_to :category, optional: true
  has_and_belongs_to_many :projects
  has_one_attached :image
  validates :name_ar, presence: true
end
