require "test_helper"

class Admin::SafetyArticlesControllerTest < ActionDispatch::IntegrationTest
  test "sales role is redirected away" do
    sign_in_admin(role: "sales")
    get admin_safety_articles_path
    assert_redirected_to admin_root_path
  end

  test "index and new render" do
    sign_in_admin
    SafetyArticle.create!(name_ar: "سلامة السلالم")
    get admin_safety_articles_path
    assert_response :success
    assert_match "سلامة السلالم", response.body
    get new_admin_safety_article_path
    assert_response :success
  end

  test "create with rows and related products, then update and destroy" do
    sign_in_admin
    cat = Category.create!(name_ar: "سلالم", slug: "ladders-s")
    prod = Product.create!(name_ar: "سلم", slug: "ladder-s", category: cat)
    assert_difference("SafetyArticle.count", 1) do
      post admin_safety_articles_path, params: { safety_article: {
        name_ar: "استخدام السلم", name_en: "Ladder use", slug: "ladder-use-s", summary_ar: "ملخص", position: 1, published: "1",
        related_slugs: [ "", prod.slug ],
        points: { "0" => { title_ar: "ثبّت القاعدة", title_en: "Secure the base", desc_ar: "على أرض مستوية", desc_en: "" } },
        checklist: { "0" => { text_ar: "افحص الدرجات", text_en: "" }, "1" => { text_ar: "", text_en: "" } }
      } }
    end
    a = SafetyArticle.last
    assert_redirected_to edit_admin_safety_article_path(a)
    assert_equal [ prod.slug ], a.related_slugs
    assert_equal 1, a.points.size
    assert_equal 1, a.checklist.size
    get edit_admin_safety_article_path(a)
    assert_response :success
    assert_match "ثبّت القاعدة", response.body

    patch admin_safety_article_path(a), params: { safety_article: { name_ar: "محدّث", checklist: { "0" => { text_ar: "أ", text_en: "" }, "1" => { text_ar: "ب", text_en: "" } } } }
    assert_redirected_to edit_admin_safety_article_path(a)
    a.reload
    assert_equal "محدّث", a.name_ar
    assert_equal 2, a.checklist.size
    assert_equal [], a.points, "points removed from the form are cleared"

    patch admin_safety_article_path(a), params: { safety_article: { name_ar: "" } }
    assert_response :unprocessable_entity
    assert_difference("SafetyArticle.count", -1) { delete admin_safety_article_path(a) }
    assert_redirected_to admin_safety_articles_path
  end
end
