module Doorkeeper
  class MissingConfiguration < StandardError
    def initialize
      super("Configuration for doorkeeper missing. Do you have doorkeeper initializer?")
    end
  end

  def self.configure(&block)
    @config = Config::Builder.new(&block).build
    enable_orm
    setup_application_owner if @config.enable_application_owner?
  end

  def self.configuration
    @config || (raise MissingConfiguration.new)
  end

  def self.enable_orm
    require "doorkeeper/models/#{@config.orm}/access_grant"
    require "doorkeeper/models/#{@config.orm}/access_token"
    require "doorkeeper/models/#{@config.orm}/application"
    require 'doorkeeper/models/access_grant'
    require 'doorkeeper/models/access_token'
    require 'doorkeeper/models/application'
  end

  def self.setup_application_owner
    require File.join(File.dirname(__FILE__), 'models', 'ownership')
    Doorkeeper::Application.send :include, Doorkeeper::Models::Ownership
  end

  class Config
    class Builder
      def initialize(&block)
        @config = Config.new
        instance_eval(&block)
      end

      def build
        @config
      end

      def enable_application_owner(opts={})
        @config.instance_variable_set("@enable_application_owner", true)
        confirm_application_owner if opts[:confirmation].present? && opts[:confirmation]
      end

      def confirm_application_owner
        @config.instance_variable_set("@confirm_application_owner", true)
      end

      def default_scopes(*scopes)
        @config.instance_variable_set("@default_scopes", Doorkeeper::OAuth::Scopes.from_array(scopes))
      end

      def optional_scopes(*scopes)
        @config.instance_variable_set("@optional_scopes", Doorkeeper::OAuth::Scopes.from_array(scopes))
      end

      def client_credentials(*methods)
        @config.instance_variable_set("@client_credentials", methods)
      end

      def access_token_methods(*methods)
        @config.instance_variable_set("@access_token_methods", methods)
      end

      def use_refresh_token
        @config.instance_variable_set("@refresh_token_enabled", true)
      end
    end

    module Option

      # Defines configuration option
      #
      # When you call option, it defines two methods. One method will take place
      # in the +Config+ class and the other method will take place in the
      # +Builder+ class.
      #
      # The +name+ parameter will set both builder method and config attribute.
      # If the +:as+ option is defined, the builder method will be the specified
      # option while the config attribute will be the +name+ parameter.
      #
      # If you want to introduce another level of config DSL you can
      # define +builder_class+ parameter.
      # Builder should take a block as the initializer parameter and respond to function +build+
      # that returns the value of the config attribute.
      #
      # ==== Options
      #
      # * [:+as+] Set the builder method that goes inside +configure+ block
      # * [+:default+] The default value in case no option was set
      #
      # ==== Examples
      #
      #    option :name
      #    option :name, :as => :set_name
      #    option :name, :default => "My Name"
      #    option :scopes :builder_class => ScopesBuilder
      #
      def option(name, options = {})
        attribute = options[:as] || name
        attribute_builder = options[:builder_class]

        Builder.instance_eval do
          define_method name do |*args, &block|
            # TODO: is builder_class option being used?
            value = unless attribute_builder
              block ? block : args.first
            else
              attribute_builder.new(&block).build
            end

            @config.instance_variable_set(:"@#{attribute}", value)
          end
        end

        define_method attribute do |*args|
          if instance_variable_defined?(:"@#{attribute}")
            instance_variable_get(:"@#{attribute}")
          else
            options[:default]
          end
        end

        public attribute
      end

      def extended(base)
        base.send(:private, :option)
      end
    end

    extend Option

    option :resource_owner_authenticator,
           :as => :authenticate_resource_owner,
           :default => lambda{|routes|
             logger.warn(I18n.translate('doorkeeper.errors.messages.resource_owner_authenticator_not_configured'))
             nil
           }
    option :admin_authenticator,
           :as => :authenticate_admin,
           :default => lambda{|routes| }
    option :resource_owner_from_credentials,
           :default => lambda{|routes|
             warn(I18n.translate('doorkeeper.errors.messages.credential_flow_not_configured'))
             nil
           }
    option :skip_authorization, :default => lambda{|routes|}
    option :access_token_expires_in,      :default => 7200
    option :authorization_code_expires_in,:default => 600
    option :orm, :default => :active_record
    option :test_redirect_uri, :default => 'urn:ietf:wg:oauth:2.0:oob'
    option :active_record_options, :default => {}

    def refresh_token_enabled?
      !!@refresh_token_enabled
    end

    def enable_application_owner?
      !!@enable_application_owner
    end

    def confirm_application_owner?
      !!@confirm_application_owner
    end

    def default_scopes
      @default_scopes ||= Doorkeeper::OAuth::Scopes.new
    end

    def optional_scopes
      @optional_scopes ||= Doorkeeper::OAuth::Scopes.new
    end

    def scopes
      @scopes ||= default_scopes + optional_scopes
    end

    def orm_name
      [:mongoid2, :mongoid3].include?(orm) ? :mongoid : orm
    end

    def client_credentials_methods
      @client_credentials ||= [:from_basic, :from_params]
    end

    def access_token_methods
      @access_token_methods ||= [:from_bearer_authorization, :from_access_token_param, :from_bearer_param]
    end
  end
end
