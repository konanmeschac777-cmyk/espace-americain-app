class MembersController < ApplicationController
  def new
    # Abonné qui vient d'être inscrit : l'écran de succès prend la place,
    # car le bibliothécaire doit d'abord recopier le numéro sur la carte.
    @confirmed_member = Member.find_by(id: params[:confirmed_member_id])
    return if @confirmed_member

    @member = Member.new(
      site: current_site,
      card_number: Member.next_card_number,
      joined_on: Date.current,
      expires_on: Date.current >> Setting.membership_months
    )
  end

  def create
    @member = Member.new(member_params)
    @member.site       = current_site
    @member.joined_on  = Date.current
    @member.expires_on = Date.current >> Setting.membership_months

    if @member.save
      redirect_to new_member_path(confirmed_member_id: @member.id)
    else
      # Le numéro proposé peut avoir été pris entre l'affichage du
      # formulaire et l'enregistrement. On en recalcule un plutôt que de
      # renvoyer le bibliothécaire vers une erreur qu'il ne peut pas régler.
      @member.card_number = Member.next_card_number if @member.errors.of_kind?(:card_number, :taken)
      render :new, status: :unprocessable_entity
    end
  end

  # Réinscrit pour un an. L'adhésion est gratuite : il n'y a aucun montant
  # à saisir, seulement une autorisation à enregistrer.
  def renew
    member = Member.find(params[:id])
    member.renew_membership!

    message = "#{member.full_name} est réinscrit jusqu'au #{l(member.expires_on, format: :long)}."

    if params[:redirect_to_loan]
      redirect_to new_loan_path(member_id: member.id), notice: message
    else
      redirect_back fallback_location: root_path, notice: message
    end
  end

  private

  def member_params
    params.expect(member: [ :first_name, :last_name, :phone, :card_number ])
  end

  # Le MVP ne sert que Tiassalé. Le jour où une autre antenne ouvre, c'est
  # ici que le site viendra de la session du bibliothécaire.
  def current_site
    @current_site ||= Site.active.first || Site.first
  end
end
