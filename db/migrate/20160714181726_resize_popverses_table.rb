class ResizePopversesTable < ActiveRecord::Migration

  def up
    change_column :popverses, :niv_text, :string, :limit => 300
    change_column :popverses, :esv_text, :string, :limit => 300
    change_column :popverses, :nas_text, :string, :limit => 300
    change_column :popverses, :nkj_text, :string, :limit => 300
    change_column :popverses, :kjv_text, :string, :limit => 300
    change_column :popverses, :rsv_text, :string, :limit => 300
  end

  def down
    change_column :popverses, :niv_text, :string, :limit => 255
    change_column :popverses, :esv_text, :string, :limit => 255
    change_column :popverses, :nas_text, :string, :limit => 255
    change_column :popverses, :nkj_text, :string, :limit => 255
    change_column :popverses, :kjv_text, :string, :limit => 255
    change_column :popverses, :rsv_text, :string, :limit => 255  
  end

end
