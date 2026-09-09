class CreateLeads < ActiveRecord::Migration[8.0]
  def change
    create_table :leads do |t|
      t.string :kind, null: false, default: "contact"   # rfq / quote / partner / download / contact
      t.string :name, null: false
      t.string :phone
      t.string :email
      t.string :org_type                                  # contractor / distributor / project / end_user / other
      t.string :interest                                  # product / partnership / project / ...
      t.text   :message
      t.string :source                                    # page or campaign the lead came from
      t.string :download_key                              # for gated downloads
      t.jsonb  :payload, null: false, default: {}         # extra RFQ fields (quantities, location, timing...)
      t.timestamps
    end
    add_index :leads, :kind
    add_index :leads, :created_at
  end
end
