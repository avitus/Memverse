# coding: utf-8

module ApplicationHelper

  # ----------------------------------------------------------------------------------------------------------             
  # Idea came from http://stackoverflow.com/questions/185965/how-do-i-change-the-title-of-a-page-in-rails
  # <title><%= page_title %></title> goes in layout view
  # <% page_title "Page Title" %> goes in the actual view. This changes the title also.
  # In our case, page_headings will use the translations found in config/locales ----------------------------------------------------------------------------------------------------------  
   
   
  def page_title(title = nil)
    if title
      content_for(:page_title) { title + " - Memverse" }
    else
      content_for?(:page_title) ? content_for(:page_title) : "Memverse"
    end
  end
 
  def page_description(description = nil)
    if description
      content_for(:page_description) { description }
    else
      content_for?(:page_description) ? content_for(:page_description) : t(:default, :scope => 'page_descriptions')
    end
  end
	# Remember to def page_description
	# Original description: A free, online tool for memorizing the bible
	#  def page_heading(text)
	#    content_tag(:p, content_for(:title){ text })
	#  end
	#
	#  def page_title(title = nil)
	#    if title
	#      content_for(:page_title) { title } + " &mdash; Memverse"
	#    else
	#      content_for?(:page_title) ? content_for(:page_title) : APP_CONFIG[:site_name]  # or a hard-coded default
	#    end
	#  end
	
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
        messages << content_tag(:div, flash[t].html_safe, :id => "flash-#{t}", :class => "flash gray-box-bg" ) << '<div><img src="trans.png" width="1" height="10" alt="" /></div>'.html_safe
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

    value = 'inactive'
    value = 'selected' if tab
    
    if include_class_text
      ('class="' << value << '"').html_safe
    else
      value
    end
  end  

  # ----------------------------------------------------------------------------------------------------------
  # Adds 'selected' class to menu item matching current page
  # ---------------------------------------------------------------------------------------------------------- 
  def sub( sub, include_class_text = true )

    value = 'inactive'
    value = 'active' if sub
    
    if include_class_text
      ('class="' << value << '"').html_safe
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
