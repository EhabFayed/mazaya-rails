# Product categories with nested subcategories and spec label rows.
module Admin
  class CategoriesController < BaseController
    BLANK_SUBCATEGORY_ROWS = 3

    before_action :require_content!
    before_action :set_category, only: %i[edit update destroy]

    def admin_section = "categories"

    def index
      @categories  = Category.ordered.with_attached_image
      @sub_counts  = Subcategory.group(:category_id).count
      @prod_counts = Product.group(:category_id).count
    end

    def new
      @category = Category.new(published: true)
      load_form
    end

    def edit = load_form

    def create
      @category = Category.new
      if save_category
        redirect_to edit_admin_category_path(@category), notice: "تم الحفظ."
      else
        load_form
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if save_category
        redirect_to edit_admin_category_path(@category), notice: "تم الحفظ."
      else
        load_form
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @category.destroy
        redirect_to admin_categories_path, notice: "تم حذف الفئة."
      else
        redirect_to edit_admin_category_path(@category), alert: "لا يمكن الحذف: #{@category.errors.full_messages.join('، ')}"
      end
    end

    private

    def set_category = @category = Category.find(params[:id])

    def load_form
      @catalog_docs = Document.where(doc_type: %w[catalog technical]).ordered
      BLANK_SUBCATEGORY_ROWS.times { @category.subcategories.build }
    end

    def category_params
      params.require(:category).permit(:name_ar, :name_en, :slug, :desc_ar, :desc_en, :b2c_ar, :b2c_en, :b2b_ar, :b2b_en,
                                       :about_ar, :about_en, :finder_ar, :finder_en, :catalog_key, :position, :published, :image,
                                       subcategories_attributes: %i[id name_ar name_en slug position _destroy])
    end

    def save_category
      raw = params.require(:category)
      attrs = category_params
      # Slugs default from the English name (Arabic names don't parameterize).
      attrs[:subcategories_attributes]&.each_value { |sa| sa[:slug] = sa[:name_en].to_s.parameterize if sa[:slug].blank? && sa[:name_en].present? }
      @category.assign_attributes(attrs)
      @category.slug = @category.name_en.to_s.parameterize if @category.slug.blank?
      @category.spec_labels = ContentRecord.rows(raw[:spec_labels])
      @category.save
    end
  end
end
