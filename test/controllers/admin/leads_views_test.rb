require "test_helper"

class Admin::LeadsViewsTest < ActionDispatch::IntegrationTest
  setup do
    @lead = Lead.create!(kind: "rfq", name: "شركة الاختبار", phone: "0500000001", email: "rfq@example.com", source: "rfq-page",
                         message: "نحتاج ١٠٠ سلم", payload: { "company" => "مقاولات النور", "project_type" => "أبراج", "empty" => "" })
    @lead.files.attach(io: File.open(Rails.root.join("public/downloads/placeholder.pdf")), filename: "spec.pdf", content_type: "application/pdf")
  end

  test "index lists leads with filters and counts for sales" do
    sign_in_admin(role: "sales")
    get admin_leads_path
    assert_response :success
    assert_select "table.adm-table td a", text: "شركة الاختبار"
    assert_select ".hint", text: "مقاولات النور"
    assert_select "span.status.status-new", text: "جديد"
    assert_select "a.filter", text: /طلب عرض سعر \(RFQ\) \(1\)/
    assert_select "a.filter", text: /جديد \(1\)/
    assert_select "a[href=?]", admin_leads_path(format: :csv)
    assert_match "أبراج", response.body
  end

  test "index filters by status/kind/q and preserves them in csv link" do
    sign_in_admin(role: "sales")
    get admin_leads_path(status: "won", kind: "rfq", q: "النور")
    assert_response :success
    assert_select "a[href=?]", admin_leads_path(format: :csv, kind: "rfq", status: "won")
    assert_select ".muted", text: "لا توجد طلبات مطابقة لهذا الفلتر."
    get admin_leads_path(q: "النور")
    assert_select "table.adm-table td a", text: "شركة الاختبار"
  end

  test "show renders contact, payload, attachments and the manage form" do
    sign_in_admin(role: "sales")
    get admin_lead_path(@lead)
    assert_response :success
    assert_select "a.btn-wa[href='https://wa.me/0500000001']"
    assert_select "a[href='mailto:rfq@example.com']"
    assert_select "th.tr-key", text: "project_type"
    assert_select "th.tr-key", text: "empty", count: 0
    assert_select "a", text: "spec.pdf"
    assert_select "form[action=?]", admin_lead_path(@lead) do
      assert_select "select[name='lead[status]']"
      assert_select "select[name='lead[assigned_to_id]']"
      assert_select "textarea[name='lead[notes]']"
    end
    assert_match "نحتاج ١٠٠ سلم", response.body
  end

  test "update changes status/notes/assignee and stamps contacted_at" do
    user = sign_in_admin(role: "sales")
    patch admin_lead_path(@lead), params: { lead: { status: "contacted", notes: "اتصلنا", assigned_to_id: user.id } }
    assert_redirected_to admin_lead_path(@lead)
    @lead.reload
    assert_equal "contacted", @lead.status
    assert_equal "اتصلنا", @lead.notes
    assert_equal user, @lead.assigned_to
    assert_not_nil @lead.contacted_at
    follow_redirect!
    assert_select ".flash.ok", text: "تم تحديث الطلب."
    assert_match "تم التواصل", response.body
  end

  test "editor is redirected away from leads" do
    sign_in_admin(role: "editor")
    get admin_leads_path
    assert_redirected_to admin_root_path
    get admin_lead_path(@lead)
    assert_redirected_to admin_root_path
  end

  test "anonymous is sent to login" do
    get admin_leads_path
    assert_redirected_to admin_login_path
  end
end
