require "test_helper"

class SitemapsControllerTest < ActionDispatch::IntegrationTest
  test "sitemap lists every product in both locales" do
    get "/sitemap.xml"
    assert_response :success
    assert_equal "application/xml", response.media_type
    SiteData::PRODUCTS.each do |p|
      assert_match "/products/#{p[:category]}/#{p[:slug]}</loc>", response.body
      assert_match "/en/products/#{p[:category]}/#{p[:slug]}</loc>", response.body
    end
    assert_no_match "event-template", response.body
  end

  test "product page carries JSON-LD" do
    get "/products/ladders/multi-position-ladder"
    assert_match "application/ld+json", response.body
    assert_match '"@type":"Product"', response.body
    assert_match '"sku":"MML-000"', response.body
  end
end
