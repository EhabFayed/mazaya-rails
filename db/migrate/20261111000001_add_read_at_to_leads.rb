# Admin inbox: when a lead was first read (nil = unread). Existing leads count as read.
class AddReadAtToLeads < ActiveRecord::Migration[8.0]
  def up
    add_column :leads, :read_at, :datetime
    add_index :leads, :read_at
    execute "UPDATE leads SET read_at = created_at"
  end

  def down
    remove_column :leads, :read_at
  end
end
