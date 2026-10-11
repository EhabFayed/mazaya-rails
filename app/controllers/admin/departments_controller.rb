# Contact-page departments (sales, export, support...).
module Admin
  class DepartmentsController < BaseController
    before_action :require_content!
    before_action :set_department, only: %i[edit update destroy]

    def admin_section = "departments"

    def index
      @departments = Department.ordered
    end

    def new
      @department = Department.new
    end

    def create
      @department = Department.new(department_params)
      if @department.save
        redirect_to edit_admin_department_path(@department), notice: "تم الحفظ."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @department.update(department_params)
        redirect_to edit_admin_department_path(@department), notice: "تم الحفظ."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @department.destroy
      redirect_to admin_departments_path, notice: "تم حذف القسم."
    end

    private

    def set_department = @department = Department.find(params[:id])

    def department_params
      params.require(:department).permit(:key, :name_ar, :name_en, :desc_ar, :desc_en, :phone, :email, :position)
    end
  end
end
