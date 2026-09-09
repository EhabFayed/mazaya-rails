require "test_helper"

# Every public route renders 200 with no missing translations.
class SiteSmokeTest < ActionDispatch::IntegrationTest
  ROUTES = %w[
    / /b2b /solutions /catalog /rfq /partners /projects /products
    /about /original /quality /safety /news /contact /search /search?q=%D8%B3%D9%84%D9%85
    /products/ladders /products/ladders?sub=single&kind=ready
    /news?topic=safety /contact?dept=export
    /en /en/b2b /en/products /en/products/ladders /en/products/ladders/single-ladder /en/rfq /en/about
    /en/original /en/quality /en/safety /en/news /en/contact /en/search?q=ladder /en/projects/qiddiya
  ].freeze

  ROUTES.each do |path|
    test "GET #{path}" do
      get path
      assert_response :success
      assert_no_match(/translation missing/, response.body, "missing translation on #{path}")
    end
  end

  test "every data-driven detail page renders" do
    SiteData::SOLUTIONS.each { |s| get "/solutions/#{s[:slug]}"; assert_response :success }
    SiteData::PROJECTS.each  { |p| get "/projects/#{p[:slug]}";  assert_response :success }
    SiteData::PRODUCTS.each  { |p| get "/products/#{p[:category]}/#{p[:slug]}"; assert_response :success }
    SiteData::SAFETY.each    { |a| get "/safety/#{a[:slug]}";    assert_response :success }
    SiteData.posts.each      { |n| get "/news/#{n[:slug]}";      assert_response :success }
  end

  test "english pages render in english and link back to arabic" do
    get "/en/about"
    assert_response :success
    assert_match(/lang="en"/, response.body)
    assert_match(/dir="ltr"/, response.body)
    assert_match(/Since 1991/, response.body)
    assert_match(%r{href="/about"[^>]*hreflang="ar"}, response.body)
    get "/about"
    assert_match(%r{href="/en/about"[^>]*hreflang="en"}, response.body)
  end

  test "unknown slugs 404" do
    get "/products/ladders/nope"
    assert_response :not_found
  end

  test "legacy v1 urls redirect" do
    get "/ladders"
    assert_redirected_to "/products/ladders"
    get "/custom"
    assert_redirected_to "/solutions"
  end

  test "gated download without cookie redirects to the catalog form" do
    get "/downloads/catalog-full"
    assert_redirected_to "/catalog?gate=catalog-full#download"
  end
end
