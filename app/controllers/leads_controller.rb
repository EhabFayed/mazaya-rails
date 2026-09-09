# Every form on the site posts here (RFQ, quote, partner application, gated
# download, contact). `kind` + `source` tag where the lead came from so we can
# tell which track produces real leads. Attachments go to Active Storage and
# the team is notified by email (LeadMailer, when LEADS_NOTIFY_TO is set).
class LeadsController < ApplicationController
  KINDS = %w[rfq quote partner download contact].freeze

  def create
    return head :ok if params[:website].present? # honeypot

    lead = Lead.new(lead_params.except(:files))
    lead.kind = KINDS.include?(lead.kind) ? lead.kind : "contact"
    lead.source ||= request.referer
    lead.payload = params[:lead][:payload].to_unsafe_h if params.dig(:lead, :payload).respond_to?(:to_unsafe_h)
    lead.files.attach(Array(lead_params[:files]).compact_blank) if lead_params[:files].present?

    if lead.save
      notify(lead)
      cookies[:mz_gate] = { value: "1", expires: 30.days.from_now, httponly: true, same_site: :lax } if lead.kind == "download"
      download = lead.download_key.present? ? site.download(lead.download_key) : nil
      render json: { ok: true, id: lead.id, file: download && download[:file] }, status: :created
    else
      render json: { ok: false, errors: lead.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def lead_params
    params.require(:lead).permit(:name, :phone, :email, :org_type, :interest, :message, :kind, :source, :download_key, files: [])
  end

  def notify(lead)
    LeadMailer.new_lead(lead).deliver_later
  rescue StandardError => e
    Rails.logger.error("[leads] notification failed: #{e.class}: #{e.message}")
  end
end
