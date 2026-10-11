# B2C track: hub -> category (sub-categories + filters) -> product.
class ProductsController < ApplicationController
  def index
    @categories = site::CATEGORIES
    @popular = site.popular_products
  end

  def category
    @category = site.category(params[:category]) or not_found!
    @categories = site::CATEGORIES
    @sub = params[:sub].presence
    @kind = params[:kind].presence
    @products = site.products_in(@category[:slug]) # filtering is client-side; ?sub= & ?kind= pre-select
    @catalog = site.download(@category[:catalog])
  end

  def show
    @category = site.category(params[:category]) or not_found!
    @product = site.product(params[:slug]) or not_found!
    not_found! unless @product[:category] == @category[:slug]
    @subcategory = site.subcategory(@category, @product[:subcategory])
    @related = @product[:related].filter_map { |slug| site.product(slug) }
    @safety = @product[:safety] && site.safety(@product[:safety])
    @solutions = site::SOLUTIONS.select { |s| s[:category] == @category[:slug] }
  end
end
