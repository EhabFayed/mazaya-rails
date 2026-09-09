require "test_helper"

class Admin::CategoriesControllerTest < ActionDispatch::IntegrationTest
  IMAGE = Rails.root.join("public/assets/products/mml-000-front.jpg")

  setup do
    @category = Category.create!(name_ar: "سلالم", name_en: "Ladders", slug: "ladders", spec_labels: [ { "label_ar" => "الخامة", "label_en" => "Material" } ])
    @sub = @category.subcategories.create!(name_ar: "سلم مفرد", slug: "single")
    sign_in_admin
  end

  test "index shows counts" do
    Product.create!(category: @category, name_ar: "منتج", slug: "p1")
    get admin_categories_path
    assert_response :success
    assert_includes response.body, "سلالم"
    assert_select "tbody tr", 1
    assert_select "tbody tr td:nth-child(4)", text: "1"
    assert_select "tbody tr td:nth-child(5) a", text: "1"
  end

  test "new and edit render the form with blank subcategory rows" do
    get new_admin_category_path
    assert_response :success
    assert_select "input[name='category[subcategories_attributes][0][name_ar]']"
    assert_select "input[name='category[subcategories_attributes][2][name_ar]']"

    get edit_admin_category_path(@category)
    assert_response :success
    assert_select "input[name='category[subcategories_attributes][0][name_ar]'][value='سلم مفرد']"
    assert_select "input[name='category[subcategories_attributes][0][_destroy]']"
    assert_select "input[name='category[subcategories_attributes][3][name_ar]']"
    assert_select "[data-rows=spec_labels] input[value='الخامة']"
  end

  test "create with nested subcategories, spec labels and image" do
    Document.create!(key: "catalog-carts", doc_type: "catalog", title_ar: "كتالوج العربات")
    assert_difference([ "Category.count", "Subcategory.count" ], 1) do
      post admin_categories_path, params: { category: {
        name_ar: "عربات", name_en: "Carts", slug: "", desc_ar: "وصف", b2c_ar: "أفراد", b2b_ar: "شركات", about_ar: "عن", finder_ar: "تبحث عن عربة؟",
        catalog_key: "catalog-carts", position: "2", published: "1",
        image: fixture_file_upload(IMAGE, "image/jpeg"),
        spec_labels: { "0" => { label_ar: "الحمولة", label_en: "Load" }, "1" => { label_ar: "", label_en: "" } },
        subcategories_attributes: { "0" => { name_ar: "عربة يد", name_en: "Hand Cart", slug: "", position: "1" }, "1" => { name_ar: "", name_en: "", slug: "", position: "" } }
      } }
    end
    c = Category.find_by!(slug: "carts")
    assert_redirected_to edit_admin_category_path(c)
    assert c.image.attached?
    assert_equal "catalog-carts", c.catalog_key
    assert_equal [ { "label_ar" => "الحمولة", "label_en" => "Load" } ], c.spec_labels
    assert_equal "hand-cart", c.subcategories.first.slug
  end

  test "update edits and destroys nested subcategories" do
    patch admin_category_path(@category), params: { category: {
      name_ar: "سلالم", spec_labels: {},
      subcategories_attributes: { "0" => { id: @sub.id, name_ar: "سلم مفرد", _destroy: "1" }, "1" => { name_ar: "سلم مزدوج", name_en: "Double", slug: "" } }
    } }
    assert_redirected_to edit_admin_category_path(@category)
    @category.reload
    assert_equal [ "سلم مزدوج" ], @category.subcategories.map(&:name_ar)
    assert_equal [], @category.spec_labels
  end

  test "invalid update re-renders with errors" do
    patch admin_category_path(@category), params: { category: { name_ar: "" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "destroy is blocked while products exist, allowed otherwise" do
    Product.create!(category: @category, name_ar: "منتج", slug: "p1")
    assert_no_difference("Category.count") { delete admin_category_path(@category) }
    assert_redirected_to edit_admin_category_path(@category)
    assert_match(/لا يمكن الحذف/, flash[:alert])

    Product.delete_all
    assert_difference("Category.count", -1) { delete admin_category_path(@category) }
    assert_redirected_to admin_categories_path
  end

  test "sales role is redirected away" do
    delete admin_logout_path
    sign_in_admin(role: "sales")
    get admin_categories_path
    assert_redirected_to admin_root_path
  end
end
