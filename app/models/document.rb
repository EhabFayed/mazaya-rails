class Document < ApplicationRecord
  include ContentRecord
  TYPES = %w[catalog technical profile tds guide certificate report].freeze
  localized :title, :desc, :cta
  has_one_attached :file
  before_validation { self.key = key.presence || title_ar.to_s.parameterize.presence || SecureRandom.hex(4) }
  validates :key, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  validates :title_ar, presence: true
  validates :doc_type, inclusion: { in: TYPES }

  # An uploaded file (admin) wins; otherwise the static file for this key in SiteData::Defaults::DOWNLOADS
  # (public/downloads/…), else the placeholder.
  def file_path
    return Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true, disposition: "inline") if file.attached?
    static_path || "/downloads/placeholder.pdf"
  end

  def static_path = SiteData::Defaults::DOWNLOADS.dig(key, :file).presence

  # a real file on the server (public/downloads/…), not the placeholder
  def static_file?
    p = static_path
    p.present? && !p.end_with?("placeholder.pdf") && File.exist?(Rails.public_path.join(p.delete_prefix("/")))
  end

  def has_file? = file.attached? || static_file?

  # human size of the attached or static file (nil when unknown)
  def file_size
    bytes = file.attached? ? file.byte_size : (static_path && File.size?(Rails.public_path.join(static_path.delete_prefix("/"))))
    bytes && ActiveSupport::NumberHelper.number_to_human_size(bytes)
  end
end
