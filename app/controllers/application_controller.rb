class ApplicationController < ActionController::Base
  helper_method :site, :locale_prefix, :switch_locale_path

  around_action :switch_locale

  def site = SiteData

  # "" for Arabic (default), "/en" for English — for hand-built URLs.
  def locale_prefix = I18n.locale == :en ? "/en" : ""

  # Same page in the other language.
  def switch_locale_path
    other = I18n.locale == :en ? nil : "en"
    url_for(request.query_parameters.merge(locale: other, only_path: true))
  rescue ActionController::UrlGenerationError
    other ? "/en" : "/"
  end

  private

  def switch_locale(&)
    locale = params[:locale].presence_in(%w[en]) || I18n.default_locale
    I18n.with_locale(locale, &)
  end

  def default_url_options
    { locale: I18n.locale == :en ? "en" : nil }
  end

  def not_found!
    raise ActionController::RoutingError, "Not Found"
  end
end
