# Reference projects: main image, gallery, linked solutions, detail fields.
module Admin
  class ProjectsController < BaseController
    before_action :require_content!
    before_action :set_project, only: %i[edit update destroy purge_gallery_image]

    def admin_section = "projects"

    def index
      @projects = Project.ordered.includes(:solutions).with_attached_image
    end

    def new
      @project = Project.new(published: true)
      load_options
    end

    def create
      @project = Project.new(project_params)
      if @project.save
        attach_gallery
        redirect_to edit_admin_project_path(@project), notice: "تم الحفظ."
      else
        load_options
        render :new, status: :unprocessable_entity
      end
    end

    def edit = load_options

    def update
      if @project.update(project_params)
        attach_gallery
        redirect_to edit_admin_project_path(@project), notice: "تم الحفظ."
      else
        load_options
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @project.destroy
      redirect_to admin_projects_path, notice: "تم حذف المشروع."
    end

    # DELETE /admin/projects/:id/purge_gallery_image?blob_id=
    def purge_gallery_image
      @project.gallery_attachments.find_by(blob_id: params[:blob_id])&.purge
      redirect_to edit_admin_project_path(@project), notice: "تم حذف الصورة."
    end

    private

    def set_project = @project = Project.find(params[:id])

    def load_options = @solutions = Solution.ordered

    # New gallery files are appended — never replace the existing set.
    def attach_gallery
      files = Array(params.dig(:project, :gallery)).reject(&:blank?)
      @project.gallery.attach(files) if files.any?
    end

    def project_params
      attrs = params.require(:project).permit(
        :name_ar, :name_en, :slug, :type_ar, :type_en, :featured, :published, :position, :image,
        :product_supplied_ar, :product_supplied_en, :scope_ar, :scope_en, :quantity_ar, :quantity_en, :year,
        :requirements_ar, :requirements_en, :solution_ar, :solution_en, solution_ids: []
      )
      attrs.delete(:image) if attrs[:image].blank?
      attrs
    end
  end
end
