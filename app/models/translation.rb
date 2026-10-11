# Admin overrides for page copy keys from config/locales/*.yml.
class Translation < ApplicationRecord
  validates :locale, inclusion: { in: %w[ar en] }
  validates :key, presence: true, uniqueness: { scope: :locale }
  after_commit { I18n::DbOverrides.reload!; Setting.bump_content_version! }
end
