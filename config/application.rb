require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Sforcesuppl
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    config.assets.precompile += %w(handsontable.full.js)
    config.assets.precompile += %w(handsontable-chosen-editor.js)
    config.assets.precompile += %w(jquery-1.11.2.min.js)
    config.assets.precompile += %w(jquery-ui-1.11.3.min.js)
    config.assets.precompile += %w(jstree.js)
    config.assets.precompile += %w(jstree.dropdown.js)
    config.assets.precompile += %w(select2.full.js)
    config.assets.precompile += %w(jquery.fileDownload.js)
    config.assets.precompile += %w(chosen.jquery.js)
    config.assets.precompile += %w(ajaxDownload.js)
    config.assets.precompile += %w(ajaxUtils.js)
    config.assets.precompile += %w(main.coffee)
    config.assets.precompile += %w(describe.coffee)
    config.assets.precompile += %w(soqlexecuter.coffee)
    config.assets.precompile += %w(metadata.coffee)
    config.assets.precompile += %w(tooling.coffee)
    config.assets.precompile += %w(apex.coffee)

    config.before_configuration do
      env_file = File.join(Rails.root, 'config', 'local_env.yml')
      YAML.load(File.open(env_file)).each do |key, value|
        ENV[key.to_s] = value
      end if File.exists?(env_file)
    end
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
