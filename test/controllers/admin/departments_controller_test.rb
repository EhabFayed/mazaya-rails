require "test_helper"

class Admin::DepartmentsControllerTest < ActionDispatch::IntegrationTest
  test "sales role is redirected away" do
    sign_in_admin(role: "sales")
    get admin_departments_path
    assert_redirected_to admin_root_path
  end

  test "index and new render" do
    sign_in_admin
    Department.create!(name_ar: "المبيعات", key: "sales-t", phone: "0500000000")
    get admin_departments_path
    assert_response :success
    assert_match "المبيعات", response.body
    assert_match "sales-t", response.body
    get new_admin_department_path
    assert_response :success
  end

  test "create, update, destroy" do
    sign_in_admin
    assert_difference("Department.count", 1) do
      post admin_departments_path, params: { department: { name_ar: "التصدير", name_en: "Export", key: "", desc_ar: "طلبات خارج السعودية", phone: "+966500000001", email: "export@test.local", position: 3 } }
    end
    d = Department.last
    assert_redirected_to edit_admin_department_path(d)
    assert_equal "export", d.key, "key derived from the English name"
    get edit_admin_department_path(d)
    assert_response :success

    patch admin_department_path(d), params: { department: { key: "export-2", email: "x@test.local" } }
    assert_redirected_to edit_admin_department_path(d)
    assert_equal "export-2", d.reload.key

    patch admin_department_path(d), params: { department: { name_ar: "" } }
    assert_response :unprocessable_entity
    assert_difference("Department.count", -1) { delete admin_department_path(d) }
    assert_redirected_to admin_departments_path
  end
end
