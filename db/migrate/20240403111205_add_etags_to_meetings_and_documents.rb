class AddEtagsToMeetingsAndDocuments < ActiveRecord::Migration[7.0]
  def change
    add_column :meetings, :etag, :string
    add_column :documents, :etag, :string
  end
end
