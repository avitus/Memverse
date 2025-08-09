class RenameTitleToNameOnForemForums < ActiveRecord::Migration[7.0]
  def up
  	rename_column :forem_forums, :title, :name
  end
end

