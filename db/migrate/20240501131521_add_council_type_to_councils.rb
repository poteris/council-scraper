class AddCouncilTypeToCouncils < ActiveRecord::Migration[7.0]
  def change
    add_column :councils, :council_type, :integer
  end
end
