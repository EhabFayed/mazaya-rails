require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  test "index lists users with role labels" do
    admin = sign_in_admin
    User.create!(name: "سالم", email: "salem@test.local", password: "secret-pass-123", role: "sales", last_login_at: Time.current)
    get admin_users_path
    assert_response :success
    assert_select "td a", text: admin.name
    assert_select "td a", text: "سالم"
    assert_select "span.kind", text: "مبيعات"
    assert_select "span.pill-on", text: "نشط", minimum: 2
  end

  test "creates a user" do
    sign_in_admin
    assert_difference("User.count", 1) do
      post admin_users_path, params: { user: { name: "محرر", email: "Editor@Test.local", role: "editor", active: "1", password: "secret-pass-123", password_confirmation: "secret-pass-123" } }
    end
    assert_redirected_to admin_users_path
    u = User.find_by(email: "editor@test.local")
    assert_equal "editor", u.role
    assert u.authenticate("secret-pass-123")
  end

  test "create re-renders on validation errors" do
    sign_in_admin
    post admin_users_path, params: { user: { name: "", email: "bad", role: "editor", password: "x", password_confirmation: "y" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "update keeps the password when left blank" do
    sign_in_admin
    u = User.create!(name: "سالم", email: "salem@test.local", password: "secret-pass-123", role: "sales")
    patch admin_user_path(u), params: { user: { name: "سالم الجديد", email: u.email, role: "editor", active: "0", password: "", password_confirmation: "" } }
    assert_redirected_to admin_users_path
    u.reload
    assert_equal "سالم الجديد", u.name
    assert_equal "editor", u.role
    assert_equal false, u.active
    assert u.authenticate("secret-pass-123")
  end

  test "update changes the password when given" do
    sign_in_admin
    u = User.create!(name: "سالم", email: "salem@test.local", password: "secret-pass-123", role: "sales")
    patch admin_user_path(u), params: { user: { name: u.name, email: u.email, role: "sales", password: "new-pass-4567", password_confirmation: "new-pass-4567" } }
    assert u.reload.authenticate("new-pass-4567")
  end

  test "non-admin can edit only their own name/password, not role or others" do
    me = sign_in_admin(role: "editor")
    other = User.create!(name: "آخر", email: "other@test.local", password: "secret-pass-123", role: "sales")

    get edit_admin_user_path(me)
    assert_response :success
    patch admin_user_path(me), params: { user: { name: "اسمي الجديد", role: "admin", active: "0", email: "hijack@test.local", password: "new-pass-4567", password_confirmation: "new-pass-4567" } }
    assert_redirected_to admin_root_path
    me.reload
    assert_equal "اسمي الجديد", me.name
    assert_equal "editor", me.role
    assert me.active
    assert_not_equal "hijack@test.local", me.email
    assert me.authenticate("new-pass-4567")

    get edit_admin_user_path(other)
    assert_redirected_to admin_root_path
    patch admin_user_path(other), params: { user: { name: "x" } }
    assert_redirected_to admin_root_path
    assert_equal "آخر", other.reload.name
    get admin_users_path
    assert_redirected_to admin_root_path
  end

  test "cannot delete yourself" do
    admin = sign_in_admin
    assert_no_difference("User.count") { delete admin_user_path(admin) }
    assert_redirected_to admin_users_path
    assert_equal "لا يمكنك حذف حسابك الحالي.", flash[:alert]
  end

  test "last admin cannot be deleted (only reachable as self); another admin can" do
    me = sign_in_admin
    User.where(role: "admin").where.not(id: me.id).update_all(role: "editor")
    assert_equal [ me.id ], User.where(role: "admin").pluck(:id)
    assert_no_difference("User.count") { delete admin_user_path(me) }
    assert_redirected_to admin_users_path
    assert_match(/لا يمكنك حذف حسابك/, flash[:alert])

    other_admin = User.create!(name: "مدير ثانٍ", email: "admin2@test.local", password: "secret-pass-123", role: "admin")
    assert_difference("User.count", -1) { delete admin_user_path(other_admin) }
    assert_redirected_to admin_users_path
    assert_equal [ me.id ], User.where(role: "admin").pluck(:id)
  end

  test "destroy deletes another user" do
    sign_in_admin
    u = User.create!(name: "سالم", email: "salem@test.local", password: "secret-pass-123", role: "sales")
    assert_difference("User.count", -1) { delete admin_user_path(u) }
    assert_redirected_to admin_users_path
  end

  test "sales cannot access users" do
    sign_in_admin(role: "sales")
    get admin_users_path
    assert_redirected_to admin_root_path
    get new_admin_user_path
    assert_redirected_to admin_root_path
  end
end
