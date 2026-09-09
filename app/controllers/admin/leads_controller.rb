# Minimal back-office for leads: list, filter by kind, view payload and
# attachments, export CSV. Protected by HTTP Basic auth
# (ENV ADMIN_USER / ADMIN_PASSWORD; defaults to admin/admin outside production).
module Admin
  class LeadsController < ApplicationController
    layout "admin"
    http_basic_authenticate_with(
      name: ENV.fetch("ADMIN_USER", Rails.env.production? ? SecureRandom.hex(16) : "admin"),
      password: ENV.fetch("ADMIN_PASSWORD", Rails.env.production? ? SecureRandom.hex(16) : "admin")
    )

    KINDS = Lead::KINDS

    def index
      @kind = KINDS.include?(params[:kind]) ? params[:kind] : nil
      scope = Lead.recent.of_kind(@kind).with_attached_files
      @counts = Lead.group(:kind).count
      respond_to do |format|
        format.html { @leads = scope.limit(200) }
        format.csv  { send_data Lead.of_kind(@kind).to_csv, filename: "mazaya-leads-#{Date.current}.csv", type: "text/csv; charset=utf-8" }
      end
    end

    def show
      @lead = Lead.find(params[:id])
    end
  end
end
