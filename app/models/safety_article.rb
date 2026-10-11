class SafetyArticle < ApplicationRecord
  include ContentRecord
  localized :name, :summary
  sluggable
  validates :name_ar, presence: true
  def points_bi    = points.map { |r| Localizable.pair(r) }
  def checklist_bi = checklist.map { |r| Localizable.bi(r, "text") }
end
