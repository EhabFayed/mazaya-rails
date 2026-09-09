class Client < ApplicationRecord
  include ContentRecord
  localized :name
  has_one_attached :logo
  validates :name_ar, presence: true
  validates :bg, format: { with: /\A#[0-9A-Fa-f]{6}\z/ }
end
