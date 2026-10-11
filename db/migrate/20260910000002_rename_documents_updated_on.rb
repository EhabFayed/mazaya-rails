class RenameDocumentsUpdatedOn < ActiveRecord::Migration[8.0]
  def change
    rename_column :documents, :updated_on, :version_date # `updated_on` is a magic timestamp column in Rails
  end
end
