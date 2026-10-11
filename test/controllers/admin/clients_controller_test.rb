require "test_helper"

class Admin::ClientsControllerTest < ActionDispatch::IntegrationTest
  def logo = Rack::Test::UploadedFile.new(Rails.root.join("public/assets/logo-saco.png"), "image/png")

  test "sales role is redirected away" do
    sign_in_admin(role: "sales")
    get admin_clients_path
    assert_redirected_to admin_root_path
  end

  test "index and new render" do
    sign_in_admin
    c = Client.create!(name_ar: "ساكو", bg: "#123456")
    c.logo.attach(logo)
    get admin_clients_path
    assert_response :success
    assert_match "ساكو", response.body
    assert_match "#123456", response.body
    get new_admin_client_path
    assert_response :success
  end

  test "create with logo and colour, update, destroy" do
    sign_in_admin
    assert_difference("Client.count", 1) do
      post admin_clients_path, params: { client: { name_ar: "روشن", name_en: "Roshn", bg: "#0d1744", position: 2, published: "1", logo: logo } }
    end
    c = Client.last
    assert_redirected_to edit_admin_client_path(c)
    assert_equal "#0D1744", c.bg
    assert c.logo.attached?
    get edit_admin_client_path(c)
    assert_response :success

    patch admin_client_path(c), params: { client: { name_ar: "روشن ٢", published: "0" } }
    assert_redirected_to edit_admin_client_path(c)
    c.reload
    assert_equal "روشن ٢", c.name_ar
    assert_not c.published
    assert c.logo.attached?

    patch admin_client_path(c), params: { client: { bg: "red" } }
    assert_response :unprocessable_entity
    assert_difference("Client.count", -1) { delete admin_client_path(c) }
    assert_redirected_to admin_clients_path
  end
end
