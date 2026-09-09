require "test_helper"

class Admin::SolutionsControllerTest < ActionDispatch::IntegrationTest
  def image = Rack::Test::UploadedFile.new(Rails.root.join("public/assets/proj-tower.jpg"), "image/jpeg")

  test "sales role is redirected away" do
    sign_in_admin(role: "sales")
    get admin_solutions_path
    assert_redirected_to admin_root_path
  end

  test "index and new render" do
    sign_in_admin
    Solution.create!(name_ar: "سلالم مخصصة")
    get admin_solutions_path
    assert_response :success
    assert_match "سلالم مخصصة", response.body
    get new_admin_solution_path
    assert_response :success
  end

  test "create with image, category and projects" do
    sign_in_admin
    cat = Category.create!(name_ar: "سلالم", slug: "ladders-t")
    proj = Project.create!(name_ar: "القدية")
    assert_difference("Solution.count", 1) do
      post admin_solutions_path, params: { solution: { name_ar: "منصات عمل", name_en: "Work platforms", slug: "work-platforms", desc_ar: "وصف", category_id: cat.id, project_ids: [ "", proj.id.to_s ], position: 3, published: "1", image: image } }
    end
    s = Solution.last
    assert_redirected_to edit_admin_solution_path(s)
    assert_equal "work-platforms", s.slug
    assert_equal cat, s.category
    assert_equal [ proj ], s.projects.to_a
    assert s.image.attached?
    follow_redirect!
    assert_match "تم الحفظ.", response.body
  end

  test "create with blank name re-renders the form" do
    sign_in_admin
    assert_no_difference("Solution.count") do
      post admin_solutions_path, params: { solution: { name_ar: "", name_en: "X" } }
    end
    assert_response :unprocessable_entity
    assert_match "لم يتم الحفظ", response.body
  end

  test "update keeps the image when none is uploaded and destroy removes" do
    sign_in_admin
    s = Solution.create!(name_ar: "قديم")
    s.image.attach(image)
    patch admin_solution_path(s), params: { solution: { name_ar: "جديد", published: "0" } }
    assert_redirected_to edit_admin_solution_path(s)
    s.reload
    assert_equal "جديد", s.name_ar
    assert_not s.published
    assert s.image.attached?
    assert_difference("Solution.count", -1) { delete admin_solution_path(s) }
    assert_redirected_to admin_solutions_path
  end
end
