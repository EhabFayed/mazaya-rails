# Ordered bilingual lists (stats, social links, steps, checklists...).
# One row per ContentList::SCHEMA key; rows are created lazily.
module Admin
  class ContentListsController < BaseController
    before_action :require_content!
    before_action :set_list, only: %i[edit update]
    helper_method :schema_cols

    FIELD_LABELS = {
      "title" => "العنوان", "desc" => "الوصف", "text" => "النص", "label" => "التسمية", "sub" => "وصف فرعي",
      "original" => "الأصلي", "counterfeit" => "المقلد", "cta" => "نص الزر", "q" => "السؤال", "a" => "الجواب",
      "value" => "القيمة", "suffix" => "اللاحقة (+ / %)", "key" => "المفتاح", "url" => "الرابط", "abbr" => "اختصار",
      "ar" => "عربي", "en" => "English"
    }.freeze
    TEXTAREA_FIELDS = %w[desc text original counterfeit a].freeze

    def admin_section = "content_lists"

    def index
      existing = ContentList.where(key: ContentList::SCHEMA.keys).index_by(&:key)
      @lists = ContentList::SCHEMA.keys.map { |key| existing[key] || ContentList.create!(key: key) }
    end

    def edit; end

    def update
      @list.items = ContentRecord.rows(params.dig(:content_list, :items))
      if @list.save
        redirect_to edit_admin_content_list_path(@list.key), notice: "تم الحفظ."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_list
      raise ActiveRecord::RecordNotFound unless ContentList::SCHEMA.key?(params[:key])
      @list = ContentList.find_or_create_by!(key: params[:key])
    end

    # [[field, arabic label, type], ...] for rows_editor, derived from the schema.
    def schema_cols(list)
      list.fields.map do |f|
        base, suffix = f.match(/\A(.+?)(?:_(ar|en))?\z/).captures
        label = FIELD_LABELS.fetch(base, base)
        label += suffix == "ar" ? " (عربي)" : " (EN)" if suffix
        type = if TEXTAREA_FIELDS.include?(base) then :textarea
        elsif base == "value" then :number
        else :text
        end
        [ f, label, type ]
      end
    end
  end
end
