# Layer admin-edited translations (Translation table) on top of the YAML files.
# I18n::DbOverrides is a Simple backend fed from the DB; the Chain checks it
# first and falls back to the YAML backend for everything else.
module I18n
  class DbOverrides < I18n::Backend::Simple
    def initialize
      super
      @loaded_version = nil
    end

    # This backend must never fall back en -> ar (the YAML backend does that);
    # config.i18n.fallbacks mixes Fallbacks into Simple, so disable it here.
    def translate(locale, key, options = EMPTY_HASH)
      super(locale, key, options.merge(fallback: false))
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

    # Called by Translation after_commit; finds this backend inside the chain.
    def self.reload!
      chain = I18n.backend
      return unless chain.respond_to?(:backends)
      chain.backends.grep(I18n::DbOverrides).each(&:reload!)
    end

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
