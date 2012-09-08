Split::Dashboard.use Rack::Auth::Basic do |username, password|
  username == 'abadmin' && password == 'MVsplit' # TODO: Figure out how to just check if current_user is admin
end