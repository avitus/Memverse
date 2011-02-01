module ApplicationHelper

  # ----------------------------------------------------------------------------------------------------------             
  # Sets the page title and outputs title if container is passed in.
  # eg. <%= title('Hello World', :h2) %> will return the following:
  # <h2>Hello World</h2> as well as setting the page title.
  # ----------------------------------------------------------------------------------------------------------  
  def title(str, container = nil)
    @page_title = str
    content_tag(container, str) if container
  end
  
  # ----------------------------------------------------------------------------------------------------------
  # Outputs the corresponding flash message if any are set (Rails 2 version left for reference)
  # ----------------------------------------------------------------------------------------------------------  
  #  def flash_messages
  #    messages = []
  #    %w(notice warning error).each do |msg|
  ##      messages << content_tag(:div, html_escape(flash[msg.to_sym]), :id => "flash-#{msg}") unless flash[msg.to_sym].blank?
  #      messages << content_tag(:div, flash[msg.to_sym].html_safe, :id => "flash-#{msg}") unless flash[msg.to_sym].blank?
  #    end
  #    messages
  #  end
      
  def flash_messages
    messages = ''.html_safe
    [:error, :notice].each do |t|
      if flash[t]
        messages << content_tag(:div, flash[t].html_safe, :id => "flash-#{t}")
     end
    end
    unless messages.blank?
       content_tag(:div, messages)
    end
  end     
    
    
  # ----------------------------------------------------------------------------------------------------------
  # Returns bible book index
  # Input:  'Deuteronomy' or 'Deut'
  # Output: 5 or nil if book doesn't exist
  # Note: This breaks if string is not a valid book because you can't add 1 + nil
  # ----------------------------------------------------------------------------------------------------------  
  def book_index(str)
    if x = (BIBLEBOOKS.index(str.titleize) || BIBLEABBREV.index(str.titleize))
      return 1+x
    else
      return nil
    end
  end  


  # ----------------------------------------------------------------------------------------------------------
  # Adds 'selected' class to menu item matching current page
  # ---------------------------------------------------------------------------------------------------------- 
  def tab( tab, include_class_text = true )

    value = ''
    value = 'selected'   if tab
    
    if include_class_text
      'class="' << value << '"'
    else
      value
    end
  end  

  # ----------------------------------------------------------------------------------------------------------
  # Support for tag cloud
  # ----------------------------------------------------------------------------------------------------------   
  def tag_cloud( tags )
    classes = %w(cloud1 cloud2 cloud3 cloud4 cloud5 cloud6 cloud7)
  
    max, min = 0, 0
    
    tags.each { |t|
      max = t.count.to_i if t.count.to_i > max
      min = t.count.to_i if t.count.to_i < min
    }
  
    divisor = ((max - min) / classes.size) + 1 
  
    tags.each { |t|
       yield t.name, classes[(t.count.to_i - min) / divisor]
    }
  end
  
  
  # ----------------------------------------------------------------------------------------------------------
  # This function replaces 'escape_javascript' which used to work under Rails 2.2.2 but stopped working in 
  # Rails 2.3.4. For some reason, verses were being truncated on semicolons.
  # ----------------------------------------------------------------------------------------------------------   
  VS_ESCAPE_MAP = {
  '\\'    => '\\\\',
  '</'    => '<\/',
  "\r\n"  => '\n',
  "\n"    => '\n',
  "\r"    => '\n',
  ";"     => "%3B",
  '"'     => '\\"',
  "'"     => "\\'" }
  
  def escape_verse(javascript)
    if javascript
      javascript.gsub(/(\\|<\/|\r\n|[\n\r;"'])/) { VS_ESCAPE_MAP[$1] }
    else
      ''
    end
  end
  
  
end
