# Forem.user_class         = "User"
# Forem.email_from_address = '"Memverse" <admin@memverse.com>'
# Forem.avatar_user_method = :blog_avatar_url  # ALV: match blog avatar
# Forem.per_page           = 20
# Forem.user_profile_links = true
# Forem.layout             = 'application'

# Forem::NilUser.class_eval do
#   # NilUser#blog_avatar_url calls #email instead of #forem_email
#   alias_method :email, :forem_email
# end
