# Layer admin-edited translations (Translation table) on top of the YAML files.
# I18n::DbOverrides is a Simple backend fed from the DB; the Chain checks it
# first and falls back to the YAML backend for everything else.
module I18n
  class DbOverrides < I18n::Backend::Simple
    def initialize
      super
      @loaded_version = nil
    end

    # Lazily (re)load when the translations table changes.
    def lookup(locale, key, scope = [], options = {})
      ensure_loaded
      super
    end

    def reload!
      @loaded_version = nil
      @translations = nil
      @initialized = false
      self
    end

    def self.reload! = I18n.backend.backends.first.reload! if I18n.backend.respond_to?(:backends)

    private

    def ensure_loaded
      return if @loaded_version && @loaded_version == cache_version
      @translations = nil
      @initialized = true
      @loaded_version = cache_version
      return unless defined?(Translation) && ActiveRecord::Base.connection.table_exists?("translations")
      Translation.find_each { |t| store_translations(t.locale, t.key.split(".").reverse.inject(t.value) { |v, k| { k => v } }) if t.value.present? }
    rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished, PG::Error
      @loaded_version = :unavailable
    end

    def cache_version
      Setting.table_exists? ? Setting.content_version : :none
    rescue StandardError
      :none
    end
  end
end

Rails.application.config.after_initialize do
  I18n.backend = I18n::Backend::Chain.new(I18n::DbOverrides.new, I18n.backend) unless I18n.backend.is_a?(I18n::Backend::Chain)
end
