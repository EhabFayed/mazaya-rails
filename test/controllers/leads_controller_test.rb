require "test_helper"

class LeadsControllerTest < ActionDispatch::IntegrationTest
  test "creates a lead and tags kind/source/payload" do
    assert_difference("Lead.count", 1) do
      post leads_path, params: { lead: { kind: "rfq", name: "أحمد", phone: "0500000000", source: "rfq-page", payload: { project_type: "مقاولات", quantity: "١٠٠" } } }, as: :json
    end
    assert_response :created
    lead = Lead.last
    assert_equal "rfq", lead.kind
    assert_equal "مقاولات", lead.payload["project_type"]
  end

  test "download leads set the gate cookie and return the file" do
    post leads_path, params: { lead: { kind: "download", name: "سارة", email: "s@example.com", download_key: "catalog-full" } }, as: :json
    assert_response :created
    assert_equal "/downloads/placeholder.pdf", response.parsed_body["file"]
    assert_equal "1", cookies["mz_gate"]
  end

  test "rejects a lead without phone or email" do
    post leads_path, params: { lead: { kind: "contact", name: "x" } }, as: :json
    assert_response :unprocessable_entity
  end

  test "honeypot silently drops bots" do
    assert_no_difference("Lead.count") do
      post leads_path, params: { website: "spam", lead: { kind: "contact", name: "bot", phone: "1" } }, as: :json
    end
    assert_response :ok
  end
end

class LeadsAttachmentsTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  test "attaches uploaded files and notifies the team" do
    ENV["LEADS_NOTIFY_TO"] = "sales@example.com"
    file = Rack::Test::UploadedFile.new(Rails.root.join("public/downloads/placeholder.pdf"), "application/pdf")
    assert_enqueued_emails 1 do
      post leads_path, params: { lead: { kind: "rfq", name: "سارة", email: "s@example.com", files: [ file ] } }
    end
    assert_response :created
    assert_equal 1, Lead.last.files.count
  ensure
    ENV.delete("LEADS_NOTIFY_TO")
  end

  test "rejects disallowed file types" do
    file = Rack::Test::UploadedFile.new(Rails.root.join("public/site.js"), "text/javascript")
    post leads_path, params: { lead: { kind: "contact", name: "x", phone: "1", files: [ file ] } }
    assert_response :unprocessable_entity
    assert_match "غير مسموح", response.body
  end
end
