module HomeHelper

  # Public: Link for setting Bible version on quick_start
  #
  # abbrev - The String for the abbreviation used to identify the version.
  # name   - The String for the name of the version displayed to the user.
  #
  # Returns the HTML String.
  def version_set_link(abbrev, name)
    content_tag(:li, id: abbrev, class: "tl-set") do
      link_to name, set_translation_path(abbrev), remote: true
    end
  end
end
