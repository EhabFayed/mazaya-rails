# Notifies the sales/partnership team about every new lead.
# Recipient(s): ENV["LEADS_NOTIFY_TO"] (comma-separated). Nothing is sent when unset.
class LeadMailer < ApplicationMailer
  KIND_LABELS = {
    "rfq" => "طلب عرض سعر (RFQ)", "quote" => "طلب عرض سعر", "partner" => "طلب انضمام موزّع",
    "download" => "تحميل ملف", "contact" => "تواصل"
  }.freeze

  def new_lead(lead)
    @lead = lead
    @kind = KIND_LABELS.fetch(lead.kind, lead.kind)
    recipients = ENV.fetch("LEADS_NOTIFY_TO", "").split(",").map(&:strip).reject(&:blank?)
    return if recipients.empty?

    mail(to: recipients, subject: "[مزايا] #{@kind} — #{lead.name}")
  end
end
