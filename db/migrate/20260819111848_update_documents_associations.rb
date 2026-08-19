class UpdateDocumentsAssociations < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key "documents", "meetings"
    rename_column :documents, :meeting_id, :source_id
    add_column :documents, :source_type, :string
    ActiveRecord::Base.connection.execute(<<~SQL)
      UPDATE documents
      SET source_type = 'Meeting'
      WHERE source_id IS NOT NULL
    SQL
  end
end
