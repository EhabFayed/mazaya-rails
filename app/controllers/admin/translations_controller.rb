# Page-copy editor: overrides YAML locale keys with Translation rows.
# update is PATCH /admin/translations/:id where :id is the page key (or "search").
module Admin
  class TranslationsController < BaseController
    before_action :require_content!

    def admin_section = "translations"

    def index
      @pages = TranslationCatalog.pages
      @page  = @pages.key?(params[:page]) ? params[:page] : @pages.keys.first
      @q     = params[:q].to_s.strip
      @keys  = TranslationCatalog.keys_for(@q.present? ? nil : @page, @q)
      @overrides = Translation.where(key: @keys.keys).each_with_object({}) { |t, h| (h[t.key] ||= {})[t.locale] = t.value }
      @override_counts = Translation.group(:key).count.keys.group_by { |k| TranslationCatalog.page_of(k) }.transform_values(&:size)
    end

    def update
      submitted = params.fetch(:translations, {}).to_unsafe_h
      reverts   = params.fetch(:revert, {}).to_unsafe_h
      changed = 0
      Translation.transaction do
        submitted.each do |key, locales|
          default = TranslationCatalog.defaults[key]
          next unless default # ignore unknown keys
          %w[ar en].each do |loc|
            next unless locales.is_a?(Hash) && locales.key?(loc)
            value = normalize(locales[loc])
            row = Translation.find_by(locale: loc, key: key)
            if reverts[key].present? || value.blank? || value == normalize(default[loc])
              changed += 1 if row&.destroy
            elsif row.nil? || row.value != value
              (row || Translation.new(locale: loc, key: key)).update!(value: value)
              changed += 1
            end
          end
        end
      end
      page = TranslationCatalog.pages.key?(params[:id]) ? params[:id] : nil
      redirect_to admin_translations_path(page: page, q: params[:q].presence),
                  notice: changed.positive? ? "تم حفظ #{changed} تغيير." : "لا توجد تغييرات."
    end

    private

    def normalize(v) = v.to_s.gsub("\r\n", "\n").strip
  end
end
