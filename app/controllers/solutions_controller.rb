# B2B track: custom solutions (index) and one page per named solution.
class SolutionsController < ApplicationController
  def index
    @solutions = site::SOLUTIONS
    @features = site::CUSTOM_FEATURES
    @steps = site::CUSTOM_STEPS
    @projects = site::PROJECTS
  end

  def show
    @solution = site.solution(params[:slug]) or not_found!
    @category = site.category(@solution[:category])
    @projects = site.projects_for_solution(@solution[:slug])
    @features = site::CUSTOM_FEATURES
    @steps = site::CUSTOM_STEPS
    @others = site::SOLUTIONS.reject { |s| s[:slug] == @solution[:slug] }
  end
end
