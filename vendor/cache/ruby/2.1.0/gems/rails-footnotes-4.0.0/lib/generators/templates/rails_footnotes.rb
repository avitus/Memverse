Footnotes.setup do |f|
  # Wether or not to enable footnotes
  f.enabled = Rails.env.development?
  # You can also use a lambda / proc to conditionally toggle footnotes
  # Example :
  # f.enabled = -> { User.current.admin? }
  # Beware of thread-safety though, Footnotes.enabled is NOT thread safe
  # and should not be modified anywhere else.

  # Only toggle some notes :
  # f.notes = [:session, :cookies, :params, :filters, :routes, :env, :queries, :log, :general]

  # Change the prefix :
  # f.prefix = 'mvim://open?url=file://%s&line=%d&column=%d'

  # Disable style :
  # f.no_style = true

  # Allow to open multiple notes :
  # f.multiple_notes = true
end
