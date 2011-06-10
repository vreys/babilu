require "lucy"
require "i18n_extensions"
module Babilu
  mattr_accessor :cookie_name
  @@cookie_name = 'locale'

  JAVASCRIPT = File.read(File.join(File.dirname(__FILE__), 'javascripts', 'babilu.js'))

  def self.generate
    Lucy.generate("locales") do |g|
      g.namespace = "I18n"
      g[:defaultLocale] = default_locale
      g[:translations] = translations
      g[:cookie_name] = Babilu.cookie_name
      g << methods
    end
  end

  def self.translations
    I18n.all_translations
  end

  def self.default_locale
    I18n.default_locale
  end

  def self.methods
    JAVASCRIPT
  end


  module ControllerMethods

    def self.included(controller)
      controller.send(:after_filter, :set_locale_cookie)
      controller.send(:after_filter, :generate_locale_javascript) if Rails.env.development?
    end

  private

    def set_locale_cookie
      cookies[:locale] = I18n.locale.to_s
    end

    #In development mode, re-generate locale data on each request
    def generate_locale_javascript
      Babilu.generate
    end

  end

  class Railtie < Rails::Railtie
    config.before_configuration do
      config.action_view.javascript_expansions[:defaults] ||= [] << 'locales'
    end
  end if defined?(Rails::Railtie)

end

ActionController::Base.send(:include, Babilu::ControllerMethods)
