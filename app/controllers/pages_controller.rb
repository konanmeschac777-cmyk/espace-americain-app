# Écran de couverture, avant la connexion.
#
# Un bibliothécaire déjà connecté n'a rien à faire ici : il retrouve
# directement le geste le plus fréquent, prêter un livre.
class PagesController < ApplicationController
  allow_unauthenticated_access only: :accueil

  def accueil
    return redirect_to tableau_de_bord_path if authenticated?

    @total_copies = Book.active.sum(:total_copies)
  end

  # Écran 10 : ce que le bibliothécaire voit en arrivant, une fois connecté.
  def tableau_de_bord
    @initiales = Current.user.initials
    @prets_en_cours = Loan.open.count
    @retards = Loan.overdue.count
    @total_copies = Book.active.sum(:total_copies)
    @disponibles = @total_copies - @prets_en_cours

    # Les retards remontent en premier (dates les plus anciennes), puis ce
    # qui arrive à échéance dans la semaine : c'est ce qu'il faut relancer
    # ou surveiller aujourd'hui, pas la liste complète des prêts.
    @a_relancer = Loan.open.includes(:book, :member)
                      .where(due_on: ..7.days.from_now.to_date)
                      .oldest_due_first
                      .limit(5)
  end

  # Écran 11 : les chiffres du mois en cours, présentables tels quels au
  # réseau American Spaces et à l'ambassade.
  def rapport_du_mois
    @mois = parse_mois(params[:mois]) || Date.current.beginning_of_month
    periode = @mois..@mois.end_of_month

    @prets_du_mois = Loan.where(borrowed_on: periode).count
    @nouveaux_abonnes = Member.where(joined_on: periode).count

    rendus_du_mois = Loan.returned.where(returned_on: periode)
    @rendus_total = rendus_du_mois.count
    @rendus_a_temps = rendus_du_mois.where("returned_on <= due_on").count

    # Un point par semaine calendaire du mois, pour un petit graphique en
    # barres sans bibliothèque externe.
    @semaines = periode.to_a.group_by(&:cweek).map do |semaine, jours|
      [ "S#{semaine}", Loan.where(borrowed_on: jours.first..jours.last).count ]
    end
    plus_grande_semaine = @semaines.map(&:last).max.to_f
    @semaines = @semaines.map do |libelle, compte|
      proportion = plus_grande_semaine.zero? ? 0 : (compte / plus_grande_semaine * 100).round
      [ libelle, compte, proportion ]
    end

    # Popularité sur l'ensemble du fonds, pas seulement ce mois : avec peu
    # de prêts encore enregistrés, se limiter au mois donnerait une liste
    # vide la plupart du temps.
    compte_par_livre = Loan.group(:book_id).count.sort_by { |_id, compte| -compte }.first(5)
    livres = Book.where(id: compte_par_livre.map(&:first)).index_by(&:id)
    @plus_demandes = compte_par_livre.map { |book_id, compte| [ livres[book_id], compte ] }
  end

  # Écran 20. Une seule langue existe vraiment aujourd'hui : cet écran le
  # dit clairement plutôt que de promettre des traductions qui n'existent
  # pas encore.
  def langue
  end

  # Informations du compte connecté, atteint depuis l'avatar du tableau de
  # bord. C'est ici, et non plus d'un simple appui sur l'avatar, que se
  # trouve la déconnexion.
  def compte
    @initiales = Current.user.initials
  end

  private

  # "2026-07" -> 1er juillet 2026. Ignoré si absent ou mal formé plutôt
  # que de faire planter l'écran pour un lien trafiqué.
  def parse_mois(valeur)
    Date.strptime(valeur, "%Y-%m").beginning_of_month if valeur.present?
  rescue ArgumentError
    nil
  end
end
