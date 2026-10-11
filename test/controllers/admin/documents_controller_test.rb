require "test_helper"

class Admin::DocumentsControllerTest < ActionDispatch::IntegrationTest
  def pdf = Rack::Test::UploadedFile.new(Rails.root.join("public/downloads/placeholder.pdf"), "application/pdf")

  test "sales role is redirected away" do
    sign_in_admin(role: "sales")
    get admin_documents_path
    assert_redirected_to admin_root_path
  end

  test "index shows type label, key and file state" do
    sign_in_admin
    d = Document.create!(title_ar: "الكتالوج الكامل", key: "catalog-full-t", doc_type: "catalog", version: "v2")
    get admin_documents_path
    assert_response :success
    assert_match "catalog-full-t", response.body
    assert_match "كتالوج", response.body
    assert_match "بدون ملف", response.body
    d.file.attach(pdf)
    get admin_documents_path
    assert_match "PDF", response.body
    get new_admin_document_path
    assert_response :success
  end

  test "create with a pdf, update without a file keeps it, destroy removes" do
    sign_in_admin
    assert_difference("Document.count", 1) do
      post admin_documents_path, params: { document: { title_ar: "شهادة", title_en: "Certificate", key: "cert-t", doc_type: "certificate", desc_ar: "وصف", cta_ar: "تحميل", gated: "0", version: "1.0", version_date: "2026-02-01", position: 4, published: "1", file: pdf } }
    end
    d = Document.last
    assert_redirected_to edit_admin_document_path(d)
    assert_equal "certificate", d.doc_type
    assert_not d.gated
    assert_equal Date.new(2026, 2, 1), d.version_date
    assert d.file.attached?
    get edit_admin_document_path(d)
    assert_response :success
    assert_match "placeholder.pdf", response.body

    patch admin_document_path(d), params: { document: { title_ar: "شهادة محدثة", version: "1.1" } }
    assert_redirected_to edit_admin_document_path(d)
    d.reload
    assert_equal "1.1", d.version
    assert d.file.attached?

    patch admin_document_path(d), params: { document: { key: "Bad Key!" } }
    assert_response :unprocessable_entity
    assert_difference("Document.count", -1) { delete admin_document_path(d) }
    assert_redirected_to admin_documents_path
  end
end
