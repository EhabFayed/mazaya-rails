# Custom solutions (B2B): name, category, linked projects, hero image.
module Admin
  class SolutionsController < BaseController
    before_action :require_content!
    before_action :set_solution, only: %i[edit update destroy]

    def admin_section = "solutions"

    def index
      @solutions = Solution.ordered.includes(:category, :projects).with_attached_image
    end

    def new
      @solution = Solution.new(published: true)
      load_options
    end

    def create
      @solution = Solution.new(solution_params)
      if @solution.save
        redirect_to edit_admin_solution_path(@solution), notice: "تم الحفظ."
      else
        load_options
        render :new, status: :unprocessable_entity
      end
    end

    def edit = load_options

    def update
      if @solution.update(solution_params)
        redirect_to edit_admin_solution_path(@solution), notice: "تم الحفظ."
      else
        load_options
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @solution.destroy
      redirect_to admin_solutions_path, notice: "تم حذف الحل."
    end

    private

    def set_solution = @solution = Solution.find(params[:id])

    def load_options
      @categories = Category.ordered
      @projects = Project.ordered
    end

    def solution_params
      attrs = params.require(:solution).permit(:name_ar, :name_en, :slug, :desc_ar, :desc_en, :category_id, :position, :published, :image, project_ids: [])
      attrs.delete(:image) if attrs[:image].blank?
      attrs
    end
  end
end
