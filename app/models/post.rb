class Post < ApplicationRecord
  include ContentRecord
  TYPES = %w[news article].freeze
  TOPICS = %w[news products safety quality projects original].freeze
  localized :title, :excerpt, :body, :category
  sluggable from: :title_ar
  has_one_attached :image
  validates :title_ar, presence: true
  validates :post_type, inclusion: { in: TYPES }
  validates :topic, inclusion: { in: TOPICS }
  scope :news, -> { where(post_type: "news") }
  scope :articles, -> { where(post_type: "article") }

  def points_bi    = points.map { |r| Localizable.pair(r) }
  def checklist_bi = checklist.map { |r| Localizable.bi(r, "text") }
  def paragraphs   = body.to_s.split(/\n{2,}|\r\n\r\n/).map(&:strip).reject(&:blank?)
end
