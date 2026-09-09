require "test_helper"

class Admin::TranslationsControllerTest < ActionDispatch::IntegrationTest
  test "index renders the page selector and rows for the selected page" do
    sign_in_admin(role: "editor")
    get admin_translations_path(page: "home")
    assert_response :success
    assert_select "a.filter.active", text: /الرئيسية/
    assert_select "a.filter", text: /تواصل/
    assert_select ".tr-key", text: "home.hero.badge"
    assert_select "textarea[name='translations[home.hero.badge][ar]']", text: I18n.t("home.hero.badge", locale: :ar)
    assert_select "textarea[name='translations[home.hero.badge][en]']", text: I18n.t("home.hero.badge", locale: :en)
    # arrays are read-only
    assert_select ".tr-key", text: "home.why.cards"
    assert_select "textarea[name='translations[home.why.cards][ar]']", count: 0
    assert_match "يُعدَّل من ملف اللغة", response.body
    # skipped branches never appear
    assert_select ".tr-key", text: /^date\./, count: 0
    assert_select ".tr-key", text: /^admin\./, count: 0
  end

  test "search filters across pages by key or text" do
    sign_in_admin(role: "editor")
    get admin_translations_path(q: "hero.badge")
    assert_response :success
    assert_select ".tr-key", text: /\Ahome\.hero\.badge/
    assert_select ".tr-key", text: /\Ahome\.hero\.h1/, count: 0
    assert_select "form[action=?]", admin_translation_path("search")
  end

  test "override, revert, and the public page reflects the override" do
    sign_in_admin(role: "editor")
    default_ar = I18n.t("home.hero.badge", locale: :ar)
    default_en = I18n.t("home.hero.badge", locale: :en)

    patch admin_translation_path("home"), params: { translations: {
      "home.hero.badge" => { "ar" => "شارة جديدة للاختبار", "en" => default_en },
      "home.hero.h1" => { "ar" => I18n.t("home.hero.h1", locale: :ar), "en" => "" }
    } }
    assert_redirected_to admin_translations_path(page: "home")
    assert_equal 1, Translation.count
    t = Translation.first
    assert_equal [ "ar", "home.hero.badge", "شارة جديدة للاختبار" ], [ t.locale, t.key, t.value ]

    get "/"
    assert_response :success
    assert_match "شارة جديدة للاختبار", response.body
    assert_no_match default_ar, response.body
    get "/en"
    assert_match default_en, response.body

    get admin_translations_path(page: "home")
    assert_select "textarea[name='translations[home.hero.badge][ar]']", text: "شارة جديدة للاختبار"
    assert_select ".tr-default", text: /#{Regexp.escape(default_ar)}/
    assert_select "input[name='revert[home.hero.badge]']"

    # Saving the default text back deletes the override
    patch admin_translation_path("home"), params: { translations: { "home.hero.badge" => { "ar" => default_ar, "en" => default_en } } }
    assert_equal 0, Translation.count

    # Revert checkbox deletes the override even if a value is submitted
    patch admin_translation_path("home"), params: { translations: { "home.hero.badge" => { "ar" => "مؤقت", "en" => default_en } } }
    assert_equal 1, Translation.count
    patch admin_translation_path("home"), params: { revert: { "home.hero.badge" => "1" }, translations: { "home.hero.badge" => { "ar" => "مؤقت", "en" => default_en } } }
    assert_equal 0, Translation.count
    get "/"
    assert_match default_ar, response.body
    assert_no_match "مؤقت", response.body
  end

  test "unknown keys are ignored" do
    sign_in_admin(role: "editor")
    patch admin_translation_path("home"), params: { translations: { "nope.key" => { "ar" => "x" } } }
    assert_equal 0, Translation.count
  end

  test "sales cannot access translations" do
    sign_in_admin(role: "sales")
    get admin_translations_path
    assert_redirected_to admin_root_path
  end
end
