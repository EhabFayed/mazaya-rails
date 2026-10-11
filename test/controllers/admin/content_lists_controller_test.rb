require "test_helper"

class Admin::ContentListsControllerTest < ActionDispatch::IntegrationTest
  test "sales role is redirected away" do
    sign_in_admin(role: "sales")
    get admin_content_lists_path
    assert_redirected_to admin_root_path
  end

  test "index lists every schema key and creates missing rows" do
    sign_in_admin
    get admin_content_lists_path
    assert_response :success
    ContentList::SCHEMA.each do |key, meta|
      assert_match key, response.body
      assert_match meta[:label], response.body
    end
    assert_equal ContentList::SCHEMA.keys.sort, ContentList.pluck(:key).sort
  end

  test "edit renders schema columns with arabic labels" do
    sign_in_admin
    get edit_admin_content_list_path("stats")
    assert_response :success
    assert_match 'name="content_list[items][__i__][value]"', response.body
    assert_match "التسمية (عربي)", response.body
    assert_match "التسمية (EN)", response.body
    get edit_admin_content_list_path("comparison")
    assert_match "الأصلي (عربي)", response.body
    assert_match "المقلد (EN)", response.body
  end

  test "unknown key 404s" do
    sign_in_admin
    get edit_admin_content_list_path("nope")
    assert_response :not_found
  end

  test "update stores normalised rows and drops empty ones" do
    sign_in_admin
    patch admin_content_list_path("stats"), params: { content_list: { items: {
      "0" => { value: "35", suffix: "+", label_ar: "سنة خبرة", label_en: "Years", sub_ar: "", sub_en: "" },
      "1" => { value: "", suffix: "", label_ar: "", label_en: "", sub_ar: "", sub_en: "" },
      "2" => { value: "1200", suffix: "", label_ar: "مشروع", label_en: "Projects", sub_ar: "", sub_en: "" }
    } } }
    assert_redirected_to edit_admin_content_list_path("stats")
    list = ContentList.find_by!(key: "stats")
    assert_equal 2, list.items.size
    assert_equal "35", list.items.first["value"]
    assert_equal "مشروع", list.items.last["label_ar"]
    assert_equal 35, SiteData::Builder.stats.first[:value]

    patch admin_content_list_path("stats"), params: { content_list: { note: "x" } }
    assert_equal [], list.reload.items, "submitting no rows clears the list"
  end
end
