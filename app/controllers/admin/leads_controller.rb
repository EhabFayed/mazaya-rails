# Leads pipeline: list/filter, detail, status + notes + assignment, CSV export.
module Admin
  class LeadsController < BaseController
    before_action :require_sales!

    def index
      @kind   = Lead::KINDS.include?(params[:kind]) ? params[:kind] : nil
      @status = Lead::STATUSES.include?(params[:status]) ? params[:status] : nil
      @q      = params[:q].to_s.strip
      scope = Lead.recent.of_kind(@kind).with_status(@status).includes(:assigned_to).with_attached_files
      scope = scope.where("name ILIKE :q OR phone ILIKE :q OR email ILIKE :q OR message ILIKE :q OR payload::text ILIKE :q", q: "%#{@q}%") if @q.present?
      @counts = Lead.group(:kind).count
      @status_counts = Lead.group(:status).count
      respond_to do |format|
        format.html { @leads, @page, @pages = helpers.paginate(scope) }
        format.csv  { send_data Lead.of_kind(@kind).with_status(@status).to_csv, filename: "mazaya-leads-#{Date.current}.csv", type: "text/csv; charset=utf-8" }
      end
    end

    def show
      @lead = Lead.find(params[:id])
      @users = User.active.order(:name)
    end

    def update
      @lead = Lead.find(params[:id])
      attrs = params.require(:lead).permit(:status, :notes, :assigned_to_id)
      attrs[:contacted_at] = Time.current if attrs[:status] == "contacted" && @lead.contacted_at.nil?
      if @lead.update(attrs)
        redirect_to admin_lead_path(@lead), notice: "تم تحديث الطلب."
      else
        @users = User.active.order(:name)
        render :show, status: :unprocessable_entity
      end
    end
  end
end
