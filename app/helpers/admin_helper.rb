# Form building blocks shared by every admin screen.
module AdminHelper
  LEAD_STATUS = { "new" => "جديد", "contacted" => "تم التواصل", "quoted" => "أُرسل عرض", "won" => "تم الإغلاق", "lost" => "لم يتم", "spam" => "سبام" }.freeze
  DOC_TYPES = { "catalog" => "كتالوج", "technical" => "كتالوج فني", "profile" => "بروفايل الشركة", "tds" => "TDS", "guide" => "دليل استخدام", "certificate" => "شهادة", "report" => "تقرير اختبار" }.freeze

  # Arabic + English inputs side by side for a `_ar` / `_en` attribute pair.
  def bi_field(form, attr, label, type: :text_field, hint: nil, required: false, rows: 3)
    content_tag(:div, class: "bi-wrap") do
      safe_join([
        content_tag(:label, label + (required ? " *" : ""), class: "field-label"),
        content_tag(:div, class: "bi") do
          safe_join(%w[ar en].map do |loc|
            content_tag(:div, class: loc) do
              safe_join([
                content_tag(:div, loc == "ar" ? "عربي" : "ENGLISH", class: "lang"),
                type == :text_area ? form.text_area("#{attr}_#{loc}", class: "field sm", rows: rows) : form.text_field("#{attr}_#{loc}", class: "field sm", required: required && loc == "ar")
              ])
            end
          end)
        end,
        (hint ? content_tag(:div, hint, class: "hint") : "".html_safe)
      ])
    end
  end

  # Repeatable JSON rows editor. `cols` = [[key, label, type(:text|:textarea|:number)], ...]
  # Renders existing rows + a <template> for new ones; admin.js handles add/remove/reorder.
  def rows_editor(model_name, field, rows, cols, title:, hint: nil)
    render partial: "admin/shared/rows_editor", locals: { model_name: model_name, field: field, rows: Array(rows), cols: cols, title: title, hint: hint }
  end

  def yes_no(v) = v ? content_tag(:span, "منشور", class: "pill-on") : content_tag(:span, "مسودة", class: "pill-off")

  def thumb(att, alt = "")
    return content_tag(:div, "—", class: "thumb ph") unless att.respond_to?(:attached?) && att.attached?
    image_tag(rails_representation_path(att.variant(resize_to_fill: [ 112, 84 ]), only_path: true), class: "thumb", alt: alt)
  rescue StandardError
    content_tag(:div, "—", class: "thumb ph")
  end

  def errors_for(record)
    return "".html_safe if record.errors.empty?
    content_tag(:div, class: "errors") do
      safe_join([ content_tag(:strong, "لم يتم الحفظ:"), content_tag(:ul) { safe_join(record.errors.full_messages.map { |m| content_tag(:li, m) }) } ])
    end
  end

  def paginate(scope, per: 50)
    page = [ params[:page].to_i, 1 ].max
    total = scope.count
    pages = [ (total.to_f / per).ceil, 1 ].max
    items = scope.offset((page - 1) * per).limit(per)
    [ items, page, pages ]
  end

  def pagination_links(page, pages)
    return "".html_safe if pages <= 1
    content_tag(:div, class: "pagination") do
      safe_join((1..pages).map { |p| p == page ? content_tag(:span, p, class: "current") : link_to(p, url_for(request.query_parameters.merge(page: p))) })
    end
  end
end
