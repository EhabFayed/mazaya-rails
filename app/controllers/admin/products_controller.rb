# Product catalog CRUD: bilingual fields, JSON rows (features/specs/sizes/faq),
# image gallery with labels, technical files, and Excel/CSV import.
module Admin
  class ProductsController < BaseController
    KIND_LABELS = { "ready" => "جاهز", "custom" => "حسب الطلب" }.freeze
    ROW_FIELDS  = %i[features applications specs size_cols sizes faq].freeze

    before_action :require_content!
    before_action :set_product, only: %i[edit update destroy purge_image reorder]

    def admin_section = "products"

    def index
      @q           = params[:q].to_s.strip
      @category_id = params[:category_id].presence
      @kind        = Product::KINDS.include?(params[:kind]) ? params[:kind] : nil
      @published   = %w[1 0].include?(params[:published]) ? params[:published] : nil
      scope = Product.ordered.includes(:category, :subcategory, images_attachments: :blob)
      scope = scope.where("products.name_ar ILIKE :q OR products.name_en ILIKE :q OR products.code ILIKE :q", q: "%#{@q}%") if @q.present?
      scope = scope.where(category_id: @category_id) if @category_id
      scope = scope.where(kind: @kind) if @kind
      scope = scope.where(published: @published == "1") if @published
      @products, @page, @pages = helpers.paginate(scope)
      @categories = Category.ordered
    end

    def new
      @product = Product.new(kind: "ready", published: true)
      load_form
    end

    def edit = load_form

    def create
      @product = Product.new
      if save_product
        redirect_to edit_admin_product_path(@product), notice: "تم الحفظ."
      else
        load_form
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if save_product
        redirect_to edit_admin_product_path(@product), notice: "تم الحفظ."
      else
        load_form
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @product.destroy
      redirect_to admin_products_path, notice: "تم حذف المنتج."
    end

    def purge_image
      attachment = @product.images_attachments.find_by(blob_id: params[:blob_id])
      if attachment
        attachment.purge
        @product.update_column(:image_labels, @product.image_labels.except(params[:blob_id].to_s))
        @product.touch
      end
      redirect_to edit_admin_product_path(@product), notice: "تم حذف الصورة."
    end

    def reorder
      @product.update(position: params[:position].to_i)
      respond_to do |format|
        format.html { redirect_back fallback_location: admin_products_path, notice: "تم تحديث الترتيب." }
        format.json { head :no_content }
      end
    end

    # GET /admin/products/import (+ .csv template)
    def import
      respond_to do |format|
        format.html
        format.csv { send_data ProductImporter.template_csv, filename: "mazaya-products-template.csv", type: "text/csv; charset=utf-8" }
      end
    end

    # POST /admin/products/import
    def run_import
      file = params[:file]
      if file.blank? || !file.respond_to?(:path)
        flash.now[:alert] = "اختر ملف Excel أو CSV أولًا."
        return render :import, status: :unprocessable_entity
      end
      @dry_run = params[:dry_run] == "1"
      @result  = ProductImporter.new(file.path, filename: file.original_filename, dry_run: @dry_run).run
      render :import
    rescue ProductImporter::Error => e
      flash.now[:alert] = e.message
      render :import, status: :unprocessable_entity
    end

    private

    def set_product = @product = Product.find(params[:id])

    def load_form
      @categories       = Category.ordered.includes(:subcategories)
      @subcategory_opts = @categories.map { |c| [ c.name_ar, c.subcategories.map { |s| [ s.name_ar, s.id ] } ] }.reject { |_, l| l.empty? }
      @safety_articles  = SafetyArticle.ordered
      @other_products   = Product.ordered.where.not(id: @product.id)
    end

    def product_params
      params.require(:product).permit(:name_ar, :name_en, :summary_ar, :summary_en, :code, :slug, :category_id, :subcategory_id,
                                      :kind, :popular, :published, :position, :safety_slug)
    end

    # Scalars via strong params; JSON rows normalised; files attached after save
    # (never passed through `update`, which would replace the whole gallery).
    def save_product
      raw = params.require(:product)
      @product.assign_attributes(product_params)
      @product.slug = @product.name_en.to_s.parameterize if @product.slug.blank? # same rule as the admin.js slug helper
      ROW_FIELDS.each { |f| @product[f] = ContentRecord.rows(raw[f]) }
      @product.related_slugs = Array(raw[:related_slugs]).compact_blank
      if raw[:image_labels].respond_to?(:to_unsafe_h)
        incoming = raw[:image_labels].to_unsafe_h.transform_values { |v| v.to_h.slice("label_ar", "label_en") }
        @product.image_labels = @product.image_labels.merge(incoming)
      end
      return false unless @product.save

      images = Array(raw[:images]).reject(&:blank?)
      @product.images.attach(images) if images.any?
      @product.tds.attach(raw[:tds])     if raw[:tds].present?
      @product.guide.attach(raw[:guide]) if raw[:guide].present?
      true
    end
  end
end
