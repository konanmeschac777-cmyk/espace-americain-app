module ApplicationHelper
  # Auteur d'un ouvrage, ou la mention qui invite à le renseigner.
  # Le fonds a été importé sans les auteurs : l'absence est le cas courant,
  # elle ne doit pas ressembler à un bug.
  def auteur(book)
    if book.author_display
      book.author_display
    else
      tag.span "Auteur à renseigner", class: "auteur-manquant"
    end
  end

  # "5 sur 7 disponibles", coloré selon qu'il reste ou non un exemplaire.
  def badge_disponibilite(book)
    libre = book.copies_available

    if libre.positive?
      tag.span "#{libre} sur #{book.total_copies} disponibles", class: "badge badge-dispo"
    else
      tag.span "Aucun exemplaire disponible", class: "badge badge-retard"
    end
  end

  # Un abonné n'a droit qu'à un livre : l'état est binaire, il n'y a pas
  # de compteur à afficher.
  def badge_abonne(member)
    case member.borrow_block_reason
    when nil                 then tag.span "Peut emprunter",   class: "badge badge-dispo"
    when :already_borrowing  then tag.span "A déjà un livre",  class: "badge badge-attention"
    when :membership_expired then tag.span "Abonnement expiré", class: "badge badge-retard"
    when :suspended          then tag.span "Suspendu",          class: "badge badge-retard"
    end
  end

  # État d'un prêt en cours, du point de vue de l'échéance.
  def badge_echeance(loan)
    if loan.overdue?
      jours = loan.days_overdue
      tag.span "En retard de #{jours} jour#{'s' if jours > 1}", class: "badge badge-retard"
    elsif loan.days_until_due <= 2
      jours = loan.days_until_due
      libelle = jours.zero? ? "À rendre aujourd'hui" : "À rendre dans #{jours} jour#{'s' if jours > 1}"
      tag.span libelle, class: "badge badge-attention"
    else
      tag.span "Dans les délais", class: "badge badge-dispo"
    end
  end

  def date_courte(date) = date && l(date, format: :long)

  # Lien d'appel direct. Sur le téléphone du bibliothécaire, un appui
  # compose le numéro : c'est tout l'intérêt d'afficher les retards.
  # Les numéros sont saisis au format local, l'indicatif est ajouté ici.
  def lien_telephone(phone)
    return nil if phone.blank?

    "tel:+225#{phone.gsub(/\D/, '')}"
  end
end
