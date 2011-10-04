require "digest/sha1"  

module Devise
  
  # This module might only be needed for very old versions of restful_authentication
  # module Encryptors
    # class OldRestfulAuthentication < Base
      # def self.digest(password, stretches, salt, pepper)
        # Digest::SHA1.hexdigest("--#{salt}--#{password}--")
      # end
    # end
  # end
#   
  # module Models
    # module DatabaseAuthenticatable      
      # def valid_password_with_legacy?(password)
        # if self.legacy_password_hash.present?
          # if ::Digest::MD5.hexdigest(password).upcase == self.legacy_password_hash
            # self.password = password
            # self.legacy_password_hash = nil
            # self.save!
            # return true
          # else
            # return false
          # end
        # else
          # return valid_password_without_legacy?(password)
        # end
      # end
# 
      # alias_method_chain :valid_password?, :legacy
    # end
# 
    # module Recoverable
      # def reset_password_with_legacy!(new_password, new_password_confirmation)
        # self.legacy_password_hash = nil
        # reset_password_without_legacy!(new_password, new_password_confirmation)
      # end
# 
      # alias_method_chain :reset_password!, :legacy
    # end
  # end
end