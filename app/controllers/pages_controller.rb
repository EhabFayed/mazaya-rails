class PagesController < ApplicationController
  PAGES = %w[about products ladders carts custom projects quality partners original contact].freeze

  def home
    render layout: false
  end

  PAGES.each do |page|
    define_method(page) { render page }
  end
end
