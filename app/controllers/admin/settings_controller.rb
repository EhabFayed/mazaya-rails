# Site-wide contact details, map, RFQ response time and lead notifications
# (the Setting singleton). Admin only.
module Admin
  class SettingsController < BaseController
    before_action :require_admin!

    def admin_section = "settings"

    def show
      @setting = Setting.current
    end

    def update
      @setting = Setting.current
      attrs = setting_params
      attrs[:map_embed] = self.class.extract_map_src(attrs[:map_embed]) if attrs.key?(:map_embed)
      attrs[:whatsapp_number] = attrs[:whatsapp_number].to_s.delete("^0-9") if attrs.key?(:whatsapp_number)
      if @setting.update(attrs)
        redirect_to admin_settings_path, notice: "تم حفظ الإعدادات."
      else
        render :show, status: :unprocessable_entity
      end
    end

    # Accept either a bare embed URL or a full <iframe …> tag pasted from Google Maps.
    def self.extract_map_src(value)
      v = value.to_s.strip
      return v unless v.include?("<iframe")
      v[/src\s*=\s*["']([^"']+)["']/i, 1].to_s.strip
    end

    private

    def setting_params
      params.require(:setting).permit(:whatsapp_display, :whatsapp_number, :phone, :email,
                                      :address_ar, :address_en, :hours_ar, :hours_en, :map_embed,
                                      :rfq_response_ar, :rfq_response_en, :notify_emails, :founded)
    end
  end
end
