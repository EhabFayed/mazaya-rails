# Singleton: site-wide contact details and the content cache version.
class Setting < ApplicationRecord
  include Localizable
  localized :address, :hours, :rfq_response

  def self.current = first || create!
  def self.content_version = (pick(:content_version) || 1)
  def self.bump_content_version!
    return unless table_exists?
    row = first || create!
    row.update_column(:content_version, row.content_version + 1)
  end

  def whatsapp_href = "https://wa.me/#{(whatsapp_number.presence || whatsapp_display).to_s.delete('^0-9')}"
  def notify_list = notify_emails.to_s.split(/[,\s;]+/).reject(&:blank?)
  after_commit { self.class.bump_content_version! }
end
