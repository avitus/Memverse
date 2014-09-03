class AddSubsectionToMemverses < ActiveRecord::Migration
  def change
    add_column :memverses, :subsection, :integer
  end
end
