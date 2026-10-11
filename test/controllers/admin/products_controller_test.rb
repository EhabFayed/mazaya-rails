require "test_helper"

class Admin::ProductsControllerTest < ActionDispatch::IntegrationTest
  IMAGE = Rails.root.join("public/assets/products/mml-000-front.jpg")

  setup do
    @category = Category.create!(name_ar: "سلالم", name_en: "Ladders", slug: "ladders")
    @sub      = @category.subcategories.create!(name_ar: "سلم مفرد", name_en: "Single", slug: "single")
    @other    = Category.create!(name_ar: "عربات", name_en: "Carts", slug: "carts")
    @other_sub = @other.subcategories.create!(name_ar: "عربة يد", slug: "hand")
    @product  = Product.create!(category: @category, subcategory: @sub, name_ar: "سلم مفرد ٣ م", name_en: "Single Ladder 3m", code: "MML-100", slug: "single-ladder-3m")
    sign_in_admin
  end

  test "index lists, searches and filters" do
    Product.create!(category: @other, name_ar: "عربة نقل", code: "CRT-1", kind: "custom", published: false)
    get admin_products_path
    assert_response :success
    assert_includes response.body, "سلم مفرد ٣ م"
    assert_includes response.body, "عربة نقل"

    get admin_products_path(q: "MML")
    assert_includes response.body, "سلم مفرد ٣ م"
    assert_not_includes response.body, "عربة نقل"

    get admin_products_path(category_id: @other.id, kind: "custom", published: "0")
    assert_not_includes response.body, "سلم مفرد ٣ م"
    assert_includes response.body, "عربة نقل"
  end

  test "new and edit render the form" do
    get new_admin_product_path
    assert_response :success
    assert_select "form#productForm"
    get edit_admin_product_path(@product)
    assert_response :success
    assert_select "input[name='product[name_ar]'][value='سلم مفرد ٣ م']"
    assert_select "[data-rows=features]"
    assert_select "[data-rows=sizes]"
    assert_select "form#deleteProduct"
  end

  test "create saves scalars, JSON rows and related slugs" do
    assert_difference("Product.count", 1) do
      post admin_products_path, params: { product: {
        name_ar: "سلم منصة", name_en: "Platform Ladder", code: "MML-200", slug: "", category_id: @category.id, subcategory_id: @sub.id,
        kind: "ready", popular: "1", published: "1", position: "3", summary_ar: "ملخص",
        features: { "0" => { title_ar: "خفيف", title_en: "Light", desc_ar: "", desc_en: "" }, "1" => { title_ar: "", title_en: "", desc_ar: "", desc_en: "" } },
        specs: { "0" => { label_ar: "الخامة", label_en: "Material", value_ar: "ألومنيوم", value_en: "Aluminium" } },
        size_cols: { "0" => { col_ar: "الكود", col_en: "Code" }, "1" => { col_ar: "الطول", col_en: "Height" } },
        sizes: { "0" => { c0: "MML-200-3", c1: "3 m", c2: "", c3: "", c4: "", c5: "" } },
        faq: { "0" => { q_ar: "س؟", q_en: "Q?", a_ar: "ج", a_en: "A" } },
        related_slugs: [ "", @product.slug ], safety_slug: ""
      } }
    end
    p = Product.find_by!(code: "MML-200")
    assert_redirected_to edit_admin_product_path(p)
    assert_equal "platform-ladder", p.slug
    assert_equal 1, p.features.size, "blank rows are dropped"
    assert_equal "خفيف", p.features.first["title_ar"]
    assert_equal "Aluminium", p.specs.first["value_en"]
    assert_equal 2, p.size_cols.size
    assert_equal "3 m", p.sizes.first["c1"]
    assert_equal [ @product.slug ], p.related_slugs
    assert p.popular
    assert_equal 3, p.position
    follow_redirect!
    assert_includes response.body, "تم الحفظ."
  end

  test "create re-renders with errors when invalid" do
    assert_no_difference("Product.count") do
      post admin_products_path, params: { product: { name_ar: "", category_id: @category.id, kind: "ready" } }
    end
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "update rejects a subcategory from another category" do
    patch admin_product_path(@product), params: { product: { name_ar: @product.name_ar, category_id: @category.id, subcategory_id: @other_sub.id, kind: "ready" } }
    assert_response :unprocessable_entity
    assert_includes response.body, "لا تنتمي لهذه الفئة"
    assert_equal @sub, @product.reload.subcategory
  end

  test "update attaches images without replacing existing ones, then labels and purges them" do
    patch admin_product_path(@product), params: { product: { name_ar: @product.name_ar, category_id: @category.id, kind: "ready", images: [ fixture_file_upload(IMAGE, "image/jpeg") ] } }
    assert_redirected_to edit_admin_product_path(@product)
    assert_equal 1, @product.reload.images.count

    patch admin_product_path(@product), params: { product: { name_ar: @product.name_ar, category_id: @category.id, kind: "ready", images: [ fixture_file_upload(IMAGE, "image/jpeg") ] } }
    assert_equal 2, @product.reload.images.count, "second upload is appended, not replacing"

    first_blob = @product.images.first.blob
    patch admin_product_path(@product), params: { product: { name_ar: @product.name_ar, category_id: @category.id, kind: "ready", image_labels: { first_blob.id.to_s => { label_ar: "واجهة", label_en: "Front" } } } }
    assert_equal({ "label_ar" => "واجهة", "label_en" => "Front" }, @product.reload.image_labels[first_blob.id.to_s])

    get edit_admin_product_path(@product)
    assert_select ".img-card", 2
    assert_select "input[name='product[image_labels][#{first_blob.id}][label_ar]'][value='واجهة']"
    assert_select "form#purge-#{first_blob.id}"

    delete purge_image_admin_product_path(@product, blob_id: first_blob.id)
    assert_redirected_to edit_admin_product_path(@product)
    assert_equal 1, @product.reload.images.count
    assert_nil @product.image_labels[first_blob.id.to_s]
  end

  test "update attaches tds and guide files" do
    pdf = fixture_file_upload(Rails.root.join("public/downloads/placeholder.pdf"), "application/pdf")
    patch admin_product_path(@product), params: { product: { name_ar: @product.name_ar, category_id: @category.id, kind: "ready", tds: pdf, guide: pdf } }
    assert @product.reload.tds.attached?
    assert @product.guide.attached?
    get edit_admin_product_path(@product)
    assert_includes response.body, "placeholder.pdf"
  end

  test "reorder updates position" do
    patch reorder_admin_product_path(@product), params: { position: 9 }, headers: { "HTTP_REFERER" => admin_products_path }
    assert_redirected_to admin_products_path
    assert_equal 9, @product.reload.position
  end

  test "destroy removes the product" do
    assert_difference("Product.count", -1) { delete admin_product_path(@product) }
    assert_redirected_to admin_products_path
  end

  test "import page renders and serves a CSV template" do
    get import_admin_products_path
    assert_response :success
    assert_select "input[type=file][name=file]"
    get import_admin_products_path(format: :csv)
    assert_response :success
    assert_match(/text\/csv/, response.content_type)
    assert_includes response.body, "category_ar,category_en"
  end

  test "import dry run reports without saving, real import saves" do
    csv = fixture_file_upload("products_import.csv", "text/csv")
    assert_no_difference("Product.count") do
      post import_admin_products_path, params: { file: csv, dry_run: "1" }
    end
    assert_response :success
    assert_includes response.body, "نتيجة الفحص"
    assert_includes response.body, "جديد: 2" # MML-100 already exists (setup) -> updated
    assert_includes response.body, "محدَّث: 1"
    assert_includes response.body, "الاسم العربي مطلوب"

    assert_difference("Product.count", 2) do
      post import_admin_products_path, params: { file: fixture_file_upload("products_import.csv", "text/csv"), dry_run: "0" }
    end
    assert_response :success
    assert_includes response.body, "تم الاستيراد"
    assert Product.exists?(code: "MML-101")
    assert_equal @category, Product.find_by!(code: "MML-100").category, "matches the existing category by name_ar"
  end

  test "import without a file shows an alert" do
    post import_admin_products_path, params: { dry_run: "1" }
    assert_response :unprocessable_entity
    assert_includes response.body, "اختر ملف"
  end

  test "public product page renders saved sizes, TDS and guide" do
    pdf = fixture_file_upload(Rails.root.join("public/downloads/placeholder.pdf"), "application/pdf")
    patch admin_product_path(@product), params: { product: {
      name_ar: @product.name_ar, category_id: @category.id, kind: "ready", published: "1", tds: pdf, guide: pdf,
      size_cols: { "0" => { col_ar: "الكود", col_en: "Code" }, "1" => { col_ar: "الطول", col_en: "Height" } },
      sizes: { "0" => { c0: "MML-100-3", c1: "٣ م", c2: "ignored", c3: "", c4: "", c5: "" }, "1" => { c0: "MML-100-4", c1: "٤ م", c2: "", c3: "", c4: "", c5: "" } }
    } }
    assert_redirected_to edit_admin_product_path(@product)
    get "/products/ladders/single-ladder-3m"
    assert_response :success
    assert_select "#specs table.spec-table tbody tr", 2
    assert_select "#specs td", text: "MML-100-3"
    assert_select "#specs td", text: "٤ م"
    assert_select "#specs td", text: "ignored", count: 0 # only as many cells as size_cols
    assert_select "#specs .pending", count: 0 # no size placeholder rows once real sizes exist
    assert_select "a[data-gate=tds][href^='/rails/active_storage/blobs']"
    assert_select "#downloads a.card-link[href^='/rails/active_storage/blobs']"
  end

  test "sales role is redirected away" do
    delete admin_logout_path
    sign_in_admin(role: "sales")
    get admin_products_path
    assert_redirected_to admin_root_path
    post admin_products_path, params: { product: { name_ar: "x", category_id: @category.id, kind: "ready" } }
    assert_redirected_to admin_root_path
  end

  test "guests are sent to login" do
    delete admin_logout_path
    get admin_products_path
    assert_redirected_to admin_login_path
  end
end
