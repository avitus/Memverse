module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name

    when /the home\s?page/
      '/'.dup

    when /the sign up page/
      '/users/sign_up'.dup

    when /the sign in page/
      '/users/sign_in'.dup

    when /the main memorization page/
      '/test_verse_quick'.dup

    when /the learn verse page/
      '/learn'.dup

    when /(.*)'s referrer page/
      "/?referrer=#{$1}".dup

    when /the new blog post page for the blog titled "(.*)"/
      blog_id = Bloggity::Blog.where(:title => $1).first.id.to_s
      "/blog/blogs/#{blog_id}/blog_posts/new".dup

    when /the blog/
      '/blog'.dup

    when /the page for the memverse with the id of ([0-9]+)/
      "/memory_verse/#{$1}".dup

    when /my group page/
      '/mygroup'.dup

    when /the admin dashboard/
      '/admin'.dup

    when /the utils dashboard/
      '/utils/dashboard'.dup

    # Add more mappings here.
    # Here is an example that pulls values out of the Regexp:
    when /^(.*)'s dashboard$/i
      user_path(User.find_by_login($1))

    else
      begin
        page_name =~ /the (.*) page/
        path_components = $1.split(/\s+/)
        result = path_components.push('path').join('_').to_sym
        self.send(result)
      rescue Object => e
        raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
          "Now, go and add a mapping in #{__FILE__}"
      end
    end
  end
end

World(NavigationHelpers)
