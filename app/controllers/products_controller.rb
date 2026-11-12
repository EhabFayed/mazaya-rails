# B2C track: hub -> category (sub-categories + filters) -> product.
class ProductsController < ApplicationController
  def index
    @categories = site::CATEGORIES
    @popular = site.popular_products
    @kind = params[:kind].presence_in(%w[ready custom]) # carried on to the category pages (e.g. from the home page's "custom" card)
  end

  def category
    @category = site.category(params[:category]) or not_found!
    @categories = site::CATEGORIES
    @sub = params[:sub].presence
    @kind = params[:kind].presence
    @q = params[:q].to_s.strip.presence
    @sort = params[:sort].presence
    @products = site.products_in(@category[:slug]) # filtering is client-side; ?sub= ?kind= ?q= ?sort= pre-select
    @catalog = site.download(@category[:catalog])   # title of the section catalog; the file is the B2C catalog
  end

  def show
    @category = site.category(params[:category]) or not_found!
    @product = site.product(params[:slug]) or not_found!
    not_found! unless @product[:category] == @category[:slug]
    @subcategory = site.subcategory(@category, @product[:subcategory])
    @related = @product[:related].filter_map { |slug| site.product(slug) }
    @safety = @product[:safety] && site.safety(@product[:safety])
    @solutions = site::SOLUTIONS.select { |s| s[:category] == @category[:slug] }
    # load-test reports / data sheets tagged with this product (quality page, section 04)
    @load_tests = site::Defaults::LOAD_TESTS.select { |d| d[:product] == "#{@category[:slug]}/#{@product[:slug]}" }
  end
end
