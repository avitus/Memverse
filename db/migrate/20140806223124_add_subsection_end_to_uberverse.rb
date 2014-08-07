class AddSubsectionEndToUberverse < ActiveRecord::Migration
  def change
    add_column :uberverses, :subsection_end, :integer
  end
end
