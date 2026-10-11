# Notifies the sales/partnership team about every new lead.
# Recipient(s): Setting#notify_emails (admin → الإعدادات → الإشعارات), falling back
# to ENV["LEADS_NOTIFY_TO"] (comma-separated). Nothing is sent when both are empty.
class LeadMailer < ApplicationMailer
  KIND_LABELS = {
    "rfq" => "طلب عرض سعر (RFQ)", "quote" => "طلب عرض سعر", "partner" => "طلب انضمام موزّع",
    "download" => "تحميل ملف", "contact" => "تواصل"
  }.freeze

  def new_lead(lead)
    @lead = lead
    @kind = KIND_LABELS.fetch(lead.kind, lead.kind)
    recipients = self.class.recipients
    return if recipients.empty?

    mail(to: recipients, subject: "[مزايا] #{@kind} — #{lead.name}")
  end

  def self.recipients
    from_db = Setting.table_exists? ? Setting.current.notify_list : []
    return from_db if from_db.any?
    ENV.fetch("LEADS_NOTIFY_TO", "").split(",").map(&:strip).reject(&:blank?)
  rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished
    ENV.fetch("LEADS_NOTIFY_TO", "").split(",").map(&:strip).reject(&:blank?)
  end
end
