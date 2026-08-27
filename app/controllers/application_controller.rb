class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  around_action :avec_locale

  private

  # La langue se choisit sur l'écran 20 (?locale=en dans le lien), puis se
  # garde dans un cookie pour toute la suite de la visite sur cet appareil.
  # Pas dans l'URL au-delà de ce clic : un lien partagé reste valide quelle
  # que soit la langue de celui qui l'ouvre.
  def avec_locale(&block)
    I18n.with_locale(locale_demandee, &block)
  end

  def locale_demandee
    disponibles = I18n.available_locales.map(&:to_s)
    choix = params[:locale].presence || cookies[:locale]

    if disponibles.include?(choix)
      cookies.permanent[:locale] = choix if params[:locale].present?
      choix
    else
      I18n.default_locale
    end
  end
end
