require "net/smtp"

class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_password_path, alert: t("app.flash.trop_de_tentatives") }

  # Sur le serveur local de l'Espace, il n'y a pas d'internet : le serveur
  # d'envoi est hors d'atteinte. La connexion casse à un endroit différent
  # selon le cas — résolution du nom, route réseau, poignée de main TLS ou
  # dialogue SMTP — mais la conclusion est la même au comptoir, alors on les
  # traite ensemble.
  DELIVERY_ERRORS = [
    SocketError, SystemCallError, Timeout::Error,
    OpenSSL::SSL::SSLError, Net::SMTPError
  ].freeze

  def new
    @offline = offline_server?
  end

  def create
    @email_address = params[:email_address]

    # Sur le serveur local, on ne cherche même pas le compte : la réponse doit
    # être identique que l'adresse existe ou non. Sinon l'écran devient un
    # révélateur de comptes — "pas d'internet" pour une adresse connue, "lien
    # envoyé" pour une inconnue — pour quiconque est sur le Wi-Fi de l'Espace.
    return render_offline_notice if offline_server?

    if user = User.find_by(email_address: @email_address)
      # deliver_now plutôt que deliver_later : pas de file d'attente à
      # faire tourner en plus du serveur pour un envoi aussi rare.
      PasswordsMailer.reset(user).deliver_now
    end

    @sent = true
    render :new
  rescue *DELIVERY_ERRORS
    # Filet de sécurité pour l'instance en ligne : si le serveur d'envoi tombe,
    # mieux vaut la marche à suivre qu'une page d'erreur.
    render_offline_notice
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: t("app.flash.mot_de_passe_modifie")
    else
      redirect_to edit_password_path(params[:token]), alert: t("app.flash.mots_de_passe_ne_correspondent_pas")
    end
  end

  private
    # Vrai sur le serveur local de l'Espace, qui tourne sans internet et ne
    # peut donc envoyer aucun e-mail (OFFLINE_SERVER=true dans compose.yaml).
    def offline_server?
      Rails.configuration.x.offline_server.present?
    end

    def render_offline_notice
      @offline = true
      render :new
    end

    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: t("app.flash.lien_invalide")
    end
end
