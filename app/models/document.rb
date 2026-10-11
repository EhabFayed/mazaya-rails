class Document < ApplicationRecord
  include ContentRecord
  TYPES = %w[catalog technical profile tds guide certificate report].freeze
  localized :title, :desc, :cta
  has_one_attached :file
  before_validation { self.key = key.presence || title_ar.to_s.parameterize.presence || SecureRandom.hex(4) }
  validates :key, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  validates :title_ar, presence: true
  validates :doc_type, inclusion: { in: TYPES }

  def file_path
    return "/downloads/placeholder.pdf" unless file.attached?
    Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true, disposition: "inline")
  end
end
