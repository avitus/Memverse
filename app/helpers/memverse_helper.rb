module MemverseHelper
  
  # Coloring for test page feedback
  def match_color( match, include_class_text = true )

    value = 'incorrect'
    value = 'correct'   if match
    
    if include_class_text
      'class="' << value << '"'
    else
      value
    end
  end
  
  # Determines the CSS class based on whether user has verse in his/her list
  # (returns the string version of the class, lowercased, as the CSS class name)
  def css_in_user_list( vs_id, include_class_text = true )
    value = 'not-in-user-list'
    value = 'is-in-user-list' if current_user.has_verse_id?(vs_id)
    
    if include_class_text
      'class="' << value << '"'
    else
      value
    end
  end
  

  # Determines the CSS class based on whether this is the current user
  # (returns the string version of the class, lowercased, as the CSS class name)
  def css_current_user_check( user, include_class_text = true )
    value = 'not-current_user'
    value = 'current_user' if current_user == user
    
    if include_class_text
      'class="' << value << '"'
    else
      value
    end
  end  
  
  
end