require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Sforcesuppl
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1
    #config.autoload_paths += %W(#{config.root}/lib)
    #config.eager_load_paths += %W(#{config.root}/lib)
    #config.eager_load_paths += ["#{Rails.root}/lib"]
    config.assets.precompile += %w(handsontable.full.min.js)
    config.assets.precompile += %w(jquery-1.11.2.min.js)
    config.assets.precompile += %w(jquery-ui-1.11.3.min.js)
    config.assets.precompile += %w(jstree.js)
    config.assets.precompile += %w(jstree.min.js)
    config.assets.precompile += %w(main.coffee)
    config.assets.precompile += %w(describe.coffee)
    config.assets.precompile += %w(soqlexecuter.coffee)
    config.assets.precompile += %w(metadata.coffee)
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
