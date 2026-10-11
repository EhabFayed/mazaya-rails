module Admin
  class DashboardController < BaseController
    def admin_section = "dashboard"

    def show
      @lead_counts = Lead.group(:status).count
      @leads_today = Lead.where(created_at: Time.current.beginning_of_day..).count
      @leads_week  = Lead.where(created_at: 7.days.ago..).count
      @leads_by_kind = Lead.where(created_at: 30.days.ago..).group(:kind).count
      @recent_leads = Lead.recent.includes(:assigned_to).limit(8)
      @content = {
        "المنتجات" => [ Product.count, Product.published.count, admin_products_path ],
        "الفئات" => [ Category.count, Category.published.count, admin_categories_path ],
        "الحلول المخصصة" => [ Solution.count, Solution.published.count, admin_solutions_path ],
        "المشاريع" => [ Project.count, Project.published.count, admin_projects_path ],
        "الأخبار والمقالات" => [ Post.count, Post.published.count, admin_posts_path ],
        "الوثائق والكتالوجات" => [ Document.count, Document.joins(:file_attachment).count, admin_documents_path ]
      }
      @pending = pending_items
    end

    private

    # What the client still has to supply — surfaced on the dashboard.
    def pending_items
      items = []
      s = Setting.current
      items << [ "بيانات التواصل (العنوان / الساعات / الهاتف / البريد)", admin_settings_path ] if s.address_ar.blank? || s.phone.blank? || s.email.blank?
      items << [ "خريطة Google Maps", admin_settings_path ] if s.map_embed.blank?
      missing_docs = Document.left_joins(:file_attachment).where(active_storage_attachments: { id: nil }).count
      items << [ "#{missing_docs} وثيقة/كتالوج بدون ملف مرفوع", admin_documents_path ] if missing_docs.positive?
      no_img = Product.left_joins(:images_attachments).where(active_storage_attachments: { id: nil }).count
      items << [ "#{no_img} منتج بدون صور", admin_products_path ] if no_img.positive?
      no_specs = Product.where(specs: []).count
      items << [ "#{no_specs} منتج بدون مواصفات", admin_products_path ] if no_specs.positive?
      no_details = Project.where(product_supplied_ar: [ nil, "" ]).count
      items << [ "#{no_details} مشروع بدون تفاصيل (المنتج المورّد / النطاق / السنة)", admin_projects_path ] if no_details.positive?
      items << [ "#{Post.where(template: true).count} خبر لسه قالب (Template)", admin_posts_path ] if Post.where(template: true).exists?
      items << [ "زمن الرد المتوقع على طلبات RFQ", admin_settings_path ] if s.rfq_response_ar.blank?
      items
    end
  end
end
