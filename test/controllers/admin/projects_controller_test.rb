require "test_helper"

class Admin::ProjectsControllerTest < ActionDispatch::IntegrationTest
  def image(name = "proj-tower.jpg") = Rack::Test::UploadedFile.new(Rails.root.join("public/assets/#{name}"), "image/jpeg")

  test "sales role is redirected away" do
    sign_in_admin(role: "sales")
    get admin_projects_path
    assert_redirected_to admin_root_path
  end

  test "index, new and edit render" do
    sign_in_admin
    p = Project.create!(name_ar: "روشن", type_ar: "مشروع سكني")
    p.gallery.attach(image)
    get admin_projects_path
    assert_response :success
    assert_match "مشروع سكني", response.body
    get new_admin_project_path
    assert_response :success
    get edit_admin_project_path(p)
    assert_response :success
    assert_match "purge_gallery_image", response.body
  end

  test "create with main image, gallery, solutions and detail fields" do
    sign_in_admin
    sol = Solution.create!(name_ar: "حل")
    assert_difference("Project.count", 1) do
      post admin_projects_path, params: { project: {
        name_ar: "القدية", name_en: "Qiddiya", slug: "qiddiya-t", type_ar: "ترفيهي", featured: "1", published: "1", position: 1,
        product_supplied_ar: "سلالم", scope_ar: "توريد", quantity_ar: "200", year: "2024", requirements_ar: "متطلبات", solution_ar: "الحل",
        solution_ids: [ "", sol.id.to_s ], image: image, gallery: [ image, image("proj-roshn.jpg") ]
      } }
    end
    p = Project.last
    assert_redirected_to edit_admin_project_path(p)
    assert p.featured
    assert_equal [ sol ], p.solutions.to_a
    assert p.image.attached?
    assert_equal 2, p.gallery.count
    assert_equal "2024", p.year
  end

  test "update appends to the gallery instead of replacing it, purge removes one image" do
    sign_in_admin
    p = Project.create!(name_ar: "روشن")
    p.gallery.attach(image)
    patch admin_project_path(p), params: { project: { name_ar: "روشن ٢", gallery: [ image("proj-saco.jpg") ] } }
    assert_redirected_to edit_admin_project_path(p)
    p.reload
    assert_equal "روشن ٢", p.name_ar
    assert_equal 2, p.gallery.count

    patch admin_project_path(p), params: { project: { year: "2023" } }
    assert_equal 2, p.reload.gallery.count, "update without files must not touch the gallery"

    blob_id = p.gallery.first.blob_id
    delete purge_gallery_image_admin_project_path(p, blob_id: blob_id)
    assert_redirected_to edit_admin_project_path(p)
    assert_equal 1, p.reload.gallery.count
    assert_not p.gallery.map(&:blob_id).include?(blob_id)
  end

  test "invalid create re-renders and destroy removes" do
    sign_in_admin
    post admin_projects_path, params: { project: { name_ar: "" } }
    assert_response :unprocessable_entity
    p = Project.create!(name_ar: "x")
    assert_difference("Project.count", -1) { delete admin_project_path(p) }
    assert_redirected_to admin_projects_path
  end

  test "public project page renders admin data instead of placeholders" do
    p = Project.create!(name_ar: "برج الرياض", slug: "riyadh-tower", product_supplied_ar: "سلالم ألومنيوم", year: "2022", requirements_ar: "احتاج العميل سلالم آمنة", solution_ar: "وفّرنا سلالم مخصصة")
    p.gallery.attach(image)
    get "/projects/riyadh-tower"
    assert_response :success
    assert_match "سلالم ألومنيوم", response.body
    assert_match "احتاج العميل سلالم آمنة", response.body
    assert_match "وفّرنا سلالم مخصصة", response.body
    assert_no_match(/ph-slot/, response.body)
  end
end
