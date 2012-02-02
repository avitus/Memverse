class AddSlugToModels < ActiveRecord::Migration
  def change
    add_column :american_states, :slug, :string
    add_index :american_states, :slug
    
    add_column :countries, :slug, :string
    add_index :countries, :slug
  end
end
