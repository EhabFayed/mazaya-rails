# Shared trunk: safety & usage guide + per-product guide library.
class SafetyController < ApplicationController
  def index
    @articles = site::SAFETY
    @choose = site::SAFETY_CHOOSE
    @checklist = site::SAFETY_CHECKLIST
    @use = site::SAFETY_USE
    @categories = site::CATEGORIES
    @guides = site::PRODUCTS
  end

  def show
    @article = site.safety(params[:slug]) or not_found!
    @products = @article[:products].filter_map { |slug| site.product(slug) }
    @others = site::SAFETY.reject { |a| a[:slug] == @article[:slug] }
  end
end
