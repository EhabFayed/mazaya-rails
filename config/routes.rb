Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Lead capture (RFQ, quotes, partner applications, gated downloads) — locale-agnostic
  resources :leads, only: [ :create ]
  get "/sitemap.xml", to: "sitemaps#show", as: :sitemap, defaults: { format: :xml }
  namespace :admin do
    root "dashboard#show"
    get  "login",  to: "sessions#new"
    post "login",  to: "sessions#create"
    delete "logout", to: "sessions#destroy"
    resources :leads, only: [ :index, :show, :update ]
    resources :products do
      collection { get :import; post :import, action: :run_import }
      member { delete :purge_image; patch :reorder }
    end
    resources :categories
    resources :solutions
    resources :projects do
      member { delete :purge_gallery_image }
    end
    resources :posts
    resources :safety_articles
    resources :documents
    resources :content_lists, only: [ :index, :edit, :update ], param: :key
    resources :clients
    resources :departments
    resources :translations, only: [ :index, :update ]
    resource  :settings, only: [ :show, :update ]
    resources :users
  end

  # /ar is the default (no prefix); English lives under /en
  scope "(:locale)", locale: /en/ do
  # Homepage = router between the two tracks
  root "pages#home"

  # ---- B2B track: solutions & projects -------------------------------------
  get "/b2b",       to: "pages#b2b",      as: :b2b
  get "/solutions", to: "solutions#index", as: :solutions
  get "/solutions/:slug", to: "solutions#show", as: :solution
  get "/catalog",   to: "pages#catalog",  as: :catalog
  get "/rfq",       to: "pages#rfq",      as: :rfq
  get "/partners",  to: "pages#partners", as: :partners
  get "/projects",  to: "projects#index", as: :projects
  get "/projects/:slug", to: "projects#show", as: :project

  # ---- B2C track: ready-made products --------------------------------------
  get "/products", to: "products#index", as: :products
  get "/products/:category", to: "products#category", as: :product_category
  get "/products/:category/:slug", to: "products#show", as: :product

  # ---- Shared trunk --------------------------------------------------------
  get "/about",    to: "pages#about",    as: :about
  get "/original", to: "pages#original", as: :original
  get "/quality",  to: "pages#quality",  as: :quality
  get "/safety",   to: "safety#index",   as: :safety
  get "/safety/:slug", to: "safety#show", as: :safety_article
  get "/news",     to: "news#index",     as: :news
  get "/news/:slug", to: "news#show",    as: :news_post
  get "/contact",  to: "pages#contact",  as: :contact
  get "/search",   to: "search#index",   as: :search

  get "/downloads/:key", to: "downloads#show", as: :download
  end

  # ---- Legacy URLs (v1 site) -----------------------------------------------
  get "/ladders", to: redirect("/products/ladders", status: 301)
  get "/carts",   to: redirect("/products/carts", status: 301)
  get "/custom",  to: redirect("/solutions", status: 301)
  get "/index.html", to: redirect("/", status: 301)
  %w[about products ladders carts custom projects quality partners original contact].each do |page|
    get "/#{page}.html", to: redirect("/#{page}", status: 301)
  end
end
