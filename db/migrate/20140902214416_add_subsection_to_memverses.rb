class AddSubsectionToMemverses < ActiveRecord::Migration[7.0]
  def change
    add_column :memverses, :subsection, :integer
  end
end
