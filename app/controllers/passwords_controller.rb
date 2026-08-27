class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_password_path, alert: t("app.flash.trop_de_tentatives") }

  def new
  end

  def create
    @email_address = params[:email_address]

    if user = User.find_by(email_address: @email_address)
      # deliver_now plutôt que deliver_later : pas de file d'attente à
      # faire tourner en plus du serveur pour un envoi aussi rare.
      PasswordsMailer.reset(user).deliver_now
    end

    @sent = true
    render :new
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
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: t("app.flash.lien_invalide")
    end
end
