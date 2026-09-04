class ApplicationController < ActionController::Base
  include Authentication

  # Le seuil de navigateur, mesuré sur ce que l'application utilise vraiment
  # plutôt que sur le préréglage :modern de Rails.
  #
  # :modern exigeait Chrome 120 (décembre 2023) parce qu'il réclame le webp,
  # les notifications push et les badges — dont aucun ne sert ici : les
  # images sont en jpg et png, et la partie PWA est restée commentée. Sur le
  # serveur de l'Espace, qui n'a pas internet, les navigateurs des téléphones
  # ne se mettront jamais à jour : refuser un Chrome de 2023 rendrait le
  # comptoir inutilisable sans aucun moyen d'y remédier sur place.
  #
  # Ce qui fixe réellement le plancher :
  #
  #   @layer      Chrome 99, Safari 15.4, Firefox 97   toute la feuille de
  #               style est enveloppée dedans : sans lui, la page s'affiche
  #               entièrement nue. C'est le seul qui ne dégrade pas.
  #   import maps Chrome 89, Safari 16.4, Firefox 108  sans eux, aucun
  #               JavaScript ne se charge : le tiroir de navigation ne
  #               s'ouvre plus.
  #   color-mix   Chrome 111, Safari 16.2, Firefox 113 Tailwind écrit une
  #               couleur de repli avant, puis surcharge dans @supports.
  #
  # On retient le plus exigeant des trois, celui en dessous duquel
  # l'application cesse d'être utilisable et non seulement d'être jolie.
  allow_browser versions: { chrome: 111, safari: 16.4, firefox: 113, opera: 97, ie: false }

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  around_action :avec_locale

  private

  # Le MVP ne sert que Tiassalé. Le jour où une autre antenne ouvre, c'est
  # ici que le site viendra de la session du bibliothécaire — à un seul
  # endroit, et non dans chaque contrôleur qui enregistre quelque chose.
  def current_site
    @current_site ||= Site.active.first || Site.first
  end

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
