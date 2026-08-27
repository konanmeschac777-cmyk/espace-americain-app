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

    # Français par défaut, anglais disponible en second (écran 20, "Choisir
    # la langue"). Le choix se garde par appareil, dans un cookie, pas dans
    # l'URL : un lien partagé ou un signet reste valide quelle que soit la
    # langue de celui qui l'ouvre.
    config.i18n.default_locale = :fr
    config.i18n.available_locales = [ :fr, :en ]

    # Abidjan est à UTC+0 toute l'année, sans heure d'été. Les dates
    # d'échéance des prêts tombent donc toujours le bon jour.
    config.time_zone = "UTC"
  end
end
