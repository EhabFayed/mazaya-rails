# Admin accounts. Only admins manage users; any logged-in user may edit
# their own name/password (not role/active/email).
module Admin
  class UsersController < BaseController
    ROLE_LABELS = { "admin" => "مدير", "editor" => "محرر", "sales" => "مبيعات" }.freeze

    before_action :require_admin!, except: [ :edit, :update ]
    before_action :set_user, only: [ :show, :edit, :update, :destroy ]
    before_action :require_admin_or_self!, only: [ :edit, :update ]

    def index
      @users = User.order(:name)
    end

    def show = redirect_to(edit_admin_user_path(@user))

    def new
      @user = User.new(role: "editor", active: true)
    end

    def create
      @user = User.new(user_params)
      if @user.save
        redirect_to admin_users_path, notice: "تمت إضافة المستخدم."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @user.update(user_params)
        redirect_to(current_user.admin? ? admin_users_path : admin_root_path, notice: "تم حفظ التغييرات.")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @user == current_user
        redirect_to admin_users_path, alert: "لا يمكنك حذف حسابك الحالي."
      elsif @user.admin? && User.where(role: "admin").where.not(id: @user.id).none?
        redirect_to admin_users_path, alert: "لا يمكن حذف آخر مدير في النظام."
      else
        @user.destroy
        redirect_to admin_users_path, notice: "تم حذف المستخدم."
      end
    end

    private

    def set_user = @user = User.find(params[:id])

    def require_admin_or_self!
      return if current_user.admin? || @user == current_user
      redirect_to admin_root_path, alert: "ليست لديك صلاحية لهذا القسم."
    end

    def user_params
      allowed = current_user.admin? ? [ :name, :email, :role, :active ] : [ :name ]
      attrs = params.require(:user).permit(*allowed, :password, :password_confirmation)
      # Leave the password untouched when the field is left blank.
      if attrs[:password].blank?
        attrs.delete(:password)
        attrs.delete(:password_confirmation)
      end
      # An admin can't demote/deactivate themselves (they'd lose access).
      attrs.extract!(:role, :active) if @user && @user == current_user
      attrs
    end
  end
end
