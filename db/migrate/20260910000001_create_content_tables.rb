# Database-backed site content managed from /admin. Every human-readable
# field exists twice (_ar / _en). JSON columns hold ordered lists of
# {title_ar, title_en, desc_ar, desc_en} rows edited from the admin.
class CreateContentTables < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :role, null: false, default: "editor" # admin / editor / sales
      t.boolean :active, null: false, default: true
      t.datetime :last_login_at
      t.timestamps
    end
    add_index :users, "lower(email)", unique: true, name: "index_users_on_lower_email"

    create_table :categories do |t|
      t.string :slug, null: false
      t.string :name_ar, null: false
      t.string :name_en
      t.text :desc_ar, :desc_en, :b2c_ar, :b2c_en, :b2b_ar, :b2b_en, :about_ar, :about_en
      t.string :finder_ar, :finder_en
      t.jsonb :spec_labels, null: false, default: []   # [{ar:, en:}]
      t.string :catalog_key                            # documents.key of the category catalogue
      t.integer :position, null: false, default: 0
      t.boolean :published, null: false, default: true
      t.timestamps
    end
    add_index :categories, :slug, unique: true

    create_table :subcategories do |t|
      t.references :category, null: false, foreign_key: true
      t.string :slug, null: false
      t.string :name_ar, null: false
      t.string :name_en
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :subcategories, [ :category_id, :slug ], unique: true

    create_table :products do |t|
      t.references :category, null: false, foreign_key: true
      t.references :subcategory, foreign_key: true
      t.string :slug, null: false
      t.string :code
      t.string :name_ar, null: false
      t.string :name_en
      t.text :summary_ar, :summary_en
      t.string :kind, null: false, default: "ready"   # ready / custom
      t.boolean :popular, null: false, default: false
      t.boolean :published, null: false, default: true
      t.integer :position, null: false, default: 0
      t.jsonb :features,     null: false, default: []  # [{title_ar,title_en,desc_ar,desc_en}]
      t.jsonb :applications, null: false, default: []
      t.jsonb :specs,        null: false, default: []  # [{label_ar,label_en,value_ar,value_en}]
      t.jsonb :size_cols,    null: false, default: []  # [{ar,en}]
      t.jsonb :sizes,        null: false, default: []  # [[cell,...]] rows
      t.jsonb :faq,          null: false, default: []  # [{q_ar,q_en,a_ar,a_en}]
      t.string :safety_slug
      t.jsonb :related_slugs, null: false, default: []
      t.jsonb :image_labels, null: false, default: {} # blob_id => {ar,en}
      t.timestamps
    end
    add_index :products, :slug, unique: true
    add_index :products, :code

    create_table :solutions do |t|
      t.string :slug, null: false
      t.string :name_ar, null: false
      t.string :name_en
      t.text :desc_ar, :desc_en
      t.references :category, foreign_key: true
      t.integer :position, null: false, default: 0
      t.boolean :published, null: false, default: true
      t.timestamps
    end
    add_index :solutions, :slug, unique: true

    create_table :projects do |t|
      t.string :slug, null: false
      t.string :name_ar, null: false
      t.string :name_en
      t.string :type_ar, :type_en
      t.boolean :featured, null: false, default: false
      t.boolean :published, null: false, default: true
      t.integer :position, null: false, default: 0
      t.string :product_supplied_ar, :product_supplied_en, :scope_ar, :scope_en, :quantity_ar, :quantity_en, :year
      t.text :requirements_ar, :requirements_en, :solution_ar, :solution_en
      t.timestamps
    end
    add_index :projects, :slug, unique: true

    create_join_table :projects, :solutions do |t|
      t.index [ :project_id, :solution_id ], unique: true
    end

    create_table :posts do |t|
      t.string :slug, null: false
      t.string :post_type, null: false, default: "article" # news / article
      t.string :topic, null: false, default: "news"
      t.string :category_ar, :category_en
      t.string :title_ar, null: false
      t.string :title_en
      t.text :excerpt_ar, :excerpt_en, :body_ar, :body_en
      t.date :published_on
      t.boolean :featured, null: false, default: false
      t.boolean :template, null: false, default: false
      t.boolean :published, null: false, default: true
      t.integer :position, null: false, default: 0
      t.jsonb :points, null: false, default: []     # [{title_ar,title_en,desc_ar,desc_en}]
      t.jsonb :checklist, null: false, default: []  # [{ar,en}]
      t.jsonb :related_slugs, null: false, default: []
      t.string :related_safety_slug
      t.timestamps
    end
    add_index :posts, :slug, unique: true

    create_table :safety_articles do |t|
      t.string :slug, null: false
      t.string :name_ar, null: false
      t.string :name_en
      t.text :summary_ar, :summary_en
      t.jsonb :points, null: false, default: []
      t.jsonb :checklist, null: false, default: []
      t.jsonb :related_slugs, null: false, default: []
      t.integer :position, null: false, default: 0
      t.boolean :published, null: false, default: true
      t.timestamps
    end
    add_index :safety_articles, :slug, unique: true

    # Certificates, test reports, catalogues, company profile, TDS, guides.
    create_table :documents do |t|
      t.string :key, null: false            # catalog-full, catalog-ladders, tds, company-profile, cert-iso ...
      t.string :doc_type, null: false, default: "catalog" # catalog / certificate / report / profile / tds / guide
      t.string :title_ar, null: false
      t.string :title_en
      t.text :desc_ar, :desc_en
      t.string :cta_ar, :cta_en
      t.boolean :gated, null: false, default: true
      t.string :version
      t.date :updated_on
      t.integer :position, null: false, default: 0
      t.boolean :published, null: false, default: true
      t.timestamps
    end
    add_index :documents, :key, unique: true

    create_table :clients do |t|
      t.string :name_ar, null: false
      t.string :name_en
      t.string :bg, null: false, default: "#FFFFFF"
      t.integer :position, null: false, default: 0
      t.boolean :published, null: false, default: true
      t.timestamps
    end

    create_table :departments do |t|
      t.string :key, null: false
      t.string :name_ar, null: false
      t.string :name_en
      t.text :desc_ar, :desc_en
      t.string :phone, :email
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :departments, :key, unique: true

    # Small ordered lists rendered as cards/rows: quality steps, custom
    # features/steps, safety points, authenticity checks, comparison rows,
    # certifications, stats, inquiry types, topics, social links...
    create_table :content_lists do |t|
      t.string :key, null: false
      t.string :label
      t.jsonb :items, null: false, default: []
      t.timestamps
    end
    add_index :content_lists, :key, unique: true

    # Singleton row of site-wide settings.
    create_table :settings do |t|
      t.string :whatsapp_display, :whatsapp_number, :phone, :email
      t.text :address_ar, :address_en, :hours_ar, :hours_en
      t.text :map_embed
      t.string :rfq_response_ar, :rfq_response_en
      t.text :notify_emails
      t.integer :founded, default: 1991
      t.integer :content_version, null: false, default: 1
      t.timestamps
    end

    # Overrides for any page-copy key in config/locales/*.yml.
    create_table :translations do |t|
      t.string :locale, null: false
      t.string :key, null: false
      t.text :value
      t.timestamps
    end
    add_index :translations, [ :locale, :key ], unique: true

    change_table :leads do |t|
      t.string :status, null: false, default: "new"   # new / contacted / quoted / won / lost / spam
      t.text :notes
      t.references :assigned_to, foreign_key: { to_table: :users }
      t.datetime :contacted_at
    end
    add_index :leads, :status
  end
end
