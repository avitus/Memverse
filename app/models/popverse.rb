class Popverse < ActiveRecord::Base
 
  # Structure  
  #      t.string    :pop_ref,     :null => false
  #      t.integer   :num_users,   :null => false
  #      t.string    :book,        :null => false
  #      t.string    :chapter,     :null => false
  #      t.string    :versenum,    :null => false      
  #      t.integer   :niv
  #      t.integer   :esv
  #      t.integer   :nas
  #      t.integer   :nkj
  #      t.integer   :kjv 
  #      t.integer   :rsv 
  #      t.string    :niv_text
  #      t.string    :esv_text
  #      t.string    :nas_text
  #      t.string    :nkj_text
  #      t.string    :kjv_text
  #      t.string    :rsv_text       

  # Validations
  validates_presence_of :pop_ref, :num_users, :book, :chapter, :versenum

  protected
  
end