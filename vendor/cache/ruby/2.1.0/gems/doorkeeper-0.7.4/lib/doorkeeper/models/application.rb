module Doorkeeper
  class Application
    include Doorkeeper::OAuth::Helpers

    has_many :access_grants, :dependent => :destroy, :class_name => "Doorkeeper::AccessGrant"
    has_many :access_tokens, :dependent => :destroy, :class_name => "Doorkeeper::AccessToken"

    validates :name, :secret, :uid, :redirect_uri, :presence => true
    validates :uid, :uniqueness => true
    validates :redirect_uri, :redirect_uri => true

    before_validation :generate_uid, :generate_secret, :on => :create

    if ::Rails.version.to_i < 4 || defined?(ProtectedAttributes)
      attr_accessible :name, :redirect_uri
    end

    def self.model_name
      ActiveModel::Name.new(self, Doorkeeper, 'Application')
    end

    def self.authenticate(uid, secret)
      self.where(:uid => uid, :secret => secret).first
    end

    def self.by_uid(uid)
      self.where(:uid => uid).first
    end

    private

    def generate_uid
      self.uid = UniqueToken.generate
    end

    def generate_secret
      self.secret = UniqueToken.generate
    end
  end
end
