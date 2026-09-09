# frozen_string_literal: true

# Shared behaviour for admin-managed content: bilingual columns, slug
# handling, ordering, publish flag, and bumping the content cache version.
module ContentRecord
  extend ActiveSupport::Concern

  included do
    include Localizable
    after_commit { Setting.bump_content_version! }
    scope :ordered, -> { order(:position, :id) }
    scope :published, -> { column_names.include?("published") ? where(published: true) : all }
  end

  class_methods do
    def sluggable(from: :name_ar)
      before_validation { self.slug = slug.presence || send(from).to_s.parameterize.presence || SecureRandom.hex(4) }
      validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/, message: "أحرف لاتينية صغيرة وأرقام وشرطات فقط" }
    end
  end

  # Normalise JSON list params coming from the admin form:
  # {"0"=>{...},"1"=>{...}} -> [{...},{...}] without empty rows.
  def self.rows(value)
    list = value.respond_to?(:values) ? value.values : Array(value)
    list.map { |r| r.respond_to?(:to_unsafe_h) ? r.to_unsafe_h : r.to_h }.map(&:stringify_keys).reject { |r| r.values.all?(&:blank?) }
  end
end
