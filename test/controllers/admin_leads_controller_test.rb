require "test_helper"

class AdminLeadsControllerTest < ActionDispatch::IntegrationTest
  setup { @lead = Lead.create!(kind: "rfq", name: "أحمد", phone: "0500000000", payload: { "company" => "شركة", "quantity" => "١٠٠" }) }

  test "requires basic auth" do
    get admin_leads_path
    assert_response :unauthorized
  end

  test "lists, filters and exports leads" do
    auth = { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "admin") }
    get admin_leads_path, headers: auth
    assert_response :success
    assert_match "أحمد", response.body
    get admin_leads_path(kind: "partner"), headers: auth
    assert_no_match "أحمد", response.body
    get admin_lead_path(@lead), headers: auth
    assert_match "١٠٠", response.body
    get admin_leads_path(format: :csv), headers: auth
    assert_equal "text/csv; charset=utf-8", response.media_type + "; charset=utf-8"
    assert_match "0500000000", response.body
  end
end
