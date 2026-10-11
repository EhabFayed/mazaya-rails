# Safety guides: summary + bilingual points/checklist + related products.
module Admin
  class SafetyArticlesController < BaseController
    before_action :require_content!
    before_action :set_article, only: %i[edit update destroy]

    def admin_section = "safety_articles"

    def index
      @articles = SafetyArticle.ordered
    end

    def new
      @article = SafetyArticle.new(published: true)
      load_options
    end

    def create
      @article = SafetyArticle.new(article_params)
      if @article.save
        redirect_to edit_admin_safety_article_path(@article), notice: "تم الحفظ."
      else
        load_options
        render :new, status: :unprocessable_entity
      end
    end

    def edit = load_options

    def update
      if @article.update(article_params)
        redirect_to edit_admin_safety_article_path(@article), notice: "تم الحفظ."
      else
        load_options
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @article.destroy
      redirect_to admin_safety_articles_path, notice: "تم حذف الدليل."
    end

    private

    def set_article = @article = SafetyArticle.find(params[:id])

    def load_options = @products = Product.ordered.includes(:category)

    def article_params
      raw = params.require(:safety_article)
      attrs = raw.permit(:name_ar, :name_en, :slug, :summary_ar, :summary_en, :position, :published, related_slugs: [])
      attrs[:related_slugs] = Array(attrs[:related_slugs]).reject(&:blank?) if raw.key?(:related_slugs)
      attrs[:points]    = ContentRecord.rows(raw[:points])    if raw.key?(:points) || action_name == "update"
      attrs[:checklist] = ContentRecord.rows(raw[:checklist]) if raw.key?(:checklist) || action_name == "update"
      attrs
    end
  end
end
