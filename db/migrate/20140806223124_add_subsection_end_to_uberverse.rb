class AddSubsectionEndToUberverse < ActiveRecord::Migration[7.0]
  def change
    add_column :uberverses, :subsection_end, :integer
  end
end
