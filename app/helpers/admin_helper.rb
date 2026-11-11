# Form building blocks shared by every admin screen.
module AdminHelper
  LEAD_STATUS = { "new" => "جديد", "contacted" => "تم التواصل", "quoted" => "أُرسل عرض", "won" => "تم الإغلاق", "lost" => "لم يتم", "spam" => "سبام" }.freeze
  DOC_TYPES = { "catalog" => "كتالوج", "technical" => "كتالوج فني", "profile" => "بروفايل الشركة", "tds" => "TDS", "guide" => "دليل استخدام", "certificate" => "شهادة", "report" => "تقرير اختبار" }.freeze

  # Sidebar icons (24px stroke paths). Rendered with admin_icon(:name).
  ICONS = {
    home: '<path d="M3 11l9-7 9 7"/><path d="M5 10v10h14V10"/>',
    inbox: '<path d="M22 12h-6l-2 3h-4l-2-3H2"/><path d="M5.5 5h13L22 12v7H2v-7z"/>',
    box: '<path d="M21 8l-9-5-9 5 9 5 9-5z"/><path d="M3 8v8l9 5 9-5V8"/><path d="M12 13v8"/>',
    grid: '<rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/>',
    file: '<path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5"/><path d="M9 13h6M9 17h6"/>',
    tool: '<path d="M14.7 6.3a4 4 0 0 0-5.4 5.4L3 18l3 3 6.3-6.3a4 4 0 0 0 5.4-5.4l-2.5 2.5-2.4-.6-.6-2.4z"/>',
    building: '<rect x="4" y="3" width="16" height="18" rx="1.5"/><path d="M9 7h1M14 7h1M9 11h1M14 11h1M9 15h1M14 15h1"/>',
    star: '<path d="M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 9.5l6.1-.9z"/>',
    news: '<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M7 8h10M7 12h10M7 16h6"/>',
    shield: '<path d="M12 3l8 3v6c0 4.5-3.4 8.3-8 9-4.6-.7-8-4.5-8-9V6z"/><path d="M9 12l2 2 4-4"/>',
    type: '<path d="M4 7V5h16v2"/><path d="M12 5v14M9 19h6"/>',
    list: '<path d="M8 6h13M8 12h13M8 18h13"/><circle cx="4" cy="6" r="1"/><circle cx="4" cy="12" r="1"/><circle cx="4" cy="18" r="1"/>',
    phone: '<path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.2 2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7c.1.9.4 1.8.7 2.7a2 2 0 0 1-.5 2.1L8 9.8a16 16 0 0 0 6 6l1.3-1.3a2 2 0 0 1 2.1-.4c.9.3 1.8.6 2.7.7a2 2 0 0 1 1.7 2z"/>',
    gear: '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/>',
    users: '<circle cx="9" cy="8" r="4"/><path d="M2 21a7 7 0 0 1 14 0"/><path d="M16 4a4 4 0 0 1 0 8M22 21a7 7 0 0 0-4-6.3"/>',
    plus: '<path d="M12 5v14M5 12h14"/>',
    external: '<path d="M14 4h6v6M20 4l-9 9"/><path d="M19 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1h5"/>'
  }.freeze

  def admin_icon(name, size: 18)
    %(<svg class="adm-ico" width="#{size}" height="#{size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">#{ICONS.fetch(name)}</svg>).html_safe
  end

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
