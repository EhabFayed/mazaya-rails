class Lead < ApplicationRecord
  KINDS = %w[rfq quote partner download contact].freeze
  ORG_TYPES = %w[contractor distributor project end_user other].freeze
  MAX_FILES = 5
  MAX_FILE_SIZE = 15.megabytes
  ALLOWED_TYPES = %w[application/pdf image/jpeg image/png image/webp application/zip
                     application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document
                     application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
                     application/acad image/vnd.dwg application/dxf].freeze

  belongs_to :assigned_to, class_name: "User", optional: true, inverse_of: :leads
  STATUSES = %w[new contacted quoted won lost spam].freeze
  validates :status, inclusion: { in: STATUSES }
  scope :with_status, ->(s) { s.present? ? where(status: s) : all }

  has_many_attached :files

  validates :name, presence: true
  validates :kind, inclusion: { in: KINDS }
  validate :phone_or_email
  validate :files_are_acceptable

  scope :recent, -> { order(created_at: :desc) }
  scope :of_kind, ->(kind) { kind.present? ? where(kind: kind) : all }

  def self.to_csv
    require "csv"
    CSV.generate(col_sep: ",", write_headers: true, headers: %w[id created_at kind name phone email org_type interest message source download_key payload]) do |csv|
      recent.find_each { |l| csv << [ l.id, l.created_at.iso8601, l.kind, l.name, l.phone, l.email, l.org_type, l.interest, l.message, l.source, l.download_key, l.payload.to_json ] }
    end
  end

  private

  def phone_or_email
    errors.add(:base, "أدخل رقم الجوال أو البريد الإلكتروني") if phone.blank? && email.blank?
  end

  def files_are_acceptable
    return unless files.attached?
    errors.add(:files, "الحد الأقصى #{MAX_FILES} ملفات") if files.size > MAX_FILES
    files.each do |f|
      errors.add(:files, "#{f.filename}: الحد الأقصى 15 ميجابايت") if f.byte_size > MAX_FILE_SIZE
      errors.add(:files, "#{f.filename}: نوع ملف غير مسموح") unless ALLOWED_TYPES.include?(f.content_type)
    end
  end
end
