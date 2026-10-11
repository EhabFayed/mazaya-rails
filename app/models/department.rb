class Department < ApplicationRecord
  include ContentRecord
  localized :name, :desc
  before_validation { self.key = key.presence || name_en.to_s.parameterize.presence || SecureRandom.hex(3) }
  validates :key, presence: true, uniqueness: true
  validates :name_ar, presence: true
end
