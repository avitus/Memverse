class AddFavoriteTranslation < ActiveRecord::Migration
 
  def self.up
   
    # Create US States Table - created separately to include data    
    add_column :users,            :gender,         :string
    add_column :users,            :translation,    :string,  :default => "NIV"
    
    # Guess favorite translation
    User.reset_column_information  
    User.all.each do |u|
      if !u.memverses.empty?
        u.update_attribute :translation, u.memverses.map { |mv| mv.verse.translation }.group_by { |tl| tl }.values.max_by(&:size).first
      end
    end      
    
  end


  def self.down
    remove_column :users,           :gender
    remove_column :users,           :translation
  end
  
end






