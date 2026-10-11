# Client logos shown in the trust strip.
module Admin
  class ClientsController < BaseController
    before_action :require_content!
    before_action :set_client, only: %i[edit update destroy]

    def admin_section = "clients"

    def index
      @clients = Client.ordered.with_attached_logo
    end

    def new
      @client = Client.new(published: true, bg: "#FFFFFF")
    end

    def create
      @client = Client.new(client_params)
      if @client.save
        redirect_to edit_admin_client_path(@client), notice: "تم الحفظ."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @client.update(client_params)
        redirect_to edit_admin_client_path(@client), notice: "تم الحفظ."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @client.destroy
      redirect_to admin_clients_path, notice: "تم حذف الشعار."
    end

    private

    def set_client = @client = Client.find(params[:id])

    def client_params
      attrs = params.require(:client).permit(:name_ar, :name_en, :bg, :logo, :position, :published)
      attrs.delete(:logo) if attrs[:logo].blank?
      attrs[:bg] = attrs[:bg].to_s.strip.upcase if attrs.key?(:bg)
      attrs
    end
  end
end
