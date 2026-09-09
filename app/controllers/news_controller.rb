# Shared trunk: news (with template cards) + articles, filterable by topic.
class NewsController < ApplicationController
  def index
    @topic = site::TOPICS.key?(params[:topic]) ? params[:topic] : nil
    @featured = site::NEWS.find { |n| n[:featured] }
    @news = site::NEWS
    @articles = site::ARTICLES
    @posts = site.posts_in(@topic)
    @topics = site::TOPICS
  end

  def show
    @post = site.post(params[:slug]) or not_found!
    @related = site.posts.reject { |n| n[:slug] == @post[:slug] || n[:template] }.select { |n| n[:topic] == @post[:topic] }.first(3)
    @related = site.posts.reject { |n| n[:slug] == @post[:slug] || n[:template] }.first(3) if @related.empty?
    @products = (@post[:related_products] || []).filter_map { |s| site.product(s) }
  end
end
