# /sitemap.xml — every public page in both locales with hreflang alternates.
class SitemapsController < ApplicationController
  def show
    static = %w[/ /b2b /solutions /catalog /rfq /partners /projects /products /about /original /quality /safety /news /contact]
    dynamic = SiteData::SOLUTIONS.map { |s| "/solutions/#{s[:slug]}" } +
              SiteData::PROJECTS.map { |p| "/projects/#{p[:slug]}" } +
              SiteData::CATEGORIES.map { |c| "/products/#{c[:slug]}" } +
              SiteData::PRODUCTS.map { |p| "/products/#{p[:category]}/#{p[:slug]}" } +
              SiteData::SAFETY.map { |a| "/safety/#{a[:slug]}" } +
              SiteData.posts.reject { |n| n[:template] }.map { |n| "/news/#{n[:slug]}" }
    @paths = static + dynamic
    @base = request.base_url
    expires_in 12.hours, public: true
    render formats: :xml, content_type: "application/xml"
  end
end
