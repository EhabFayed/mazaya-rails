module Admin
  class DashboardController < BaseController
    def admin_section = "dashboard"

    def show
      @unread      = Lead.unread.count
      @leads_today = Lead.where(created_at: Time.current.beginning_of_day..).count
      @leads_week  = Lead.where(created_at: 7.days.ago..).count
      @downloads_30 = Lead.where(kind: "download", created_at: 30.days.ago..).count
      @leads_by_kind = Lead.where(created_at: 30.days.ago..).group(:kind).count
      @recent_leads = Lead.recent.includes(:assigned_to).limit(8)
      @content = content_overview if can?(:content)
      @pending = pending_items
    end

    private

    # [label, count shown, sub-label, path, icon]
    def content_overview
      docs = Document.published.to_a
      [
        [ "المنتجات", Product.published.count, "منشور من #{Product.count}", admin_products_path, :box ],
        [ "فئات المنتجات", Category.published.count, "منشورة", admin_categories_path, :grid ],
        [ "الحلول المخصصة", Solution.published.count, "منشورة", admin_solutions_path, :tool ],
        [ "المشاريع", Project.published.count, "منشورة", admin_projects_path, :building ],
        [ "الأخبار والمقالات", Post.published.where(template: false).count, "منشورة", admin_posts_path, :news ],
        [ "الكتالوجات والملفات", docs.count(&:has_file?), "لها ملف من #{docs.size}", admin_documents_path, :file ]
      ]
    end

    # What still needs doing before launch: [label, path, level] (level :warn = important)
    def pending_items
      items = []
      s = Setting.current
      if can?(:settings)
        items << [ "بيانات التواصل غير مكتملة (العنوان / الهاتف / البريد)", admin_settings_path, :warn ] if s.address_ar.blank? || s.phone.blank? || s.email.blank?
        items << [ "خريطة Google Maps غير مضافة", admin_settings_path, :warn ] if s.map_embed.blank?
        items << [ "لا يوجد بريد لاستقبال إشعارات الطلبات", admin_settings_path, :warn ] if LeadMailer.recipients.empty?
        items << [ "إرسال البريد غير مُعدّ على الخادم (SMTP) — إشعارات الطلبات لن تصل بالإيميل", admin_settings_path, :warn ] if ENV["SMTP_ADDRESS"].blank?
        admin = User.find_by(email: "admin@mazaya.local")
        items << [ "كلمة مرور المدير ما زالت الافتراضية — غيّرها", edit_admin_user_path(admin), :warn ] if admin&.authenticate("mazaya-admin-2026")
      end
      if can?(:content)
        if SiteData::SOCIAL.all? { |x| x[:url].to_s.in?([ "", "#" ]) }
          items << [ "روابط السوشيال غير مضافة (الأيقونات لا تفتح شيئًا)", edit_admin_content_list_path("social"), :warn ]
        end
        missing = Document.published.where(key: %w[tds user-guide company-profile]).reject(&:has_file?)
        items << [ "ملفات لم تُرفع بعد (أزرارها مخفية في الموقع): #{missing.map(&:title_ar).join('، ')}", admin_documents_path, :info ] if missing.any?
        no_img = Product.published.left_joins(:images_attachments).where(active_storage_attachments: { id: nil }).count
        items << [ "#{no_img} منتج منشور بدون صور", admin_products_path(no_image: 1, published: 1), :warn ] if no_img.positive?
        hidden = Product.where(published: false).count
        items << [ "#{hidden} منتج غير منشور (مخفي من الموقع)", admin_products_path(published: 0), :info ] if hidden.positive?
        no_details = Project.published.where(product_supplied_ar: [ nil, "" ]).count
        items << [ "#{no_details} مشروع بدون تفاصيل (تظهر صفحته بالصورة والاسم فقط)", admin_projects_path, :info ] if no_details.positive?
        templates = Post.where(template: true).count
        items << [ "#{templates} خبر ما زال قالبًا — مخفي من الموقع حتى يُستكمل", admin_posts_path, :info ] if templates.positive?
      end
      items.sort_by { |_, _, level| level == :warn ? 0 : 1 }
    end
  end
end
