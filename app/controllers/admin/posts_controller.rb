# News & articles: one table, `post_type` decides where it shows on the site.
module Admin
  class PostsController < BaseController
    before_action :require_content!
    before_action :set_post, only: %i[edit update destroy]

    def admin_section = "posts"

    def index
      @type  = Post::TYPES.include?(params[:type]) ? params[:type] : nil
      @topic = Post::TOPICS.include?(params[:topic]) ? params[:topic] : nil
      scope = Post.ordered.with_attached_image
      scope = scope.where(post_type: @type) if @type
      scope = scope.where(topic: @topic) if @topic
      @counts = Post.group(:post_type).count
      @posts, @page, @pages = helpers.paginate(scope)
    end

    def new
      @post = Post.new(post_type: Post::TYPES.include?(params[:type]) ? params[:type] : "news", topic: "news", published: true, published_on: Date.current)
      load_options
    end

    def create
      @post = Post.new(post_params)
      if @post.save
        redirect_to edit_admin_post_path(@post), notice: "تم الحفظ."
      else
        load_options
        render :new, status: :unprocessable_entity
      end
    end

    def edit = load_options

    def update
      if @post.update(post_params)
        redirect_to edit_admin_post_path(@post), notice: "تم الحفظ."
      else
        load_options
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @post.destroy
      redirect_to admin_posts_path, notice: "تم حذف المنشور."
    end

    private

    def set_post = @post = Post.find(params[:id])

    def load_options
      @products = Product.ordered.includes(:category)
      @safety_articles = SafetyArticle.ordered
    end

    def post_params
      raw = params.require(:post)
      attrs = raw.permit(:post_type, :topic, :category_ar, :category_en, :title_ar, :title_en, :slug, :excerpt_ar, :excerpt_en,
                         :body_ar, :body_en, :published_on, :featured, :template, :published, :position, :image, :related_safety_slug, related_slugs: [])
      attrs.delete(:image) if attrs[:image].blank?
      attrs[:related_slugs] = Array(attrs[:related_slugs]).reject(&:blank?) if raw.key?(:related_slugs)
      attrs[:points]    = ContentRecord.rows(raw[:points])    if raw.key?(:points) || action_name == "update"
      attrs[:checklist] = ContentRecord.rows(raw[:checklist]) if raw.key?(:checklist) || action_name == "update"
      attrs
    end
  end
end
