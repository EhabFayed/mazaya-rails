require "test_helper"

class AdminDashboardTest < ActionDispatch::IntegrationTest
  test "redirects anonymous visitors to login" do
    get admin_root_path
    assert_redirected_to admin_login_path
  end

  test "logs in and shows the dashboard" do
    user = sign_in_admin
    assert_redirected_to admin_root_path
    get admin_root_path
    assert_response :success
    assert_match user.name, response.body
    assert_match "ناقص قبل الإطلاق", response.body
  end

  test "rejects wrong credentials" do
    User.create!(name: "x", email: "x@test.local", password: "secret-pass-123", role: "admin")
    post admin_login_path, params: { email: "x@test.local", password: "nope" }
    assert_response :unprocessable_entity
  end

  test "sales role does not see content sections" do
    sign_in_admin(role: "sales")
    get admin_root_path
    assert_response :success
    assert_no_match "الحلول المخصصة", response.body
    get admin_products_path
    assert_redirected_to admin_root_path
  end

  test "site data is served from the database with cache invalidation" do
    Category.create!(slug: "test-cat", name_ar: "فئة تجريبية", name_en: "Test Category")
    Current.reset
    assert SiteData::CATEGORIES.any? { |c| c[:slug] == "test-cat" }
    Category.find_by!(slug: "test-cat").update!(name_ar: "فئة معدّلة")
    Current.reset
    assert_equal "فئة معدّلة", SiteData.category("test-cat")[:name].to_s
  end
end
