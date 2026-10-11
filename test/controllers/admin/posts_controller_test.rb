require "test_helper"

class Admin::PostsControllerTest < ActionDispatch::IntegrationTest
  def image = Rack::Test::UploadedFile.new(Rails.root.join("public/assets/proj-tower.jpg"), "image/jpeg")

  test "sales role is redirected away" do
    sign_in_admin(role: "sales")
    get admin_posts_path
    assert_redirected_to admin_root_path
  end

  test "index filters by type and topic" do
    sign_in_admin
    Post.create!(title_ar: "خبر واحد", post_type: "news", topic: "news")
    Post.create!(title_ar: "مقال واحد", post_type: "article", topic: "safety")
    get admin_posts_path
    assert_response :success
    assert_match "خبر واحد", response.body
    assert_match "مقال واحد", response.body
    get admin_posts_path(type: "article")
    assert_match "مقال واحد", response.body
    assert_no_match(/خبر واحد/, response.body)
    get admin_posts_path(topic: "news")
    assert_match "خبر واحد", response.body
    assert_no_match(/مقال واحد/, response.body)
    get new_admin_post_path(type: "article")
    assert_response :success
  end

  test "create with image, rows and related slugs" do
    sign_in_admin
    cat = Category.create!(name_ar: "سلالم", slug: "ladders-p")
    prod = Product.create!(name_ar: "سلم", slug: "ladder-p", category: cat)
    safety = SafetyArticle.create!(name_ar: "سلامة", slug: "safety-p")
    assert_difference("Post.count", 1) do
      post admin_posts_path, params: { post: {
        post_type: "article", topic: "safety", category_ar: "دليل", title_ar: "عنوان", title_en: "Title", slug: "title-p",
        excerpt_ar: "مقتطف", body_ar: "فقرة ١\n\nفقرة ٢", published_on: "2026-01-15", featured: "1", template: "0", published: "1", position: 2,
        image: image, related_slugs: [ "", prod.slug ], related_safety_slug: safety.slug,
        points: { "0" => { title_ar: "نقطة", title_en: "Point", desc_ar: "وصف", desc_en: "" }, "1" => { title_ar: "", title_en: "", desc_ar: "", desc_en: "" } },
        checklist: { "0" => { text_ar: "افحص", text_en: "Check" } }
      } }
    end
    p = Post.last
    assert_redirected_to edit_admin_post_path(p)
    assert_equal "article", p.post_type
    assert_equal Date.new(2026, 1, 15), p.published_on
    assert_equal [ prod.slug ], p.related_slugs
    assert_equal safety.slug, p.related_safety_slug
    assert_equal 1, p.points.size, "empty rows are dropped"
    assert_equal "نقطة", p.points.first["title_ar"]
    assert_equal 1, p.checklist.size
    assert_equal 2, p.paragraphs.size
    assert p.image.attached?
    get edit_admin_post_path(p)
    assert_response :success
    assert_match "افحص", response.body
  end

  test "update clears rows when all are removed, invalid update re-renders, destroy removes" do
    sign_in_admin
    p = Post.create!(title_ar: "قديم", points: [ { "title_ar" => "x" } ])
    patch admin_post_path(p), params: { post: { title_ar: "جديد", post_type: "news" } }
    assert_redirected_to edit_admin_post_path(p)
    p.reload
    assert_equal "جديد", p.title_ar
    assert_equal [], p.points
    patch admin_post_path(p), params: { post: { title_ar: "" } }
    assert_response :unprocessable_entity
    assert_difference("Post.count", -1) { delete admin_post_path(p) }
    assert_redirected_to admin_posts_path
  end
end
