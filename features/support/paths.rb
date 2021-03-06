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
      '/'

    when /the sign up page/
      '/users/sign_up'

    when /the sign in page/
      '/users/sign_in'

    when /the main memorization page/
      '/test_verse_quick'

    when /the learn verse page/
      '/learn'

    when /(.*)'s referrer page/
      '/?referrer='+$1

    when /the new blog post page for the blog titled "(.*)"/
      blog_id = Bloggity::Blog.where(:title => $1).first.id.to_s
      '/blog/blogs/'+blog_id+'/blog_posts/new'

    when /the blog/
      '/blog'

    when /the page for the memverse with the id of ([0-9]+)/
      '/memory_verse/'+$1

    when /my group page/
      '/mygroup'

    when /the admin dashboard/
      '/admin'

    when /the utils dashboard/
      '/utils/dashboard'

    # Add more mappings here.
    # Here is an example that pulls values out of the Regexp:
    when /^(.*)'s dashboard$/i
      user_path(User.find_by_login($1))

    else
      begin
        page_name =~ /the (.*) page/
        path_components = $1.split(/\s+/)
        self.send(path_components.push('path').join('_').to_sym)
      rescue Object => e
        raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
          "Now, go and add a mapping in #{__FILE__}"
      end
    end
  end
end

World(NavigationHelpers)
