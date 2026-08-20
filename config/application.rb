require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module EspaceAmericainApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # L'application est entièrement en français : messages, dates, erreurs.
    config.i18n.default_locale = :fr
    config.i18n.available_locales = [ :fr ]

    # Abidjan est à UTC+0 toute l'année, sans heure d'été. Les dates
    # d'échéance des prêts tombent donc toujours le bon jour.
    config.time_zone = "UTC"
  end
end
