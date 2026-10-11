# Static-ish pages. Data-driven pages (products, projects, solutions,
# safety, news) live in their own controllers.
class PagesController < ApplicationController
  # Homepage: router between the B2B and B2C tracks.
  def home
    @featured_projects = site.featured_projects.first(3)
    @latest_news = site::NEWS.first(3)
  end

  # ---- B2B ----
  def b2b
    @categories = site::CATEGORIES
    @projects = site::PROJECTS
  end

  def catalog
    @full = site.download("catalog-full")
    @by_category = site::CATEGORIES.map { |c| [ c, site.download(c[:catalog]) ] }
  end

  def rfq
    @categories = site::CATEGORIES
    @solutions = site::SOLUTIONS
  end

  def partners
    @categories = site::CATEGORIES
  end

  # ---- Shared ----
  def about
    @categories = site::CATEGORIES
  end

  def original
    @checks = site::AUTHENTICITY_CHECKS
    @comparison = site::COMPARISON
  end

  def quality
    @certifications = site::CERTIFICATIONS
    @documents = site::DOCUMENTS
    @steps = site::QUALITY_STEPS
  end

  def contact
    @departments = site::DEPARTMENTS
    @dept = params[:dept].presence
    @inquiry_types = site::INQUIRY_TYPES
  end
end
