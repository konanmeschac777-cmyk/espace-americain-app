class MembersController < ApplicationController
  RESULTS_LIMIT = 60

  FILTRES = {
    "tous"         => "Tous",
    "en_retard"    => "En retard",
    "a_reinscrire" => "À réinscrire"
  }.freeze

  def index
    @filtre = FILTRES.key?(params[:filtre]) ? params[:filtre] : "tous"
    @query = params[:q].to_s

    en_retard = Member.where(id: Loan.overdue.select(:member_id))

    portee = case @filtre
    when "en_retard"    then en_retard
    when "a_reinscrire" then Member.expired
    else Member.all
    end

    # open_loans (et son ouvrage) sont préchargés pour le badge de chaque
    # ligne, qui a besoin du prêt en cours et de son retard éventuel. Sans
    # ça, soixante abonnés affichés faisaient soixante requêtes de plus.
    @members = portee.search(@query).by_name.includes(open_loans: :book).limit(RESULTS_LIMIT)

    # Toujours visible sous l'onglet "Tous" : ce qui demande une action,
    # peu importe le filtre choisi juste après.
    if @filtre == "tous"
      @a_relancer = en_retard.or(Member.expired).or(Member.suspended)
                             .search(@query).by_name.includes(open_loans: :book).limit(5)
    end

    @total_membres = Member.count
    @adhesions_a_jour = Member.where(suspended: false).where("expires_on > ?", Date.current).count
  end

  def show
    @member = Member.find(params[:id])
    @loan = @member.current_loan
    @history_total = @member.loans.returned.count
    @history = @member.loans.returned.order(returned_on: :desc).limit(10)
    @retards_total = @member.loans.returned.where("returned_on > due_on").count
  end

  def new
    @member = Member.new(
      site: current_site,
      card_number: Member.next_card_number,
      joined_on: Date.current,
      expires_on: Date.current >> Setting.membership_months
    )
  end

  def create
    @member = Member.new(member_params)
    @member.first_name, @member.last_name = split_full_name(params.dig(:member, :full_name))
    @member.site       = current_site
    @member.joined_on  = Date.current
    @member.expires_on = Date.current >> Setting.membership_months

    if @member.save
      # Pas d'écran de succès dédié pour l'inscription : direction le
      # tableau de bord (23), avec le numéro de carte dans le bandeau.
      message = t("app.flash.carte_creee", numero: @member.card_number, nom: @member.full_name)
      redirect_to tableau_de_bord_path, notice: message
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
    @member = Member.find(params[:id])
    @member.renew_membership!

    if ActiveModel::Type::Boolean.new.cast(params[:redirect_to_loan])
      message = t("app.flash.abonne_reinscrit", nom: @member.full_name, date: l(@member.expires_on, format: :long))
      return redirect_to new_loan_path(member_id: @member.id), notice: message
    end

    # Sinon, Rails rend directement members/renew.html.erb : l'écran dédié
    # de la maquette (17), avec la nouvelle date bien en vue.
    @adhesions_a_jour = Member.where(suspended: false).where("expires_on > ?", Date.current).count
    @total_membres = Member.count
  end

  def edit
    @member = Member.find(params[:id])
  end

  def update
    @member = Member.find(params[:id])
    @member.assign_attributes(member_update_params)
    @member.first_name, @member.last_name = split_full_name(params.dig(:member, :full_name))

    if @member.save
      redirect_to member_path(@member), notice: t("app.flash.fiche_modifiee", nom: @member.full_name)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Suspension décidée au comptoir (vol, dégradation, comportement...), pas
  # celle posée automatiquement par un retard.
  def suspend
    member = Member.find(params[:id])
    member.suspend!
    redirect_to member_path(member), notice: t("app.flash.abonne_suspendu", nom: member.full_name)
  end

  def lift_suspend
    member = Member.find(params[:id])
    member.unsuspend!
    redirect_to member_path(member), notice: t("app.flash.suspension_levee", nom: member.full_name)
  end

  private

  def member_params
    params.expect(member: [ :phone, :phone_country_code, :card_number, :age, :neighborhood ])
  end

  # Le numéro de carte ne se modifie pas après coup depuis la fiche : il
  # est calculé une fois à l'inscription, le changer créerait un écart
  # avec la carte physique déjà remise à l'abonné.
  def member_update_params
    params.expect(member: [ :phone, :phone_country_code, :age, :neighborhood ])
  end

  # Le formulaire ne propose qu'un seul champ, "Nom et prénoms" : c'est ce
  # que montre la maquette. Le dernier mot devient le nom de famille, le
  # reste les prénoms, pour rester compatible avec le tri par nom.
  def split_full_name(saisie)
    mots = saisie.to_s.strip.split(/\s+/)
    return [ nil, nil ] if mots.empty?
    return [ mots.first, mots.first ] if mots.size == 1

    [ mots[0..-2].join(" "), mots.last ]
  end
end
