class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    @results = site.search(@query, prefix: locale_prefix)
  end
end
