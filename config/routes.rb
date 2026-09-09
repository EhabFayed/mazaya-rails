Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#home"

  PagesController::PAGES.each do |page|
    get "/#{page}", to: "pages##{page}", as: page
  end

  # legacy static-site URLs
  get "/index.html", to: redirect("/", status: 301)
  PagesController::PAGES.each do |page|
    get "/#{page}.html", to: redirect("/#{page}", status: 301)
  end
end
