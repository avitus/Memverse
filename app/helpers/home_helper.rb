module HomeHelper

  # Public: Link for setting Bible translation on quick_start
  #
  # abbrev - The String for the abbreviation used to identify the translation.
  # name   - The String for the name of the translation displayed to the user.
  #
  # Returns the HTML String.
  def trans_set_link(abbrev, name)
    content_tag(:li, id: abbrev, class: "tl-set") do
      link_to name, set_translation_path(abbrev), remote: true
    end
  end
end
