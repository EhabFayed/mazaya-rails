require "test_helper"

class Admin::SettingsControllerTest < ActionDispatch::IntegrationTest
  test "show renders the sections" do
    sign_in_admin
    get admin_settings_path
    assert_response :success
    %w[واتساب\ والتواصل العنوان\ وساعات\ العمل الخريطة طلبات\ عرض\ السعر الإشعارات].each { |h| assert_select ".section h2", text: h }
    assert_select "textarea[name='setting[map_embed]']"
    assert_select "input[name='setting[address_ar]'], textarea[name='setting[address_ar]']"
    assert_select "input[name='setting[rfq_response_en]']"
  end

  test "update saves settings and extracts the iframe src" do
    sign_in_admin
    iframe = %(<iframe src="https://www.google.com/maps/embed?pb=!1m18!2sMazaya" width="600" height="450" style="border:0;" allowfullscreen="" loading="lazy"></iframe>)
    patch admin_settings_path, params: { setting: {
      whatsapp_display: "+966 50 000 0000", whatsapp_number: "+966 50 000 0000", phone: "+966 11 000 0000", email: "info@mazaya.test",
      address_ar: "الرياض", address_en: "Riyadh", hours_ar: "٨-٥", hours_en: "8-5", map_embed: iframe,
      rfq_response_ar: "خلال يوم عمل", rfq_response_en: "Within one business day",
      notify_emails: "sales@mazaya.test, export@mazaya.test", founded: 1991
    } }
    assert_redirected_to admin_settings_path
    s = Setting.current
    assert_equal "https://www.google.com/maps/embed?pb=!1m18!2sMazaya", s.map_embed
    assert_equal "966500000000", s.whatsapp_number
    assert_equal %w[sales@mazaya.test export@mazaya.test], s.notify_list
    assert_equal "خلال يوم عمل", s.rfq_response_ar
    follow_redirect!
    assert_select ".flash.ok", text: "تم حفظ الإعدادات."
    assert_select "iframe[src='https://www.google.com/maps/embed?pb=!1m18!2sMazaya']"
  end

  test "a bare url is kept as-is" do
    sign_in_admin
    patch admin_settings_path, params: { setting: { map_embed: "  https://www.google.com/maps/embed?pb=abc  " } }
    assert_equal "https://www.google.com/maps/embed?pb=abc", Setting.current.map_embed
  end

  test "public pages reflect saved settings" do
    sign_in_admin
    patch admin_settings_path, params: { setting: { map_embed: "https://www.google.com/maps/embed?pb=xyz", rfq_response_ar: "خلال ٢٤ ساعة", rfq_response_en: "Within 24 hours", phone: "+966 11 123 4567" } }
    get "/contact"
    assert_response :success
    assert_select "iframe[src='https://www.google.com/maps/embed?pb=xyz']"
    assert_match "+966 11 123 4567", response.body
    get "/rfq"
    assert_match "خلال ٢٤ ساعة", response.body
    assert_no_match I18n.t("rfq.after.response_pending", locale: :ar), response.body
    get "/en/rfq"
    assert_match "Within 24 hours", response.body
  end

  test "rfq page shows the pending placeholder when no response time is set" do
    Setting.current.update!(rfq_response_ar: nil)
    get "/rfq"
    assert_match I18n.t("rfq.after.response_pending", locale: :ar), response.body
  end

  test "lead mailer uses notify_emails and falls back to ENV" do
    Setting.current.update!(notify_emails: "a@x.test; b@x.test")
    assert_equal %w[a@x.test b@x.test], LeadMailer.recipients
    Setting.current.update!(notify_emails: "")
    ENV["LEADS_NOTIFY_TO"] = "env@x.test"
    assert_equal %w[env@x.test], LeadMailer.recipients
    ENV.delete("LEADS_NOTIFY_TO")
    assert_equal [], LeadMailer.recipients
    lead = Lead.new(kind: "contact", name: "x", phone: "1")
    assert_nil LeadMailer.new_lead(lead).message.to
  ensure
    ENV.delete("LEADS_NOTIFY_TO")
  end

  test "editor cannot access settings" do
    sign_in_admin(role: "editor")
    get admin_settings_path
    assert_redirected_to admin_root_path
    patch admin_settings_path, params: { setting: { phone: "1" } }
    assert_redirected_to admin_root_path
  end
end
