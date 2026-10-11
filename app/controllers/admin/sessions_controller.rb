module Admin
  class SessionsController < BaseController
    skip_before_action :require_login
    layout "admin_auth"

    def new
      redirect_to admin_root_path if current_user
    end

    def create
      user = User.active.find_by("lower(email) = ?", params[:email].to_s.strip.downcase)
      if user&.authenticate(params[:password])
        reset_session
        session[:user_id] = user.id
        user.update_column(:last_login_at, Time.current)
        redirect_to session.delete(:return_to) || admin_root_path, notice: "أهلًا #{user.name}."
      else
        flash.now[:alert] = "البريد أو كلمة المرور غير صحيحة."
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      reset_session
      redirect_to admin_login_path, notice: "تم تسجيل الخروج."
    end
  end
end
