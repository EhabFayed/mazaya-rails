# B2B track: reference projects. Detail data is PENDING until the client
# supplies approved information (see SiteData::PROJECT_FIELDS).
class ProjectsController < ApplicationController
  def index
    @projects = site::PROJECTS
  end

  def show
    @project = site.project(params[:slug]) or not_found!
    @solutions = site.solutions_for_project(@project)
    @fields = site::PROJECT_FIELDS
    @more = site::PROJECTS.reject { |p| p[:slug] == @project[:slug] }.first(3)
  end
end
