# All admin screens inherit from here: session auth, role checks, Arabic UI,
# and cache-version bumps after writes.
module Admin
  class BaseController < ActionController::Base
    layout "admin"
    protect_from_forgery with: :exception
    before_action :require_login
    before_action { I18n.locale = :ar }
    helper_method :current_user, :can?, :admin_section

    # Which sidebar section is active (override per controller).
    def admin_section = controller_name

    private

    def current_user
      @current_user ||= User.active.find_by(id: session[:user_id])
    end

    def require_login
      return if current_user
      session[:return_to] = request.fullpath if request.get?
      redirect_to admin_login_path, alert: "سجّل الدخول أولًا."
    end

    # Roles: admin (everything), editor (content), sales (leads).
    def can?(area)
      case area
      when :content then current_user&.editor?
      when :leads   then current_user&.sales?
      when :users, :settings then current_user&.admin?
      else false
      end
    end

    def require_role!(area)
      return if can?(area)
      redirect_to admin_root_path, alert: "ليست لديك صلاحية لهذا القسم."
    end

    def require_content! = require_role!(:content)
    def require_sales!   = require_role!(:leads)
    def require_admin!   = require_role!(:users)
  end
end
